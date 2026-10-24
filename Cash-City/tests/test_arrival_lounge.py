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

 def test_saved_sign_has_two_readable_faces(self):
  import xml.etree.ElementTree as ET
  root=ET.parse(P/'SmallSignals_DetroitRiverfront_v0_14.rbxlx')
  signs=[n for n in root.iter('Item') if n.find("Properties/string[@name='Name']") is not None and n.find("Properties/string[@name='Name']").text=='GenericAtriumSign']
  self.assertEqual(len(signs),1)
  surfaces=[n for n in signs[0].findall('Item') if n.get('class')=='SurfaceGui']
  self.assertEqual({int(n.find("Properties/token[@name='Face']").text) for n in surfaces},{2,5})
  for surface in surfaces:
   label=surface.find("Item[@class='TextLabel']")
   self.assertEqual(label.find("Properties/string[@name='Text']").text,'RIVERFRONT ATRIUM')

 def test_finish_parts_stay_inside_reviewed_furniture_zones(self):
  import math
  records=json.loads((P/'data/arrival_lounge_preview.json').read_text())
  anchors=json.loads((P/'data/arrival_lounge.json').read_text())['seats']
  self.assertEqual(len(records),23)
  self.assertEqual(sum(r['name']=='OriginalIndoorFoliage' for r in records),6)
  for r in records:
   self.assertTrue(any(math.hypot(r['pos'][0]-a['pos'][0],r['pos'][2]-a['pos'][2])+math.hypot(r['size'][0],r['size'][2])/2<9 for a in anchors))
  self.assertTrue(all(not r['collide'] for r in records if r['name'] in ['OriginalIndoorFoliage','ArrivalLightDiffuser','PlanterSoil']))
  self.assertTrue(all(r['material']=='WoodPlanks' for r in records if r['name']=='BenchBack'))
