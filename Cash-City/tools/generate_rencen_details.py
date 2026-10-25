"""Bounded original Renaissance Center accents on unchanged source facades."""
import hashlib
import json
import math
import os
from pathlib import Path
import sys

sys.path.insert(0, str(Path(os.environ.get("TEMP", "")) / "smallsignals-test-deps"))
from shapely.geometry import Polygon
from shapely.strtree import STRtree

ROOT = Path(__file__).resolve().parents[1]
IDS = (30258238, 419447171, 419447172, 419447173, 419447174, 107551662, 56019569)
ATRIUM_CANDIDATE = 419447156
PODIUM = 1307210646
REFERENCES = ["https://www.som.com/projects/general-motors-renaissance-center/",
              "https://gmrencen.com/wp-content/uploads/2021/09/GMRENCEN-Complex-Map-Update.pdf"]


def wall_footprint(record):
    m, p, size = record["matrix"], record["pos"], record["size"]
    return Polygon([(p[0] + m[0] * x + m[2] * z, p[2] + m[6] * x + m[8] * z)
                    for x, z in [(-size[0]/2, -size[2]/2), (size[0]/2, -size[2]/2),
                                 (size[0]/2, size[2]/2), (-size[0]/2, size[2]/2)]])


def overlapping_wall_indices(detail, walls, polygons, tree):
    polygon = wall_footprint(detail)
    low, high = detail["pos"][1] - detail["size"][1]/2, detail["pos"][1] + detail["size"][1]/2
    result = []
    for index in tree.query(polygon, predicate="intersects"):
        wall = walls[index]
        bottom, top = wall["pos"][1]-wall["size"][1]/2, wall["pos"][1]+wall["size"][1]/2
        if low < top and high > bottom and polygon.intersection(polygons[index]).area > 1e-8:
            result.append(int(index))
    return result


def polygon_center(coordinates):
    ring = coordinates[0]
    cross = [a[0] * b[1] - b[0] * a[1] for a, b in zip(ring, ring[1:])]
    denominator = 3 * sum(cross)
    assert abs(denominator) > 1e-9, "Degenerate source footprint"
    return [sum((a[axis] + b[axis]) * c for a, b, c in zip(ring, ring[1:], cross)) / denominator for axis in (0, 1)]


def make_plan(geography, geometry):
    scale = geography["studsPerMeter"]
    features = {f["osm"]: f for f in geography["features"] if f["kind"] == "building"}
    plan = {"version": 1, "references": REFERENCES,
            "status": "Original reference-inspired accents; source geometry retained; native/visual acceptance pending",
            "dimensions": "Source face geometry exact; accent spacing, widths and metal colors are artistic estimates",
            "sourceFinishChanges": [], "faces": [], "buildings": [], "details": [], "neighborWallAdjustments": []}
    walls = [r for r in geometry if r["name"].startswith("Facade_")]
    polygons = [wall_footprint(r) for r in walls]
    tree = STRtree(polygons)
    for osm in IDS + (ATRIUM_CANDIDATE, PODIUM):
        feature = features[osm]
        center = [n * scale for n in polygon_center(feature["geometry"]["coordinates"])]
        faces = [(i, r) for i, r in enumerate(geometry) if r["name"] == "Facade_" + str(osm)]
        assert faces, f"Missing existing source facade {osm}"
        plan["buildings"].append({"osm": osm, "name": feature["name"], "centerStudsXZ": center,
                                   "sourceFootprint": feature["geometry"], "sourceBaseMeters": feature["base"],
                                   "sourceHeightMeters": feature["height"], "heightSource": feature["heightSource"],
                                   "sourceFaceCount": len(faces)})
        for face_number, (source_index, record) in enumerate(faces):
            matrix, pos, size = record["matrix"], record["pos"], record["size"]
            # Source local X is facade-normal; choose its outward radial sign, preserving alignment.
            normal = [matrix[0], matrix[3], matrix[6]]
            sign = 1 if normal[0] * (pos[0] - center[0]) + normal[2] * (pos[2] - center[1]) > 0 else -1
            normal = [n * sign for n in normal]
            guard = {"sourceIndex": source_index, "record": record, "outwardNormalXYZ": normal}
            plan["faces"].append(guard)
            base, top = pos[1] - size[1] / 2, pos[1] + size[1] / 2
            if osm == PODIUM:
                plan["sourceFinishChanges"].append({"sourceIndex": source_index, "record": record,
                                                     "color": [190, 190, 179], "material": "Limestone"})
                continue

            def add(label, y, length, tall, depth, color, material):
                gap = .10
                offset = size[0] / 2 + gap + depth / 2
                detail = {"name": f"RenCen_{label}_{osm}_{face_number:02d}",
                                         "pos": [pos[0] + normal[0] * offset, y, pos[2] + normal[2] * offset],
                                         "size": [depth, tall, length], "matrix": list(matrix),
                                         "color": color, "material": material, "osm": osm,
                                         "collide": False, "sourceIndex": source_index,
                                         "surfaceGapStuds": gap, "dimensionStatus": "artistic estimate"}
                original_length = length
                overlaps = overlapping_wall_indices(detail, walls, polygons, tree)
                original_overlaps = [walls[i]["name"] for i in overlaps]
                # Own-face separation alone does not clear corners of neighboring walls.
                # Trim symmetric reveal ends until the entire volume clears every source wall.
                while overlaps and detail["size"][2] > .3:
                    detail["size"][2] = max(.2, detail["size"][2] - .2)
                    overlaps = overlapping_wall_indices(detail, walls, polygons, tree)
                if detail["size"][2] != original_length or overlaps:
                    plan["neighborWallAdjustments"].append({"name": detail["name"], "originalLengthStuds": original_length,
                                                            "finalLengthStuds": None if overlaps else detail["size"][2],
                                                            "overlappingSourceNames": original_overlaps,
                                                            "action": "omitted" if overlaps else "end_trimmed"})
                if not overlaps:
                    plan["details"].append(detail)

            if osm == ATRIUM_CANDIDATE:
                # Only existing river-facing facets, not the backs occluded by source podium.
                if normal[2] > .4:
                    for fraction in (.25, .5, .75):
                        add(f"RiverEntryHorizontal{int(fraction*100)}", base + size[1] * fraction,
                            max(.2, size[2] - .08), .32, .14, [165, 176, 180], "Metal")
                    # One centered vertical accent per facet; real bay widths are unmeasured.
                    add("RiverEntryVertical", (base + top) / 2, .24, size[1] * .96, .14, [165, 176, 180], "Metal")
            else:
                # A narrow upper reveal, not a replacement crown or occupied floor band.
                add("UpperReveal", top - 1.2, max(.2, size[2] - .08), 1.2, .16, [130, 143, 150], "Metal")
                # Complete the vertical frame rhythm on all five main tower masses.
                # Each narrow bar still uses its exact source-face clearance guard.
                if osm not in (107551662, 56019569):
                    add("VerticalMullion", (base + top) / 2, .22, size[1] * .96, .12, [164, 173, 175], "Metal")
                if osm == 30258238:
                    add("BodyBaseReveal", base + 1.2, max(.2, size[2] - .08), 1.2, .16, [118, 132, 138], "Metal")
    assert len(plan["details"]) <= 420, "Bounded accent budget exceeded"
    plan["atriumCandidate"] = {"osm": ATRIUM_CANDIDATE, "identityStatus": "Anonymous source glass part; map/reference-correlated Wintergarden candidate, not definitive named identity",
                               "roofChanges": False, "curvedRoofCreated": False, "sourceFacadeCount": 10}
    plan["limitations"] = ["No duplicate source facade or glass sheet is created; 24 podium finish-only changes are explicit and guarded.",
                           "Source base/top bounds govern every accent. Separate source cap, podium and Wintergarden remain untouched.",
                           "No logos, signage, authentic interior, exact real-world bay count or current redevelopment status claimed.",
                           "Metal color and spacing need Lead visual review against primary reference photos.",
                           "Decorative records must be anchored with collision/touch disabled by the integration consumer.",
                           "Live walking, FPS, streaming, multiplayer and device acceptance remain pending."]
    return plan


def generate(root=ROOT):
    paths = [root / "data/detroit_geography.json", root / "data/geometry.json"]
    geography, geometry = [json.loads(p.read_text(encoding="utf-8")) for p in paths]
    plan = make_plan(geography, geometry)
    plan["sourceHashes"] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    return plan


if __name__ == "__main__":
    plan = generate()
    (ROOT / "data/rencen_detail_plan.json").write_text(json.dumps(plan, sort_keys=True, separators=(",", ":"), allow_nan=False) + "\n", encoding="utf-8")
    print(f"RenCen: {len(plan['buildings'])} preserved masses, {len(plan['faces'])} guarded faces, {len(plan['details'])} noncolliding accents")
