"""Original low-part trees inside existing mapped lawn; source geometry read-only."""
import hashlib,json,math
from pathlib import Path
from generate_river_access import surface_polygon,shape,Point,Polygon,unary_union
from shapely import affinity
from shapely.ops import nearest_points
ROOT=Path(__file__).resolve().parents[1]

def generate(root=ROOT):
    paths=[root/'data/detroit_geography.json',root/'data/geometry.json']
    geography,geometry=[json.loads(p.read_text()) for p in paths];scale=geography['studsPerMeter']
    source=next(f for f in geography['features'] if f.get('osm')==107609230 and f['kind']=='park')
    park=affinity.scale(shape(source['geometry']),xfact=scale,yfact=scale,origin=(0,0))
    lawn_records=[r for r in geometry if r['name']=='JoinedPark' and surface_polygon(r).intersects(park)]
    paved=unary_union([surface_polygon(r) for r in geometry if r['name'] in ('JoinedWalk','JoinedRoad') and surface_polygon(r).intersects(park)])
    lawn=unary_union([surface_polygon(r) for r in lawn_records]).intersection(park).difference(paved.buffer(.25))
    safe=lawn.buffer(-10)
    reserve=[]
    for team in geography['gameplay'].values():
        for p in [team['spawn'],team['exit'],team['transit']]+team['sockets']:reserve.append(Point(p[0]*scale,p[1]*scale))
    x0,z0,x1,z1=safe.bounds;candidates=[]
    for x in range(math.ceil(x0/8)*8,math.floor(x1/8)*8+1,8):
        for z in range(math.ceil(z0/8)*8,math.floor(z1/8)*8+1,8):
            p=Point(x,z)
            if safe.covers(p) and all(p.distance(a)>16 for a in reserve):candidates.append(p)
    assert len(candidates)>=5,'No source-clear park tree layout'
    centers=[min(candidates,key=lambda p:(p.x,p.y))]
    while len(centers)<5:
        p=max(candidates,key=lambda p:(min(p.distance(q) for q in centers),-p.x,-p.y))
        assert min(p.distance(q) for q in centers)>28,'Tree spacing requires review'
        centers.append(p)
    records=[];anchors=[];vertical=[0,-1,0,1,0,0,0,0,1];identity=[1,0,0,0,1,0,0,0,1]
    for index,p in enumerate(centers):
        support=[r for r in lawn_records if surface_polygon(r).covers(p)];assert support
        floor=max(r['pos'][1]+sum(abs(r['matrix'][3+i])*r['size'][i]/2 for i in range(3)) for r in support)
        anchors.append(dict(x=p.x,z=p.y,floor=floor))
        def add(label,size,offset,color,material,shape_name,matrix,collide=False):
            records.append(dict(name='ParkTree_'+str(index)+'_'+label,size=size,pos=[p.x+offset[0],floor+offset[1],p.y+offset[2]],matrix=matrix,color=color,material=material,shape=shape_name,collide=collide))
        add('Mulch',[.1,7,7],[0,.07,0],[76,61,43],'Ground','Cylinder',vertical)
        add('Trunk',[12,1.1,1.1],[0,6,0],[96,79,60],'Wood','Cylinder',vertical,True)
        colors=([68,96,57],[77,105,62],[62,89,52]) if index%2==0 else ([74,101,57],[84,111,64],[67,94,51])
        for label,size,offset,color in zip(('Crown','WestCrown','EastCrown'),([14,12,14],[11,9,11],[10,8,10]),([0,16,0],[-3,14,2],[3,17,-2]),colors):
            assert lawn.covers(Point(p.x+offset[0],p.y+offset[2]).buffer(max(size[0],size[2])/2))
            add(label,size,offset,color,'Grass','Ball',identity)
    assert len(records)==25
    walks=unary_union([surface_polygon(r) for r in geometry if r['name']=='JoinedWalk' and surface_polygon(r).intersects(park)])
    sites=[];x0,z0,x1,z1=park.bounds
    for x in range(math.ceil(x0/4)*4,math.floor(x1/4)*4+1,4):
        for z in range(math.ceil(z0/4)*4,math.floor(z1/4)*4+1,4):
            p=Point(x,z);distance=walks.distance(p)
            if not 2.5<distance<7:continue
            q=nearest_points(p,walks)[1];fx,fz=(q.x-x)/distance,(q.y-z)/distance
            rx,rz=-fz,fx;bx,bz=-fx,-fz
            footprint=Polygon([(x+rx*a+bx*b,z+rz*a+bz*b) for a,b in [(-4,-2),(-4,2),(4,2),(4,-2)]])
            if not lawn.covers(footprint) or any(footprint.distance(t)<2.4 for t in centers) or any(footprint.distance(a)<10 for a in reserve):continue
            lamp=next((Point(x+rx*side*5.3,z+rz*side*5.3) for side in (-1,1) if lawn.covers(Point(x+rx*side*5.3,z+rz*side*5.3).buffer(.8))),None)
            if lamp is not None:sites.append((p,footprint,[rx,0,bx,0,1,0,rz,0,bz],lamp))
    chosen=[]
    for index in range(4):
        available=[v for v in sites if all(v[0].distance(old[0])>22 for old in chosen)]
        assert available,'Insufficient clear seating bays'
        site=min(available,key=lambda v:(v[0].x,v[0].y)) if not chosen else max(available,key=lambda v:(min(v[0].distance(old[0]) for old in chosen),-v[0].x,-v[0].y))
        chosen.append(site)
        p,footprint,m,lamp=site
        support=[r for r in lawn_records if surface_polygon(r).covers(p)];assert support
        floor=max(r['pos'][1]+sum(abs(r['matrix'][3+i])*r['size'][i]/2 for i in range(3)) for r in support)
        def prop(label,size,offset,color,material,collide=False,**extra):
            x,y,z=offset
            records.append(dict(name='ParkSeat_'+str(index)+'_'+label,size=size,pos=[p.x+m[0]*x+m[2]*z,floor+y,p.y+m[6]*x+m[8]*z],matrix=m,color=color,material=material,shape='Block',collide=collide,**extra))
        prop('PavingPad',[8,.18,4],[0,.11,0],[151,147,135],'Concrete',True)
        prop('Seat',[6.5,.35,2],[0,1.35,0],[111,83,55],'WoodPlanks',True,seat=True)
        prop('Back',[6.5,1.25,.18],[0,2.05,1.03],[111,83,55],'WoodPlanks',True)
        for side in (-1,1):
            prop('Leg'+str(side),[.2,1.1,1.7],[side*2.5,.75,0],[65,73,70],'Metal')
            prop('Arm'+str(side),[.2,.2,2],[side*3.2,1.85,0],[65,73,70],'Metal')
        for label,size,y,color,material,extra in [('Base',[1,.2,1],.1,[66,74,70],'Metal',{}),('Pole',[.3,2.8,.3],1.6,[132,143,135],'Metal',{}),('Lens',[.8,.4,.8],3.2,[249,231,190],'Neon',{'light':True})]:
            records.append(dict(name='ParkLight_'+str(index)+'_'+label,size=size,pos=[lamp.x,floor+y,lamp.y],matrix=identity,color=color,material=material,shape='Block',collide=False,**extra))
    seating=[dict(x=v[0].x,z=v[0].y,matrix=v[2],floor=next(r['pos'][1]-.11 for r in records if r['name']=='ParkSeat_'+str(i)+'_PavingPad'),lamp=[v[3].x,v[3].y]) for i,v in enumerate(chosen)]
    assert len(records)==65
    return dict(id='Map1RiverfrontPark',records=records,anchors=anchors,seatingSites=seating,sourceOSM=source['osm'],classification='Mapped lawn; original trees, seating and lighting, not surveyed',sourceHashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in paths})

TAIL='''
local Park={}
function Park.finish(model)
 local byName={}for _,r in ipairs(plan.records) do byName[r.name]=r end
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then
  local r=assert(byName[p.Name])
  if r.seat and not p:IsA('Seat') then
   local seat=Instance.new('Seat');seat.Name=p.Name;seat.Size=p.Size;seat.CFrame=p.CFrame;seat.Color=p.Color;seat.Material=p.Material;seat.Parent=p.Parent;p:Destroy();p=seat
  end
  p.Shape=Enum.PartType[r.shape];p.Anchored=true;p.CanTouch=r.seat==true;p.CanCollide=r.collide==true;p.CastShadow=false;p.CanQuery=r.collide==true
  if r.light and not p:FindFirstChild('ParkLight') then
   local light=Instance.new('PointLight');light.Name='ParkLight';light.Brightness=.25;light.Range=12;light.Color=Color3.fromRGB(255,235,199);light.Shadows=false;light.Parent=p
  end
 end end
end
function Park.build(root)
 local model,stats=require(script.Parent.CityBlockGenerator).build(root,plan,nil,80)
 Park.finish(model)
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 model:SetAttribute('ReferenceStatus',plan.classification)
 return model,stats
end
return Park
'''
if __name__=='__main__':
    plan=generate();payload=json.dumps(plan,separators=(',',':'),allow_nan=False)
    (ROOT/'data/riverfront_park_plan.json').write_text(payload+'\n',encoding='utf-8')
    (ROOT/'src/RiverfrontPark.lua').write_text('-- Generated by tools/generate_riverfront_park.py\nlocal plan=game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n'+TAIL,encoding='utf-8')
    print(json.dumps({'parts':len(plan['records']),'anchors':plan['anchors']}))
