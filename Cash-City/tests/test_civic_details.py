from pathlib import Path
import json,sys,unittest
P=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(P/'tools'))
from generate_civic_details import make_plan

class CivicDetails(unittest.TestCase):
 def test_preserved_shells_and_reference_orientation(self):
  source=json.loads((P/'data/civic_facades.json').read_text())
  plan=make_plan(source)
  self.assertEqual(len(plan['faces']),12)
  self.assertLessEqual(len(plan['details']),450)
  self.assertEqual(plan,make_plan(source))
  original=[f['record'] for b in source['buildings'] for f in b['faces']]
  for actual,face in zip(original,plan['faces']):
   self.assertEqual(actual['pos'],face['pos']);self.assertEqual(actual['size'],face['size']);self.assertEqual(actual['matrix'],face['matrix'])
   if face['finish']=='west_blank_marble':self.assertEqual(face['material'],'Marble')
   if face['finish']=='east_brick':self.assertEqual(face['material'],'Brick')
  self.assertTrue(all(not d['collide'] for d in plan['details']))
  self.assertTrue(any(d['name']=='Civic_VerticalMarblePier' for d in plan['details']))
  self.assertTrue(any(d['name']=='Civic_AdminRibbon' for d in plan['details']))

if __name__=='__main__':unittest.main()
