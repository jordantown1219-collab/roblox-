import hashlib,json,math,sys
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'tools'))
from generate_river_access import generate,shape,affinity,Polygon,Point,LineString,unary_union
from shapely.geometry import MultiPoint
from shapely.strtree import STRtree

def volume(r):
    m,p,s=r['matrix'],r['pos'],r['size'];points=[]
    for x in (-.5,.5):
        for y in (-.5,.5):
            for z in (-.5,.5):
                v=[x*s[0],y*s[1],z*s[2]];points.append([p[i]+sum(m[i*3+j]*v[j] for j in range(3)) for i in range(3)])
    return min(p[1] for p in points),max(p[1] for p in points),MultiPoint([(p[0],p[2]) for p in points]).convex_hull

class RiverAccessTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.plan=generate();cls.geo=json.loads((ROOT/'data/detroit_geography.json').read_text());cls.source=json.loads((ROOT/'data/geometry.json').read_text())
        cls.wg=json.loads((ROOT/'data/wintergarden_plan.json').read_text());s=cls.geo['studsPerMeter']
        cls.roads=unary_union([affinity.scale(shape(f['geometry']).buffer(f['width']/2,cap_style=2),xfact=s,yfact=s,origin=(0,0)) for f in cls.geo['features'] if f['kind']=='road' and f['elevation']==0])
        cls.land=affinity.scale(shape(cls.geo['land']),xfact=s,yfact=s,origin=(0,0))

    def test_determinism_hashes_originals_and_budget(self):
        self.assertEqual(self.plan,json.loads((ROOT/'data/river_access_plan.json').read_text()))
        self.assertEqual(len(self.plan['records']),9)
        self.assertNotIn('sourceReplacements',self.plan)
        self.assertEqual(self.plan['metadata']['promenadeLengthMetersPreserved'],80)
        for key in ('routeRamp','routeStairs'):
            for a,b in zip(self.plan[key],self.plan[key][1:]):self.assertLessEqual(math.dist(a['pos'],b['pos']),25+1e-8)
        for name,digest in self.plan['sourceHashes'].items():self.assertEqual(hashlib.sha256((ROOT/'data'/name).read_bytes()).hexdigest(),digest)
        for r in self.plan['records']:
            self.assertTrue(all(math.isfinite(n) and 0<n<=2048 for n in r['size']))
            m=r['matrix'];axes=[[m[i],m[i+3],m[i+6]] for i in range(3)]
            for i,a in enumerate(axes):
                for j,b in enumerate(axes):self.assertAlmostEqual(sum(a[k]*b[k] for k in range(3)),1 if i==j else 0)

    def test_all_new_surfaces_are_land_and_disjoint_from_roads(self):
        for r in self.plan['records']:
            vertices=r.get('meta',{}).get('surfaceTriangleVertices')
            polygon=Polygon([(v[0],v[2]) for v in vertices]) if vertices else volume(r)[2]
            self.assertLess(polygon.difference(self.land).area,1e-6)
            self.assertLess(polygon.intersection(self.roads).area,1e-6,r['name'])

    def test_low_stair_risers_and_gentle_ramp_continuity_all_scales(self):
        p=self.plan
        stairs=[r for r in p['records'] if r['name']=='RiverAccess_LowStairTread']
        tops=[.55]+[volume(r)[1] for r in stairs]+[-.25]
        self.assertEqual(len(stairs),3)
        for a,b in zip(tops,tops[1:]):self.assertAlmostEqual(a-b,.2)
        self.assertLess(p['metadata']['rampGradeDegrees'],4)
        ramp=next(r for r in p['records'] if r['name']=='RiverAccess_GentleParallelRamp')
        m,s,c=ramp['matrix'],ramp['size'],ramp['pos']
        ends=[[c[i]+m[i*3+1]*s[1]/2+sign*m[i*3+2]*s[2]/2 for i in range(3)] for sign in (-1,1)]
        self.assertAlmostEqual(ends[0][1],.55);self.assertAlmostEqual(ends[1][1],-.25)
        for scale in (1,.65,.4,.22):
            self.assertGreaterEqual(s[0],6*scale)
            self.assertGreater(8,6*scale)
        self.assertFalse(any('LowerLanding' in r['name'] for r in p['records']))

    def test_source_and_rebuilt_wintergarden_full_body_headroom(self):
        removed={g['sourceIndex'] for g in self.wg['replacements']}
        obstacles=[]
        for r in [r for i,r in enumerate(self.source) if i not in removed]+self.wg['records']:
            if not r.get('collide',True):continue
            lo,hi,poly=volume(r)
            if hi<=.85 or lo>=8.6:continue
            obstacles.append((r['name'],lo,hi,poly))
        tree=STRtree([o[3] for o in obstacles])
        for key in ('routeRamp','routeStairs'):
            route=self.plan[key]
            for a,b in zip(route,route[1:]):
                a,b=a['pos'],b['pos'];steps=max(1,math.ceil(math.dist(a,b)))
                for step in range(steps+1):
                    t=step/steps;p=[a[i]+(b[i]-a[i])*t for i in range(3)];body=Point(p[0],p[2]).buffer(3)
                    for index in tree.query(body,predicate='intersects'):
                        name,lo,hi,poly=obstacles[index]
                        if lo<p[1]+8 and hi>p[1]+.1:self.fail(f'{key} blocked by {name} at {p}')

if __name__=='__main__':unittest.main()
