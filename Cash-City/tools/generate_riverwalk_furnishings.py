"""Original source-clear planting/light clusters beside the existing 80m promenade."""
import json,math,hashlib
from pathlib import Path
from generate_walk_route import collider_polygon
from generate_river_access import surface_polygon
from shapely.geometry import Point,Polygon,LineString,shape
from shapely.ops import unary_union
ROOT=Path(__file__).resolve().parents[1]
def generate():
    names=['rencen_walk_plan.json','detroit_geography.json','geometry.json','detail_preview.json']
    old,g,geometry,details=[json.loads((ROOT/'data'/n).read_text())for n in names]
    scale=g['studsPerMeter'];line=LineString(old['segmentMetersXZ']);land=shape(g['land']);corridor=line.buffer(1.25,cap_style=2)
    roads=unary_union([shape(f['geometry']).buffer(f['width']/2)for f in g['features']if f['kind']=='road' and f['elevation']==0])
    buildings=unary_union([shape(f['geometry'])for f in g['features']if f['kind']=='building'])
    obstacles=unary_union([poly for r in geometry+[r for d in details for r in d['parts']]if(poly:=collider_polygon(r,scale))is not None])
    reserve=[Point(q)for t in g['gameplay'].values()for q in [t['spawn'],t['exit'],t['transit']]+t['sockets']]
    protected_names=['river_access_plan.json','park_connection_plan.json']
    access_records=[r for n in protected_names for r in json.loads((ROOT/'data'/n).read_text())['records']]
    protected=unary_union([surface_polygon(r) for r in access_records]).buffer(.5*scale)
    names+=protected_names
    records=[];anchors=[];vertical=[0,-1,0,1,0,0,0,0,1];identity=[1,0,0,0,1,0,0,0,1]
    for distance in range(6,80,10):
        p=line.interpolate(distance);a=line.interpolate(distance-.1);b=line.interpolate(distance+.1);length=a.distance(b);fx,fz=(b.x-a.x)/length,(b.y-a.y)/length;rx,rz=fz,-fx
        options=[]
        for sign in (-1,1):
            x,z=p.x+rx*sign*2.2,p.y+rz*sign*2.2
            # Combined tree planter and adjacent light footprint, with path clearance.
            footprint=Polygon([(x+rx*u+fx*v,z+rz*u+fz*v)for u,v in [(-.65,-.65),(-.65,1.6),(.65,1.6),(.65,-.65)]])
            footprint_studs=Polygon([(u*scale,v*scale)for u,v in footprint.exterior.coords])
            if footprint_studs.intersects(protected):continue
            if not land.covers(footprint)or footprint.intersects(corridor)or footprint.intersects(roads)or footprint.intersects(buildings)or footprint.intersects(obstacles)or any(footprint.distance(q)<2 for q in reserve):continue
            wx,wz=x*scale,z*scale
            floors=[r for r in geometry if r['name']in('JoinedPark','JoinedWalk','SourceLand')and surface_polygon(r).covers(Point(wx,wz))]
            if not floors:continue
            top=max(r['pos'][1]+sum(abs(r['matrix'][3+i])*r['size'][i]/2 for i in range(3))for r in floors)
            options.append((Point(x,z).distance(land.boundary),x,z,top))
        if not options:continue
        _,x,z,top=max(options);index=len(anchors);anchors.append(dict(x=x*scale,z=z*scale,floor=top,distanceMeters=distance))
        def add(label,size,offset,color,material,shape_name='Block',matrix=identity,collide=False,**extra):
            u,y,v=offset;records.append(dict(name=f'PromenadePocket_{index}_{label}',size=size,pos=[x*scale+rx*u+fx*v,top+y,z*scale+rz*u+fz*v],matrix=matrix,color=color,material=material,shape=shape_name,collide=collide,**extra))
        add('Planter',[3.6,1.2,3.6],[0,.6,0],[133,131,119],'Concrete',collide=True)
        add('Soil',[3.25,.08,3.25],[0,1.24,0],[66,56,42],'Ground')
        add('Trunk',[8,.55,.55],[0,5.25,0],[96,79,60],'Wood','Cylinder',vertical,True)
        add('LowerCrown',[5.4,4.6,5.4],[-.5,9.2,0],[69,98,57],'Grass','Ball')
        add('UpperCrown',[4.6,5.3,4.6],[.45,11,0],[82,108,63],'Grass','Ball')
        add('LightBase',[.9,.2,.9],[0,.1,4.7],[74,82,79],'Metal',collide=True)
        add('LightColumn',[.18,11,.18],[0,5.7,4.7],[146,154,151],'Metal')
        add('LightHead',[.65,.7,.65],[0,11.5,4.7],[246,233,205],'Neon',light=True)
    assert 4<=len(anchors)<=8 and len(records)==len(anchors)*8,'Insufficient safe furnishing sites'
    bench_count=0
    a,b=line.coords[0],line.coords[-1];fx,fz=(b[0]-a[0])/80,(b[1]-a[1])/80;rx,rz=fz,-fx
    for index,anchor in enumerate(anchors):
        if index%2:continue
        center=line.interpolate(anchor['distanceMeters']);sign=1 if (anchor['x']/scale-center.x)*rx+(anchor['z']/scale-center.y)*rz>0 else -1
        x,z=anchor['x']-fx*6,anchor['z']-fz*6
        footprint=Polygon([(x+fx*u+rx*v,z+fz*u+rz*v)for u,v in [(-3.6,-1.3),(-3.6,1.3),(3.6,1.3),(3.6,-1.3)]])
        meters=Polygon([(u/scale,v/scale)for u,v in footprint.exterior.coords])
        assert land.covers(meters) and not any(meters.intersects(v)for v in(corridor,roads,buildings,obstacles)) and not footprint.intersects(protected),'Bench requires clear land outside access paths'
        assert all(meters.distance(q)>2 for q in reserve)
        top=anchor['floor'];m=[-sign*fx,0,sign*rx,0,1,0,-sign*fz,0,sign*rz]
        def bench(label,size,offset,color,material,collide=False,**extra):
            u,y,v=offset;records.append(dict(name=f'PromenadeBench_{index}_{label}',size=size,pos=[x+m[0]*u+m[2]*v,top+y,z+m[6]*u+m[8]*v],matrix=m,color=color,material=material,shape='Block',collide=collide,**extra))
        bench('Seat',[6.5,.35,1.8],[0,1.35,0],[104,77,51],'WoodPlanks',True,seat=True)
        bench('Back',[6.5,1.1,.18],[0,2.05,.95],[104,77,51],'WoodPlanks',True)
        for side in(-1,1):
            bench('Leg'+str(side),[.18,1.1,1.5],[side*2.5,.55,0],[63,68,66],'Metal')
            bench('Arm'+str(side),[.18,.18,1.8],[side*3.15,1.8,0],[63,68,66],'Metal')
        bench('CrossBrace',[5.2,.18,.18],[0,.7,.35],[63,68,66],'Metal')
        bench_count+=1
    assert bench_count==4 and len(records)==92
    return dict(id='Map1PromenadeFurnishings',records=records,anchors=anchors,benchCount=bench_count,classification='Original planting/light layout on source land beside existing 80m path; not surveyed',sourceHashes={n:hashlib.sha256((ROOT/'data'/n).read_bytes()).hexdigest()for n in names})
TAIL="""
local Furnishings={}
function Furnishings.finish(model)
 local lookup={}for _,r in plan.records do lookup[r.name]=r end
 for _,p in model:GetDescendants()do if p:IsA('BasePart')then
  local r=assert(lookup[p.Name]);if r.seat and not p:IsA('Seat')then local seat=Instance.new('Seat');seat.Name=p.Name;seat.Size=p.Size;seat.CFrame=p.CFrame;seat.Color=p.Color;seat.Material=p.Material;seat.Parent=p.Parent;p:Destroy();p=seat end;p.Shape=Enum.PartType[r.shape];p.Anchored=true;p.CanCollide=r.collide==true;p.CanQuery=r.collide==true;p.CanTouch=r.seat==true;p.CastShadow=false
  if r.light then local light=Instance.new('PointLight');light.Name='PromenadeLight';light.Brightness=.2;light.Range=12;light.Color=Color3.fromRGB(255,235,199);light.Shadows=false;light.Parent=p end
 end end
end
function Furnishings.build(root)
 local model,stats=require(script.Parent.CityBlockGenerator).build(root,plan,nil,80)
 Furnishings.finish(model)
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;model:SetAttribute('ReferenceStatus',plan.classification)
 return model,stats
end
return Furnishings
"""
if __name__=='__main__':
 p=generate();payload=json.dumps(p,separators=(',',':'),allow_nan=False)
 (ROOT/'data/riverwalk_furnishings_plan.json').write_text(payload+'\n')
 (ROOT/'src/RiverWalkFurnishings.lua').write_text('-- Generated by tools/generate_riverwalk_furnishings.py\nlocal plan=game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n'+TAIL)
 print(json.dumps({'parts':len(p['records']),'clusters':len(p['anchors'])}))
