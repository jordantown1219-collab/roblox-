# Streaming Conversion Changes

Audit: October 22, 2026, America/New_York. Targeted source fixes for existing streaming-enabled city; automatic broad conversion was not run.

## Workspace Properties
Read-only Studio baseline: StreamingEnabled true; 52 models, 14,805 BaseParts; 30 Nonatomic and 22 Persistent models. Existing radii retained. StreamingMinRadius read returned an API-member error; no live settings changed.

## Asset Relocations
None.

## Model Structure Refactoring
None.

## ModelStreamingMode Changes
None. Preserve persistent staging and landing pads and nonatomic sectors; no giant atomic city.

## LevelOfDetail Changes
None.

## Script Anti-Pattern Fixes
- StarterPlayer.StarterPlayerScripts.RiverfrontClient: handle prompts arriving after tagged nonatomic models via DescendantAdded. Disconnect listeners and delete cached models on stream-out; reattach on stream-in. Guard stored model accesses with Parent checks. React to Range and player Scale changes.
- RiverfrontClient replicated-package/module and PlayerGui waits have 15-second bounds and warnings. No per-frame geometry scans added.
- ServerScriptService.SmallSignalsServer: prefetch before teleport. Door/transit revalidate round, membership, stage, and downed state after yielding. Loading blocks further gameplay actions. Balance untouched.

## Prefetches and Replication Foci
- New ServerScriptService.WorldLoading: server Player:RequestStreamAroundAsync(destination,4), temporary root anchor, per-player pending guard, cleanup on error, character identity and caller cancellation checks. No new remotes or client-selected destination.
- Client loading label uses RiverfrontLoading; RiverfrontLastPrefetchMs records request duration. Existing client FPS/worst-frame/memory measurements retained.
- Prefetch completion cannot guarantee all requested content. No permanent replication foci added.
- Official references: https://create.roblox.com/docs/workspace/streaming/techniques and https://create.roblox.com/docs/reference/engine/classes/Player

## Validation Fixes
Studio loadstring compilation passed for all three edited source files. Five isolated mocked module checks passed: success; cancellation; API-error cleanup; duplicate rejection; missing character. No live instances created and no Play-mode change.

Bundled-runtime full discovery ran 14 tests: 12 passed; embedding failed because v0.11 place was not built yet, geometry budget failed (64,124 parts versus existing 20,000 maximum). These concurrent integration issues are assigned to the parent integrator. Existing InteractionRules (18 assertions) and Rules (23 assertions) passed.

New focused tests/test_loading.py passed with bundled Python. It executes the actual spawn function against mocks and proves failed prefetch places the same player in persistent staging, equips and shields them, attaches death recovery, retains membership/checkpoint/stage, releases the spawn guard, and bypasses prefetch for normal lobby spawns. Initial system-Python run was unusable due to incompatible temporary shapely/lupa binaries.

## Warnings / Manual Review
Integrator must include WorldLoading.lua directly under ServerScriptService in build and Rojo trees (script.Parent.WorldLoading). Spawn failures/cancellation use persistent lobby with protection and equipment, retaining membership and checkpoint. RiverfrontSpawnRecovery marks fallback. Match progress is preserved; automatic retry into the city is not added. Server action reentrancy is blocked while loading, and per-player pending requests reject overlapping operations. Door/transit validity uses captured round/member/stage and current downed status after the yield. Final Play checks pending: deployment, respawn, all signal stages, district transit, round/death cancellation, prompt stream-in, network and low-memory devices. No measured FPS/load-time improvement claimed; runtime baseline unavailable while parent edits live geometry.
