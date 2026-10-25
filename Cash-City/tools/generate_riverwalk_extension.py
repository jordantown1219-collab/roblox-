"""One source-aligned RiverWalk section; original path and geography are read-only."""
import argparse,hashlib,json,math
from pathlib import Path
from generate_walk_route import collider_polygon
from generate_wintergarden import sub,dot,cross,norm
import shapely
from shapely.geometry import LineString,Point,Polygon,shape
from shapely.ops import substring,unary_union

ROOT=Path(__file__).resolve().parents[1]

def generate(root=ROOT,section=1):
    assert section in (1,2),'Only the two reviewed sections are supported'
    names=['rencen_walk_plan.json','detroit_geography.json','geometry.json','detail_preview.json']
    old,g,geometry,details=[json.loads((root/'data'/n).read_text()) for n in names]
    scale=g['studsPerMeter']
    source=next(f for f in g['features'] if f.get('osm')==old['sourceOSM'] and f['kind']=='path')
    line=LineString(source['geometry']['coordinates'])
    start=line.project(Point(old['segmentMetersXZ'][-1]))+40*(section-1)
    route=substring(line,start,start+40)
    assert abs(route.length-40)<1e-6,'Insufficient mapped path; preserve original'
    corridor=route.buffer(1.45,cap_style=2,join_style=2)
    land=shape(g['land'])
    roads=unary_union([shape(f['geometry']).buffer(f['width']/2,cap_style=2) for f in g['features'] if f['kind']=='road' and f['elevation']==0])
    buildings=unary_union([shape(f['geometry']) for f in g['features'] if f['kind']=='building'])
    colliders=unary_union([p for r in geometry+[r for d in details for r in d['parts']] if (p:=collider_polygon(r,scale)) is not None])
    forbidden=unary_union([roads,buildings,colliders])
    assert land.covers(corridor) and not corridor.intersects(forbidden),'Extension requires source-clearance review'
    records=[]
    def add(name,size,pos,matrix,material='Concrete',color=None,**extra):
        records.append(dict(name=name,size=size,pos=pos,matrix=matrix,material=material,color=color or [174,171,161],collide=True,**extra))
    def surface(name,polygon,top,color):
        for tri in shapely.constrained_delaunay_triangles(polygon).geoms:
            a,b,c=[[x*scale,top-.06,z*scale] for x,z in list(tri.exterior.coords)[:3]]
            ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
            if dot(ab,ab)>dot(ac,ac) and dot(ab,ab)>dot(bc,bc):c,a=a,c
            elif dot(ac,ac)>dot(bc,bc) and dot(ac,ac)>dot(ab,ab):a,b=b,a
            ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
            normal=norm(cross(ac,ab));back=norm(bc);up=norm(cross(bc,normal));width=abs(dot(ab,up))
            for other,v,flip in [(b,ab,1),(c,ac,-1)]:
                length=abs(dot(v,back))
                if min(width,length)<.001:continue
                matrix=[normal[0]*flip,up[0],back[0]*flip,normal[1]*flip,up[1],back[1]*flip,normal[2]*flip,up[2],back[2]*flip]
                add(name,[.12,width,length],[(a[i]+other[i])/2 for i in range(3)],matrix,color=color,cls='WedgePart')
    surface('Extension_PaleConcreteWalk',corridor,.41,[174,171,161])
    def frame(distance):
        p=route.interpolate(distance);a=route.interpolate(max(0,distance-.1));b=route.interpolate(min(40,distance+.1))
        f=norm([b.x-a.x,0,b.y-a.y]);r=[f[2],0,-f[0]]
        return p,f,r,[r[0],0,f[0],0,1,0,r[2],0,f[2]]
    bay_count=0
    for distance in (8,27):
        p,f,r,m=frame(distance)
        choices=[]
        for sign in (-1,1):
            center=[p.x+r[0]*sign*3.4,p.y+r[2]*sign*3.4]
            poly=Polygon([(center[0]+r[0]*x+f[0]*z,center[1]+r[2]*x+f[2]*z) for x,z in [(-2,-3),(-2,3),(2,3),(2,-3)]]).difference(corridor)
            if land.covers(poly) and not poly.intersects(forbidden):choices.append((Point(center).distance(land.boundary),sign,poly))
        assert choices,'No clear seating bay; do not place into existing work'
        _,sign,bay=max(choices,key=lambda c:c[0]);bay_count+=1
        surface('Extension_GraniteSeatingBay',bay,.41,[151,146,137])
        def prop(name,x,z,y,size,material,color,**extra):
            add(name,size,[(p.x+r[0]*x+f[0]*z)*scale,y,(p.y+r[2]*x+f[2]*z)*scale],m,material,color,**extra)
        # Original benches: native Seat, timber back and two steel legs.
        for z in (-1.7,1.7):
            prop('Extension_TimberBenchSeat',sign*3.5,z,1.48,[6.5,.35,1.8],'WoodPlanks',[104,77,51],seat=True)
            prop('Extension_TimberBenchBack',sign*3.5,z+.32,2.18,[6.5,1.1,.18],'WoodPlanks',[104,77,51])
            for x in (sign*3.5-.65,sign*3.5+.65):prop('Extension_BenchSteelLeg',x,z,.9,[.15,.85,1.5],'Metal',[63,68,66])
        for z in (-2.65,2.65):
            prop('Extension_Planter',sign*4.3,z,1.1,[2.4,1.38,2.4],'Concrete',[117,116,105])
            prop('Extension_OriginalShrub',sign*4.3,z,2.05,[2.65,1.4,2.65],'Grass',[67,91,56],foliage=True)
        prop('Extension_SilverLightColumn',sign*5,z,5.3,[.23,9.78,.23],'Metal',[144,150,148])
        prop('Extension_LanternCap',sign*5,z,10.2,[1.2,.35,1.2],'SmoothPlastic',[232,225,200],lamp=True)
        # Bay rear railing leaves the full mapped walking strip unobstructed.
        for z in (-2.8,0,2.8):prop('Extension_BayRailPost',sign*5.15,z,2.15,[.16,3.48,.16],'Metal',[79,87,86])
        for y in (1.4,3.8):prop('Extension_BayRail',sign*5.15,0,y,[.12,.12,5.6*scale],'Metal',[79,87,86])
        if section==2:
            # Low planted bed behind the seating, inside the reviewed bay.
            # Preserve the route, benches and existing corner planters exactly.
            cx=sign*4.8
            bed=Polygon([(p.x+r[0]*(cx+x)+f[0]*z,p.y+r[2]*(cx+x)+f[2]*z)
                         for x,z in [(-.27,-1.25),(-.27,1.25),(.27,1.25),(.27,-1.25)]])
            assert land.covers(bed) and not bed.intersects(forbidden) and not bed.intersects(corridor)
            prop('Extension_RearPlantingBed',cx,0,.96,[.54*scale,1.1,2.5*scale],'Concrete',[132,130,118])
            prop('Extension_PlantingSoil',cx,0,1.54,[.46*scale,.08,2.42*scale],'Ground',[67,57,43],decor=True)
            for z,color in [(-.8,[71,94,59]),(0,[82,105,66]),(.8,[64,87,53])]:
                prop('Extension_LowLandscapeShrub',cx,z,2.12,[.5*scale,1.16,.78*scale],'Grass',color,foliage=True)
    # Sparse dark expansion joints, above the floor and noncollidable.
    for distance in range(2,40,2):
        p,f,r,m=frame(distance)
        add('Extension_PavingJoint',[2.84*scale,.012,.025],[p.x*scale,.418,p.y*scale],m,color=[109,111,108],decor=True)
    assert len(records)<150 and bay_count==2
    for r in records:
        assert all(math.isfinite(v) and 0<v<=2048 for v in r['size'])
        obstacle=collider_polygon(r,scale)
        if obstacle is not None:assert not obstacle.intersects(corridor.buffer(-.1)),r['name']+' blocks mapped path'
    return {'id':'RenCenRiverWalkExtension'+('2' if section==2 else ''),'records':records,'lengthMeters':40,'bayCount':bay_count,
            'routeSamples':[{'pos':[p.x*scale,.41,p.y*scale],'floorY':.41} for d in range(0,41,5) for p in [route.interpolate(d)]],
            'sourceOSM':old['sourceOSM'],'classification':'Mapped route; original furnishing layout, flat grade and panel joints estimated',
            'sourceHashes':{n:hashlib.sha256((root/'data'/n).read_bytes()).hexdigest() for n in names}}

TAIL='''
local Extension={}
function Extension.build(root)
 local model,stats=require(script.Parent.CityBlockGenerator).build(root,plan,nil,80)
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 model:SetAttribute('ReferenceStatus',plan.classification)
 local byName={} for _,r in ipairs(plan.records) do byName[r.name]=r end
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then
  local r=byName[p.Name] p.CastShadow=false
  if r and r.seat then
   local seat=Instance.new('Seat') seat.Name=p.Name seat.Size=p.Size seat.CFrame=p.CFrame seat.Color=p.Color seat.Material=p.Material
   seat.Anchored=true seat.CanTouch=true seat.CastShadow=false seat.Parent=p.Parent p:Destroy() p=seat
  end
  if r and (r.decor or r.foliage) then p.CanCollide=false p.CanTouch=false p.CanQuery=false end
  if r and r.foliage then p.Shape=Enum.PartType.Ball end
  if r and r.lamp then local l=Instance.new('PointLight') l.Brightness=.35 l.Range=16 l.Color=Color3.fromRGB(255,235,199) l.Shadows=false l.Parent=p end
 end end
 return model,stats
end
return Extension
'''

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--section',type=int,choices=(1,2),default=1)
    section=parser.parse_args().section
    plan=generate(section=section)
    suffix='2' if section==2 else ''
    payload=json.dumps(plan,separators=(',',':'),allow_nan=False)
    (ROOT/f'data/riverwalk_extension{suffix}_plan.json').write_text(payload+'\n')
    (ROOT/f'src/RiverWalkExtension{suffix}.lua').write_text('-- Generated by tools/generate_riverwalk_extension.py; source map unchanged.\nlocal plan=game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n'+TAIL)
    print(json.dumps({'records':len(plan['records']),'lengthMeters':plan['lengthMeters'],'bays':plan['bayCount'],'start':plan['routeSamples'][0]['pos'],'end':plan['routeSamples'][-1]['pos']}))
