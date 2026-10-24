import sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from citygeo import project,inverse,height_info,sector_key
class Geography(unittest.TestCase):
 def test_origin(self): self.assertEqual(project(42.329,-83.040), (0.0,0.0))
 def test_east_north(self):
  x,z=project(42.330,-83.039);self.assertGreater(x,0);self.assertLess(z,0)
 def test_round_trip(self):
  for lat,lon in [(42.328,-83.046),(42.330,-83.039)]:
   a,b=inverse(*project(lat,lon));self.assertAlmostEqual(a,lat,8);self.assertAlmostEqual(b,lon,8)
 def test_tower_measurement(self):
  self.assertEqual(height_info({'name':'Renaissance Center Tower 100'})[0],155.0)
 def test_estimate_is_labeled(self): self.assertIn('estimate',height_info({'building':'yes'})[1])
 def test_known_osm_height(self): self.assertEqual(height_info({'height':'42'})[0],42.0)
 def test_sector_stable(self): self.assertEqual(sector_key(10,20),'0_0')
if __name__=='__main__':unittest.main()
