"""Small original land-grade access study; roads and existing promenade untouched."""
import hashlib,json,math,os,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(Path(os.environ.get('TEMP',''))/'smallsignals-test-deps'))
import shapely
from shapely.geometry import Polygon,Point,LineString,shape
from shapely.ops import unary_union
from shapely import affinity
from generate_wintergarden import sub,dot,cross,norm

def generate(root=ROOT):
    names=['detroit_geography.json','geometry.json','wintergarden_plan.json','rencen_walk_plan.json']
    loaded={name:json.loads((root/'data'/name).read_text()) for name in names}
    g=loaded[names[0]];scale=g['studsPerMeter'];door=loaded[names[2]]['doorAnchors'][0]
    origin=[door['pos'][0],door['pos'][2]];f=[door['outwardNormal'][0],door['outwardNormal'][2]];right=[f[1],-f[0]]
    def point(t,side,y):return [origin[0]+f[0]*t+right[0]*side,y,origin[1]+f[1]*t+right[1]*side]
    def rectangle(t0,t1,s0,s1):return Polygon([(point(t,s,0)[0],point(t,s,0)[2]) for t,s in [(t0,s0),(t1,s0),(t1,s1),(t0,s1)]])
    roads=unary_union([affinity.scale(shape(feat['geometry']).buffer(feat['width']/2,cap_style=2),xfact=scale,yfact=scale,origin=(0,0))
                       for feat in g['features'] if feat['kind']=='road' and feat['elevation']==0])
    land=affinity.scale(shape(g['land']),xfact=scale,yfact=scale,origin=(0,0))
    # Only downstream dry polygon retained. No new surface lies on the Atwater corridor.
    landing=rectangle(42,60,-10,10).difference(roads)
    if landing.geom_type=='MultiPolygon':landing=max(landing.geoms,key=lambda poly:poly.centroid.distance(Point(point(42,0,0)[0],point(42,0,0)[2])))
    assert landing.geom_type=='Polygon' and land.covers(landing),'Dry source landing unavailable'
    records=[]
    def add(name,size,pos,matrix,material='Concrete',color=None,cls='Part'):
        records.append({'name':name,'size':size,'pos':pos,'matrix':matrix,'material':material,'color':color or [175,174,164],
                        'collide':True,'trans':0,'cls':cls,'meta':{'owner':'RenCenRiverAccess','classification':'Original estimated low-grade access'}})
    def triangle(a,b,c,y):
        a,b,c=[[p[0],y,p[1]] for p in (a,b,c)]
        ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
        if dot(ab,ab)>dot(ac,ac) and dot(ab,ab)>dot(bc,bc):c,a=a,c
        elif dot(ac,ac)>dot(bc,bc) and dot(ac,ac)>dot(ab,ab):a,b=b,a
        ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
        normal=norm(cross(ac,ab));back=norm(bc);up=norm(cross(bc,normal));width=abs(dot(ab,up))
        for other,v,flip in [(b,ab,1),(c,ac,-1)]:
            length=abs(dot(v,back))
            if min(width,length)<.001:continue
            matrix=[normal[0]*flip,up[0],back[0]*flip,normal[1]*flip,up[1],back[1]*flip,normal[2]*flip,up[2],back[2]*flip]
            add('RiverAccess_DryUpperLanding',[.25,width,length],[(a[i]+other[i])/2 for i in range(3)],matrix,cls='WedgePart')
            records[-1]['meta']['surfaceTriangleVertices']=[[p[0],.55,p[2]] for p in (a,b,c)]
    for tri in shapely.constrained_delaunay_triangles(landing).geoms:triangle(*list(tri.exterior.coords)[:3],.425)
    def deck(name,a,b,width):
        z=norm(sub(b,a));x=norm(cross([0,1,0],z));y=cross(z,x);matrix=[x[0],y[0],z[0],x[1],y[1],z[1],x[2],y[2],z[2]]
        add(name,[width,.25,math.dist(a,b)],[(a[i]+b[i])/2-y[i]*.125 for i in range(3)],matrix)
    matrix=[right[0],0,f[0],0,1,0,right[1],0,f[1]]
    # Three real treads plus unchanged land supply four .2stud risers.
    for index,top in enumerate((.35,.15,-.05)):
        center=point(61.5+3*index,6,(top-.35)/2)
        add('RiverAccess_LowStairTread',[8,top+.35,3],center,matrix)
    deck('RiverAccess_GentleParallelRamp',point(60,-6,.55),point(72,-6,-.25),8)
    junction=point(80,0,-.25)
    promenade=loaded[names[3]]['records'][0];destination=[promenade['pos'][0],.41,promenade['pos'][2]]
    direction=norm(sub([destination[0],-.25,destination[2]],junction))
    across=[promenade['matrix'][0],0,promenade['matrix'][6]]
    distance_to_edge=(promenade['size'][0]/2-.2)/abs(dot(direction,across))
    connection=[destination[0]-direction[0]*distance_to_edge,.41,destination[2]-direction[2]*distance_to_edge]
    deck('RiverAccess_PavedPromenadeConnector',junction,connection,8)
    assert len(records)<=70
    # Existing road/walk/land carry the pre-landing crossing and the branch merge.
    route_prefix=[]
    for t in (0,12,24,34,44,50,56):
        p=point(t,0,0);inside_road=roads.covers(Point(p[0],p[2]));dry=landing.covers(Point(p[0],p[2]))
        p[1]=.55 if inside_road or dry else .35 if t<44 else -.25
        route_prefix.append({'pos':p,'floorY':p[1],'width':6,'clearHeight':8,'span':'unchanged source road crossing' if inside_road else 'source walk / dry landing'})
    def sample(p,label):return {'pos':p,'floorY':p[1],'width':6,'clearHeight':8,'span':label}
    ramp=route_prefix+[sample(point(60,-6,.55),'ramp top'),sample(point(66,-6,.15),'gentle ramp'),sample(point(72,-6,-.25),'ramp bottom'),sample(junction,'unchanged land merge'),sample(connection,'existing promenade edge'),sample(destination,'existing promenade')]
    stairs=route_prefix+[sample(point(60,6,.55),'stairs top')]+[sample(point(61.5+3*i,6,top),'broad tread') for i,top in enumerate((.35,.15,-.05))]+[sample(point(70.5,6,-.25),'unchanged source land fourth landing'),sample(junction,'unchanged land merge'),sample(connection,'existing promenade edge'),sample(destination,'existing promenade')]
    # Bound native MoveTo fixture legs without changing any geometry/profile.
    def short_legs(route):
        result=[route[0]]
        for target in route[1:]:
            a,b=result[-1]['pos'],target['pos'];count=max(1,math.ceil(math.dist(a,b)/25))
            for index in range(1,count):
                t=index/count;p=[a[i]+(b[i]-a[i])*t for i in range(3)]
                result.append(sample(p,'intermediate connector review'))
            result.append(target)
        return result
    ramp,stairs=short_legs(ramp),short_legs(stairs)
    return {'id':'RenCenRiverAccess','records':records,'routeRamp':ramp,'routeStairs':stairs,
            'sourceHashes':{name:hashlib.sha256((root/'data'/name).read_bytes()).hexdigest() for name in names},
            'metadata':{'classification':'Original low-grade access estimate, not historical surveyed steps','doorOriginXZ':origin,'outwardXZ':f,
                        'upperLandingY':.55,'lowerNativeLandY':-.25,'riserHeights':[.2,.2,.2,.2],
                        'rampRunStuds':12,'rampRiseStuds':.8,'rampGradeDegrees':math.degrees(math.atan2(.8,12)),
                        'landingPolygonStuds':{'type':'Polygon','coordinates':[list(map(list,landing.exterior.coords))]},
                        'promenadeId':loaded[names[3]]['id'],'promenadeLengthMetersPreserved':80,'connectorEnd':connection,
                        'sourcePreservation':'No source replacements, road surface overlays, shoreline, door, landmark or promenade modifications',
                        'limitations':['Existing Atwater crossing remains unchanged; no traffic/pedestrian safety simulation claimed.','Route floor samples before dry landing follow source/native estimates; Lead must raycast each segment.',
                                       'The fourth stair landing and lane merge use existing SourceLand to avoid coplanar new slabs.','No guards added for a maximum.8stud landscape grade; path widths remain8studs minimum.',
                                       'Native tiny/normal avatar walking, headroom, visual seams and FPS remain pending.']}}

if __name__=='__main__':
    p=generate();(ROOT/'data/river_access_plan.json').write_text(json.dumps(p,sort_keys=True,separators=(',',':'),allow_nan=False)+'\n',encoding='utf-8')
    print(json.dumps({'records':len(p['records']),'rampGrade':p['metadata']['rampGradeDegrees']}))
