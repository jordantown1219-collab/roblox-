from pathlib import Path
import copy
import hashlib
import json
import math
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from generate_rencen_walk import make_plan


class RenCenWalk(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.inputs=[json.loads((ROOT/'data'/name).read_text()) for name in ['detroit_geography.json','geometry.json','detail_preview.json']]
        cls.plan=make_plan(*cls.inputs)

    def test_deterministic_bounded_without_source_mutation(self):
        before=json.dumps(self.inputs,sort_keys=True)
        self.assertEqual(self.plan,make_plan(*self.inputs))
        self.assertEqual(before,json.dumps(self.inputs,sort_keys=True))
        self.assertEqual(len(self.plan['records']),81)
        self.assertEqual(self.plan['lengthMeters'],80)
        self.assertGreater(self.plan['clearancesMeters']['shoreline'],3.7)
        self.assertTrue(all(value>0 for value in self.plan['clearancesMeters'].values()))

    def test_continuous_collision_and_panel_bounds(self):
        floor,*panels=self.plan['records']
        self.assertTrue(floor['collide'])
        self.assertEqual(floor['trans'],1)
        top=floor['pos'][1]+floor['size'][1]/2
        self.assertAlmostEqual(top,.41)
        for panel in panels:
            self.assertFalse(panel['collide'])
            self.assertEqual(panel['material'],'Concrete')
            self.assertAlmostEqual(panel['pos'][1]+panel['size'][1]/2,top)
            delta=[panel['pos'][i]-floor['pos'][i] for i in (0,2)]
            matrix=floor['matrix']
            for axis,first,second in [(0,0,6),(2,2,8)]:
                local=delta[0]*matrix[first]+delta[1]*matrix[second]
                self.assertLessEqual(abs(local)+panel['size'][axis]/2,floor['size'][axis]/2+1e-6)
        self.assertEqual(sum(r['collide'] for r in self.plan['records']),1)

    def test_reject_source_path_change(self):
        geography=copy.deepcopy(self.inputs[0])
        path=next(f for f in geography['features'] if f['osm']==69706033)
        path['steps']=True
        with self.assertRaises(AssertionError): make_plan(geography,*self.inputs[1:])

    def test_saved_plan_matches_and_sources_unchanged(self):
        saved=json.loads((ROOT/'data/rencen_walk_plan.json').read_text())
        hashes=saved.pop('sourceHashes')
        self.assertEqual(saved,self.plan)
        for name,digest in hashes.items(): self.assertEqual(hashlib.sha256((ROOT/'data'/name).read_bytes()).hexdigest(),digest)

    def test_extension_keeps_completed_walk_and_reproduces_furnishings(self):
        from generate_riverwalk_extension import generate
        before=hashlib.sha256((ROOT/'data/rencen_walk_plan.json').read_bytes()).hexdigest()
        plan=generate()
        self.assertEqual(plan,generate())
        self.assertEqual(plan['lengthMeters'],40)
        self.assertEqual(plan['bayCount'],2)
        self.assertEqual(sum(bool(r.get('seat')) for r in plan['records']),4)
        self.assertEqual(sum(bool(r.get('lamp')) for r in plan['records']),2)
        self.assertLess(len(plan['records']),150)
        self.assertEqual(before,hashlib.sha256((ROOT/'data/rencen_walk_plan.json').read_bytes()).hexdigest())
        old=json.loads((ROOT/'data/rencen_walk_plan.json').read_text())
        expected=[old['segmentMetersXZ'][-1][0]*old['studsPerMeter'],.41,old['segmentMetersXZ'][-1][1]*old['studsPerMeter']]
        for a,b in zip(plan['routeSamples'][0]['pos'],expected):self.assertAlmostEqual(a,b)

    def test_second_section_connects_and_preserves_first(self):
        from generate_riverwalk_extension import generate
        path=ROOT/'src/RiverWalkExtension.lua'
        before=hashlib.sha256(path.read_bytes()).hexdigest()
        first=generate();second=generate(section=2)
        self.assertEqual(first['routeSamples'][-1]['pos'],second['routeSamples'][0]['pos'])
        self.assertNotEqual(first['id'],second['id'])
        self.assertEqual(second['id'],'RenCenRiverWalkExtension2')
        self.assertEqual(second['lengthMeters'],40)
        self.assertEqual(sum(bool(r.get('seat')) for r in second['records']),4)
        self.assertEqual(before,hashlib.sha256(path.read_bytes()).hexdigest())


if __name__=='__main__': unittest.main()
