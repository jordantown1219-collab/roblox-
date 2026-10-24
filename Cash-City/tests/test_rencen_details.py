import copy
import json
import math
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from generate_rencen_details import generate, make_plan, IDS, ATRIUM_CANDIDATE, PODIUM, wall_footprint, overlapping_wall_indices, STRtree


class RenCenDetailTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.geography = json.loads((ROOT / "data/detroit_geography.json").read_text())
        cls.geometry = json.loads((ROOT / "data/geometry.json").read_text())
        cls.plan = generate()

    def test_saved_determinism_budget_and_preservation(self):
        before = copy.deepcopy(self.geometry)
        self.assertEqual(self.plan, generate())
        self.assertEqual(self.plan, json.loads((ROOT / "data/rencen_detail_plan.json").read_text()))
        self.assertEqual(self.geometry, before)
        self.assertEqual(len(self.plan["details"]), 304)
        self.assertLessEqual(len(self.plan["details"]), 420)
        self.assertEqual(len(self.plan["buildings"]), 9)
        self.assertEqual(len(self.plan["faces"]), 216)
        for face in self.plan["faces"]:
            self.assertEqual(face["record"], self.geometry[face["sourceIndex"]])

    def test_source_aligned_positive_gap_and_height_bounds(self):
        guards = {f["sourceIndex"]: f for f in self.plan["faces"]}
        names = set()
        for detail in self.plan["details"]:
            self.assertNotIn(detail["name"], names)
            names.add(detail["name"])
            self.assertIn(detail["osm"], IDS + (ATRIUM_CANDIDATE,))
            self.assertFalse(detail["collide"])
            self.assertTrue(all(math.isfinite(n) and n > 0 for n in detail["size"]))
            guard = guards[detail["sourceIndex"]]
            source = guard["record"]
            self.assertEqual(detail["matrix"], source["matrix"])
            n = guard["outwardNormalXYZ"]
            displacement = [detail["pos"][i] - source["pos"][i] for i in range(3)]
            projected = sum(displacement[i] * n[i] for i in range(3))
            self.assertAlmostEqual(projected - source["size"][0] / 2 - detail["size"][0] / 2, .1)
            self.assertLessEqual(detail["size"][2], source["size"][2])
            self.assertGreaterEqual(detail["pos"][1] - detail["size"][1] / 2, source["pos"][1] - source["size"][1] / 2)
            self.assertLessEqual(detail["pos"][1] + detail["size"][1] / 2, source["pos"][1] + source["size"][1] / 2)

    def test_missing_source_guard_refuses_generation(self):
        incomplete = [r for r in self.geometry if r["name"] != "Facade_30258238"]
        with self.assertRaises(AssertionError):
            make_plan(self.geography, incomplete)

    def test_every_detail_clears_all_source_walls_with_overlapping_height(self):
        walls = [r for r in self.geometry if r["name"].startswith("Facade_")]
        polygons = [wall_footprint(r) for r in walls]
        tree = STRtree(polygons)
        for detail in self.plan["details"]:
            self.assertEqual(overlapping_wall_indices(detail, walls, polygons, tree), [], detail["name"])
        adjustments = self.plan["neighborWallAdjustments"]
        self.assertEqual(sum(a["action"] == "omitted" for a in adjustments), 9)
        # Independent RED/GREEN reproduction of QA's concrete neighboring-wall regression.
        name = "RenCen_UpperReveal_419447171_06"
        fixed = next(r for r in self.plan["details"] if r["name"] == name)
        adjustment = next(r for r in adjustments if r["name"] == name)
        original = copy.deepcopy(fixed)
        original["size"][2] = adjustment["originalLengthStuds"]
        neighbor = self.geometry[15361]
        self.assertEqual(neighbor["name"], "Facade_419447171")
        self.assertGreater(wall_footprint(original).intersection(wall_footprint(neighbor)).area, .2)
        self.assertLess(wall_footprint(fixed).intersection(wall_footprint(neighbor)).area, 1e-8)

    def test_podium_finishes_are_exact_explicit_and_never_touch_roofs(self):
        finishes = self.plan["sourceFinishChanges"]
        self.assertEqual(len(finishes), 24)
        expected = {i for i, r in enumerate(self.geometry) if r["name"] == "Facade_" + str(PODIUM)}
        self.assertEqual({f["sourceIndex"] for f in finishes}, expected)
        guards = {f["sourceIndex"] for f in self.plan["faces"]}
        for finish in finishes:
            self.assertEqual(finish["record"], self.geometry[finish["sourceIndex"]])
            self.assertEqual(finish["record"]["material"], "Concrete")
            self.assertEqual(finish["material"], "Limestone")
            self.assertEqual(finish["color"], [190, 190, 179])
            self.assertIn(finish["sourceIndex"], guards)
            self.assertFalse(finish["record"]["name"].startswith("Roof_"))
        candidate = self.plan["atriumCandidate"]
        self.assertEqual(candidate["sourceFacadeCount"], 10)
        self.assertFalse(candidate["roofChanges"] or candidate["curvedRoofCreated"])
        entry = [d for d in self.plan["details"] if d["osm"] == ATRIUM_CANDIDATE]
        self.assertEqual(len(entry), 24)
        self.assertEqual(sum("Vertical" in d["name"] for d in entry), 6)
        self.assertTrue(all(d["material"] == "Metal" for d in entry))
        self.assertFalse(any(d["osm"] == PODIUM for d in self.plan["details"]))


if __name__ == "__main__":
    unittest.main()
