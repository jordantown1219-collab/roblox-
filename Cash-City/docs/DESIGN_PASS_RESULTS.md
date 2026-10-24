# Riverfront v0.11 design pass — 2026-10-22

## Saved work
- v0.10 disk baseline remains unchanged; working copy is Detroit_Riverfront_v0_11.
- Joined road/path surfaces replace overlapping equal-height segments. Material surfaces are separated vertically; ground is a lower substrate. 19,845 geographic primitives, unchanged 20,000 guard passes. Source centerlines remain intact; rendered corridor outlines use a documented 2.75 m simplification and exact shoreline clipping. This is not surveyed street geometry.
- Added a generated textured Spirit of Detroit interpretation with pedestal/backdrop, native Joe Louis Fist interpretation and Transcending arch, plus eight original benches. These are game interpretations; visual accuracy is not accepted as an authentic reconstruction.
- Added three matching textured SUVs: one driveable, two parked. Native four-wheel motors, two steering servos, entry/exit, brakes, lights/brake lamps, engine/horn, recover control, driver scale/alive validation. Supported driving is full-size only. No opening doors/hood/hatch, passenger system, damage model, suspension travel or full interior interaction is accepted as complete.
- Rifle/SMG/knife exterior assemblies replace simple handle blocks. Modern carbine/compact silhouettes, magazine motion, loaded shot/reload audio and muzzle light. Existing server combat tuning retained. No full first-person arm rig or aim/recoil animation pass is accepted.
- Bounded native prefetch before map transfers, loading feedback, stale operation guards, stream-in prompt handling, safe spawn recovery and seat release before transfers.

## Actual engine results
- Twelve weapon/scale assemblies passed connectivity, collision and muzzle checks.
- SUV chassis test passed: four connected motor hinges, two steering hinges, no anchored dynamic parts, parked variants present.
- Corrected motor sign: W produced +13.47 studs forward displacement; S produced -19.56 studs. Steering changed heading ~7 degrees over 18.2 studs in the recorded short test. Braking reached ~0.08 studs/s in the first test; another reverse/braking sample still had ~2.67 studs/s after one second, so stopping-distance tuning remains pending.
- Driver entry/exit, light toggle, recovery and audio loading verified. Turn stability sample up-vector Y=.99999; not a long road/durability test.
- Solo vote/deployment, all three gate prompts (.65/.40/.22 scale), both pad clearance checks and Amber extraction victory passed. Gate-to-gate test teleports used; full walking route remains pending.
- Prefetch measured 22 ms at deployment and 16/20/17 ms at gates in this local test, with loading flags cleared and no recovery needed. These are local observations, not network latency guarantees.
- One normal accepted rifle shot reduced ammo 20 -> 19; shot/reload sounds loaded. Reload requested; complete animation visual QA remains pending.
- Full offline discovery: 15 unittest cases passed, plus 18 interaction and 23 game-rule assertions, and existing panel regressions.

## Performance not accepted
Client diagnostic samples fell to roughly 7-9 FPS with ~2,356 MB memory in this Studio environment. A MicroProfiler sample recorded 120 engine frames over 3,711 ms, 30 main-thread Presents; Present consumed 2,661 ms (~88.7 ms each). Game client scripts used ~0.25 ms per presented game frame; physics ~0.93 ms. A snapshot had 4,327 streamed BaseParts and 17 draw calls / 25,209 triangles at the current camera. Multiple open-place render jobs were present.
This identifies display presentation as the measured bottleneck; it does not establish the exact driver/window cause or prove the map performs well in a standalone client. No smooth-FPS claim. Native and Windows screenshot capture intermittently timed out; do not claim full visual QA. The user was asked whether movement looks choppy; no answer was available at save time.

## Next acceptance
Resolve Studio presentation/obtain comparable clean-client measurements. Review city surfaces from moving views. Tune/validate vehicle stopping, steering, collision recovery, accessibility and touch/controller inputs; complete any intended door/interior/passenger scope. Review all art and weapon alignment/firing/reload visually at each scale. Complete workshop, transit, six-client and real-device tests. Do not publish this as finished.

## References
- Detroit Riverfront Conservancy: https://www.detroitriverfront.org/map
- Detroit street guide: https://detroitmi.gov/departments/department-public-works/complete-streets/transportation-planning-resources/street-design-guidelines
- City Hart Plaza art inventory: https://detroitmi.gov/departments/detroit-parks-recreation/parks-and-greenways/hart-plaza
- Detroit Historical Society Spirit reference: https://www.detroithistorical.org/learn/online-research/encyclopedia-of-detroit/spirit-detroit
- DIA Joe Louis reference: https://dia.org/about/blog/wait-thats-ours-dia-owns-fist
- Ford SUV design reference: https://www.ford.com.pr/en/crossovers-suvs/explorer/design/
- Colt visual reference: https://www.colt.com/wp-content/uploads/2026/02/25-COLT-1930-COLLATERAL-2026-MLE-Catalog-RND7-FINAL-Paperturn-Single-Pages.pdf

Generated art asset provenance is in data/art_assets.json. Mesh generation published original art assets through Studio's built-in generation tool; the game/place was not published. Free Creator Store audio IDs are recorded in the source.
