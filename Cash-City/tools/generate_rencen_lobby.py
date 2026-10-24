"""Original estimated public lobby/connector; source plans remain untouched."""
import hashlib
import json
import math
import os
from pathlib import Path
import sys
sys.path.insert(0,str(Path(os.environ.get('TEMP',''))/'smallsignals-test-deps'))
from shapely.geometry import Point,Polygon,LineString,shape
from shapely import affinity
from shapely.ops import unary_union

ROOT=Path(__file__).resolve().parents[1]
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def cross(a,b):return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
def norm(v):
    length=math.sqrt(dot(v,v));return [x/length for x in v]

def generate(root=ROOT):
    filenames=['geometry.json','detroit_geography.json','rencen_detail_plan.json','wintergarden_plan.json']
    inputs={name:json.loads((root/'data'/name).read_text()) for name in filenames}
    source=inputs['geometry.json'];guard=source[19478]
    assert guard['name']=='Facade_1307210646','Source portal index changed'
    finish=next(f for f in inputs['rencen_detail_plan.json']['sourceFinishChanges'] if f['sourceIndex']==19478)
    assert finish['record']==guard,'Approved finish guard differs'
    portal=[guard['pos'][0],.35,guard['pos'][2]]
    center=[70.973,36,6.539];west=[-24.812053,36,60.624336]
    city_guard=source[19465]
    assert city_guard['name']=='Facade_1307210646','Jefferson portal index changed'
    city_finish=next(f for f in inputs['rencen_detail_plan.json']['sourceFinishChanges'] if f['sourceIndex']==19465)
    assert city_finish['record']==city_guard,'Jefferson finish guard differs'
    cm,cp,cs=city_guard['matrix'],city_guard['pos'],city_guard['size'];city_along=-7.927974693429661
    city_portal=[cp[0]+cm[2]*city_along,.35,cp[2]+cm[8]*city_along]
    city_length=math.hypot(center[0]-city_portal[0],center[2]-city_portal[2])
    city_inward=[(center[0]-city_portal[0])/city_length,0,(center[2]-city_portal[2])/city_length]
    city_outside=[city_portal[0]-cm[0]*10,-.25,city_portal[2]-cm[6]*10]
    city_landing=[city_portal[i]+city_inward[i]*10 for i in range(3)]
    city_ramp_end=[center[i]-city_inward[i]*55 for i in range(3)]
    length=math.hypot(portal[0]-center[0],portal[2]-center[2])
    outward=[(portal[0]-center[0])/length,0,(portal[2]-center[2])/length]
    ramp_end=[center[0]+outward[0]*55,36,center[2]+outward[2]*55]
    hall_direction=norm([west[i]-center[i] for i in range(3)])
    hall_start=[center[i]+hall_direction[i]*54.8 for i in range(3)]
    hall_end=[west[i]-hall_direction[i]*18 for i in range(3)]
    # Room local X points from west reception toward the central circulation floor.
    room_x=[-hall_direction[0],0,-hall_direction[2]]
    room_z=cross(room_x,[0,1,0])
    room_matrix=[room_x[0],0,room_z[0],0,1,0,room_x[2],0,room_z[2]]
    records=[]
    def add(name,size,pos,matrix=None,color=None,material='Limestone',collide=True,shape_value=None):
        record={'name':name,'size':size,'pos':pos,'matrix':matrix or [1,0,0,0,1,0,0,0,1],
                'color':color or [188,186,173],'material':material,'collide':collide,'trans':0,'cls':'Part',
                'meta':{'owner':'RenaissanceLobby','classification':'Original gameplay estimate'}}
        if shape_value is not None:record['shape']=shape_value
        records.append(record);return record
    def deck(name,a,b,width,color=None):
        direction=norm([b[i]-a[i] for i in range(3)])
        right=norm(cross([0,1,0],direction));up=cross(direction,right)
        matrix=[right[0],up[0],direction[0],right[1],up[1],direction[1],right[2],up[2],direction[2]]
        pos=[(a[i]+b[i])/2-up[i]*.25 for i in range(3)]
        add(name,[width,.5,math.dist(a,b)],pos,matrix,color)
        return right
    def rail(name,a,b):
        direction=norm([b[i]-a[i] for i in range(3)])
        right=norm(cross([0,1,0],direction));up=cross(direction,right)
        matrix=[right[0],up[0],direction[0],right[1],up[1],direction[1],right[2],up[2],direction[2]]
        # Continuous guard panel, not only a top tube that tiny players fall through.
        add(name,[.25,3.5,math.dist(a,b)],[(a[i]+b[i])/2+(1.75 if i==1 else 0) for i in range(3)],matrix,[139,149,150],'Metal')
    ramp_right=deck('Lobby_RisingConnectorFloor',portal,ramp_end,10)
    # Start guards beyond the source aperture, so they cannot narrow the8stud portal.
    for sign in (-1,1):
        a=[portal[i]+(ramp_end[i]-portal[i])*.025+ramp_right[i]*4.875*sign for i in range(3)]
        b=[ramp_end[i]+ramp_right[i]*4.875*sign for i in range(3)]
        rail('Lobby_RampFallGuard',a,b)
    circle_matrix=[0,-1,0,1,0,0,0,0,1]
    add('Lobby_CircularCirculationFloor',[.5,110,110],[center[0],35.75,center[2]],circle_matrix,[192,190,177],shape_value=2)
    hall_right=deck('Lobby_WestHallFloor',hall_start,hall_end,10)
    for sign in (-1,1):
        rail('Lobby_HallFallGuard',[hall_start[i]+hall_right[i]*4.875*sign for i in range(3)],
             [hall_end[i]+hall_right[i]*4.875*sign for i in range(3)])
    # Omit circle-edge guards wherever the real connector/hallway joins.
    joins=unary_union([LineString([(portal[0],portal[2]),(center[0],center[2])]).buffer(5.2),
           LineString([(center[0],center[2]),(west[0],west[2])]).buffer(5.2),
           LineString([(city_portal[0],city_portal[2]),(center[0],center[2])]).buffer(5.2)])
    for index in range(16):
        angles=[2*math.pi*index/16,2*math.pi*(index+1)/16]
        points=[[center[0]+54.7*math.cos(a),36,center[2]+54.7*math.sin(a)] for a in angles]
        line=LineString([(p[0],p[2]) for p in points])
        remaining=line.difference(joins)
        pieces=list(remaining.geoms) if remaining.geom_type=='MultiLineString' else [remaining]
        for piece in pieces:
            if piece.is_empty or piece.length<.2:continue
            a,b=piece.coords[0],piece.coords[-1]
            rail('Lobby_CirculationFallGuard',[a[0],36,a[1]],[b[0],36,b[1]])
    def room_point(x,y,z):return [west[0]+room_x[0]*x+room_z[0]*z,y,west[2]+room_x[2]*x+room_z[2]*z]
    add('Lobby_WestReceptionFloor',[36,.5,28],room_point(0,35.75,0),room_matrix)
    add('Lobby_WestReceptionCeiling',[36,.4,28],room_point(0,48.2,0),room_matrix,[208,205,193])
    add('Lobby_WestBackWall',[.4,12,28],room_point(-18,42,0),room_matrix,[208,205,193])
    for sign in (-1,1):
        add('Lobby_WestSideWall',[36,12,.4],room_point(0,42,sign*14),room_matrix,[208,205,193])
        add('Lobby_WestEntrySide',[.4,12,9],room_point(18,42,sign*9.5),room_matrix,[208,205,193])
    add('Lobby_WestEntryHeader',[.4,2,10],room_point(18,47,0),room_matrix,[208,205,193])
    add('Lobby_DecorativeReceptionCounter',[4,3,14],room_point(-10,37.5,0),room_matrix,[109,91,70],'WoodPlanks',True)
    add('Lobby_DecorativeCounterTop',[4.4,.25,14.4],room_point(-10,39.125,0),room_matrix,[201,198,184],'Marble',True)
    # Native seats are upgraded by the runtime factory; no per-chair scripts.
    for side in (-1,1):
        orientation=[v*(side if index in (0,2,6,8) else 1) for index,v in enumerate(room_matrix)]
        z=side*8
        for number,x in enumerate((-1.5,1.5)):
            seat=add('Lobby_GuestSeat_'+str(side)+'_'+str(number),[2.8,.3,2.6],room_point(x,37.4,z),orientation,[88,104,105],'Metal')
            seat['seat']=True
        add('Lobby_GuestBenchBack',[6,2,.25],room_point(0,38.25,z+side*1.35),room_matrix,[112,87,61],'WoodPlanks')
        add('Lobby_GuestBenchPlinth',[6,.3,4],room_point(0,36.15,z),room_matrix,[171,173,168],'Concrete')
        add('Lobby_GuestPlanter',[1.8,1.4,1.8],room_point(8,36.7,z),room_matrix,[177,175,164],'Concrete')
        add('Lobby_GuestGreenery',[1.3,1.6,1.3],room_point(8,38.05,z),room_matrix,[69,100,62],'Grass',False)
    # Flat generic sign anchor; Lead adds actual text, no pretend interactive desk.
    sign={'text':'SKYLINE HOTEL','pos':room_point(-17.65,44,0),'matrix':room_matrix,'size':[.15,2.5,13]}
    add('Lobby_GenericHotelSignBoard',sign['size'],sign['pos'],sign['matrix'],[54,66,68],'Metal',False)
    wayfinding=add('Lobby_WintergardenWayfinding',[.12,1.8,8],
                   [portal[0]-guard['matrix'][0]*.7,11.6,portal[2]-guard['matrix'][6]*.7],guard['matrix'],[54,66,68],'Metal',False)
    wayfinding['signText']='HOTEL LOBBY'
    wayfinding['returnText']='RIVERWALK'
    # Explicit source-aware portal infill retains the approved pale podium finish.
    m,p,s=guard['matrix'],guard['pos'],guard['size'];bottom=.35;top=10.35
    for sign_value in (-1,1):
        side=(s[2]-8)/2;along=sign_value*(4+side/2)
        add('Lobby_SourcePortalSideInfill',[s[0],s[1],side],[p[0]+m[2]*along,p[1],p[2]+m[8]*along],m,finish['color'],finish['material'])
    add('Lobby_SourcePortalHeader',[s[0],s[1]-top,8],[p[0],(top+s[1])/2,p[2]],m,finish['color'],finish['material'])
    add('Lobby_SourcePortalSill',[s[0],bottom,8],[p[0],bottom/2,p[2]],m,finish['color'],finish['material'])
    rear={'center':[portal[0],5.35,portal[2]],'pos':[portal[0],5.35,portal[2]],'matrix':m,'width':8,'height':10,'bottomY':.35,'topY':10.35}
    # Jefferson frontage: original estimated apron, a flat door sweep landing, then ramp.
    deck('Lobby_JeffersonApronFloor',city_outside,city_portal,10)
    deck('Lobby_JeffersonLandingFloor',city_portal,city_landing,10)
    city_right=deck('Lobby_JeffersonRisingFloor',city_landing,city_ramp_end,10)
    for side_sign in (-1,1):
        rail('Lobby_JeffersonRampFallGuard',[city_landing[i]+city_right[i]*4.875*side_sign for i in range(3)],
             [city_ramp_end[i]+city_right[i]*4.875*side_sign for i in range(3)])
    # Offset doorway leaves unequal source-wall side spans; never assume a centered cut.
    for lo,hi in [(-cs[2]/2,city_along-4),(city_along+4,cs[2]/2)]:
        along=(lo+hi)/2
        add('Lobby_JeffersonSourcePortalSideInfill',[cs[0],cs[1],hi-lo],
            [cp[0]+cm[2]*along,cp[1],cp[2]+cm[8]*along],cm,city_finish['color'],city_finish['material'])
    add('Lobby_JeffersonSourcePortalHeader',[cs[0],cs[1]-10.35,8],
        [city_portal[0],(10.35+cs[1])/2,city_portal[2]],cm,city_finish['color'],city_finish['material'])
    add('Lobby_JeffersonSourcePortalSill',[cs[0],.35,8],[city_portal[0],.175,city_portal[2]],cm,city_finish['color'],city_finish['material'])
    city_sign=add('Lobby_JeffersonWayfinding',[.12,1.8,8],[city_portal[0]-cm[0]*.7,11.6,city_portal[2]-cm[6]*.7],cm,[54,66,68],'Metal',False)
    city_sign['signText']='SKYLINE HOTEL';city_sign['returnText']='JEFFERSON / CITY'
    city_door={'name':'Jefferson city entrance','pos':[city_portal[0],5.35,city_portal[2]],
               'matrix':[cm[2],0,-cm[0],0,1,0,cm[8],0,-cm[6]],'width':8,'apertureWidth':8,'height':10,
               'approachPoints':[[city_portal[0]-cm[0]*5,.35,city_portal[2]-cm[6]*5],city_landing]}
    city_samples=[]
    for point,label in [(city_outside,'external original apron'),(city_portal,'Jefferson doorway'),(city_landing,'flat inside door landing')]:
        city_samples.append({'pos':point,'floorY':point[1],'width':6,'clearHeight':8,'span':label})
    for t in (.2,.4,.6,.8,1):
        point=[city_landing[i]+(city_ramp_end[i]-city_landing[i])*t for i in range(3)]
        city_samples.append({'pos':point,'floorY':point[1],'width':6,'clearHeight':8,'span':'Jefferson rising connector'})
    city_samples.append({'pos':center,'floorY':36,'width':6,'clearHeight':8,'span':'circular circulation'})
    samples=[]
    # Include source-floor approach, smooth ramp and flat circle/hall/room targets.
    source_inward=[m[0],0,m[6]]
    samples.append({'pos':[portal[0]-source_inward[0]*8,.35,portal[2]-source_inward[2]*8],'floorY':.35,'width':6,'clearHeight':8,'span':'Wintergarden rear approach'})
    for t in (0,.2,.4,.6,.8,1):
        point=[portal[i]+(ramp_end[i]-portal[i])*t for i in range(3)]
        samples.append({'pos':point,'floorY':point[1],'width':6,'clearHeight':8,'span':'rising connector'})
    for point,name in [(center,'circular circulation'),(hall_end,'west entrance'),(west,'west reception')]:
        samples.append({'pos':point,'floorY':36,'width':6,'clearHeight':8,'span':name})
    assert len(records)<=120,'Bounded lobby budget exceeded'
    return {'id':'RenaissanceLobby','records':records,'sourceReplacements':[{'sourceIndex':19478,'record':guard},{'sourceIndex':19465,'record':city_guard}],
            'rearPortal':rear,'routeSamples':samples,'routeJefferson':city_samples,'doorAnchors':[city_door],'signAnchors':[sign],
            'metadata':{'sourceHashes':{name:hashlib.sha256((root/'data'/name).read_bytes()).hexdigest() for name in filenames},
                        'floorY':36,'classification':'Original estimated public hotel lobby; not measured historic Level3',
                        'center':center,'outerRadius':55,'innerReferenceRadius':22,'westRoomCenter':west,
                        'westRoomSize':[36,12,28],'rampStart':portal,'rampEnd':ramp_end,'rampWidth':10,
                        'rampGradeDegrees':math.degrees(math.atan2(35.65,math.hypot(ramp_end[0]-portal[0],ramp_end[2]-portal[2]))),
                        'podiumOsm':1307210646,'podiumSourceTopStuds':15/.28,'approvedPortalFinish':{'color':finish['color'],'material':finish['material']},
                        'jefferson':{'sourceFaceIndex':19465,'sourceLocalZ':city_along,'doorway':city_portal,'outside':city_outside,'landingEnd':city_landing,
                                     'rampEnd':city_ramp_end,'rampWidth':10,'groundYEstimate':-.25,'floorY':.35,'insideFlatLength':10,
                                     'rampGradeDegrees':math.degrees(math.atan2(35.65,city_length-65)),
                                     'nearestSourcePathOsm':325808775,'nearestSourcePathDistanceMeters':32.58958901532056,
                                     'classification':'Original estimated apron/entrance; not verified existing sidewalk or historic entrance location'},
                        'assumptions':['Circular floor has no invented solid elevator core.','Sloped floor meets raised circle at its perimeter with no step, then route continues flat to center.',
                                       'Rear portal and shared Wintergarden back opening are Lead atomic integration dependencies.','No door or per-object script on ramp; west hallway has an open10stud entry.',
                                       'Prior native furniture/players/vehicles, actual walking at all sizes, guard continuity, sign rendering and FPS need Lead validation.']}}

if __name__=='__main__':
    plan=generate();(ROOT/'data/rencen_lobby_plan.json').write_text(json.dumps(plan,sort_keys=True,separators=(',',':'),allow_nan=False)+'\n',encoding='utf-8')
    print(json.dumps({'parts':len(plan['records']),'rampGradeDegrees':plan['metadata']['rampGradeDegrees'],'replacements':len(plan['sourceReplacements'])}))
