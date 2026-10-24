"""Opt-in paved RiverWalk study on a source-derived straight RenCen segment."""
import hashlib
import json
import math
from pathlib import Path
from generate_walk_route import collider_polygon  # Sets bundled Shapely dependency path.
from shapely.geometry import LineString, shape
from shapely.ops import unary_union

ROOT = Path(__file__).resolve().parents[1]
OSM = 69706033


def make_plan(geography, geometry, details):
    scale = geography['studsPerMeter']
    source = next(f for f in geography['features'] if f['osm'] == OSM and f['kind'] == 'path')
    assert source['elevation'] == 0 and not source['steps']
    # Existing segment endpoints selected from the source, not invented plaza coordinates.
    coordinates = source['geometry']['coordinates']
    candidates = [(math.dist(a, b), a, b) for a, b in zip(coordinates, coordinates[1:])
                  if 20 < (a[0]+b[0])/2 < 120 and 100 < (a[1]+b[1])/2 < 160 and math.dist(a,b)>=80]
    assert candidates, 'Source RiverWalk segment changed; stop for review'
    _, a, b = min(candidates)
    line = LineString([a,b])
    start = line.interpolate((line.length-80)/2)
    end = line.interpolate((line.length+80)/2)
    route = LineString([start,end])
    corridor = route.buffer(1.25, cap_style=2)
    land = shape(geography['land'])
    assert land.covers(corridor), 'Do not extend paving into water'
    assert shape(source['geometry']).buffer(source['width']/2).covers(corridor), 'Outside mapped path'
    buildings = unary_union([shape(f['geometry']) for f in geography['features'] if f['kind']=='building'])
    roads = unary_union([shape(f['geometry']).buffer(f['width']/2,cap_style=2) for f in geography['features'] if f['kind']=='road' and f['elevation']==0])
    obstacles = unary_union([p for r in geometry+[r for model in details for r in model['parts']]
                            for p in [collider_polygon(r,scale)] if p is not None])
    for category, obstacle in [('building',buildings),('road',roads),('standing collider',obstacles)]:
        assert not corridor.intersects(obstacle), 'Promenade intersects '+category
    ax,az=start.x,start.y
    bx,bz=end.x,end.y
    forward=((bx-ax)/80,(bz-az)/80)
    right=(forward[1],-forward[0])
    matrix=[right[0],0,forward[0],0,1,0,right[1],0,forward[1]]
    width,length=2.5*scale,80*scale
    top=.41  # Existing rendered path .35 plus .06: estimated datum, never survey grade.
    def position(x,z,y): return [(ax+bx)*scale/2+right[0]*x+forward[0]*z,y,(az+bz)*scale/2+right[1]*x+forward[1]*z]
    records=[{'name':'RenCenContinuousPromenadeCollision','size':[width,.08,length],
              'pos':position(0,0,top-.04),'matrix':matrix,'material':'Concrete','color':[157,154,145],
              'collide':True,'trans':1}]
    for row in range(40):
        for col in range(2):
            tone=((row*7+col*3)%5)-2
            records.append({'name':'RenCenPavedPanel','size':[width/2-.025,.03,length/40-.025],
                            'pos':position((col-.5)*width/2,(row-19.5)*length/40,top-.015),
                            'matrix':matrix,'material':'Concrete','color':[157+tone,154+tone,145+tone], 'collide':False})
    return {'id':'RenCenPromenade_69706033','records':records,'sourceOSM':OSM,
            'segmentMetersXZ':[[ax,az],[bx,bz]],'lengthMeters':80,'widthMeters':2.5,
            'sourceSegmentMetersXZ':[a,b],'sourcePathWidthMeters':source['width'],
            'studsPerMeter':scale,'groundDatum':geography['groundDatum'],'heightChangeStuds':.06,
            'status':'offline_source_clearance_verified_native_walk_pending',
            'reference':'https://www.detroitriverfront.org/plan-your-visit/parks-greenways/the-riverwalk',
            'referenceStatus':'Paved concrete material study; panel layout and flat grade are estimates, not surveyed/as-built reproductions',
            'clearancesMeters':{'shoreline':corridor.distance(land.boundary),'building':corridor.distance(buildings),'road':corridor.distance(roads),'standingCollider':corridor.distance(obstacles)},
            'limitations':['No source-proven hole or flicker defect identified; additive surface trial only.',
                           'No shoreline/landmark/source geometry edits; no invented wood boardwalk, stairs or elevations.',
                           'Collision continuity is analytic; native raycasts, avatar route, source-surface visual overlap and performance remain pending.']}


def main():
    names=['detroit_geography.json','geometry.json','detail_preview.json']
    loaded=[json.loads((ROOT/'data'/name).read_text()) for name in names]
    plan=make_plan(*loaded)
    plan['sourceHashes']={name:hashlib.sha256((ROOT/'data'/name).read_bytes()).hexdigest() for name in names}
    (ROOT/'data/rencen_walk_plan.json').write_text(json.dumps(plan,indent=2,allow_nan=False)+'\n')
    print(f"RenCen: {len(plan['records'])} records,80m; native validation pending")


if __name__=='__main__': main()
