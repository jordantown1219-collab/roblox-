"""Original furniture inside the verified atrium floor; not a hotel lobby survey."""
import json,math,sys,os
from pathlib import Path
P=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(Path(os.environ['TEMP'])/'smallsignals-test-deps'))
from shapely.geometry import shape,Point,LineString,Polygon
def generate():
    garden=json.loads((P/'data/wintergarden_plan.json').read_text())
    floor=shape(garden['metadata']['sourceFootprintStuds'])
    route=LineString([garden['doorAnchors'][0]['approachPoints'][0][:1]+[garden['doorAnchors'][0]['approachPoints'][0][2]]]+[[p['pos'][0],p['pos'][2]] for p in garden['routeSamples']])
    candidates=[]
    replaced={g['sourceIndex'] for g in garden['replacements']}
    obstacles=[]
    for index,r in enumerate(json.loads((P/'data/geometry.json').read_text())):
        if index in replaced or not r.get('collide',True):continue
        if r['pos'][1]+r['size'][1]/2<.6 or r['pos'][1]-r['size'][1]/2>8:continue
        m=r['matrix'];x,z=r['pos'][0],r['pos'][2];a,b=r['size'][0]/2,r['size'][2]/2
        ex=abs(m[0])*a+abs(m[2])*b;ez=abs(m[6])*a+abs(m[8])*b
        if x+ex<floor.bounds[0] or x-ex>floor.bounds[2] or z+ez<floor.bounds[1] or z-ez>floor.bounds[3]:continue
        obstacles.append(Polygon([(x+m[0]*sx+m[2]*sz,z+m[6]*sx+m[8]*sz) for sx,sz in [(-a,-b),(a,-b),(a,b),(-a,b)]]))
    planters=[r['pos'] for r in garden['records'] if 'Planter' in r['name']]
    for x in range(math.ceil(floor.bounds[0]),math.floor(floor.bounds[2]),8):
        for z in range(math.ceil(floor.bounds[1]),math.floor(floor.bounds[3]),8):
            pt=Point(x,z)
            area=pt.buffer(7)
            if floor.contains(pt.buffer(9)) and pt.distance(route)>15 and all(pt.distance(Point(p[0],p[2]))>10 for p in planters) and not any(o.intersects(area) for o in obstacles):
                candidates.append((pt.distance(floor.centroid),x,z))
    candidates.sort()
    seats=[]
    for _,x,z in candidates:
        if all(math.hypot(x-a['pos'][0],z-a['pos'][2])>18 for a in seats):
            seats.append({'pos':[x,.35,z],'matrix':[1,0,0,0,1,0,0,0,1]})
        if len(seats)==2:break
    assert len(seats)==2,'No clear original lounge placement'
    return {'seats':seats,'floorTop':.35,'referenceStatus':'Original Wintergarden arrival lounge; not the hotel third-floor lobby',
            'sign':'RIVERFRONT ATRIUM','routeClearanceStuds':15}
if __name__=='__main__':
    data=generate();(P/'data/arrival_lounge.json').write_text(json.dumps(data,sort_keys=True))
    (P/'src/ArrivalLoungeData.lua').write_text('return game:GetService("HttpService"):JSONDecode([=['+json.dumps(data,separators=(',',':'))+']=])\n')
    print('Original arrival seating groups:',len(data['seats']))
