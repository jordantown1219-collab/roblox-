import hashlib
import json
import math
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from inspect_playable_block import analyze, civic_facades, load_sources, shape, LineString, Point, unary_union


class PlayableBlockTests(unittest.TestCase):
    def test_map1_boundary_contains_existing_gameplay_and_rejects_exits(self):
        from lupa import LuaRuntime
        lua=LuaRuntime()
        boundary=lua.execute((ROOT/'src/Map1Boundary.lua').read_text())
        lua.execute('Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}')
        config=lua.execute((ROOT/'src/CityConfig.lua').read_text())
        for category in ('Spawns','Transit','Exits'):
            for _,position in config[category].items():self.assertTrue(boundary.contains(position),category)
        for _,spots in config['Sockets'].items():
            for _,position in spots.items():self.assertTrue(boundary.contains(position),'Gate outside enclosure')
        park=shape(next(f for f in self.geography['features'] if f.get('osm')==69349404)['geometry'])
        scale=self.geography['studsPerMeter']
        x0,z0,x1,z1=park.bounds
        for x in (x0,x1):
            for z in (z0,z1):self.assertTrue(boundary.contains(lua.table_from({'X':x*scale,'Y':5,'Z':z*scale})),'Hart Plaza cropped')
        completed=json.loads((ROOT/'data/rencen_detail_plan.json').read_text())
        for face in completed['faces']:
            r=face['record'];m=r['matrix'];p=r['pos'];size=r['size']
            for x in (-.5,.5):
                for z in (-.5,.5):
                    self.assertTrue(boundary.contains(lua.table_from({'X':p[0]+m[0]*size[0]*x+m[2]*size[2]*z,'Y':5,'Z':p[2]+m[6]*size[0]*x+m[8]*size[2]*z})),'Completed RenCen face cropped')
        b=boundary.limits
        center={'X':(b.minX+b.maxX)/2,'Y':5,'Z':(b.minZ+b.maxZ)/2}
        for key,value in [('X',b.minX-1),('X',b.maxX+1),('Z',b.minZ-1),('Z',b.maxZ+1),('Y',b.resetY-1),('Y',b.floorY+3),('Y',b.ceilingY+1)]:
            p=dict(center);p[key]=value
            self.assertFalse(boundary.contains(lua.table_from(p)))

    @classmethod
    def setUpClass(cls):
        cls.geography, cls.geometry, cls.hashes = load_sources()
        cls.plan = analyze()

    def test_saved_plan_determinism_datum_and_provenance(self):
        self.assertEqual(self.plan, json.loads((ROOT / "data/playable_block.json").read_text()))
        self.assertEqual(self.plan["sourceHashes"], self.hashes)
        self.assertEqual(self.plan["mapOriginLatLon"], [42.329, -83.04])
        self.assertAlmostEqual(self.plan["studsPerMeter"], 1 / .28)
        self.assertEqual(self.plan["groundDatum"], self.geography["groundDatum"])
        for landmark in self.plan["landmarks"]:
            source = next(f for f in self.geography["features"] if f["osm"] == landmark["osm"])
            self.assertEqual(landmark["footprintMeters"], source["geometry"])
            self.assertEqual(landmark["sourceHeightMeters"], source.get("height"))

    def test_route_is_source_derived_clear_land_corridor(self):
        route = self.plan["firstMapSlice"]
        line = LineString(route["segmentMetersXZ"])
        corridor = line.buffer(route["reviewHalfWidthMeters"], cap_style=2)
        source = next(f for f in self.geography["features"] if f["osm"] == route["pathOsm"])
        self.assertEqual(source["kind"], "path")
        self.assertFalse(source["steps"])
        self.assertAlmostEqual(line.length, 12)
        self.assertLess(line.difference(shape(source["geometry"]).buffer(1e-7)).length, 1e-7)
        self.assertTrue(shape(self.geography["land"]).covers(corridor))
        plaza = next(f for f in self.geography["features"] if f["osm"] == 69349404)
        self.assertTrue(shape(plaza["geometry"]).covers(corridor))
        for feature in self.geography["features"]:
            if feature["kind"] == "building":
                self.assertFalse(corridor.intersects(shape(feature["geometry"])))
            if feature["kind"] == "road" and feature["elevation"] == 0:
                self.assertFalse(corridor.intersects(shape(feature["geometry"]).buffer(feature["width"] / 2, cap_style=2)))
        self.assertGreater(route["gameplayAnchorClearanceMeters"], 5)
        for anchor, coordinate in zip(route["anchorsStudsXYZ"], (line.coords[0], line.coords[-1])):
            self.assertAlmostEqual(anchor[0], coordinate[0] * self.plan["studsPerMeter"])
            self.assertAlmostEqual(anchor[2], coordinate[1] * self.plan["studsPerMeter"])

    def test_secondary_fit_is_not_false_placement_acceptance(self):
        candidate = self.plan["secondaryFootprint"]
        self.assertTrue(shape(candidate["sourceFeature"]["geometry"]).covers(shape(candidate["outerRoofFootprintMeters"])))
        self.assertTrue(candidate["fitsSourceFootprint"])
        self.assertIn("rejected", candidate["status"])
        self.assertEqual(candidate["roadClearanceMeters"], 0)
        self.assertTrue(candidate["existingShellRetained"])
        config = candidate["templateConfig"]
        self.assertTrue(24 <= config["width"] <= 80 and 16 <= config["depth"] <= 80 and 12 <= config["height"] <= 24)
        cf = candidate["cframeComponents"]
        self.assertAlmostEqual(cf[3] * cf[11] - cf[5] * cf[9], 1)

    def test_civic_faces_preserve_exact_records_and_outward_normals(self):
        civic = civic_facades()
        self.assertEqual(civic, json.loads((ROOT / "data/civic_facades.json").read_text()))
        self.assertEqual([len(b["faces"]) for b in civic["buildings"]], [4, 8])
        for building in civic["buildings"]:
            polygon = shape(building["sourceFeature"]["geometry"])
            for face in building["faces"]:
                self.assertEqual(face["record"], self.geometry[face["sourceIndex"]])
                nx, _, nz = face["outwardNormalXYZ"]
                self.assertAlmostEqual(math.hypot(nx, nz), 1)
                # Existing generator simplifies facade footprints by .35m; retain that
                # measured mismatch instead of pretending generated centers lie exactly on source.
                self.assertLess(face["edgeDistanceMeters"], .35)
                a, b = face["matchedSourceEdgeMetersXZ"]
                midpoint = Point((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
                self.assertFalse(polygon.covers(Point(midpoint.x + nx * .01, midpoint.y + nz * .01)))
                self.assertTrue(polygon.covers(Point(midpoint.x - nx * .01, midpoint.y - nz * .01)))


if __name__ == "__main__":
    unittest.main()
