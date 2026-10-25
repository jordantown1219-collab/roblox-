# Park four-size navigation — centerline PASS / side-width FAIL

Canonical place untouched; SHA256 AE6AA260681DEAB439CF809D4FE6F3FA44FC0F072842355B70E8795418625E68. Before-run remote91d42a3 matched clean checkout; native before-place checkpointead0f68 preserved.

## Completed actual Studio tests
- Current avatar cloned into a fresh scriptless, unseated, server-owned Humanoid rig for each case.
- Existing STUDIO_RIVER_ACCESS_WALK.lua reused with ParkConnection's87route samples and scale parameter substituted in memory. No new harness/file or production code.
- All87waypoints passed at100%,65%,40%,22%:348completions in386.819332seconds.
- Rigs called native Model:ScaleTo, WalkSpeed restored16, JumpHeight7.2*scale; every sample required positive health and actual supporting-floor ray.
- These are physical navigation rigs, not a size-scaled health/damage or multiplayer test.

## Width defects found
Existing STUDIO_RIVER_ACCESS_FLOORS.lua reused with park route; yielded every200checks for responsiveness.9048floor/width probes and9048headroom probes.
Centerline traversal passed, but12side-width floor probes fell to SourceLandY-0.25 instead of expected pavingY0.41 (0.66stud drop). No headroom failures.

Two clusters:
1. NearX-605.3,Z785.6:2failedsamples on outside of route leg29.
2. NearX-1488.3,Z1163.5:10failedsamples on route leg84.

This is not full-width acceptance. Do not hide the failures by lowering expected heights, shrinking clearance or claiming the entire map passed.

## Cleanup and scope
All test rigs/templates/progress marker removed. Player, camera, door code and all map geometry unchanged. Play left running normally for user; no additional camera or keyboard commands.
No FPS improvement, phone performance, private3v3 or other-route acceptance claimed. Existing82offlinePASS remains separate evidence.

## Next repair
Inspect tools/generate_park_connection.py and its existing tests. Preserve completed160m RiverWalk, manual Hart path and existing new path records.
Repair only unsupported corner-width footprints on land, off roads, without coplanar overlays; regenerate via generator, not hand-editing generated module.
Add a regression for these exact width samples. After integration run the strict sweep and a bounded22%route check. Do not rebuild the whole map or repeat completed four-size cases without a new reason.

Full raw case/point/sweep results: Map1_Task6_PARK_WALKS.json.
