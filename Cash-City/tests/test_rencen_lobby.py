import copy
import json
import math
from pathlib import Path
import sys
import unittest
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from generate_rencen_lobby import generate,Point,Polygon,LineString,shape,affinity
from shapely.geometry import MultiPoint
from shapely.ops import unary_union

def bounds(record):
    m,p,s=record['matrix'],record['pos'],record['size'];points=[]
    for x in (-.5,.5):
        for y in (-.5,.5):
            for z in (-.5,.5):
                v=[x*s[0],y*s[1],z*s[2]]
                points.append([p[i]+sum(m[i*3+j]*v[j] for j in range(3)) for i in range(3)])
    return min(v[1] for v in points),max(v[1] for v in points),MultiPoint([(v[0],v[2]) for v in points]).convex_hull

def cut_wg_portal(records,portal):
    result=[];changed=0;px,_,pz=portal['center'];normal=[portal['matrix'][0],portal['matrix'][6]]
    for r in records:
        if r['name']!='Wintergarden_GlassWall':result.append(r);continue
        m,p,s=r['matrix'],r['pos'],r['size'];delta=[px-p[0],pz-p[2]]
        plane=abs(delta[0]*normal[0]+delta[1]*normal[1]);along=delta[0]*m[2]+delta[1]*m[8]
        lo,hi=max(-s[2]/2,along-4),min(s[2]/2,along+4)
        if plane>.5 or hi<=lo:result.append(r);continue
        changed+=1
        for a,b in [(-s[2]/2,lo),(hi,s[2]/2)]:
            if b-a<1e-7:continue
            panel=copy.deepcopy(r);panel['size'][2]=b-a;t=(a+b)/2
            panel['pos']=[p[0]+m[2]*t,p[1],p[2]+m[8]*t];result.append(panel)
        panel=copy.deepcopy(r);top=p[1]+s[1]/2;panel['size'][1]=top-portal['topY'];panel['size'][2]=hi-lo
        panel['pos']=[p[0]+m[2]*(lo+hi)/2,(top+portal['topY'])/2,p[2]+m[8]*(lo+hi)/2];result.append(panel)
    return result,changed

class RenCenLobbyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.plan=generate()
        cls.source=json.loads((ROOT/'data/geometry.json').read_text())
        cls.geo=json.loads((ROOT/'data/detroit_geography.json').read_text())
        cls.wg=json.loads((ROOT/'data/wintergarden_plan.json').read_text())

    def test_determinism_source_finish_and_bounded_valid_frames(self):
        p=self.plan
        self.assertEqual(p,json.loads((ROOT/'data/rencen_lobby_plan.json').read_text()))
        self.assertEqual(len(p['records']),53)
        self.assertEqual(sum(bool(r.get('seat')) for r in p['records']),4)
        self.assertEqual(p['sourceReplacements'],[{'sourceIndex':19478,'record':self.source[19478]}])
        self.assertEqual(p['metadata']['approvedPortalFinish']['material'],'Limestone')
        for r in p['records']:
            self.assertTrue(all(math.isfinite(n) and 0<n<=2048 for n in r['size']))
            m=r['matrix'];columns=[[m[i],m[i+3],m[i+6]] for i in range(3)]
            for i,a in enumerate(columns):
                for j,b in enumerate(columns):self.assertAlmostEqual(sum(a[k]*b[k] for k in range(3)),1 if i==j else 0)
            if 'SourcePortal' in r['name']:
                self.assertEqual(r['material'],'Limestone')
                self.assertEqual(r['color'],p['metadata']['approvedPortalFinish']['color'])

    def test_floors_and_room_fit_existing_podium_with_roof_headroom(self):
        p=self.plan;scale=self.geo['studsPerMeter']
        podium=affinity.scale(shape(next(f for f in self.geo['features'] if f['osm']==1307210646)['geometry']),xfact=scale,yfact=scale,origin=(0,0))
        allowed=podium.union(shape(self.wg['metadata']['sourceFootprintStuds']))
        for r in p['records']:
            if not ('Floor' in r['name'] or 'Ceiling' in r['name']):continue
            if r.get('shape')==2:
                footprint=Point(r['pos'][0],r['pos'][2]).buffer(r['size'][1]/2)
            else:footprint=bounds(r)[2]
            self.assertLess(footprint.difference(allowed.buffer(.5)).area,1e-6)
            self.assertLess(bounds(r)[1],p['metadata']['podiumSourceTopStuds']-.2)
        circle=next(r for r in p['records'] if r['name']=='Lobby_CircularCirculationFloor')
        self.assertEqual(circle['shape'],2)
        self.assertAlmostEqual(bounds(circle)[1],36)
        self.assertLess(p['metadata']['rampGradeDegrees'],19)

    def test_six_wide_eight_high_continuous_route_after_explicit_portal_dependencies(self):
        p=self.plan;removed={g['sourceIndex'] for g in self.wg['replacements']}|{19478}
        wg_records,changed=cut_wg_portal(self.wg['records'],p['rearPortal'])
        self.assertEqual(changed,2,'Shared WG aperture surgery is a real dependency')
        all_records=[r for i,r in enumerate(self.source) if i not in removed]+wg_records+p['records']
        obstacles=[]
        for r in all_records:
            if not r.get('collide',True) or 'Floor' in r['name']:continue
            lo,hi,poly=bounds(r)
            if hi<=.36 or lo>=44:continue
            obstacles.append((r['name'],lo,hi,poly))
        path=[p['routeSamples'][0]['pos'],p['metadata']['rampStart'],p['metadata']['rampEnd'],p['metadata']['center'],p['metadata']['westRoomCenter']]
        for a,b in zip(path,path[1:]):
            steps=max(1,math.ceil(math.dist(a,b)))
            for step in range(steps+1):
                t=step/steps;position=[a[i]+(b[i]-a[i])*t for i in range(3)];probe=Point(position[0],position[2]).buffer(3)
                for name,lo,hi,poly in obstacles:
                    if lo<position[1]+8 and hi>position[1]+.1:
                        self.assertFalse(poly.intersects(probe),f'Route obstructed by {name} at {position}')

    def test_portal_height_and_explicit_original_not_authentic_lobby(self):
        p=self.plan;portal=p['rearPortal']
        self.assertEqual((portal['width'],portal['height'],portal['bottomY'],portal['topY']),(8,10,.35,10.35))
        self.assertEqual(p['metadata']['floorY'],36)
        self.assertIn('Original estimated',p['metadata']['classification'])
        self.assertEqual(p['signAnchors'][0]['text'],'SKYLINE HOTEL')
        self.assertFalse(any('Elevator' in r['name'] or 'Script' in r['name'] for r in p['records']))

if __name__=='__main__':unittest.main()
