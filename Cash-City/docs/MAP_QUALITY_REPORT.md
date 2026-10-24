> v0.10 continuation: see docs/STUDIO_RESULTS.md for current native MCP and partial solo acceptance. Historical pending statements below describe v0.9; unchecked rows remain pending. Rojo live sync is still unverified.

# Map quality report — v0.9, 2026-10-22

This report deliberately separates generated implementation from engine acceptance. No FPS, multiplayer animation, city-interior or visual-fidelity target is marked verified.

## Geographic areas implemented
Mapped riverfront extent approximately 1.44 x .946 km: Hart Plaza, Renaissance Center complex, Detroit River shoreline/Riverwalk paths, Jefferson and Woodward approach plus neighboring downtown roads/building footprints. Uses 1,830 processed feature records from a 2,147-feature query and a separate riverbank relation query. Source positions retained; boundary and projection in SOURCES_AND_SCALE.md.

## Buildings and surfaces
14,780 geographic native primitives in 30 sectors. Footprints become polygon facade shells and triangulated roofs, including the source's separate RenCen body/cap/office sections. Roads and paths follow source centerlines. Land and water follow the clipped riverbank; geometry frames are numerically validated. This is an exterior massing blockout. Facade material variation is native Glass/Metal/Concrete, not a completed PBR asset pass. Generic floors, no surveyed terrain. Flat steps/tunnel omissions/bridge height estimates need repair before a real-world access claim.

## Accessible interiors
Original medium staging barracks only, outside the geographic district. The labeled interaction workshop is original test geometry inside it. No real Renaissance Center, Hart Plaza sublevel, hotel room or downtown office interior is represented as accurately reconstructed or fully explorable. Geographic building shells have no interaction prompts; architectural glass stays fixed.

## Implemented interaction candidates
- Original workshop hinged leaf: hinge pivot on its edge, frame clearances, 95-degree motion.
- Original workshop sliding pane: local X travel 5.4 studs, fixed neighboring pane/rails.
- Original workshop drawer: local Z travel -3.2 studs.
- Original unbranded parked workshop vehicle: opening driver leaf about its declared hinge and ordinary seated position. Not driveable. Hood/trunk/headlights/interior lights are not implemented.
- All use one tagged assembly registry, server distance/LOS/permission/alive/phase checks, cooldown/busy locks, overlap sweep checks, replicated server pivots/state and obstruction recovery at the last safe pose. Actual hinge/collision/seat behavior remains UNTESTED in Studio.
- Workshop has no sound assets; door/window/vehicle audio remains missing.
- No elevators, garage doors, breakable glass, automatic doors, double-door synchronization or light-switch system is claimed complete.
- Existing staged signal gates, district transit gates, size-matched armor and whole-team extraction are integrated but the new map is not runtime accepted.

## Scale compatibility
Current game scales remain 1/.65/.40/.22, world walking speed remains 16, health/damage/armor scaling preserved. Generic fixture prompt/server range adapts down to a 3-stud minimum. Stage gates retain existing size/order rules. No new growing mechanic is added. Minimum/default/maximum currently supported scales are .22/1/1. Larger future growth is unverified.

## Tests completed
TDD red phase recorded: interaction spec initially failed because InteractionRules was absent; geography spec initially failed because citygeo was absent. Then 18 pure interaction assertions and 7 geography tests passed. Four build checks passed (Lua syntax, source-land/building clearance for 24 anchor/arrival positions, finite positive dimensions/orthonormal geometry frames, XML unique references and exact script embedding). Existing 23 rule assertions and lobby close/reopen/queue/vote visibility checks passed.
These validate data and logic, not Roblox physics, actual streaming, line-of-sight APIs, animation alignment, or multiplayer synchronization. Exact engine tests are in tests/STUDIO_ACCEPTANCE.md.

## Performance
Measured: 14,780 static geographic primitives, 30 sectors, generated place ~36.8 MB XML. Configured: StreamingEnabled true, min radius 256 / target 768 studs, nonatomic geographic models, small persistent landing pads and persistent staging room. Local client exposes 5-second sample FPS, worst-frame milliseconds and client-memory attributes for measurements in Studio/private servers.
NOT measured: phone/tablet/PC/console FPS, server frame time, memory peaks, join/stream latency or network load. No 30/60 FPS claim. Primitive budget 20,000 is an offline project guard, not evidence of mobile performance. Further mesh reuse/LOD and world-detail reduction must follow actual measurements.

## Installation
Standalone .rbxlx generated, source files and raw/derived geography included, build command provided. Rojo 7.7.1 CLI and local Studio plugin file installed; code/full sync projects generated. Code-only Rojo build validated. Studio toolbar connection and complete playtest are NOT verified. No publishing/account changes. Prior v0.8 and earlier folders preserved; baseline place and SHA recorded in build_manifest.json.

## Main remaining problems and assets
Surveyed terrain/road grades, verified real entrance/stair/ramp locations, true architectural detailing, accessible measured interiors, elevators and remaining interaction types, legally sourced/original PBR meshes/textures, interaction/environment audio, realistic parked fleet, animation/collision engine tests, stream-in/out tests, multiplayer combat/routes/balance and physical device QA. Current protected plaza art and corporate branding are intentionally omitted rather than copied. ArcGIS data reuse terms were insufficiently clear, so that dataset was not incorporated.

## Phase status
1 inspection/research: completed for this candidate scope.
2 coordinates/boundary: implemented, source-backed; local projection limitation documented.
3 roads/ground/footprints: implemented blockout; real elevation/width/stair surveys incomplete.
4 landmarks/exteriors: source massing implemented; detail/fidelity incomplete.
5 authentic accessible interiors: not completed.
6 reusable interactions: initial workshop candidates implemented; engine acceptance and remaining types incomplete.
7 shrinking integration: code integrated; engine acceptance pending.
8 high-fidelity visuals/audio: not completed.
9 sectors/streaming: configured; measured optimization pending.
10 tests: offline checks passed; engine/multiplayer/device tests pending.
11 integration: installable candidate and sync setup supplied; live Studio acceptance pending.
