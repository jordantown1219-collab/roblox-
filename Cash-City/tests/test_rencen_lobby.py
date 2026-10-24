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
from shapely.strtree import STRtree

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
        self.assertEqual(len(p['records']),63)
        self.assertEqual(sum(bool(r.get('seat')) for r in p['records']),4)
        self.assertEqual(p['sourceReplacements'],[{'sourceIndex':19478,'record':self.source[19478]},{'sourceIndex':19465,'record':self.source[19465]}])
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
        land=affinity.scale(shape(self.geo['land']),xfact=scale,yfact=scale,origin=(0,0))
        for r in p['records']:
            if not ('Floor' in r['name'] or 'Ceiling' in r['name']):continue
            if r.get('shape')==2:
                footprint=Point(r['pos'][0],r['pos'][2]).buffer(r['size'][1]/2)
            else:footprint=bounds(r)[2]
            permitted=land if r['name']=='Lobby_JeffersonApronFloor' else allowed.buffer(.5)
            self.assertLess(footprint.difference(permitted).area,1e-6)
            self.assertLess(bounds(r)[1],p['metadata']['podiumSourceTopStuds']-.2)
        circle=next(r for r in p['records'] if r['name']=='Lobby_CircularCirculationFloor')
        self.assertEqual(circle['shape'],2)
        self.assertAlmostEqual(bounds(circle)[1],36)
        self.assertLess(p['metadata']['rampGradeDegrees'],19)

    def assert_clear_path(self,path):
        p=self.plan;removed={g['sourceIndex'] for g in self.wg['replacements']}|{g['sourceIndex'] for g in p['sourceReplacements']}
        wg_records,changed=cut_wg_portal(self.wg['records'],p['rearPortal'])
        self.assertEqual(changed,2,'Shared WG aperture surgery is a real dependency')
        all_records=[r for i,r in enumerate(self.source) if i not in removed]+wg_records+p['records']
        obstacles=[]
        for r in all_records:
            # Sills end at the declared .35 doorway floor and are support, like decks.
            # Their continuity is asserted separately rather than treating ramp foot contact as a wall.
            if not r.get('collide',True) or 'Floor' in r['name'] or r['name'].endswith('PortalSill'):continue
            lo,hi,poly=bounds(r)
            if hi<=-.24 or lo>=44:continue
            obstacles.append((r['name'],lo,hi,poly))
        tree=STRtree([r[3] for r in obstacles])
        for a,b in zip(path,path[1:]):
            steps=max(1,math.ceil(math.dist(a,b)))
            for step in range(steps+1):
                t=step/steps;position=[a[i]+(b[i]-a[i])*t for i in range(3)];probe=Point(position[0],position[2]).buffer(3)
                for index in tree.query(probe,predicate='intersects'):
                    name,lo,hi,poly=obstacles[index]
                    if lo<position[1]+8 and hi>position[1]+.1:
                        self.assertFalse(poly.intersects(probe),f'Route obstructed by {name} at {position}')

    def test_six_wide_eight_high_continuous_route_after_explicit_portal_dependencies(self):
        p=self.plan
        self.assert_clear_path([p['routeSamples'][0]['pos'],p['metadata']['rampStart'],p['metadata']['rampEnd'],p['metadata']['center'],p['metadata']['westRoomCenter']])

    def test_jefferson_offset_portal_continuity_and_three_dimensional_route(self):
        p=self.plan;j=p['metadata']['jefferson'];door=p['doorAnchors'][0]
        self.assertEqual(door['name'],'Jefferson city entrance')
        self.assertEqual((door['width'],door['height']),(8,10))
        self.assertAlmostEqual(j['sourceLocalZ'],-7.927974693429661)
        self.assertAlmostEqual(math.dist(j['doorway'],j['landingEnd']),10)
        self.assertEqual([j['outside'][1],j['doorway'][1],j['landingEnd'][1],j['rampEnd'][1]],[-.25,.35,.35,36])
        self.assertLess(j['rampGradeDegrees'],7)
        self.assert_clear_path([j['outside'],j['doorway'],j['landingEnd'],j['rampEnd'],p['metadata']['center'],p['metadata']['westRoomCenter']])
        # Every deck's exact top-face endpoints meet the intended floor profile.
        for name,start,end in [('Lobby_JeffersonApronFloor',j['outside'],j['doorway']),('Lobby_JeffersonLandingFloor',j['doorway'],j['landingEnd']),('Lobby_JeffersonRisingFloor',j['landingEnd'],j['rampEnd'])]:
            r=next(r for r in p['records'] if r['name']==name);m,s,c=r['matrix'],r['size'],r['pos']
            endpoints=[[c[i]+m[i*3+1]*s[1]/2+sign*m[i*3+2]*s[2]/2 for i in range(3)] for sign in (-1,1)]
            self.assertLess(math.dist(endpoints[0],start),1e-7);self.assertLess(math.dist(endpoints[1],end),1e-7)
        infill=[r for r in p['records'] if r['name']=='Lobby_JeffersonSourcePortalSideInfill']
        self.assertEqual(len(infill),2)
        self.assertNotAlmostEqual(infill[0]['size'][2],infill[1]['size'][2])
        self.assertTrue(all(r['material']=='Limestone' for r in infill))
        sill=next(r for r in p['records'] if r['name']=='Lobby_JeffersonSourcePortalSill')
        self.assertAlmostEqual(bounds(sill)[1],j['doorway'][1])

    def test_portal_height_and_explicit_original_not_authentic_lobby(self):
        p=self.plan;portal=p['rearPortal']
        self.assertEqual((portal['width'],portal['height'],portal['bottomY'],portal['topY']),(8,10,.35,10.35))
        self.assertEqual(p['metadata']['floorY'],36)
        self.assertIn('Original estimated',p['metadata']['classification'])
        self.assertEqual(p['signAnchors'][0]['text'],'SKYLINE HOTEL')
        self.assertFalse(any('Elevator' in r['name'] or 'Script' in r['name'] for r in p['records']))

if __name__=='__main__':unittest.main()
