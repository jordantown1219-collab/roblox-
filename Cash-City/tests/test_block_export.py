import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from export_city_blocks import export_blocks, make_blocks, serialize


class BlockExportTests(unittest.TestCase):
    def setUp(self):
        self.records = json.loads((ROOT / "data/geometry.json").read_text(encoding="utf-8"))

    def test_real_geometry_lossless_roundtrip_and_contract(self):
        blocks = make_blocks(self.records)
        restored = [None] * len(self.records)
        self.assertEqual(len(blocks), 30)
        for sector, block in blocks.items():
            decoded = json.loads(serialize(block))
            self.assertEqual(decoded["id"], "Sector_" + sector)
            for index, record in zip(decoded["sourceIndices"], decoded["records"]):
                self.assertIsNone(restored[index])
                restored[index] = record
                self.assertIn(record["cls"], ("Part", "WedgePart"))
                self.assertEqual(len(record["pos"]), 3)
                self.assertEqual(len(record["matrix"]), 9)
                self.assertTrue(all(0 < n <= 2048 for n in record["size"]))
        self.assertEqual(restored, self.records)

    def test_determinism_unchanged_skip_and_selective_export(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            source = folder / "geometry.json"
            source.write_text(json.dumps(self.records), encoding="utf-8")
            output = folder / "blocks"
            first = export_blocks(source, output)
            before = {p.name: (p.read_bytes(), p.stat().st_mtime_ns) for p in output.iterdir()}
            second = export_blocks(source, output)
            self.assertEqual(first["sha256"], second["sha256"])
            self.assertEqual(second["written"], [])
            self.assertEqual(len(second["unchanged"]), 30)
            changed = copy.deepcopy(self.records)
            changed[0]["meta"]["exportTest"] = "preserved"
            source.write_text(json.dumps(changed), encoding="utf-8")
            chosen = changed[0]["sector"]
            third = export_blocks(source, output, [chosen])
            self.assertEqual(third["written"], [chosen])
            for path in output.iterdir():
                if path.name != "Sector_" + chosen + ".json":
                    self.assertEqual((path.read_bytes(), path.stat().st_mtime_ns), before[path.name])
            self.assertEqual(json.loads(source.read_text()), changed)

    def test_invalid_selection_and_unsafe_sector_write_nothing(self):
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / "geometry.json"
            source.write_text(json.dumps(self.records), encoding="utf-8")
            output = Path(temporary) / "blocks"
            with self.assertRaises(ValueError):
                export_blocks(source, output, ["999_999"])
            self.assertFalse(output.exists())
            invalid = copy.deepcopy(self.records[:1])
            invalid[0]["sector"] = "../escape"
            with self.assertRaises(ValueError):
                make_blocks(invalid)
            invalid[0]["sector"] = "0_0"
            invalid[0]["cls"] = "MeshPart"
            with self.assertRaises(ValueError):
                make_blocks(invalid)


if __name__ == "__main__":
    unittest.main()
