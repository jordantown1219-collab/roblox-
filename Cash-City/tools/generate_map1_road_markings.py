"""Original paint layout on the existing source-aligned Atwater/Beaubien junction."""
import hashlib,json,math
from pathlib import Path
from generate_river_access import surface_polygon,shape,Polygon,Point,LineString,unary_union

ROOT=Path(__file__).resolve().parents[1]
ARMS=(8759335,1446468572,1446468573)

def generate(root=ROOT):
    paths=[root/'data/detroit_geography.json',root/'data/geometry.json']
    geography,geometry=[json.loads(p.read_text()) for p in paths]
    scale=geography['studsPerMeter']
    roads=[f for f in geography['features'] if f['kind']=='road' and f['elevation']==0 and f['geometry']['type']=='LineString']
    selected=[next(f for f in roads if f['osm']==osm) for osm in ARMS]
    junction=Point(selected[0]['geometry']['coordinates'][0])
    assert all(min(Point(c).distance(junction) for c in (f['geometry']['coordinates'][0],f['geometry']['coordinates'][-1]))<1e-6 for f in selected)
    rendered=[r for r in geometry if r['name']=='JoinedRoad' and surface_polygon(r).distance(Point(junction.x*scale,junction.y*scale))<160]
    assert rendered,'No rendered road below selected junction'
    road_union=unary_union([surface_polygon(r) for r in rendered])
    records=[];polygons=[];arms=[]
    for f in selected:
        coords=list(f['geometry']['coordinates'])
        if Point(coords[-1]).distance(junction)<1e-6:coords.reverse()
        # The eastern approach is split into a short source way; follow its same-name continuation.
        used={f['osm']}
        for _ in range(4):
            if LineString(coords).length>=35:break
            candidates=[]
            for other in roads:
                if other['osm'] in used or other['name']!=f['name']:continue
                more=list(other['geometry']['coordinates'])
                if Point(more[-1]).distance(Point(coords[-1]))<1e-6:more.reverse()
                if Point(more[0]).distance(Point(coords[-1]))<1e-6:candidates.append((other,more))
            if not candidates:break
            assert len(candidates)==1,'Ambiguous road continuation'
            other,more=candidates[0];used.add(other['osm']);coords+=more[1:]
        line=LineString(coords);assert line.length>11
        def placement(distance,lateral,across,along):
            p=line.interpolate(distance);a=line.interpolate(distance-.05);b=line.interpolate(distance+.05)
            dx,dz=b.x-a.x,b.y-a.y;length=math.hypot(dx,dz);fx,fz=dx/length,dz/length;rx,rz=fz,-fx
            x,z=(p.x+rx*lateral)*scale,(p.y+rz*lateral)*scale
            polygon=Polygon([(x+(rx*u+fx*v)*scale,z+(rz*u+fz*v)*scale) for u,v in [(-across/2,-along/2),(-across/2,along/2),(across/2,along/2),(across/2,-along/2)]])
            return x,z,rx,rz,fx,fz,polygon
        def usable_width(distance,along):
            width=f['width']-.8
            while width>=2.4:
                if road_union.buffer(1e-6).covers(placement(distance,0,width,along)[-1]):return width
                width-=.2
            return None
        def add(name,distance,lateral,across,along):
            x,z,rx,rz,fx,fz,polygon=placement(distance,lateral,across,along)
            assert road_union.buffer(1e-6).covers(polygon),'Paint outside rendered road'
            assert all(polygon.intersection(old).area<1e-7 for old in polygons),'Overlapping paint'
            support=[r for r in rendered if surface_polygon(r).covers(Point(x,z))]
            assert support,'No source road support'
            tops=[r['pos'][1]+sum(abs(r['matrix'][3+i])*r['size'][i]/2 for i in range(3)) for r in support]
            assert max(tops)-min(tops)<1e-5,'Road grade requires review'
            top=max(tops)
            records.append(dict(name=name,size=[across*scale,.012,along*scale],pos=[x,top+.026,z],matrix=[rx,0,fx,0,1,0,rz,0,fz],material='SmoothPlastic',color=[223,221,209],collide=False,roadTop=top,sourceOSM=f['osm']))
            polygons.append(polygon)
        # Atwater's short eastern way bends over a clipped pavement edge.
        # Locate the whole band on continuous rendered pavement before sizing paint.
        choices=[]
        for distance in (7.2,10,12,14,16,18):
            width=usable_width(distance,2.5)
            if width is not None:choices.append((width,-distance))
        assert choices,'No source-supported crossing location'
        width,negative_distance=max(choices);crossing=-negative_distance
        count=math.floor(width/1.1)
        for index in range(count):add('Crosswalk_'+str(f['osm'])+'_'+str(index),crossing,(index-(count-1)/2)*1.1,.6,2.5)
        # Inbound half-road treatment is an explicit artistic two-way-road assumption.
        stop_width=usable_width(crossing+2.8,.35)
        assert stop_width is not None,'No source-supported stop line'
        add('ApproachStopLine_'+str(f['osm']),crossing+2.8,-stop_width/4,stop_width/2-.3,.35)
        arms.append(dict(osm=f['osm'],name=f['name'],crosswalkStripes=count,widthMeters=f['width'],paintableWidthMeters=width,crossingDistanceMeters=crossing))
    assert len(records)<=32
    return dict(id='Map1AtwaterCrossing',records=records,arms=arms,junctionStuds=[junction.x*scale,junction.y*scale],classification='Mapped junction; original paint spacing and assumed two-way approach lanes; not surveyed',sourceHashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in paths})

TAIL='''
local Markings={}
function Markings.build(root)
 local model,stats=require(script.Parent.CityBlockGenerator).build(root,plan,nil,80)
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 model:SetAttribute('ReferenceStatus',plan.classification)
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 end end
 return model,stats
end
return Markings
'''
if __name__=='__main__':
    plan=generate();payload=json.dumps(plan,separators=(',',':'),allow_nan=False)
    (ROOT/'data/map1_road_markings_plan.json').write_text(payload+'\n',encoding='utf-8')
    (ROOT/'src/Map1RoadMarkings.lua').write_text('-- Generated by tools/generate_map1_road_markings.py\nlocal plan=game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n'+TAIL,encoding='utf-8')
    print(json.dumps({'parts':len(plan['records']),'arms':plan['arms'],'junction':plan['junctionStuds']}))
