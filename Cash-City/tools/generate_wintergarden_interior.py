"""Original atrium finishes inside the existing floor; routes and doors are read-only."""
import json,math,hashlib
from pathlib import Path
from generate_walk_route import collider_polygon
from generate_river_access import surface_polygon
from shapely.geometry import shape,Point,LineString
from shapely.ops import unary_union
ROOT=Path(__file__).resolve().parents[1]
def generate():
 names=['wintergarden_plan.json','arrival_lounge.json','geometry.json','detail_preview.json']
 garden,lounge,geometry,details=[json.loads((ROOT/'data'/n).read_text())for n in names]
 floor=shape(garden['metadata']['roofFootprintStuds']);top=garden['metadata']['floorTopStuds'];replaced={r['sourceIndex']for r in garden['replacements']}
 # Existing furniture and standing source geometry retain their complete footprints.
 furniture=unary_union([Point(a['pos'][0],a['pos'][2]).buffer(8)for a in lounge['seats']]+[Point(r['pos'][0],r['pos'][2]).buffer(4)for r in garden['records']if 'PlanterBase'in r['name']])
 obstacles=unary_union([poly for i,r in enumerate(geometry)if i not in replaced and(poly:=collider_polygon(r,1))is not None]+[poly for d in details for r in d['parts']if(poly:=collider_polygon(r,1))is not None])
 raised=unary_union([surface_polygon(r)for r in geometry if r['name']in('JoinedRoad','JoinedWalk')and r['pos'][1]+sum(abs(r['matrix'][3+i])*r['size'][i]/2 for i in range(3))>top+.05]).buffer(.2)
 standing=obstacles
 obstacles=unary_union([obstacles,raised])
 safe=floor.buffer(-1.1).difference(furniture.buffer(.2)).difference(obstacles.buffer(.2));records=[]
 def bar(name,a,b,width,y,height,color,material='Slate'):
  dx,dz=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dz)
  if length<.5:return
  fx,fz=dx/length,dz/length
  footprint=LineString([a,b]).buffer(width/2,cap_style=2)
  assert floor.buffer(.001).covers(footprint)
  records.append(dict(name=name,size=[width,height,length],pos=[(a[0]+b[0])/2,y,(a[1]+b[1])/2],matrix=[fz,0,fx,0,1,0,-fx,0,fz],color=color,material=material,collide=False))
 def lines(g):
  if g.is_empty:return[]
  if g.geom_type=='LineString':return[g]
  return[v for v in getattr(g,'geoms',[])if v.geom_type=='LineString' and not v.is_empty]
 x0,z0,x1,z1=safe.bounds
 for axis in(0,1):
  low,high=(x0,x1)if axis==0 else(z0,z1)
  for coordinate in range(math.ceil(low/14)*14,math.floor(high/14)*14+1,14):
   path=LineString([(coordinate,z0-1),(coordinate,z1+1)])if axis==0 else LineString([(x0-1,coordinate),(x1+1,coordinate)])
   for line in lines(safe.intersection(path)):bar('Atrium_StoneFloorInlay',line.coords[0],line.coords[-1],.1,top+.018,.012,[126,134,130])
 # Perimeter details stop before entrance/connection route reservations.
 doors=[Point(a['pos'][0],a['pos'][2]).buffer(10)for a in garden['doorAnchors']]
 rear=garden['metadata'].get('rearLobbyPortal',{})
 if rear.get('pos'):doors.append(Point(rear['pos'][0],rear['pos'][2]).buffer(10))
 reserve=unary_union(doors+[LineString([(s['pos'][0],s['pos'][2])for s in garden['routeSamples']]).buffer(8)])
 trim=floor.buffer(-.8).boundary.difference(reserve).difference(furniture).difference(obstacles.buffer(.5))
 for line in lines(trim):
  for a,b in zip(line.coords,list(line.coords)[1:]):bar('Atrium_PerimeterBronzeTrim',a,b,.18,top+.45,.7,[144,140,120],'Metal')
 # Four original perimeter uplights, away from furniture and primary circulation.
 candidates=[]
 for d in range(4,int(floor.length),7):
  q=floor.buffer(-2).exterior.interpolate(d)
  if reserve.distance(q)<3 or furniture.distance(q)<3 or obstacles.distance(q)<3:continue
  candidates.append(q)
 chosen=[]
 for q in candidates:
  if all(q.distance(old)>22 for old in chosen):chosen.append(q)
  if len(chosen)==4:break
 assert len(chosen)==4,'Four safe uplight sites required'
 for i,q in enumerate(chosen):
  records.append(dict(name=f'Atrium_Uplight_{i}',size=[.8,.12,.8],pos=[q.x,top+.1,q.y],matrix=[1,0,0,0,1,0,0,0,1],color=[240,231,208],material='SmoothPlastic',collide=False,light=True))
 for r in garden['records']:
  if r['name']=='Wintergarden_DecorativePlanterBase':
   x,y,z=r['pos']
   for side in(-1,1):records.append(dict(name='Atrium_PlanterMetalLip',size=[4.12,.12,.12],pos=[x,y+1.06,z+side*2.02],matrix=[1,0,0,0,1,0,0,0,1],color=[144,140,120],material='Metal',collide=False))
 repair=json.loads((ROOT/'data/atrium_floor_repair_plan.json').read_text())
 region=shape(json.loads(repair['cutPolygon'])).intersection(raised.buffer(.2)).intersection(floor.buffer(-1.1)).difference(furniture.buffer(.2)).difference(standing.buffer(.2))
 for axis in(0,1):
  low,high=(x0,x1)if axis==0 else(z0,z1)
  for coordinate in range(math.ceil(low/14)*14,math.floor(high/14)*14+1,14):
   path=LineString([(coordinate,z0-1),(coordinate,z1+1)])if axis==0 else LineString([(x0-1,coordinate),(x1+1,coordinate)])
   for line in lines(region.intersection(path)):bar('Atrium_RepairedStoneFloorInlay',line.coords[0],line.coords[-1],.1,top+.018,.012,[126,134,130])
 assert 20<=len(records)<=140
 return dict(id='WintergardenInteriorFinish',records=records,floorTop=top,classification='Original public-atrium finishes; source-footprint-contained, not a surveyed interior',sourceHashes={n:hashlib.sha256((ROOT/'data'/n).read_bytes()).hexdigest()for n in names+['atrium_floor_repair_plan.json']})
TAIL="""
local Finish={}
function Finish.build(root)
 local model,stats=require(script.Parent.CityBlockGenerator).build(root,plan,nil,80)
 local lookup={}for _,r in plan.records do lookup[r.name]=r end
 for _,p in model:GetDescendants()do if p:IsA('BasePart')then
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
  if lookup[p.Name].light then local light=Instance.new('PointLight');light.Name='AtriumUplight';light.Brightness=.3;light.Range=14;light.Color=Color3.fromRGB(255,238,211);light.Shadows=false;light.Parent=p end
 end end
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;model:SetAttribute('ReferenceStatus',plan.classification)
 return model,stats
end
return Finish
"""
if __name__=='__main__':
 p=generate();payload=json.dumps(p,separators=(',',':'),allow_nan=False)
 (ROOT/'data/wintergarden_interior_plan.json').write_text(payload+'\n')
 (ROOT/'src/WintergardenInteriorFinish.lua').write_text('-- Generated by tools/generate_wintergarden_interior.py\nlocal plan=game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n'+TAIL)
 print(json.dumps({'parts':len(p['records']),'uplights':sum(r.get('light',False)for r in p['records'])}))
