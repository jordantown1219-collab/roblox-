"""Derive a short source-checked Hart Plaza walking route, without altering the map."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(os.environ.get("TEMP", "")) / "smallsignals-test-deps"))
from shapely.geometry import LineString, Point, MultiPoint, shape
from shapely.ops import nearest_points, unary_union

BODY_RADIUS_METERS = .65


def inputs():
    names = ["detroit_geography.json", "geometry.json", "detail_preview.json", "playable_block.json"]
    loaded = {name: json.loads((ROOT / "data" / name).read_text(encoding="utf-8")) for name in names}
    hashes = {name: hashlib.sha256((ROOT / "data" / name).read_bytes()).hexdigest() for name in names}
    return loaded, hashes


def collider_polygon(record, scale):
    if not record.get("collide", True):
        return None
    matrix, pos, size = record.get("matrix", [1, 0, 0, 0, 1, 0, 0, 0, 1]), record["pos"], record["size"]
    corners = []
    for x in (-.5, .5):
        for y in (-.5, .5):
            for z in (-.5, .5):
                local = [x * size[0], y * size[1], z * size[2]]
                corners.append([pos[row] + sum(matrix[row * 3 + col] * local[col] for col in range(3)) for row in range(3)])
    # Ignore walkable surfaces <=.85stud and geometry entirely above a standing avatar.
    if max(p[1] for p in corners) <= .85 or min(p[1] for p in corners) >= 8:
        return None
    return MultiPoint([(p[0] / scale, p[2] / scale) for p in corners]).convex_hull


def collision_model(loaded):
    geography = loaded["detroit_geography.json"]
    features = geography["features"]
    scale = geography["studsPerMeter"]
    plaza = shape(next(f for f in features if f["osm"] == 69349404)["geometry"])
    buildings = unary_union([shape(f["geometry"]) for f in features if f["kind"] == "building"])
    roads = unary_union([shape(f["geometry"]).buffer(f["width"] / 2, cap_style=2)
                         for f in features if f["kind"] == "road" and f["elevation"] == 0])
    records = loaded["geometry.json"] + [part for model in loaded["detail_preview.json"] for part in model["parts"]]
    obstacles = [polygon for record in records for polygon in [collider_polygon(record, scale)]
                 if polygon is not None and polygon.intersects(plaza)]
    colliders = unary_union(obstacles)
    walkable = plaza.intersection(shape(geography["land"])).difference(unary_union([buildings, roads, colliders]))
    return walkable, buildings, roads, colliders


def generate():
    loaded, hashes = inputs()
    geography = loaded["detroit_geography.json"]
    scale = geography["studsPerMeter"]
    walkable, buildings, roads, colliders = collision_model(loaded)
    trial = loaded["playable_block.json"]["firstMapSlice"]
    trial_line = LineString(trial["segmentMetersXZ"])
    first, last = Point(trial_line.coords[0]), Point(trial_line.coords[-1])
    reference = Point(-405, 205)  # Search preference only; route start comes from a source path.
    candidates = []
    for feature in geography["features"]:
        if feature["kind"] != "path" or feature["steps"] or feature["elevation"] != 0:
            continue
        path = shape(feature["geometry"])
        start = nearest_points(path, reference)[0]
        if not 60 <= start.distance(first) <= 135:
            continue
        line = LineString([start, first, last])
        if line.length > 150 or not walkable.covers(line.buffer(BODY_RADIUS_METERS)):
            continue
        candidates.append((start.distance(reference), feature["osm"], feature, start, line))
    if not candidates:
        raise ValueError("No full-body-clear <=150m route found; no route exported")
    _, _, source, start, line = min(candidates, key=lambda candidate: (candidate[0], candidate[1]))
    # Two intermediate viewing stops remain exactly on the verified straight plaza connector.
    connector = LineString([start, first])
    points = [start, connector.interpolate(.35, normalized=True), connector.interpolate(.7, normalized=True), first, last]
    corridor = line.buffer(BODY_RADIUS_METERS)
    return {"schemaVersion": 1, "status": "offline_source_clearance_verified_native_walk_pending",
            "sourceHashes": hashes, "originLatLon": geography["origin"], "studsPerMeter": scale,
            "groundDatum": geography["groundDatum"], "attribution": geography["attribution"],
            "start": {"type": "existing_source_path", "osm": source["osm"], "sourceGeometry": source["geometry"]},
            "destination": {"type": "existing_Hart_paving_trial", "pathOsm": trial["pathOsm"]},
            "lengthMeters": line.length, "lengthStuds": line.length * scale,
            "fullBodyRadiusMeters": BODY_RADIUS_METERS, "fullBodyWidthStuds": BODY_RADIUS_METERS * 2 * scale,
            "segmentMetersXZ": list(map(list, line.coords)),
            "waypoints": [{"id": name, "metersXZ": [point.x, point.y],
                           "surfaceStudsXYZ": [point.x * scale, .35, point.y * scale]}
                          for name, point in zip(["source_path_start", "plaza_civic_vista", "riverfront_vista", "paving_trial_start", "paving_trial_end"], points)],
            "clearancesMeters": {"road": corridor.distance(roads), "building": corridor.distance(buildings), "generatedStandingCollider": corridor.distance(colliders)},
            "referenceIds": {"HartPlaza": 69349404, "CAYMC_Courts": 69000343, "CAYMC_Admin": 320396455, "pavingTrialPath": trial["pathOsm"]},
            "amberSpawnMetersXZ": geography["gameplay"]["Amber"]["spawn"],
            "amberSpawnDirectDistanceToTrialMeters": Point(geography["gameplay"]["Amber"]["spawn"]).distance(first),
            "elevationStatus": "Flat source datum; .35stud is an estimated review surface height, not per-waypoint native ground-ray result. Lead must raycast ground before humanoid placement.",
            "limitations": ["Route starts at nearby source path because Amber spawn to trial exceeds150m.",
                            "Civic names mark viewing references, not line-of-sight guarantees or visits to their building entrances.",
                            "Only source polygon and static/generated collider clearance checked. Moving vehicles, characters, current runtime additions and streamed availability need native checks.",
                            "Plaza connector is continuous source plaza, not invented surveyed sidewalk geometry; slopes/steps absent from flat source remain unverified.",
                            "Walking completion, frame-rate capture, multiplayer and all device checks remain pending."]}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    route = generate()
    payload = json.dumps(route, sort_keys=True, indent=2) + "\n"
    if args.write:
        (ROOT / "data/detroit_walk_route.json").write_text(payload, encoding="utf-8")
        print(json.dumps({"lengthMeters": route["lengthMeters"], "waypoints": len(route["waypoints"]), "startPath": route["start"]["osm"]}))
    else:
        print(payload)
