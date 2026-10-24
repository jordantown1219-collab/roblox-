# Map 1 Task 2 acceptance — 2026-10-24
Status: mechanical checks PASS; human visual acceptance pending. Map is not release-ready.
No production source/geometry changes in this run; existing perimeter candidate tested.

| Check | Evidence | Result |
|---|---|---|
| Perimeter/water collision sampling | 528 rays at 21 stations per side, five heights, and 3 stations x 3 heights per water blocker | PASS; no misses |
| Hidden exterior effects | Enabled GUI/light/particle descendants on archived exterior parts | 0 found |
| Actual player outside west | Studio Practice via normal client Practice remote; team Amber; position beyond minX | Returned to team spawn, health100 |
| Actual player fall | PositionY-12, below resetY-8 but above physical catch floor | Returned, health100 |
| Actual player above ceiling | PositionY1230 | Returned, health100 |
| 22% isolated avatar at north barrier | WalkSpeed16, JumpHeight7.2*.22, server-owned physics; walk+jump toward outside for3s | StayedinsideZ-547.714; blocked; health100; rig destroyed |
| Existing Wintergarden engine harness | Runtime assembly | 11/11PASS |
| Roof/lobby plan completeness | Actual part names/poses/sizes/materials versus current plans | Wintergarden183/183, RenaissanceLobby63/63 |
| Focused offline tests | test_playable_block.py | 5/5PASS1.505s |

The first Wintergarden check against the baked Edit preview returned9/11: it has preview door geometry and archive markers, not the runtime assembly. Repeating the unchanged harness against the actual runtime root passed11/11. Neither result is a real input or multiplayer test.

## Desktop sample
Single foreground contiguous sample10.017878s,601frames,59.992744FPS,p9518.365599ms,worst21.539399ms.
Camera held400/170/700 ->170/70/260 atstart/end. Viewport1593x710, qualityAutomatic, StreamingEnabledtrue.
Loaded9225BaseParts,44unanchored,engine memory2310.0117MB. Camera binding/measurement connection removed; prior camera restored. This is not a matched-baseline gain claim, low-end-mobile result, or multiplayer acceptance.

## Cleanup and remaining checks
Actual player's original character pose restored after reset tests; no scale/stats changed. Isolated rig and roof fixture destroyed. Play stopped, Edit restored. No publishing.
User visual answer pending on road-end screen appearance/concealment. All-heights aesthetic sightlines, real-device/touch/controller/multiplayer checks remain unverified. Task3/full match/all-route/device work not started here.
Budget updated by user: stop before90%USEDfivehour (10%remaining), no paidcredits. Lastread45%used, credits36.67015575unchanged.
