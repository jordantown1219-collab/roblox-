"""Four-flight residential stair draft; floor openings are a separate guarded slice."""
import json, math
from pathlib import Path
from generate_river_access import shape, Polygon, LineString, surface_polygon, unary_union
from geometry_surfaces import horizontal_parts
import shapely.affinity
ROOT=Path(__file__).resolve().parents[1]

def generate():
 access=json.loads((ROOT/'data/residential_access_plan.json').read_text())
 geo=json.loads((ROOT/'data/detroit_geography.json').read_text())
 shell=shape(next(f for f in geo['features'] if f['osm']==419447155)['geometry'])
 shell=shapely.affinity.scale(shell,xfact=geo['studsPerMeter'],yfact=geo['studsPerMeter'],origin=(0,0))
 cx,cz=access['liftCenter'];cz+=12
 footprint=Polygon([(cx+x,cz+z)for x,z in[(-63,-26),(-63,4),(-52,4),(-52,-26)]])
 assert shell.buffer(-.5).covers(footprint),'Stairs exceed source tower shell'
 records=[];routes=[];guards=[];proof=[]
 def part(label,size,pos,matrix=None,trans=0):
  records.append(dict(name='ResidentialStairs_'+str(len(records)).zfill(3),label=label,size=size,pos=pos,matrix=matrix or[1,0,0,0,1,0,0,0,1],color=[170,174,171] if label=='Tread' else[72,82,84],material='Concrete' if label in('Tread','Landing')else'Metal',collide=True,trans=trans))
 for floor,z in[(36,-24),(47,2),(58,-24),(69,2),(80,-24)]:
  part('Landing',[11,.3,4],[cx-57.5,floor-.15,cz+z])
 for flight in range(4):
  x=cx+(-60.5 if flight%2==0 else-54.5);base=36+11*flight;direction=1 if flight%2==0 else-1
  start=-22 if direction==1 else 0
  samples=[]
  for step in range(22):
   height=(step+1)*.5;z=cz+start+direction*(step+.5)
   part('Tread',[4.5,height,1],[x,base+height/2,z])
   samples.append([x,base+height,z])
  routes.append(samples)
  # Continuous inclined guards have no gaps a 22-percent avatar can pass through.
  length=math.sqrt(22**2+11**2);uy=22/length;uz=-direction*11/length;by=direction*11/length;bz=22/length
  matrix=[1,0,0,0,uy,by,0,uz,bz]
  for side in(-1,1):
   part('FlightGuard',[.12,3.5,length],[x+side*2.31,base+5.5+1.75,cz-11],matrix,1)
   part('Handrail',[.16,.16,length],[x+side*2.31,base+5.5+3.5,cz-11],matrix)
 # End and outside guards leave both lanes connected at each turn.
 for floor,z in[(36,-26),(47,4),(58,-26),(69,4),(80,-26)]:
  part('LandingEndGuard',[11,3.5,.14],[cx-57.5,floor+1.75,cz+z])
  if floor!=80:part('LandingSideGuard',[.14,3.5,4],[cx-63,floor+1.75,cz+z+(-2 if z==4 else 2)])
  if floor not in(36,80):part('LandingSideGuard',[.14,3.5,4],[cx-52,floor+1.75,cz+z+(-2 if z==4 else 2)])
 part('UpperOpeningGuard',[.14,3.5,30],[cx-63,81.75,cz-11])
 part('UpperOpeningGuard',[.14,3.5,26],[cx-52,81.75,cz-9])
 part('UpperOpeningGuard',[11,3.5,.14],[cx-57.5,81.75,cz+4])
 # Compose the already-clipped surfaces, never filling the existing lift shaft.
 raw=json.loads((ROOT/'data/geometry.json').read_text())
 residential=json.loads((ROOT/'data/residential_floor_a01_plan.json').read_text())
 def key(r):return json.dumps([r['name'],r['pos'],r['size'],r['matrix']],separators=(',',':'))
 hidden={key(g['record'])for g in access['guards']}
 effective=[r for r in raw if r['name'].startswith('Roof_')and 40<r['pos'][1]<79 and key(r)not in hidden]
 effective +=[r for r in residential['records']if r['name']=='Residence_StructuralFloor'and key(r)not in hidden]
 effective +=[r for r in access['records']if r.get('guard')is not None and (access['guards'][r['guard']]['record']['name'].startswith('Roof_')or access['guards'][r['guard']]['record']['name']=='Residence_StructuralFloor')]
 for r in effective:
  poly=surface_polygon(r)
  if poly.intersection(footprint).area<1e-6:continue
  outside=poly.difference(footprint);index=len(guards);guards.append(dict(record=r,origin='effective-surface'))
  depth=sum(abs(r['matrix'][3+i])*r['size'][i]for i in range(3));top=r['pos'][1]+depth/2
  pieces=horizontal_parts(outside,top,depth,'StairOpening',r['color'],r['material'])
  error=unary_union([surface_polygon(v)for v in pieces]).symmetric_difference(outside).area;assert error<1e-5
  proof.append(dict(kind='floor-opening',areaError=error))
  for piece in pieces:piece.update(name='ResidentialStairs_'+str(len(records)).zfill(3),guard=index);records.append(piece)
 # Branch from the existing bridge into the stair bottom landing.
 a,b=access['bridgeStart'],access['bridgeEnd'];z=cz-24;t=(z-a[1])/(b[1]-a[1]);assert 0<t<1
  # The main-bridge floor is subtracted so this junction has no coplanar overlay.
 join=[a[0]+t*(b[0]-a[0]),z];branch=LineString([join,[cx-57.5,z]]).buffer(1.9,cap_style=2)
 bridge_parts=[r for r in access['records']if r.get('guard')is None and r.get('cls')=='WedgePart']
 bridge_floor=unary_union([surface_polygon(r)for r in bridge_parts]);landing=Polygon([(cx+x,cz+v)for x,v in[(-63,-26),(-63,-22),(-52,-22),(-52,-26)]])
 deck=branch.difference(bridge_floor).difference(landing)
 for r in horizontal_parts(deck,36,.3,'Branch',[188,186,173],'Limestone'):r['name']='ResidentialStairs_'+str(len(records)).zfill(3);records.append(r)
 rail_guards=0
 for r in access['records']:
  if r.get('guard')is not None or abs(r['size'][0]-.14)>.001 or abs(r['size'][1]-3.5)>.001:continue
  # Only the west rail crosses the branch after the main floor subtraction.
  cut=surface_polygon(r).intersection(deck.buffer(.16))
  if cut.area<1e-6:continue
  index=len(guards);guards.append(dict(record=r,origin='bridge-rail'));rail_guards+=1
  values=[(x-r['pos'][0])*r['matrix'][2]+(v-r['pos'][2])*r['matrix'][8]for x,v in cut.exterior.coords]
  for lo,hi in[(-r['size'][2]/2,min(values)),(max(values),r['size'][2]/2)]:
   if hi-lo<.001:continue
   piece=dict(r);middle=(lo+hi)/2;piece.update(name='ResidentialStairs_'+str(len(records)).zfill(3),guard=index,size=[.14,3.5,hi-lo],pos=[r['pos'][0]+r['matrix'][2]*middle,r['pos'][1],r['pos'][2]+r['matrix'][8]*middle]);records.append(piece)
 assert rail_guards==1,'Branch must open exactly one main-bridge guard'
 # Branch side barriers end at the old bridge edge, outside its walking lane.
 minx,_,maxx,_=deck.bounds
 for side in(-1,1):part('BranchGuard',[maxx-minx,3.5,.14],[(minx+maxx)/2,37.75,z+side*1.9])
 assert len(routes)==4 and all(len(r)==22 for r in routes)
 assert max(r['size'][1]for r in records if r.get('label')=='Tread')==11
 return dict(id='ResidentialTowerA_Stairs',records=records,guards=guards,proof=proof,routes=routes,center=[cx,cz],branchJoin=join,footprint={'type':'Polygon','coordinates':[[list(v)for v in footprint.exterior.coords]]},status='AWAITING_FULL_ROUTE_TEST',riser=.5,tread=1,laneWidth=4.5,levels=[36,47,58,69,80])

if __name__=='__main__':
 plan=generate();payload=json.dumps(plan,separators=(',',':'))
 (ROOT/'data/residential_stairs_plan.json').write_text(payload+'\n')
 (ROOT/'src/ResidentialStairsData.lua').write_text('-- Generated stair draft; not yet connected in Arena.\nreturn game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n')
 print(json.dumps(dict(parts=len(plan['records']),flights=len(plan['routes']),shellContained=True,status=plan['status'])))
