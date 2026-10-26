# Residential access slice
1. Source-audit reception side exit, lower connector and lift shaft.
2. Split only intersecting walls/roof/floor; keep originals with rollback flags.
3. Prove exterior surface area is unchanged by clipping.
4. Add guarded lower bridge and upper landing.
5. Build server-owned two-stop lift with gated landings.
6. Validate caller distance/alive/line of sight and serialize requests.
7. Carry only occupants within the car; restore their movement state after travel.
8. Keep construction access Studio-only until acceptance.
9. Test geometry first, then lift movement and passenger behavior.
10. Record native evidence and remaining device/multiplayer tests.

## 2026-10-26 - Residential stair connection native walking checks PASS
Added source-contained four-flight stairs from lobby bridge Y36 to residential floor Y80. 166 generated parts, 88 half-stud risers, 4.5-stud lanes, five landings, continuous guards and an upper-opening barrier. Branch deck subtracts old bridge/landing floors to avoid coplanar overlays. Four guarded originals retained: podium roof, two effective structural floor wedges, one bridge guard. Exterior area reconstruction errors below 1e-5; source tower inset containment passes. Existing lift shaft remains cut out.
PASS: reused native Humanoid walking fixture, 12 waypoints per run: 22%, 100%, 40% ascending; 65% descending; health100 throughout. Separate initial22% flight passed. Fresh Play builds stairs via Arena. Temporary probes/template removed. Source syntax test passed. Rojo project generation exited0; model exports originate from legacy XML and are NOT a current saved-place checkpoint.
Edit preview installed and framed; raw ServerStorage template intentionally remains unchanged because Arena builds interiors at runtime. Initial attempt to apply stairs directly to the raw template failed its source guard (no residential floor there); preview had already succeeded. No second blind retry; corrected integration through existing Arena pipeline. Generator first attempt hit missing optional label on replacement records; fixed .get and regenerated successfully.
Files: tools/generate_residential_stairs.py; data/residential_stairs_plan.json; src/ResidentialStairsData.lua; src/Arena.lua; tools/create_rojo_project.py; scripts.project.json; full.project.json. Rollback source copies: work/stairs_preintegration_20261026. Existing geometry originals remain hidden with ResidentialAccessOriginal attributes. No deletion of completed geometry.
UNVERIFIED: visual acceptance, two directions at every size, real player/device/multiplayer route, current performance, lift monitored round-trip/passenger/security acceptance. User observed lift movement; immediate snapshot was lower stop, so no full lift PASS claimed. Stairs are an independent tested route, not a claim the entire residential tower is finished.
Working place and GitHub remain UNSAVED since b70c36e per current no-save/no-push instruction; local source/data/docs written. GitHub fetch still b70c36e. No publishing/helpers. Included usage checked17% used, credits15.8363397500 unchanged. Next map work: finish stair enclosure/lighting and upper residential access appearance, preserve existing working interactions.

## 2026-10-26 - Residential stair enclosure and landing finishes
Added src/ResidentialStairFinish.lua and Arena integration: 38 anchored parts, five shadow-free low-brightness SurfaceLights, original generic landing signs, metal frames and glazed enclosure. East side retains both bridge and residential entries. Tested structural stairs and retained originals unchanged. Finish geometry lives in separate ResidentialTowerA_StairFinish model; no existing model replaced.
PASS: Lua source syntax; fresh native Play created38parts/5lights; existing22percent Humanoid fixture passed12waypoints bridge->fourflights->residentialcorridor,health100. Probes/template removed after check. Edit framed for user visual inspection. UNVERIFIED: visual acceptance/currentFPS/device/multiplayer and lift roundtrip. No performance-improvement claim.
Updated Rojo mappings directly; did NOT run legacy XML asset regeneration or full map build. Pre-integration source/mapping copies in work/stair_finish_preintegration_20261026. GitHub fetch unchangedb70c36e. Local source/docs saved; place/GitHub remain unsaved under current instruction. No publishing/helpers/paid-credit action.
Next: residential upper access/corridor finish and readability; preserve existing apartment doors/windows. Do not resume Wintergarden door work.
