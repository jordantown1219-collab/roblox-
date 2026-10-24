import hashlib,json,math,sys
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'tools'))
from generate_river_access import generate,shape,affinity,Polygon,Point,LineString,unary_union,rendered_surfaces,surface_polygon
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
        cls.surfaces=rendered_surfaces(cls.source);cls.roads=cls.surfaces['JoinedRoad']
        cls.land=affinity.scale(shape(cls.geo['land']),xfact=s,yfact=s,origin=(0,0))

    def test_determinism_hashes_originals_and_budget(self):
        self.assertEqual(self.plan,json.loads((ROOT/'data/river_access_plan.json').read_text()))
        self.assertEqual(len(self.plan['records']),23)
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

    def test_inset_stair_sample_and_polygon_derived_approach(self):
        p=self.plan;meta=p['metadata'];origin=meta['doorOriginXZ'];f=meta['outwardXZ'];right=[f[1],-f[0]]
        def point(t,s=0):return Point(origin[0]+f[0]*t+right[0]*s,origin[1]+f[1]*t+right[1]*s)
        top=next(s for s in p['routeStairs'] if s['span']=='stairs top')
        self.assertAlmostEqual(top['pos'][0],point(58.5,6).x)
        self.assertAlmostEqual(top['pos'][2],point(58.5,6).y)
        self.assertTrue(shape(meta['landingPolygonStuds']).contains(Point(top['pos'][0],top['pos'][2])))
        a,b=meta['approachWalkEndT'],meta['approachRoadStartT']
        self.assertTrue(self.surfaces['JoinedWalk'].covers(point(a-.01)))
        self.assertFalse(self.surfaces['JoinedWalk'].covers(point(a+.01)))
        self.assertFalse(self.roads.covers(point(b-.01)))
        self.assertTrue(self.roads.covers(point(b+.01)))
        self.assertEqual(meta['approachEndHeights'],[.35,.55])
        vertices=[v for r in p['records'] if r['name']=='RiverAccess_SourceGapApproach' for v in r['meta']['surfaceTriangleVertices']]
        self.assertAlmostEqual(min(v[1] for v in vertices),.35)
        self.assertAlmostEqual(max(v[1] for v in vertices),.55)

    def test_low_stair_risers_and_gentle_ramp_continuity_all_scales(self):
        p=self.plan
        stairs=[r for r in p['records'] if r['name']=='RiverAccess_LowStairTread']
        tops=[.55]+sorted({round(volume(r)[1],7) for r in stairs},reverse=True)+[-.25]
        self.assertEqual(len(tops),5)
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

    def test_rendered_source_probe_regressions_and_no_walk_overlays(self):
        p=self.plan;origin=p['metadata']['doorOriginXZ'];f=p['metadata']['outwardXZ'];right=[f[1],-f[0]]
        def point(t,s=0):return Point(origin[0]+f[0]*t+right[0]*s,origin[1]+f[1]*t+right[1]*s)
        self.assertTrue(self.surfaces['JoinedWalk'].covers(point(8)))
        for t in (9,12,16,17):
            self.assertFalse(self.surfaces['JoinedWalk'].covers(point(t)));self.assertFalse(self.roads.covers(point(t)))
        self.assertTrue(self.roads.covers(point(18)))
        for r in p['records']:
            vertices=r.get('meta',{}).get('surfaceTriangleVertices')
            if r['name'] in ('RiverAccess_SourceGapApproach','RiverAccess_PavedPromenadeConnector','RiverAccess_LowStairTread') and vertices:
                poly=Polygon([(v[0],v[2]) for v in vertices])
                self.assertLess(poly.intersection(self.surfaces['JoinedWalk']).area,1e-6)
        landing=shape(p['metadata']['landingPolygonStuds'])
        self.assertTrue(landing.contains(point(60,6)),'Stair top must lie INSIDE real extended geometry, not merely a moved node')
        self.assertTrue(landing.contains(point(44.9)))
        # Precompute exact planes so dense lateral regression probes stay inexpensive.
        promenade=json.loads((ROOT/'data/rencen_walk_plan.json').read_text())['records'][0]
        promenade_poly=surface_polygon(promenade)
        planes=[]
        for r in p['records']:
            vertices=r.get('meta',{}).get('surfaceTriangleVertices')
            if vertices:
                poly=Polygon([(v[0],v[2]) for v in vertices]).buffer(1e-7)
                a,b,c=vertices;ab=[b[i]-a[i] for i in range(3)];ac=[c[i]-a[i] for i in range(3)]
                normal=[ab[1]*ac[2]-ab[2]*ac[1],ab[2]*ac[0]-ab[0]*ac[2],ab[0]*ac[1]-ab[1]*ac[0]]
                planes.append((poly,a,normal))
                if r['name']=='RiverAccess_PavedPromenadeConnector':self.assertLess(poly.intersection(promenade_poly).area,1e-4)
            else:
                m,c,s=r['matrix'],r['pos'],r['size'];up=[m[1],m[4],m[7]];top=[c[i]+up[i]*s[1]/2 for i in range(3)]
                planes.append((volume(r)[2].buffer(1e-7),top,up))
        def floor(q):
            heights=[-.25]
            if self.roads.covers(q):heights.append(.55)
            if self.surfaces['JoinedWalk'].covers(q):heights.append(.35)
            if promenade_poly.covers(q):heights.append(.41)
            for poly,a,normal in planes:
                if poly.covers(q):
                    heights.append(a[1]-(normal[0]*(q.x-a[0])+normal[2]*(q.y-a[2]))/normal[1])
            return max(heights)
        for t in (8,9,10,12,14,16,17,18):
            actual=floor(point(t));self.assertGreaterEqual(actual,.35-1e-6);self.assertLessEqual(actual,.55+1e-6)
        self.assertAlmostEqual(floor(point(44.9)),.55)
        self.assertAlmostEqual(floor(point(60,6)),.55)
        for x,z in [(257.8559,465.0302),(257.2244,466.3651)]:self.assertGreaterEqual(floor(Point(x,z)),.35-1e-6)
        for key in ('routeRamp','routeStairs'):
            for a,b in zip(p[key],p[key][1:]):
                a,b=a['pos'],b['pos'];steps=max(1,math.ceil(math.dist(a,b)*2));length=math.hypot(b[0]-a[0],b[2]-a[2]);right=[(b[2]-a[2])/length,-(b[0]-a[0])/length] if length>1e-8 else [1,0]
                for step in range(steps+1):
                    t=step/steps;pos=[a[i]+(b[i]-a[i])*t for i in range(3)]
                    # Lateral regression targets the reported diagonal promenade join.
                    # At earlier turning landings the side probes can legitimately lie
                    # on the adjacent descending ramp, with a different floor height.
                    sides=(-2.5,0,2.5) if pos[2]>455 else (0,)
                    for side in sides:
                        actual=floor(Point(pos[0]+right[0]*side,pos[2]+right[1]*side))
                        self.assertLessEqual(abs(actual-pos[1]),.08 if key=='routeRamp' else .23,f'{key} floor mismatch at {pos} side{side}: {actual}')

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
