from pathlib import Path
import sys,os,json,math,xml.etree.ElementTree as ET,unittest
P=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(Path(os.environ['TEMP'])/'smallsignals-test-deps'))
from shapely.geometry import shape,Point
from lupa import LuaRuntime
class BuildAcceptance(unittest.TestCase):
 def test_lua_sources(self):
  lua=LuaRuntime()
  for f in (P/'src').glob('*.lua'):lua.execute('assert(load(...))',f.read_text(encoding='utf-8-sig'))
 def test_anchor_ground(self):
  g=json.loads((P/'data/detroit_geography.json').read_text(encoding='utf-8'));land=shape(g['land']);buildings=[shape(f['geometry']) for f in g['features'] if f['kind']=='building' and f['base']==0]
  for team,d in g['gameplay'].items():
   for v in [d['spawn'],d['exit'],d['transit'],[d['transit'][0],d['transit'][1]+4*.28]]+d['sockets']:
    point=Point(v);self.assertTrue(land.buffer(-1).contains(point),(team,v))
    self.assertFalse(any(b.buffer(1).contains(point) for b in buildings),(team,v))
 def test_geometry_frames(self):
  geo=json.loads((P/'data/geometry.json').read_text(encoding='utf-8'))
  self.assertLess(len(geo),20000,'Prototype part budget exceeded')
  for b in geo:
   self.assertTrue(all(math.isfinite(x) and .001<x<=2048 for x in b['size']))
   m=b['matrix']
   cols=[[m[c],m[c+3],m[c+6]] for c in range(3)]
   for i in range(3):
    for j in range(3):self.assertAlmostEqual(sum(a*b for a,b in zip(cols[i],cols[j])),1 if i==j else 0,5)
 def test_embedding(self):
  root=ET.parse(P/'SmallSignals_DetroitRiverfront_v0_14.rbxlx').getroot()
  mapping={'HartPathData':'HartPathData.lua','CivicFacadeData':'CivicFacadeData.lua','CivicFacades':'CivicFacades.lua','StorefrontInterior':'StorefrontInterior.lua','BuildingInteractions':'BuildingInteractions.lua','BuildingTemplates':'BuildingTemplates.lua','CityBlockGenerator':'CityBlockGenerator.lua','WorldLoading':'WorldLoading.lua','WeaponVisuals':'WeaponVisuals.lua','RiverfrontVehicles':'RiverfrontVehicles.lua','CityDetails':'CityDetails.lua','VehicleClient':'VehicleClient.client.lua','Arena':'Arena.lua','LegacyArena':'LegacyArena.lua','CityConfig':'CityConfig.lua','InteractionRegistry':'InteractionRegistry.lua','InteractionWorkshop':'InteractionWorkshop.lua','InteractionRules':'InteractionRules.lua','SmallSignalsServer':'SmallSignalsServer.server.lua','SmallSignalsClient':'SmallSignalsClient.client.lua','SmallSignalsHUD':'SmallSignalsHUD.lua','SmallSignalsSettings':'SmallSignalsSettings.lua','RiverfrontClient':'RiverfrontClient.client.lua','Config':'Config.lua','Rules':'Rules.lua'}
  mapping.update(RenaissanceDetails='RenaissanceDetails.lua',RenaissanceData='RenaissanceData.lua')
  mapping.update(Wintergarden='Wintergarden.lua',WintergardenData='WintergardenData.lua')
  mapping.update(ArrivalLounge='ArrivalLounge.lua',ArrivalLoungeData='ArrivalLoungeData.lua')
  found=set();refs=[]
  for n in root.iter('Item'):
   refs.append(n.get('referent'))
   props=n.find('Properties');name=props.findtext("string[@name='Name']") if props is not None else None
   if name in mapping and n.get('class') in ('ModuleScript','Script','LocalScript'):
    self.assertEqual(props.findtext("ProtectedString[@name='Source']"),(P/'src'/mapping[name]).read_text(encoding='utf-8-sig'));found.add(name)
  self.assertEqual(found,set(mapping));self.assertEqual(len(refs),len(set(refs)))
if __name__=='__main__':unittest.main()
