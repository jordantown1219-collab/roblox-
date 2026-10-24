"""Join equal-height corridors and separate material layers vertically."""
from collections import defaultdict
import shapely
from citygeo import STUDS_PER_METER
from shapely.geometry import shape
from shapely.ops import unary_union

# Render-only outline tolerance keeps native parts under the 20,000 budget.
# It retains polygon topology; raw OSM centerlines and footprints are unchanged.
RENDER_OUTLINE_TOLERANCE_METERS = 2.75


def build_surface_layers(geography):
    land = shape(geography['land'])
    water = shape(geography['water'])
    land = land.difference(water)
    groups = defaultdict(list)
    for feature in geography['features']:
        kind = feature['kind']
        if kind not in ('road', 'path', 'plaza', 'park') or feature.get('tunnel'):
            continue
        geom = shape(feature['geometry'])
        height = max(0, feature.get('elevation', 0))
        if kind in ('road', 'path'):
            geom = geom.simplify(.45).buffer(feature['width'] / 2, quad_segs=2, cap_style='flat', join_style='mitre')
        if height == 0:
            geom = geom.intersection(land)
        if not geom.is_empty:
            groups[(height, kind)].append(geom)

    styles = {
        'road': ('JoinedRoad', .55, 'Asphalt', [49, 52, 55]),
        'path': ('JoinedWalk', .35, 'Concrete', [158, 155, 146]),
        'plaza': ('JoinedPlaza', .15, 'Granite', [157, 142, 130]),
        'park': ('JoinedPark', -.05, 'Grass', [101, 119, 79]),
    }
    layers = []
    for height in sorted({h for h, _ in groups}):
        # Each material has one joined face per elevation. A .2 stud vertical
        # gap keeps overlaid materials stable without fragmenting every crossing.
        for kind in ('road', 'path', 'plaza', 'park'):
            candidates = groups.get((height, kind))
            if not candidates:
                continue
            geom = unary_union(candidates)
            if kind in ('road', 'path'):
                # Render outline only: source centerlines remain intact in geography.
                geom = geom.simplify(RENDER_OUTLINE_TOLERANCE_METERS,
                                     preserve_topology=True)
                if height == 0:
                    geom = geom.intersection(land)
            if geom.is_empty:
                continue
            name, top, material, color = styles[kind]
            layers.append(dict(name=name, geometry=geom, top=height * STUDS_PER_METER + top,
                               material=material, color=color))
    # The solid substrate stays below every pavement top. Carving thousands of
    # hidden holes here increases triangle count without changing visible faces.
    layers.insert(0, dict(name='SourceLand', geometry=land, top=-.25, substrate=True,
                         material='Ground', color=[125, 126, 110]))
    layers.insert(1, dict(name='DetroitRiver', geometry=water, top=-2.5,
                         material='Glass', color=[39, 88, 100]))
    return layers
