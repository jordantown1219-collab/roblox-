# Wintergarden Step1 independent QA

Scope: approved Wintergarden slice only. QA owns this document and `tests/STUDIO_WINTERGARDEN_CHECK.lua`; no production geometry, source, builds, live Studio or other test files. Final generator plan was read before completing the harness. Call fresh harness result `(integratedRoot, decodedPlan)` after Lead integration.

Source419447156 is an anonymous `building:part=yes` glass perimeter correlated with the historical operator map's Wintergarden. It is not explicitly named in OSM. Ten original glass facets run fromY0 to107.142857stud and existing Concrete triangular roof caps lie at that top. Source flat grade is an estimate. Curved glass roof, opening and furnished accessible interior are new original game approximations, not surveyed historic geometry. Source replacements must retain exact original records and recoverable originals; unrelated towers, podium, manual landmarks and source shoreline remain preserved.

## Existing interaction requirements

`BuildingInteractions.door` supplies anchored `Moving` model, `MotionPivot`, `Control` with ProximityPrompt, Motion/Axis/Travel/Duration/Range, and SSInteractable tag. Assemble and parent complete tagged assemblies under the final root **before** `InteractionRegistry.start(root)`. Registry scans current tags and listens for tag addition; it does not watch arbitrary DescendantAdded reparenting of already-tagged models.

Real city doors must retain production authorization: arena `MatchActive==true`, non-neutral player, alive, not Downed, optional Team attribute matching player team, scaled interaction range, unobstructed LOS, cooldown and safe swept volume. `LobbyInteraction=true` bypasses match/non-neutral gating and must not be set on production Wintergarden merely to make a test convenient. An explicitly isolated keyboard fixture may use it with Lead authorization; that proves only fixture input, not production match permission.

Registry sweeps test13 motion samples, external collidable geometry and explicit actual character roots. Door state is shared server-owned. A physical blocker test across scales1/.65/.40/.22 is useful but is not actual avatar interaction or simulated multiplayer acceptance. Separate live-match input, reach/LOS, moving-character obstruction, concurrent users, touch and controller testing remains required.

## Planned checks

Prepared11 native checks use the actual three routeSamples, declared entrance approachPoints, roof springline/peak and exact replacement guards. Archive checks require WG_SourceIndex identities, original pose/size/material/color, inactive archived geometry and original physics rollback attributes. Four route cases query grounded2x5x2stud body boxes scaled by1/.65/.40/.22; production closed doors are excluded explicitly, so this does not claim a walk through an open door. Both declared approaches require clear occupancy and level support. Roof rays verify overhead curved roof at the declared route points, not every roof seam.

Control-distance checks use a near-control point1.25stud on each side of the declared outward normal with root height2.5*scale. This verifies numeric scaled range, not actual prompt input or unobstructed path to that point. Door blocker checks clone production doors to an isolated distant Workspace folder, clone fresh Registry/Rules ModuleScripts, register complete assemblies, insert actual colliding solid2x5x2stud scaled parts into the mid-sweep and require rejection/recovery in both directions. Temporary fixture destruction disconnects registry listeners. Original root/doors are not moved or edited.

Final harness syntax parsed successfully offline. All native execution remains pending Lead. It cannot prove integration idempotence/manual-content preservation without the build factory and before-state; Lead must separately compare manual sentinel identities and repeat guarded generation. It also does not establish complete roof-seam coverage, real avatar navigation, crush safety, prompt input, multiplayer, device or FPS acceptance. Do not count synthetic scaled solid probes as actual scaled humanoids.
