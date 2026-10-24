from pathlib import Path
import json,sys,math,unittest
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from generate_hart_path import make_plan

class HartPath(unittest.TestCase):
 def test_clearance_bounded_and_continuous(self):
  site=json.loads((ROOT/'data/playable_block.json').read_text())
  plan=make_plan(site)
  self.assertEqual(plan,make_plan(site));self.assertEqual(len(plan['records']),33)
  floor=plan['records'][0];self.assertTrue(floor['collide']);self.assertEqual(floor['trans'],1)
  top=floor['pos'][1]+floor['size'][1]/2
  self.assertAlmostEqual(top,site['firstMapSlice']['currentRenderedPathTopStuds']+.06)
  for panel in plan['records'][1:]:
   self.assertFalse(panel['collide']);self.assertEqual(panel['material'],'Granite')
   self.assertAlmostEqual(panel['pos'][1]+panel['size'][1]/2,top)
   delta=[panel['pos'][i]-floor['pos'][i] for i in [0,2]];m=floor['matrix']
   x=delta[0]*m[0]+delta[1]*m[6];z=delta[0]*m[2]+delta[1]*m[8]
   self.assertLessEqual(abs(x)+panel['size'][0]/2,floor['size'][0]/2)
   self.assertLessEqual(abs(z)+panel['size'][2]/2,floor['size'][2]/2)

if __name__=='__main__':unittest.main()
