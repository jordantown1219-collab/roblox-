"""Read-only site analysis; --write updates only the proposed playable_block.json plan."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(os.environ.get("TEMP", "")) / "smallsignals-test-deps"))
from shapely.geometry import LineString, Point, Polygon, shape
from shapely.ops import nearest_points, unary_union

LANDMARK_IDS = (69349404, 69000343, 320396455, 30258238, 419447171, 419447172,
                419447173, 419447174, 56019569, 107551662)


def load_sources(root=ROOT):
    geography_path = root / "data/detroit_geography.json"
    geometry_path = root / "data/geometry.json"
    return (json.loads(geography_path.read_text(encoding="utf-8")),
            json.loads(geometry_path.read_text(encoding="utf-8")),
            {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
             for p in (geography_path, geometry_path)})


def analyze(root=ROOT):
    geography, geometry, hashes = load_sources(root)
    scale = geography["studsPerMeter"]
    features = geography["features"]
    by_id = {f["osm"]: f for f in features}
    buildings = [f for f in features if f["kind"] == "building"]
    building_union = unary_union([shape(f["geometry"]) for f in buildings])
    roads = unary_union([shape(f["geometry"]).buffer(f["width"] / 2, cap_style=2)
                         for f in features if f["kind"] == "road" and f["elevation"] == 0])
    land = shape(geography["land"])
    plaza = shape(by_id[69349404]["geometry"])
    shoreline = LineString(geography["shoreline"])
    anchors = [Point(point) for team in geography["gameplay"].values()
               for key, value in team.items() for point in (value if key == "sockets" else [value])]

    landmarks = []
    for osm in LANDMARK_IDS:
        feature = by_id[osm]
        polygon = shape(feature["geometry"])
        center = polygon.centroid
        landmarks.append({"osm": osm, "name": feature["name"], "kind": feature["kind"],
                          "footprintMeters": feature["geometry"],
                          "boundsMetersXZ": list(polygon.bounds),
                          "centroidStudsXZ": [center.x * scale, center.y * scale],
                          "sourceHeightMeters": feature.get("height"),
                          "sourceBaseMeters": feature.get("base"),
                          "heightSource": feature.get("heightSource", "not present"),
                          "existingGeometryRecordCount": sum(p.get("meta", {}).get("osm") == osm for p in geometry)})

    # A bounded 12-metre source-path segment close to the water, fully on land/plaza.
    candidates = []
    for feature in features:
        if feature["kind"] != "path" or feature["steps"] or feature["elevation"] != 0:
            continue
        line = shape(feature["geometry"])
        if line.geom_type != "LineString":
            continue
        if line.length < 12:
            continue
        middle = line.length / 2
        # Preserve actual source shape between anchors, including any intermediate vertices.
        from shapely.ops import substring
        segment = substring(line, middle - 6, middle + 6)
        corridor = segment.buffer(min(1, feature["width"] / 2), cap_style=2)
        if not land.covers(corridor) or not plaza.covers(corridor):
            continue
        if corridor.intersects(building_union) or corridor.intersects(roads):
            continue
        anchor_clearance = min(corridor.distance(p) for p in anchors)
        if anchor_clearance < 5:
            continue
        candidates.append((segment.distance(shoreline), feature["osm"], feature, segment, corridor, anchor_clearance))
    if not candidates:
        raise ValueError("No safe bounded source-path slice found; manual site review required")
    _, _, route_feature, route, corridor, anchor_clearance = min(candidates, key=lambda item: (item[0], item[1]))
    route_data = {"status": "proposal_only_not_applied", "kind": "Hart Plaza existing pedestrian surface slice",
                  "pathOsm": route_feature["osm"], "sourceName": route_feature["name"],
                  "sourceGeometryMeters": route_feature["geometry"],
                  "segmentMetersXZ": list(map(list, route.coords)),
                  "anchorsStudsXYZ": [[x * scale, .35, z * scale] for x, z in (route.coords[0], route.coords[-1])],
                  "lengthMeters": route.length, "reviewHalfWidthMeters": min(1, route_feature["width"] / 2),
                  "sourceWidthMeters": route_feature["width"], "widthSource": route_feature["widthSource"],
                  "elevationSource": route_feature["elevationSource"],
                  "currentRenderedPathTopStuds": .35,
                  "shorelineDistanceMeters": route.distance(shoreline),
                  "roadClearanceMeters": corridor.distance(roads),
                  "buildingClearanceMeters": corridor.distance(building_union),
                  "gameplayAnchorClearanceMeters": anchor_clearance,
                  "action": "Reference-driven paving/edge treatment on existing path only; retain current levels until primary stair/terrace plans are reconciled. No invented slope or steps."}

    # Secondary anonymous source footprint: preserve the current shell until approved integration.
    feature = by_id[955345369]
    footprint = shape(feature["geometry"])
    rectangle = footprint.minimum_rotated_rectangle
    coords = list(rectangle.exterior.coords)
    ux, uz = coords[1][0] - coords[0][0], coords[1][1] - coords[0][1]
    length = math.hypot(ux, uz)
    ux, uz = ux / length, uz / length
    vx, vz = -uz, ux
    center = rectangle.centroid
    width = length * scale - 3
    depth = math.dist(coords[1], coords[2]) * scale - 3
    # Roof overhang and side-wall half-thickness must fit too, not merely the floor.
    outer = Polygon([(center.x + ux * x + vx * z, center.y + uz * x + vz * z)
                     for x, z in [(-(width + 1) / scale / 2, -(depth + 1) / scale / 2),
                                  ((width + 1) / scale / 2, -(depth + 1) / scale / 2),
                                  ((width + 1) / scale / 2, (depth + 1) / scale / 2),
                                  (-(width + 1) / scale / 2, (depth + 1) / scale / 2)]])
    paths = [f for f in features if f["kind"] == "path" and not f["steps"] and f["elevation"] == 0]
    nearest_path = min(paths, key=lambda f: footprint.distance(shape(f["geometry"])))
    on_building, on_route = nearest_points(footprint, shape(nearest_path["geometry"]))
    # Negative local Z faces whichever side is nearer the source pedestrian path.
    if (on_route.x - center.x) * vx + (on_route.y - center.y) * vz > 0:
        ux, uz, vx, vz = -ux, -uz, -vx, -vz
    cframe = [center.x * scale, 0, center.y * scale, ux, 0, vx, 0, 1, 0, uz, 0, vz]
    others = unary_union([shape(f["geometry"]) for f in buildings if f["osm"] != feature["osm"]])
    secondary = {"status": "rejected_for_integration_road_buffer_overlap", "osm": feature["osm"],
                 "sourceFeature": feature, "existingShellRetained": True,
                 "sourceHeightStuds": feature["height"] * scale,
                 "footprintBoundsMetersXZ": list(footprint.bounds), "cframeComponents": cframe,
                 "yawRadians": math.atan2(vx, ux),
                 "templateConfig": {"width": width, "depth": depth, "height": min(24, feature["height"] * scale - 1)},
                 "outerRoofFootprintMeters": {"type": "Polygon", "coordinates": [list(map(list, outer.exterior.coords))]},
                 "fitsSourceFootprint": footprint.covers(outer),
                 "otherBuildingClearanceMeters": outer.distance(others), "roadClearanceMeters": outer.distance(roads),
                 "routeOsm": nearest_path["osm"], "routeSource": nearest_path,
                 "sourceBoundaryAnchorMetersXZ": [on_building.x, on_building.y],
                 "routeAnchorMetersXZ": [on_route.x, on_route.y],
                 "routeGapMeters": on_building.distance(on_route),
                 "limitation": "Footprint fit alone is insufficient: the estimated source road corridor overlaps this site. REJECTED for placement. Source estimates two levels at 3.3 m each; single-story template is not the real interior. Existing facade/roof remain untouched. No anonymous building placement is recommended in this bounded plan."}
    return {"schemaVersion": 1, "status": "read_only_site_plan_not_applied",
            "priority": "Recognizable Hart Plaza/CAYMC/RenCen land and architecture before anonymous storefront",
            "sourceHashes": hashes, "mapOriginLatLon": geography["origin"], "studsPerMeter": scale,
            "groundDatum": geography["groundDatum"], "sourceTimestamp": geography["sourceTimestamp"],
            "attribution": geography["attribution"], "landmarks": landmarks,
            "firstMapSlice": route_data, "secondaryFootprint": secondary}


def civic_facades(root=ROOT):
    geography, geometry, hashes = load_sources(root)
    scale = geography["studsPerMeter"]
    result = {"schemaVersion": 1, "sourceHashes": hashes, "studsPerMeter": scale,
              "status": "source_derived_no_geometry_changes", "buildings": []}
    for osm in (69000343, 320396455):
        feature = next(f for f in geography["features"] if f["osm"] == osm)
        polygon = shape(feature["geometry"])
        coords = list(polygon.exterior.coords)
        edges = [(a, b, LineString([a, b])) for a, b in zip(coords, coords[1:]) if a != b]
        faces = []
        for index, record in enumerate(geometry):
            if record["name"] != "Facade_" + str(osm):
                continue
            point = Point(record["pos"][0] / scale, record["pos"][2] / scale)
            a, b, edge = min(edges, key=lambda item: point.distance(item[2]))
            dx, dz = b[0] - a[0], b[1] - a[1]
            norm = math.hypot(dx, dz)
            nx, nz = (dz / norm, -dx / norm) if polygon.exterior.is_ccw else (-dz / norm, dx / norm)
            faces.append({"sourceIndex": index, "record": record,
                          "outwardNormalXYZ": [nx, 0, nz], "matchedSourceEdgeMetersXZ": [list(a), list(b)],
                          "edgeDistanceMeters": point.distance(edge),
                          "normalProvenance": "Right normal of CCW outer ring; left normal of clockwise ring, using projected source X/Z polygon winding"})
        result["buildings"].append({"osm": osm, "name": feature["name"], "sourceFeature": feature,
                                     "centerStudsXYZ": [polygon.centroid.x * scale, feature["base"] * scale, polygon.centroid.y * scale],
                                     "boundsMetersXZ": list(polygon.bounds), "sourceHeightMeters": feature["height"],
                                     "heightSource": feature["heightSource"], "floorCount": None,
                                     "floorCountStatus": "Awaiting primary reference research; do not infer from facade height",
                                     "faces": faces})
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    result = analyze()
    payload = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.write:
        (ROOT / "data/playable_block.json").write_text(payload, encoding="utf-8")
        (ROOT / "data/civic_facades.json").write_text(json.dumps(civic_facades(), indent=2, sort_keys=True) + "\n", encoding="utf-8")
        print(json.dumps({"written": "data/playable_block.json", "pathOsm": result["firstMapSlice"]["pathOsm"],
                          "secondaryFits": result["secondaryFootprint"]["fitsSourceFootprint"]}))
    else:
        print(payload)
