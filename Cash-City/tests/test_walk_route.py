import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from generate_walk_route import generate, inputs, collision_model, shape, LineString, Point


class DetroitWalkRouteTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.loaded, cls.hashes = inputs()
        cls.route = generate()

    def test_saved_determinism_provenance_and_bounded_waypoints(self):
        self.assertEqual(self.route, json.loads((ROOT / "data/detroit_walk_route.json").read_text()))
        self.assertEqual(self.route["sourceHashes"], self.hashes)
        self.assertLessEqual(len(self.route["waypoints"]), 8)
        self.assertLessEqual(self.route["lengthMeters"], 150)
        self.assertLessEqual(self.route["lengthStuds"], 150 / .28)
        self.assertGreater(self.route["amberSpawnDirectDistanceToTrialMeters"], 150)
        self.assertIn("pending", self.route["status"])

    def test_full_body_clearance_land_plaza_roads_buildings_and_static_geometry(self):
        route = self.route
        line = LineString(route["segmentMetersXZ"])
        corridor = line.buffer(route["fullBodyRadiusMeters"])
        walkable, buildings, roads, colliders = collision_model(self.loaded)
        self.assertTrue(walkable.covers(corridor))
        self.assertFalse(corridor.intersects(buildings))
        self.assertFalse(corridor.intersects(roads))
        self.assertFalse(corridor.intersects(colliders))
        land = shape(self.loaded["detroit_geography.json"]["land"])
        water = shape(self.loaded["detroit_geography.json"]["water"])
        self.assertTrue(land.covers(corridor))
        self.assertFalse(corridor.intersects(water))
        # Negative control: the same full-body probe through a real building is rejected.
        building_center = buildings.representative_point()
        self.assertFalse(walkable.covers(building_center.buffer(route["fullBodyRadiusMeters"])))

    def test_actual_source_start_and_destination_units(self):
        route = self.route
        source = next(f for f in self.loaded["detroit_geography.json"]["features"] if f["osm"] == route["start"]["osm"])
        self.assertEqual(source["kind"], "path")
        self.assertFalse(source["steps"])
        self.assertEqual(source["elevation"], 0)
        first = route["waypoints"][0]
        self.assertLess(shape(source["geometry"]).distance(Point(first["metersXZ"])), 1e-7)
        line = LineString(route["segmentMetersXZ"])
        for waypoint in route["waypoints"]:
            self.assertLess(line.distance(Point(waypoint["metersXZ"])), 1e-7)
            x, z = waypoint["metersXZ"]
            sx, sy, sz = waypoint["surfaceStudsXYZ"]
            self.assertAlmostEqual(sx, x * route["studsPerMeter"])
            self.assertAlmostEqual(sz, z * route["studsPerMeter"])
            self.assertEqual(sy, .35)
        trial = self.loaded["playable_block.json"]["firstMapSlice"]
        self.assertEqual(route["waypoints"][-2]["metersXZ"], trial["segmentMetersXZ"][0])
        self.assertEqual(route["waypoints"][-1]["metersXZ"], trial["segmentMetersXZ"][-1])


if __name__ == "__main__":
    unittest.main()
