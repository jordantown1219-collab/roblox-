# Studio results — 2026-10-22

Native Studio MCP connected. Place1 preserved; v0.9 candidate opened separately.
R15 lobby loaded at scale 1, health 100. Lobby rendered; solo button opened vote and deployed to Detroit with carrier rifle. Three gate prompts operated with ordinary E input. Stage/scale/max health/max armor: 1/.65/80/48, 2/.40/60/36, 3/.22/40/24. WalkSpeed 16 verified at stage 3. Test teleports used between gates: walking route/collision acceptance remains pending.

Extraction regression: v0.9 pad center Y=.1, footway top Y=.35. Camera ray to prompt hit footway and E could not extract. Runtime placement at surface + half pad height + .05 produced center Y=.475 for both teams. Normal E then showed Amber wins — everyone extracted. The same placement logic is now in v0.10 Arena.lua; rebuilt-file verification is recorded below when performed.

Warnings: asset 203785492 type mismatch repeated; pre-play animation-export plugin warning. No project script stack trace observed during this smoke test. Cause of asset warning remains unresolved.

One lobby diagnostic sample: 60 FPS, worst frame 20.2 ms, client memory 1831 MB. This is not a route benchmark or physical-device acceptance.

Pending: full walking routes, city-wide visual checks, workshop motion/collisions/obstructions and seat tests, transit, armor/combat, six-client synchronization/team victory edge cases, real devices, Rojo live sync. No publication performed.

## Rebuilt v0.10 verification
Opened SmallSignals_DetroitRiverfront_v0_10.rbxlx separately. Started Play, used solo button, waited for normal vote/deployment. tests/STUDIO_EXTRACTION_CHECK.lua passed for both pads without runtime placement edits. All three gates again advanced to .65/.40/.22 using E, with test teleports between them. Normal extraction E displayed Amber wins — everyone extracted. Stopped Play afterward, leaving candidate in Edit mode. All four offline test scripts and Rojo model export passed.
