"""Source-guarded reception exit, preserved shell openings, bridge and lift shaft."""
import json,math,hashlib
from pathlib import Path
from generate_river_access import shape,Point,Polygon,LineString,surface_polygon,unary_union
from geometry_surfaces import horizontal_parts
ROOT=Path(__file__).resolve().parents[1]
def generate():
 names=['geometry.json','rencen_lobby_plan.json','lobby_interior_finish_plan.json','residential_floor_a01_plan.json']
 raw,lobby,finish,res=[json.loads((ROOT/'data'/n).read_text())for n in names];rf=next(r for r in lobby['records']if r['name']=='Lobby_WestReceptionFloor');m,c=rf['matrix'],rf['pos']
 start=[c[0]+m[0]*12+m[2]*14,c[2]+m[6]*12+m[8]*14];cx=sum(u['center'][0]for u in res['units'])/4;cz=sum(u['center'][2]for u in res['units'])/4-12;end=[cx,cz-3.4]
 bridge=LineString([start,end]);tunnel=bridge.buffer(3.1,cap_style=2);shaft=Polygon([(cx+a,cz+b)for a,b in[(-3.4,-3.4),(-3.4,3.4),(3.4,3.4),(3.4,-3.4)]])
 records=[];guards=[];proof=[]
 def add(r,guard=None):
  r=dict(r);r['name']='ResidentialAccess_'+str(len(records)).zfill(3);r['guard']=guard;records.append(r)
 def guard(r,origin):
  key=len(guards);guards.append(dict(record=r,origin=origin));return key
 def clip_horizontal(r,cut,origin):
  poly=surface_polygon(r);outside=poly.difference(cut)
  if poly.intersection(cut).area<1e-6:return
  key=guard(r,origin);top=r['pos'][1]+sum(abs(r['matrix'][3+i])*r['size'][i]/2 for i in range(3));depth=min(r['size']);pieces=horizontal_parts(outside,top,depth,'piece',r['color'],r['material']);actual=unary_union([surface_polygon(v)for v in pieces]);error=actual.symmetric_difference(outside).area;assert error<1e-5
  proof.append(dict(guard=key,kind='horizontal',error=error))
  for p in pieces:add(p,key)
 def clip_vertical(r,low,high,z0,z1,origin):
  assert abs(r['matrix'][4]-1)<1e-6
  sy,sz=r['size'][1],r['size'][2];bottom=r['pos'][1]-sy/2;top=bottom+sy;low=max(low,bottom);high=min(high,top);z0=max(z0,-sz/2);z1=min(z1,sz/2)
  if high-low<.001 or z1-z0<.001:return
  key=guard(r,origin);boxes=[(-sz/2,sz/2,bottom,low),(-sz/2,sz/2,high,top),(-sz/2,z0,low,high),(z1,sz/2,low,high)];areas=[]
  for a,b,y0,y1 in boxes:
   if min(b-a,y1-y0)<.001:continue
   z=(a+b)/2;p=dict(r);p.update(size=[r['size'][0],y1-y0,b-a],pos=[r['pos'][0]+r['matrix'][2]*z,(y0+y1)/2,r['pos'][2]+r['matrix'][8]*z]);add(p,key);areas.append((b-a)*(y1-y0))
  error=abs(sum(areas)-(sy*sz-(high-low)*(z1-z0)));assert error<1e-5;proof.append(dict(guard=key,kind='vertical',error=error))
 wall=next(r for r in lobby['records']if r['name']=='Lobby_WestSideWall'and(r['pos'][0]-c[0])*m[2]+(r['pos'][2]-c[2])*m[8]>0)
 # This wall's local Z lies along the old reception wall; its local X is room X.
 # Treat it as a vertical face with swapped horizontal axes for the generic clipper.
 fake=dict(wall);wm=wall['matrix'];fake['matrix']=[wm[2],0,-wm[0],0,1,0,wm[8],0,-wm[6]];fake['size']=[wall['size'][2],wall['size'][1],wall['size'][0]]
 # fake local Z is -roomX: roomX9..15 maps to -15..-9.
 before=len(guards);clip_vertical(fake,36,44.5,-15.6,-8.4,'lobby');guards[before]['record']=wall
 for r in finish['records']:
  dx,dz=r['pos'][0]-c[0],r['pos'][2]-c[2];x,z=dx*m[0]+dz*m[6],dx*m[2]+dz*m[8]
  if r['name']=='Reception_WoodWallPanel'and abs(x-12)<.01 and z>13:guard(r,'finish')
  if r['name']=='Reception_SideWallTrim'and z>13 and r['pos'][1]<44.5:
   key=guard(r,'finish')
   for a,b in[(-17.5,8.4),(15.6,17.5)]:
    p=dict(r);p.update(size=[b-a,r['size'][1],r['size'][2]],pos=[c[0]+m[0]*(a+b)/2+m[2]*z,r['pos'][1],c[2]+m[6]*(a+b)/2+m[8]*z]);add(p,key)
 for r in raw:
  top=r['pos'][1]+sum(abs(r['matrix'][3+i])*r['size'][i]/2 for i in range(3));bottom=2*r['pos'][1]-top
  if r['name'].startswith(('Facade_','FacadeMullion'))and bottom<44.5 and top>36:
   poly=surface_polygon(r).intersection(tunnel)
   if poly.area>1e-6:
    z=[(x-r['pos'][0])*r['matrix'][2]+(y-r['pos'][2])*r['matrix'][8]for x,y in poly.exterior.coords];clip_vertical(r,36,44.5,min(z)-.05,max(z)+.05,'source')
  if r['name'].startswith('Roof_')and 40<top<79:clip_horizontal(r,shaft,'source')
 for r in res['records']:
  if r['name']=='Residence_StructuralFloor':clip_horizontal(r,shaft,'residential')
 length=bridge.length;fx,fz=(end[0]-start[0])/length,(end[1]-start[1])/length;rx,rz=fz,-fx;matrix=[rx,0,fx,0,1,0,rz,0,fz]
 def prop(size,pos,color,material='Limestone',matrix=matrix):add(dict(size=size,pos=pos,matrix=matrix,color=color,material=material,collide=True))
 room_polygon=surface_polygon(rf)
 start_inside=[start[0]-fx*2,start[1]-fz*2]
 bridge_floor=LineString([start_inside,end]).buffer(3,cap_style=2).difference(room_polygon)
 for r in horizontal_parts(bridge_floor,36,.3,'bridge',[188,186,173],'Limestone'):add(r)
 for side in(-1,1):
  prop([.14,3.5,length],[(start[0]+end[0])/2+rx*side*2.93,37.75,(start[1]+end[1])/2+rz*side*2.93],[88,96,92],'Metal')
 # Inaccessible shaft sides and non-door faces; gates/car are owned by the lift service.
 identity=[1,0,0,0,1,0,0,0,1]
 for side in(-1,1):prop([.18,53,6.8],[cx+side*3.4,62.5,cz],[184,185,176],'Concrete',identity)
 prop([6.8,44.5,.18],[cx,66.75,cz-3.4],[184,185,176],'Concrete',identity)
 prop([6.8,44,.18],[cx,58,cz+3.4],[184,185,176],'Concrete',identity)
 prop([6.8,.2,6.8],[cx,89.1,cz],[184,185,176],'Concrete',identity)
 assert len(guards)<=16 and len(records)<160
 return dict(id='ResidentialTowerA_Access',records=records,guards=guards,proof=proof,bridgeStart=start,bridgeEnd=end,liftCenter=[cx,cz],stops=[36,80],shaftPolygon={'type':'Polygon','coordinates':[[list(v)for v in shaft.exterior.coords]]},sourceHashes={n:hashlib.sha256((ROOT/'data'/n).read_bytes()).hexdigest()for n in names})
if __name__=='__main__':
 p=generate();payload=json.dumps(p,separators=(',',':'));(ROOT/'data/residential_access_plan.json').write_text(payload+'\n');(ROOT/'src/ResidentialAccessData.lua').write_text('-- Generated by tools/generate_residential_access.py\nreturn game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n');print(json.dumps({'guards':len(p['guards']),'parts':len(p['records']),'maxExteriorAreaError':max(v['error']for v in p['proof'])}))
