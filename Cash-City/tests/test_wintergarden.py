import json
import math
from pathlib import Path
import sys
import unittest
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from generate_wintergarden import generate, shape, Polygon, Point, LineString
from shapely.ops import unary_union
from shapely.geometry import MultiPoint

def room_obstacle(record):
    if not record.get('collide',True):return None
    m,p,s=record['matrix'],record['pos'],record['size']
    points=[]
    for x in (-.5,.5):
        for y in (-.5,.5):
            for z in (-.5,.5):
                v=[x*s[0],y*s[1],z*s[2]]
                points.append([p[i]+sum(m[i*3+j]*v[j] for j in range(3)) for i in range(3)])
    if max(v[1] for v in points)<=.85 or min(v[1] for v in points)>=10.35-1e-7:return None
    return MultiPoint([(v[0],v[2]) for v in points]).convex_hull


class WintergardenTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.plan=generate()
        cls.source=json.loads((ROOT/'data/geometry.json').read_text())

    def test_deterministic_exact_source_guards_and_bounded_original_records(self):
        p=self.plan
        self.assertEqual(p,json.loads((ROOT/'data/wintergarden_plan.json').read_text()))
        self.assertEqual(len(p['records']),194)
        self.assertLessEqual(len(p['records'])+8,220)
        self.assertEqual(len(p['replacements']),46)
        counts={}
        for guard in p['replacements']:
            self.assertEqual(guard['record'],self.source[guard['sourceIndex']])
            name=guard['record']['name'];counts[name]=counts.get(name,0)+1
        self.assertEqual(counts,{'Facade_419447156':10,'FacadeMullion':20,'Roof_419447156':16})
        for record in p['records']:
            self.assertTrue(all(math.isfinite(n) and 0<n<=2048 for n in record['size']))
            self.assertIn(record['cls'],('Part','WedgePart'))
            m=record['matrix'];columns=[[m[i],m[i+3],m[i+6]] for i in range(3)]
            for i,a in enumerate(columns):
                for j,b in enumerate(columns): self.assertAlmostEqual(sum(a[k]*b[k] for k in range(3)),1 if i==j else 0)

    def test_roof_fits_source_outline_below_existing_height_and_covers_floor(self):
        p=self.plan;footprint=shape(p['metadata']['roofFootprintStuds']);source=shape(p['metadata']['sourceFootprintStuds'])
        self.assertTrue(source.covers(footprint))
        triangles=[]
        for record in p['records']:
            if record['name']!='Wintergarden_CurvedGlassRoof':continue
            vertices=record['meta']['surfaceTriangleVertices']
            triangle=Polygon([(v[0],v[2]) for v in vertices])
            self.assertLess(triangle.difference(source).area,1e-6)
            self.assertLessEqual(max(v[1] for v in vertices)+record['size'][0]/2, p['metadata']['sourceTopStuds'])
            self.assertEqual(record['material'],'Glass')
            triangles.append(triangle)
        covered=unary_union(triangles)
        self.assertLess(footprint.symmetric_difference(covered).area,1e-6)
        floors=unary_union([Polygon([(v[0],v[2]) for v in r['meta']['surfaceTriangleVertices']]) for r in p['records'] if r['name']=='Wintergarden_Floor'])
        self.assertLess(footprint.symmetric_difference(floors).area,1e-6)

    def test_real_aperture_body_corridor_and_retained_geometry_clearance(self):
        p=self.plan;door=p['doorAnchors'][0]
        self.assertEqual((door['apertureWidth'],door['height']),(8,10))
        self.assertEqual(len(door['matrix']),9)
        footprint=shape(p['metadata']['roofFootprintStuds'])
        removed={r['sourceIndex'] for r in p['replacements']}
        # Conservative oriented bounding footprints are sufficient for standing-height walls.
        obstacles=[]
        for record in p['records']+[r for i,r in enumerate(self.source) if i not in removed]:
            polygon=room_obstacle(record)
            if polygon is not None:obstacles.append(polygon)
        union=unary_union(obstacles)
        approach=LineString([(v[0],v[2]) for v in door['approachPoints']])
        self.assertFalse(approach.buffer(2.3).intersects(union),'Entrance corridor obstructed')
        for sample in p['routeSamples']:
            point=Point(sample['pos'][0],sample['pos'][2]);body=point.buffer(sample['width']/2)
            self.assertTrue(footprint.covers(body))
            self.assertFalse(body.intersects(union),'Standing interior sample obstructed')
            self.assertEqual(sample['floorY'],.35)
            self.assertGreaterEqual(sample['clearHeight'],10)

    def test_decorative_roof_ribs_spine_and_planters_preserve_room(self):
        p=self.plan;outline=shape(p['metadata']['sourceFootprintStuds'])
        decorative=[r for r in p['records'] if 'Decorative' in r['name']]
        self.assertTrue(any('PaleYellowRoofRib' in r['name'] for r in decorative))
        self.assertEqual(sum('SilverInlandSpine' in r['name'] for r in decorative),1)
        self.assertEqual(sum('RoofGlazingBar' in r['name'] for r in decorative),7)
        self.assertEqual(p['metadata']['decorativePlanters'],2)
        for r in decorative:
            self.assertFalse(r['collide'])
            m,s,c=r['matrix'],r['size'],r['pos']
            for x in (-.5,.5):
                for y in (-.5,.5):
                    for z in (-.5,.5):
                        v=[x*s[0],y*s[1],z*s[2]]
                        world=[c[i]+sum(m[i*3+j]*v[j] for j in range(3)) for i in range(3)]
                        self.assertTrue(outline.covers(Point(world[0],world[2])))
                        self.assertLessEqual(world[1],p['metadata']['sourceTopStuds'])
            if 'Planter' in r['name']:
                for sample in p['routeSamples']:
                    self.assertGreater(math.hypot(c[0]-sample['pos'][0],c[2]-sample['pos'][2]),9)


if __name__=='__main__':unittest.main()
