# Detroit land-elevation feasibility — 2026-10-23

**Result: official point-elevation data is accessible and useful for a future bounded broad-grade study. It is not enough to directly reconstruct current Hart Plaza stairs, decks or ramps, or to regrade the whole city safely.** No game geometry was changed.

## Actual query evidence

Six GET requests to the [USGS EPQS API](https://epqs.nationalmap.gov/v1/docs) succeeded. Parameters: `x=longitude`, `y=latitude`, `wkid=4326`, `units=Meters`, `includeDate=true`. Raw response objects and exact URLs are retained in `data/elevation_reference_sample.json`. Sample locations are deliberately named **vicinity**: except the preserved Spirit anchor, coordinates were selected approximately for feasibility, not verified to fall on a specific stair tread, pavement face or survey monument.

| Approximate vicinity | Latitude | Longitude | EPQS elevation, m |
|---|---:|---:|---:|
| Spirit anchor vicinity | 42.3292972 | -83.0446278 | 183.141632080 |
| Hart Plaza north | 42.3287 | -83.0445 | 183.257461548 |
| Fountain vicinity | 42.32805 | -83.04445 | 183.162780762 |
| Lower terrace vicinity | 42.32735 | -83.0452 | 181.967285156 |
| West Riverwalk vicinity | 42.3270 | -83.0458 | 181.460281372 |
| East Riverwalk vicinity | 42.3275 | -83.0441 | 181.048583984 |

All responses return `rasterId:133020`, `resolution:1`, and acquisition string **`3/0/2017`**. Preserve that string literally: it suggests March 2017 but has no valid calendar day; do not manufacture an exact acquisition date. The service response does not name the individual dataset or vertical datum. Its schema documents a numeric resolution field without explicitly defining that field's units. Treat the returned 1 as reported metadata, consistent with the service's available 1-meter products, **not** proof of one-meter accuracy or a surveyed local product. Dataset-specific metadata/datum confirmation remains pending.

Observed sample range is **2.208877564 m**. Relative to the Spirit sample, north plaza is +0.115829468 m, fountain vicinity +0.021148682 m, lower terrace -1.174346924 m, west Riverwalk -1.681350708 m, east Riverwalk -2.093048096 m. These arithmetic differences suggest a broad riverward descent. Six sparse, approximately located points cannot resolve grade breaks or prove a single smooth plane.

## Reliability and interpretation

[USGS accuracy guidance](https://www.usgs.gov/faqs/how-accurate-are-elevations-generated-elevation-point-query-service-national-map) says EPQS interpolates its dynamic 3DEP service, mixing resolutions. Accuracy varies by underlying data; its stated overall service RMSE is 0.53 m. This is an aggregate figure, **not** local relative precision or a guaranteed error bound for raster 133020. Sub-decimeter differences in this sample must not be modeled as reliable curbs or steps. Query decimal precision is not measurement accuracy.

[USGS DEM guidance](https://www.usgs.gov/faqs/what-types-elevation-datasets-are-available-what-formats-do-they-come-and-where-can-i-download) distinguishes bare-earth elevation from surface objects. A DEM excludes buildings/trees and is not an architectural model. Built terraces, retaining walls, stair profiles, bridge/deck surfaces, current water levels and covered/tunnel areas need separate interpretation. The reported 2017 acquisition predates the documented 2024–25 Hart Plaza Grand Stairs work. These samples cannot establish the renovated layout or current public access.

## Next safe implementation boundary

1. Keep the existing city's Y datum, original roads, manual landmarks and gameplay anchors unchanged for now.
2. Use this cached six-point sample as feasibility evidence only; do not wire network elevation queries into gameplay.
3. Before any grade pass, select a small polygon, verify sample positions against plan/aerial references, obtain dataset metadata, and reconcile current upper/lower paved levels against recent photographs or drawings. Exclude water, decks, tunnels, fountain basin and building footprints from bare-earth interpolation.
4. A future opt-in, replaceable land patch may use broad relative grade with explicit transition/edge constraints. Apply the project's established meters-to-studs conversion once, preserving horizontal projection and one chosen reference elevation. Do not put absolute 183-meter elevations directly into the game.
5. Separately design original terrace/ramp geometry, labelled reference-inspired until contemporary plans are verified. Check normal and shrunk-player traversal, vehicle routes, foundations, holes, flicker, streaming and same-view foreground FPS before integration.

**Decision:** data access is proven; local broad-grade feasibility is promising. Survey-like reconstruction and current stair dimensions remain blocked on metadata/current built-condition evidence. No further point requests or raster downloads were performed in this bounded pass.
