# Residential expansion: bounded next slice
1. Preserve finished Level01; add one Level02 pilot at Y92, not every tower/floor at once.
2. Generator already accepts levels 1..39 with 12-stud spacing; its Lua tail still hardcodes ResidentialFloor=1.
3. Parameterize floor/finish builders with explicit target model and level; preserve default Level01 behavior.
4. Keep independent names and avoid require-cache-dependent data replacement.
5. Build a guarded Level01-to-Level02 stair opening/connection before enabling public access.
6. Preserve the existing lift stops until its separate acceptance and extension are ready.
7. Clip effective floor/ceiling surfaces without refilling existing stair/lift openings; retain originals.
8. Reuse four-suite furnishing data; do not duplicate unrelated map systems.
9. Current measured Level01 allocation: 690 parts and 30 SurfaceLights including separate finishes.
10. Replicating this unchanged across 39 floors would allocate 26,910 parts and 1,170 lights per tower; this is arithmetic, not a benchmark.
11. Measure the single-floor pilot before authorizing bulk replication; do not claim streaming eliminates its costs.
12. Validate one22percent connection route, full-size clearance where changed, and source syntax; manual/device/multiplayer checks remain distinct.

2026-10-26: Steps2-4 implemented. Level02 Edit-only pilot staged/validated689parts30lights; Level01 runtime regression passed690parts30lights. Step5 stair connection is next; upper pilot not enabled in Arena.

2026-10-26: Level02 connection added and enabled in Arena after22percent/fullsize routePASS; upper prompts startupchecked, activation/device/multiplayer/performance pending. Onlytwofloors built.

2026-10-26 user approved copying remaining floors. Levels03-05 copied/connected/22percentroutePASS; samecameraStudio~60FPS beforeafter, memory+17.81MB. Nextboundedbatch06-08; editedbuildercaches must be fresh cloned in Edit.

2026-10-26: Levels06-08 copied/connected/22percentroutePASS, fresh8floorstartupchecked. SamecameraStudio59.86->59.87FPS, observedendmemory+124.85MBnotisolatedcost. Nextfresh-startmemorycheck before09-11. FreshEditcandidateclones used; original26400partsunmoved.

2026-10-26: Levels09-11copied/connected/22percentroutePASS, fresh11floorstartupchecked. SamecameraStudio~60FPS, endmemory+121.58MBincludingbuild/test. Next12-14afterfreshmemorycheck.

2026-10-26: ALL39TowerAapartmentfloorlayouts nowcopied/furnishedandstairconnected (156apartments). Added28floorswith120actual22percentascentwaypointsPASS, freshstartup39PASS. Appliance-use/mobile/multiplayer/visualacceptance pending; other towersnotfinished. SeeRemainingApartmentsplan/results andlateststatus.
