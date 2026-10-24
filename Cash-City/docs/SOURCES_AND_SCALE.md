# Sources, scale and licensing

## Open geometry
OpenStreetMap / Overpass snapshot: see data/detroit_geography.json sourceTimestamp. Inputs: data/osm_raw.json and data/river_raw.json; query in data/osm_request.txt. Roads, paths, park/plaza polygons, building and building-part footprints, and Detroit River outer-bank geometry come from these records. No aerial photos, street-view images or third-party Roblox maps were copied.
© OpenStreetMap contributors. Database and derived geography/geometry database: Open Database License 1.0. Attribution and license information: https://www.openstreetmap.org/copyright ; license: https://opendatacommons.org/licenses/odbl/1-0/ . The raw and derived data files supplied here provide the database sources for this produced map. Existing SmallSignals code is not relicensed by this data notice.

## Factual reference checks
- Detroit Historical Society, Renaissance Center: https://www.detroithistorical.org/learn/online-research/encyclopedia-of-detroit/renaissance-center . Confirms seven-building composition and relative story counts. Text and photos are not copied as game assets.
- Council on Vertical Urbanism / Skyscraper Center: https://www.skyscrapercenter.com/detroit/detroit-marriott-at-the-renaissance-center/1225 . Central architectural height 221.5 m. OSM has a cylindrical body and separate cap; body is not arbitrarily scaled to cap height.
- Complex facts: https://www.skyscrapercenter.com/complex/487 . Named office tower heights are cross-checked here. Some OSM subparts use different heights/datums; those differences remain documented in heightSource rather than silently normalized into one mass.
- Hart Plaza context: https://detroitmi.gov/departments/detroit-parks-recreation/parks-and-greenways/hart-plaza . The public page was found but direct fetch returned 403. No private access or artwork copying attempted.
- Riverwalk context: https://www.detroitriverfront.org/map . Geometry comes from OSM, not from copying this illustrated map.
- A SEMCOG-derived ArcGIS footprint service was inspected, but no clear reuse terms were returned with its metadata. It was not used as the geometry source.

## Coordinate contract
Bounds WGS84 [west,south,east,north]: [-83.0485,42.326,-83.031,42.3345]. Approximately 1440 x 946 m. Origin: 42.329 N, -83.040 E. X east, Z south, Y up. Local equirectangular metric projection using Earth radius 6378137 m at the origin latitude; this is a local blockout approximation, not a survey-grade geodetic transform. Inverse conversion is tested. 1 m = 1/0.28 studs, consistent with Roblox's closest real-world scale reference: https://create.roblox.com/docs/resources/beyond-the-dark/building-architecture . No landmark position compression is applied.

## Estimated/incomplete items
Ground Y=0 is an artificial flat datum. River surface and rail elevations, bridge layer x 5 m elevations, road widths without width tags, default unmeasured building heights, facade modules and roof simplification are estimates. Incomplete tunnels/steps are not represented as fully functional real infrastructure. Exact terrain, elevations, curbs, stairs, accessible ramps and surveyed entrances require a later source pass.
Protected sculptures and commercial branding are omitted. The original staging room/workshop is outside the real-world boundary; it is gameplay/test geometry, not Detroit reconstruction. Signal/transit gates and extraction markers are original game objects placed on source-derived open pedestrian points.
