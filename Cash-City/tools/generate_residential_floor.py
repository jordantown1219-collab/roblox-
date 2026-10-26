"""Source-contained original residential conversion; first floor structure only."""
import json,math,hashlib
from pathlib import Path
from generate_river_access import shape,Polygon,sub,dot,cross,norm
import shapely
ROOT=Path(__file__).resolve().parents[1]
def generate(level=1):
 g=json.loads((ROOT/'data/detroit_geography.json').read_text());scale=g['studsPerMeter'];source=next(f for f in g['features']if f['osm']==419447155);poly=shape(source['geometry']);poly=shapely.affinity.scale(poly,xfact=scale,yfact=scale,origin=(0,0));center=poly.centroid;floor=80+12*(level-1);assert 1<=level<=39 and floor+10.8<source['height']*scale
 records=[]
 def part(name,size,pos,matrix=None,color=None,material='SmoothPlastic',**extra):records.append(dict(name=name,size=size,pos=pos,matrix=matrix or[1,0,0,0,1,0,0,0,1],color=color or[210,205,192],material=material,collide=True,**extra))
 def surface(label,y,color):
  for tri in shapely.constrained_delaunay_triangles(poly).geoms:
   a,b,c=[[x,y,z]for x,z in list(tri.exterior.coords)[:3]];ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
   if dot(ab,ab)>dot(ac,ac)and dot(ab,ab)>dot(bc,bc):c,a=a,c
   elif dot(ac,ac)>dot(bc,bc):a,b=b,a
   ab,ac,bc=sub(b,a),sub(c,a),sub(c,b);right=norm(cross(ac,ab));back=norm(bc);up=norm(cross(bc,right));width=abs(dot(ab,up))
   for other,v,flip in[(b,ab,1),(c,ac,-1)]:
    length=abs(dot(v,back))
    if min(width,length)<.001:continue
    part(label,[.3,width,length],[(a[i]+other[i])/2 for i in range(3)],[right[0]*flip,up[0],back[0]*flip,right[1]*flip,up[1],back[1]*flip,right[2]*flip,up[2],back[2]*flip],color,'Concrete',cls='WedgePart')
 surface('Residence_StructuralFloor',floor-.15,[181,172,153]);surface('Residence_Ceiling',floor+10.95,[221,218,207]);units=[]
 for sx in(-1,1):
  for sz in(-1,1):
   x,z=center.x+sx*26,center.y+sz*24;sign=sz;m=[sign,0,0,0,1,0,0,0,sign];unit=f'{len(units)+1:02}'
   corners=Polygon([(x+a,z+b)for a,b in[(-22,-20),(-22,20),(22,20),(22,-20)]]);assert poly.buffer(-.5).covers(corners),'Suite exceeds source shell'
   def wall(label,size,u,v,y=5.4):part('Residence_'+unit+'_'+label,size,[x+sign*u,floor+y,z+sign*v],m,[210,205,192])
   wall('RearWall',[44,10.8,.22],0,20)
   for side in(-1,1):
    wall('SideWall',[.22,10.8,40],side*22,0);wall('EntryJamb',[18.8,10.8,.22],side*12.6,-20)
   wall('EntryHeader',[6.4,2.3,.22],0,-20,9.65)
   wall('BedroomFront',[16,10.8,.18],-14,4)
   for v in(6.75,17.25):wall('BedroomDoorJamb',[.18,10.8,5.5],-6,v)
   wall('BedroomDoorHeader',[.18,2.3,5],-6,12,9.65)
   wall('BathroomFront',[10,10.8,.18],17,8)
   wall('BathroomDoorLowerJamb',[.18,10.8,1.5],12,8.75);wall('BathroomDoorUpperJamb',[.18,10.8,5.5],12,17.25);wall('BathroomDoorHeader',[.18,2.3,5],12,12,9.65)
   units.append(dict(id=unit,center=[x,floor,z],matrix=m,entry=[x,floor,z-sign*20],entryWidth=6.4,bedroomDoor=[x-sign*6,floor,z+sign*12],bathroomDoor=[x+sign*12,floor,z+sign*12]))
 assert len(records)==96
 u=units[0];mx=u['matrix'];base=u['center']
 def furnishing(label,size,offset,color,material='SmoothPlastic',**extra):
  x,y,z=offset;part('Apartment01_'+label,size,[base[0]+mx[0]*x+mx[2]*z,base[1]+y,base[2]+mx[6]*x+mx[8]*z],mx,color,material,**extra)
 furnishing('BedFrame',[6.5,.65,8.2],[-14,.65,12],[111,85,61],'WoodPlanks')
 furnishing('Mattress',[6,.7,7.8],[-14,1.3,12],[214,211,197],'Fabric')
 furnishing('Blanket',[6.05,.12,5.3],[-14,1.72,11],[91,117,119],'Fabric')
 furnishing('Headboard',[6.6,3,.2],[-14,1.8,16.2],[111,85,61],'WoodPlanks')
 for x in(-15.5,-12.5):furnishing('Pillow',[2.5,.3,1.5],[x,1.8,14.9],[232,228,213],'Fabric')
 for x in(-19,-9):furnishing('BedsideCabinet',[2.2,2.3,2.2],[x,1.15,14],[131,104,75],'WoodPlanks')
 furnishing('Wardrobe',[2.2,7.8,6],[-20.3,3.9,8],[142,116,87],'WoodPlanks')
 furnishing('KitchenLowerCabinets',[10,3,3],[11,1.5,-17],[139,116,89],'WoodPlanks')
 furnishing('KitchenCounter',[10.2,.25,3.2],[11,3.125,-17],[205,202,189],'Marble')
 furnishing('KitchenUpperCabinets',[10,3,1.5],[11,6.8,-19],[171,158,137],'WoodPlanks')
 furnishing('Sink',[2.2,.06,1.6],[9,3.28,-17],[69,78,77],'Metal')
 furnishing('ApplianceHousing',[3.2,7,3.1],[19,3.5,-17],[175,183,179],'Metal')
 furnishing('SofaBase',[8,.6,3.2],[-13,.6,-10],[103,119,116],'Fabric')
 furnishing('SofaBack',[8,2.5,.45],[-13,1.9,-11.6],[103,119,116],'Fabric')
 for x in(-15,-11):furnishing('SofaSeat',[3.7,.5,2.8],[x,1.15,-10],[118,133,128],'Fabric',seat=True)
 for x in(-17,-9):furnishing('SofaArm',[.45,1.6,3.2],[x,1.4,-10],[103,119,116],'Fabric')
 furnishing('CoffeeTableTop',[5,.25,2.7],[-13,1.5,-4.3],[156,128,93],'WoodPlanks')
 for x in(-14.8,-11.2):furnishing('CoffeeTableLeg',[.25,1.4,1.8],[x,.7,-4.3],[69,76,71],'Metal')
 furnishing('BathroomVanity',[3,2.8,2],[19,1.4,9.5],[173,163,141],'WoodPlanks')
 furnishing('BathroomBasin',[2.6,.22,1.8],[19,2.91,9.5],[225,223,210],'Marble')
 furnishing('ShowerTray',[3.8,.18,3.8],[19,.09,17],[222,224,216],'Marble')
 furnishing('BathroomTank',[1.7,2.5,1],[14.5,1.25,18.5],[229,226,212],'SmoothPlastic')
 furnishing('BathroomBowl',[1.8,1.2,2.5],[14.5,1.1,17],[229,226,212],'SmoothPlastic',shape='Ball')
 furnishing('BathroomPedestal',[1,1.2,1.4],[14.5,.6,17.2],[229,226,212],'SmoothPlastic')
 assert len(records)==125

 return dict(id='ResidentialTowerA_Level'+str(level).zfill(2),records=records,units=units,floorY=floor,sourceOSM=419447155,sourceFootprint=shapely.to_geojson(poly),phase='INACCESSIBLE_INTERIOR_IN_PROGRESS',sourceHash=hashlib.sha256((ROOT/'data/detroit_geography.json').read_bytes()).hexdigest())
TAIL="""
local Floor={}
function Floor.build(root)
 local model,stats=require(script.Parent.CityBlockGenerator).build(root,plan,nil,80)
 local lookup={}for _,r in plan.records do lookup[r.name]=r end
 for _,p in model:GetDescendants()do if p:IsA('BasePart')then local r=lookup[p.Name];if r.seat then local seat=Instance.new('Seat');seat.Name=p.Name;seat.Size=p.Size;seat.CFrame=p.CFrame;seat.Color=p.Color;seat.Material=p.Material;seat.Parent=p.Parent;p:Destroy();p=seat end;if r.shape then p.Shape=Enum.PartType[r.shape]end;p.Anchored=true;p.CanCollide=true;p.CanQuery=true;p.CanTouch=r.seat==true;p.CastShadow=false end end
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;model:SetAttribute('ConstructionPhase',plan.phase);model:SetAttribute('ResidentialFloor',1)
 return model,stats
end
return Floor
"""
if __name__=='__main__':
 p=generate();payload=json.dumps(p,separators=(',',':'),allow_nan=False)
 (ROOT/'data/residential_floor_a01_plan.json').write_text(payload+'\n')
 (ROOT/'src/ResidentialFloorA01.lua').write_text('-- Generated by tools/generate_residential_floor.py\nlocal plan=game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n'+TAIL)
 print(json.dumps({'parts':len(p['records']),'suites':len(p['units']),'floorY':p['floorY'],'phase':p['phase']}))
