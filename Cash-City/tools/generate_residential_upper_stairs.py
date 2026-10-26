"""Guarded two-flight connection from the existing Y80 landing to Level02 at Y92."""
import json,math
from pathlib import Path
from generate_river_access import Polygon,surface_polygon,unary_union
from geometry_surfaces import horizontal_parts
ROOT=Path(__file__).resolve().parents[1]

def generate(lower_level=1):
 assert isinstance(lower_level,int) and 1<=lower_level<39
 lower=json.loads((ROOT/'data/residential_stairs_plan.json').read_text())
 base=json.loads((ROOT/'data/residential_floor_a01_plan.json').read_text())
 cx,cz=lower['center'];hole=Polygon([(cx+x,cz+z)for x,z in[(-63,-26),(-63,-6),(-52,-6),(-52,-26)]])
 records=[];guards=[];proof=[]
 prefix='ResidentialUpperStairs' if lower_level==1 else 'ResidentialUpperStairs_L'+str(lower_level).zfill(2)
 def add(r,guard=None):r=dict(r);r.update(name=prefix+'_'+str(len(records)).zfill(3),guard=guard);records.append(r)
 def part(label,size,pos,material='Concrete',color=None,trans=0,matrix=None):
  add(dict(label=label,size=size,pos=pos,material=material,color=color or[170,174,171],trans=trans,collide=True,matrix=matrix or[1,0,0,0,1,0,0,0,1]))
 def clip(r,cut):
  poly=surface_polygon(r)
  if poly.intersection(cut).area<1e-6:return
  remaining=poly.difference(cut);index=len(guards);guards.append(dict(record=r,origin='upper-stair-opening'))
  depth=sum(abs(r['matrix'][3+i])*r['size'][i]for i in range(3));top=r['pos'][1]+depth/2
  pieces=horizontal_parts(remaining,top,depth,'piece',r['color'],r['material'])
  error=unary_union([surface_polygon(v)for v in pieces]).symmetric_difference(remaining).area;assert error<1e-5
  proof.append(dict(areaError=error))
  for piece in pieces:add(piece,index)
 for r in base['records']:
  if r['name']=='Residence_Ceiling':clip(r,hole)
  elif r['name']=='Residence_StructuralFloor':
   r=json.loads(json.dumps(r));r['pos'][1]+=12;clip(r,hole)
 roof=dict(name='StairRoof',size=[11.6,.18,30.6],pos=[cx-57.5,89.1,cz-11],matrix=[1,0,0,0,1,0,0,0,1],color=[65,76,79],material='Metal')
 if lower_level>1:
  roof=json.loads(json.dumps(next(r for r in generate(lower_level-1)['records']if r.get('label')=='ShaftRoof')))
  roof['pos'][1]-=12*(lower_level-1)
 clip(roof,hole.buffer(.1,join_style=2))
 for floor,z in[(86,-8),(92,-24)]:part('Landing',[11,.3,4],[cx-57.5,floor-.15,cz+z])
 for flight in range(2):
  x=cx+(-60.5 if flight==0 else-54.5);floor=80+6*flight;direction=1 if flight==0 else-1;start=-22 if flight==0 else-10
  for step in range(12):
   height=(step+1)*.5;part('Tread',[4.5,height,1],[x,floor+height/2,cz+start+direction*(step+.5)])
  length=math.sqrt(12**2+6**2);m=[1,0,0,0,12/length,direction*6/length,0,-direction*6/length,12/length]
  for side in(-1,1):
   part('FlightGuard',[.12,3.5,length],[x+side*2.31,floor+4.75,cz-16],'Metal',[72,82,84],1,m)
   part('Handrail',[.16,.16,length],[x+side*2.31,floor+6.5,cz-16],'Metal',[72,82,84],0,m)
 for x in(-63,-52):part('TurnGuard',[.14,3.5,4],[cx+x,87.75,cz-8],'Metal',[72,82,84])
 part('TurnEndGuard',[11,3.5,.14],[cx-57.5,87.75,cz-6],'Metal',[72,82,84])
 for size,pos in[([.14,3.5,20],[cx-63,93.75,cz-16]),([.14,3.5,16],[cx-52,93.75,cz-14]),([11,3.5,.14],[cx-57.5,93.75,cz-26]),([11,3.5,.14],[cx-57.5,93.75,cz-6])]:part('UpperOpeningGuard',size,pos,'Metal',[72,82,84])
 for size,pos in[([.16,12,20.4],[cx-63.22,95,cz-16]),([11.4,12,.16],[cx-57.5,95,cz-26.22]),([11.4,12,.16],[cx-57.5,95,cz-5.78]),([.16,3,20.4],[cx-51.78,90.5,cz-16]),([.16,9,16],[cx-51.78,96.5,cz-14])]:part('ShaftGlass',size,pos,'Glass',[159,191,190],.55)
 part('ShaftRoof',[11.6,.18,20.6],[cx-57.5,101.1,cz-16],'Metal',[65,76,79])
 assert len(guards)>0 and max(v['areaError']for v in proof)<1e-5
 dy=12*(lower_level-1)
 for r in records:r['pos'][1]+=dy
 for g in guards:g['record']['pos'][1]+=dy
 model_id='ResidentialTowerA_UpperStairs' if lower_level==1 else 'ResidentialTowerA_UpperStairs_'+str(lower_level).zfill(2)+'_'+str(lower_level+1).zfill(2)
 return dict(id=model_id,records=records,guards=guards,proof=proof,center=[cx,cz],levels=[80+dy,86+dy,92+dy],status='AWAITING_ROUTE_VALIDATION')

if __name__=='__main__':
 p=generate();payload=json.dumps(p,separators=(',',':'))
 (ROOT/'data/residential_upper_stairs_plan.json').write_text(payload+'\n')
 (ROOT/'src/ResidentialUpperStairsData.lua').write_text('-- Generated guarded upper stair connection\nreturn game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n')
 print(json.dumps(dict(parts=len(p['records']),guards=len(p['guards']),maxAreaError=max(v['areaError']for v in p['proof']))))
 for first,last,module in[(3,5,'ResidentialFloorBatchData'),(6,8,'ResidentialFloorBatch06Data'),(9,11,'ResidentialFloorBatch09Data')]:
  batch=dict(first=first,last=last,connections=[generate(level-1)for level in range(first,last+1)])
  payload=json.dumps(batch,separators=(',',':'))
  (ROOT/('data/residential_floor_batch_'+str(first).zfill(2)+'_'+str(last).zfill(2)+'.json')).write_text(payload+'\n')
  (ROOT/('src/'+module+'.lua')).write_text('-- Generated bounded floor batch\nreturn game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n')
  print(json.dumps(dict(first=first,last=last,parts=[len(p['records'])for p in batch['connections']])))
