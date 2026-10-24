import unittest,sys,json
from pathlib import Path
P=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(P/'tools'))
from generate_arrival_lounge import generate
class ArrivalLounge(unittest.TestCase):
 def test_saved_positions_reproduce_and_preserve_route(self):
  data=generate()
  self.assertEqual(data,json.loads((P/'data/arrival_lounge.json').read_text()))
  self.assertEqual(len(data['seats']),2)
  self.assertGreaterEqual(data['routeClearanceStuds'],15)
 def test_native_export_has_functional_static_seats_and_bounded_lights(self):
  records=json.loads((P/'data/arrival_lounge_preview.json').read_text())
  seats=[r for r in records if r['cls']=='Seat']
  self.assertEqual(len(seats),4)
  self.assertTrue(all(r['collide'] and r['touch'] for r in seats))
  self.assertEqual(sum('light' in r for r in records),2)
  self.assertTrue(all(r.get('light',{}).get('brightness',0)<=.600001 for r in records))
