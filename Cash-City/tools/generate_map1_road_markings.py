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
    # Small, original streetscape set on source sidewalk corners, off the roadway.
    center=Point(junction.x*scale,junction.y*scale)
    walks=unary_union([surface_polygon(r) for r in geometry if r['name']=='JoinedWalk' and surface_polygon(r).distance(center)<90])
    buildings=unary_union([shape(f['geometry']) for f in geography['features'] if f['kind']=='building'])
    candidates=[]
    for radius in (25,32,40,48,56):
        for degrees in range(0,360,10):
            angle=math.radians(degrees);point=Point(center.x+math.cos(angle)*radius,center.y+math.sin(angle)*radius)
            if walks.covers(point.buffer(1)) and road_union.distance(point)>3 and not buildings.intersects(Point(point.x/scale,point.y/scale).buffer(.6)):
                candidates.append((degrees,radius,point))
    anchors=[]
    identity=[1,0,0,0,1,0,0,0,1]
    for index,wanted in enumerate((45,135,225,315)):
        available=[c for c in candidates if all(c[2].distance(p)>14 for p in anchors)]
        assert available,'Insufficient clear sidewalk corners'
        degrees,radius,point=min(available,key=lambda c:(abs((c[0]-wanted+180)%360-180),c[1]))
        anchors.append(point)
        support=[r for r in geometry if r['name']=='JoinedWalk' and surface_polygon(r).covers(point)]
        assert support
        ground=max(r['pos'][1]+sum(abs(r['matrix'][3+i])*r['size'][i]/2 for i in range(3)) for r in support)
        def prop(label,offset,size,color,material='Metal',matrix=identity,**extra):
            records.append(dict(name='Junction_'+str(index)+'_'+label,size=size,pos=[point.x+offset[0],ground+offset[1],point.y+offset[2]],matrix=matrix,color=color,material=material,collide=False,groundTop=ground,anchor=[point.x,point.y],**extra))
        if index%2==0:
            prop('SignPost',[0,6.5,0],[.22,13,.22],[122,133,129])
            east=selected[1]['geometry']['coordinates'];dx,dz=east[1][0]-east[0][0],east[1][1]-east[0][1];length=math.hypot(dx,dz);fx,fz=dx/length,dz/length
            prop('AtwaterBlade',[0,12.7,0],[9,1.1,.14],[34,78,61],matrix=[fx,0,-fz,0,1,0,fz,0,fx],text='ATWATER ST')
            prop('BeaubienBlade',[0,11.4,0],[9,1.1,.14],[34,78,61],matrix=[-fz,0,-fx,0,1,0,fx,0,-fz],text='BEAUBIEN ST')
        else:
            dx,dz=center.x-point.x,center.y-point.y;length=math.hypot(dx,dz);fx,fz=dx/length,dz/length
            prop('LampBase',[0,.2,0],[1.4,.4,1.4],[65,73,70])
            prop('LampPole',[0,8.4,0],[.25,16,.25],[141,150,146])
            prop('LampArm',[fx*1.8,16.3,fz*1.8],[3.6,.22,.22],[141,150,146],matrix=[fx,0,-fz,0,1,0,fz,0,fx])
            prop('LampHead',[fx*3.6,16.15,fz*3.6],[1.7,.3,1.1],[250,235,205],'Neon',light=True)
    assert len(records)<=48
    return dict(id='Map1AtwaterCrossing',records=records,arms=arms,junctionStuds=[junction.x*scale,junction.y*scale],classification='Mapped junction; original paint spacing and assumed two-way approach lanes; not surveyed',sourceHashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in paths})

TAIL='''
local Markings={}
function Markings.finish(model)
 local byName={} for _,r in ipairs(plan.records) do byName[r.name]=r end
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then
  local r=byName[p.Name]
  if r and r.text then for _,face in ipairs({Enum.NormalId.Front,Enum.NormalId.Back}) do
   local name='StreetName'..face.Name
   if not p:FindFirstChild(name) then
    local gui=Instance.new('SurfaceGui');gui.Name=name;gui.Face=face;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=50;gui.Parent=p
    local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text=r.text;label.TextScaled=true;label.Font=Enum.Font.GothamMedium;label.TextColor3=Color3.fromRGB(240,242,232);label.Parent=gui
   end
  end end
  if r and r.light and not p:FindFirstChild('StreetLight') then
   local light=Instance.new('PointLight');light.Name='StreetLight';light.Brightness=.45;light.Range=28;light.Color=Color3.fromRGB(255,235,200);light.Shadows=false;light.Parent=p
  end
 end end
end
function Markings.build(root)
 local model,stats=require(script.Parent.CityBlockGenerator).build(root,plan,nil,80)
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 model:SetAttribute('ReferenceStatus',plan.classification)
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 end end
 Markings.finish(model)
 return model,stats
end
return Markings
'''
if __name__=='__main__':
    plan=generate();payload=json.dumps(plan,separators=(',',':'),allow_nan=False)
    (ROOT/'data/map1_road_markings_plan.json').write_text(payload+'\n',encoding='utf-8')
    (ROOT/'src/Map1RoadMarkings.lua').write_text('-- Generated by tools/generate_map1_road_markings.py\nlocal plan=game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n'+TAIL,encoding='utf-8')
    print(json.dumps({'parts':len(plan['records']),'arms':plan['arms'],'junction':plan['junctionStuds']}))
