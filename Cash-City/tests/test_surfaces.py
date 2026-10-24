"""Surface footprints must meet at seams without competing visible faces."""
import os
import sys
import unittest
from itertools import combinations
from pathlib import Path

sys.path.insert(0, str(Path(os.environ['TEMP']) / 'smallsignals-test-deps'))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from shapely.geometry import LineString, Point, box, mapping
from shapely.ops import unary_union
from surfaces import build_surface_layers


def feature(kind, geometry, **options):
    return dict(kind=kind, name=kind, geometry=mapping(geometry), osm=1,
                **options)


def corridor(kind, coords, **options):
    return feature(kind, LineString(coords), width=4, elevation=0,
                   tunnel=False, widthSource='test width', **options)


def geography(features):
    return dict(land=mapping(box(-20, -20, 20, 20)),
                water=mapping(box(20, -20, 30, 20)),
                boundsMeters=[-20, -20, 30, 20], studsPerMeter=3,
                features=features)


class SurfaceSeams(unittest.TestCase):
    def assert_disjoint(self, layers):
        for first, second in combinations(layers, 2):
            overlap = first['geometry'].intersection(second['geometry']).area
            self.assertLess(overlap, 1e-7,
                            f"Competing faces: {first['name']} / {second['name']}")

    def test_crossing_and_bent_roads_have_one_continuous_visible_surface(self):
        layers = build_surface_layers(geography([
            corridor('road', [(-15, 0), (0, 0), (0, 15)]),
            corridor('road', [(-10, -10), (10, 10)]),
        ]))
        roads = [s for s in layers if s['material'] == 'Asphalt']
        self.assertTrue(roads)
        self.assert_disjoint(roads)
        pavement = unary_union([s['geometry'] for s in roads])
        self.assertEqual(pavement.geom_type, 'Polygon')
        for point in [(-10, 0), (0, 0), (0, 10), (-5, -5), (5, 5)]:
            self.assertTrue(pavement.covers(Point(point)), point)

    def test_path_park_plaza_and_ground_have_separated_visible_faces(self):
        layers = build_surface_layers(geography([
            corridor('road', [(-20, 0), (20, 0)]),
            corridor('path', [(0, -20), (0, 20)]),
            feature('park', box(-12, -12, 12, 12)),
            feature('plaza', box(-8, -8, 8, 8)),
        ]))
        land_layers = [s for s in layers if s['name'] != 'DetroitRiver']
        visible = [s for s in land_layers if not s.get('substrate')]
        substrate = [s for s in land_layers if s.get('substrate')]
        for first, second in combinations(visible, 2):
            if first['geometry'].intersection(second['geometry']).area > 1e-7:
                self.assertGreaterEqual(abs(first['top'] - second['top']), .18 - 1e-9,
                                        'Overlaid materials need a stable vertical separation')
        self.assertTrue(substrate, 'Continuous support must remain below paved surfaces')
        for base in substrate:
            self.assertEqual(base['name'], 'SourceLand')
            self.assertLess(base['top'], min(s['top'] for s in visible),
                            'Underlay needs vertical separation to avoid competing faces')
        covered = unary_union([s['geometry'] for s in land_layers])
        self.assertLess(covered.symmetric_difference(box(-20, -20, 20, 20)).area,
                        1e-7, 'Resolving overlaps must not leave holes in the city')
        crossing = [s for s in visible if s['geometry'].covers(Point(0, 0))]
        self.assertEqual(max(crossing, key=lambda s: s['top'])['material'], 'Asphalt',
                        'Road must stay visible through a crossing footpath')

    def test_land_surfaces_stop_at_river_and_tunnels_stay_hidden(self):
        layers = build_surface_layers(geography([
            corridor('road', [(10, 0), (28, 0)]),
            feature('road', LineString([(-15, -10), (15, -10)]),
                    width=4, elevation=-5, tunnel=True, widthSource='test'),
        ]))
        for layer in layers:
            if layer['name'] != 'DetroitRiver':
                self.assertLess(layer['geometry'].intersection(box(20, -20, 30, 20)).area,
                                1e-7, layer['name'])
        self.assertFalse(any(s['material'] == 'Asphalt' and
                             s['geometry'].covers(Point(0, -10)) for s in layers))


if __name__ == '__main__':
    unittest.main()
