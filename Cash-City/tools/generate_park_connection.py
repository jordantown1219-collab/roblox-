"""Continue the existing mapped RiverWalk into the existing Hart Plaza path."""
import json,hashlib,math
from pathlib import Path
from generate_walk_route import collider_polygon
from generate_river_access import surface_polygon,rendered_surfaces
from generate_riverwalk_extension import TAIL
from generate_wintergarden import sub,dot,cross,norm
import shapely
from shapely.geometry import Point,LineString,Polygon,shape
from shapely.ops import substring,unary_union
ROOT=Path(__file__).resolve().parents[1]

def generate(root=ROOT):
    names=['detroit_geography.json','geometry.json','detail_preview.json','riverwalk_extension2_plan.json','hart_path_plan.json']
    g,geometry,details,previous,hart=[json.loads((root/'data'/n).read_text()) for n in names]
    s=g['studsPerMeter']
    source=next(f for f in g['features'] if f.get('osm')==69706033 and f['kind']=='path')
    river=shape(source['geometry'])
    last=previous['routeSamples'][-1]['pos'];start=river.project(Point(last[0]/s,last[2]/s))
    floor=hart['records'][0];target=Point(floor['pos'][0]/s,floor['pos'][2]/s)
    end=river.project(target)
    assert end>start,'Existing paths no longer ordered; preserve source'
    river_route=substring(river,start,end)
    route=LineString(list(river_route.coords)+[(target.x,target.y)])
    corridor=route.buffer(1.25,cap_style=2,join_style=2)
    land=shape(g['land'])
    forbidden=unary_union([p for r in geometry+[r for d in details for r in d['parts']] if (p:=collider_polygon(r,s)) is not None])
    assert land.covers(corridor),'Connection would leave source land'
    assert not corridor.intersects(forbidden),'Connection meets standing source geometry'
    # Existing finished paving stays unchanged. No coplanar duplicate at either join.
    old_surfaces=[surface_polygon(floor)]
    for name in ('rencen_walk_plan.json','riverwalk_extension_plan.json','riverwalk_extension2_plan.json'):
        for r in json.loads((root/'data'/name).read_text())['records']:
            if r['name'] in ('RenCenContinuousPromenadeCollision','Extension_PaleConcreteWalk'):old_surfaces.append(surface_polygon(r))
    old=unary_union(old_surfaces)
    paving=shapely.affinity.scale(corridor,xfact=s,yfact=s,origin=(0,0)).difference(old)
    samples=[]
    distances=sorted(set([0,route.length]+list(range(5,math.ceil(route.length),5))))
    for d in distances:
        p=route.interpolate(d);samples.append({'pos':[p.x*s,.41,p.y*s],'floorY':.41,'width':2.5*s,'clearHeight':8})
    # Humanoids move along chords between sampled targets. At two bends those
    # chords cut the inside corner of the mapped centerline's buffered paving.
    # Append only missing core-width support; leave all existing records intact.
    rendered=rendered_surfaces(geometry)
    movement=LineString([(p['pos'][0],p['pos'][2]) for p in samples]).buffer(2.6,cap_style=2,join_style=2)
    patches=movement.difference(unary_union([paving,old,rendered['JoinedWalk']]))
    patch_meters=shapely.affinity.scale(patches,xfact=1/s,yfact=1/s,origin=(0,0))
    assert land.covers(patch_meters),'Corner repair would leave land'
    assert patches.intersection(rendered['JoinedRoad']).area<1e-6,'Corner repair overlaps a road'
    assert not patch_meters.intersects(forbidden),'Corner repair meets standing geometry'
    records=[]
    for name,area in [('Map1_ContinuousParkWalk',paving),('Map1_ParkCornerInfill',patches)]:
        pieces=list(area.geoms) if area.geom_type=='MultiPolygon' else [area]
        for piece in pieces:
            if piece.is_empty or piece.area<1e-8:continue
            for tri in shapely.constrained_delaunay_triangles(piece).geoms:
                a,b,c=[[x,.35,z] for x,z in list(tri.exterior.coords)[:3]]
                ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
                if dot(ab,ab)>dot(ac,ac) and dot(ab,ab)>dot(bc,bc):c,a=a,c
                elif dot(ac,ac)>dot(bc,bc) and dot(ac,ac)>dot(ab,ab):a,b=b,a
                ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
                if dot(cross(ac,ab),cross(ac,ab))<1e-10:continue
                normal=norm(cross(ac,ab));back=norm(bc);up=norm(cross(bc,normal));width=abs(dot(ab,up))
                for other,v,flip in [(b,ab,1),(c,ac,-1)]:
                    length=abs(dot(v,back))
                    if min(width,length)<.001:continue
                    matrix=[normal[0]*flip,up[0],back[0]*flip,normal[1]*flip,up[1],back[1]*flip,normal[2]*flip,up[2],back[2]*flip]
                    records.append(dict(name=name,cls='WedgePart',size=[.12,width,length],pos=[(a[i]+other[i])/2 for i in range(3)],matrix=matrix,material='Concrete',color=[174,171,161],collide=True))
    assert len(records)<250 and all(0<min(r['size']) and max(r['size'])<=2048 for r in records)
    return dict(id='Map1ParkConnection',records=records,routeSamples=samples,lengthMeters=route.length,
                mappedRiverMeters=river_route.length,sourceOSM=69706033,destinationOSM=hart['sourceOSM'],
                classification='Existing mapped RiverWalk plus original short park join; flat grade estimated',
                sourceHashes={n:hashlib.sha256((root/'data'/n).read_bytes()).hexdigest() for n in names})

if __name__=='__main__':
    plan=generate();payload=json.dumps(plan,separators=(',',':'),allow_nan=False)
    (ROOT/'data/park_connection_plan.json').write_text(payload+'\n')
    (ROOT/'src/ParkConnection.lua').write_text('-- Generated by tools/generate_park_connection.py\nlocal plan=game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n'+TAIL)
    print(json.dumps({'parts':len(plan['records']),'lengthMeters':plan['lengthMeters'],'waypoints':len(plan['routeSamples'])}))
