# CC-003 gameplay audit

Inspected October 22, 2026. Scope: existing v0.14 source, Config/Rules, README, current Studio acceptance checklist, and development status. No gameplay source, balance, build, or Studio object changed. Historical Studio acceptance was not rerun by this audit.

## Existing behavior and boundaries

- `SmallSignalsServer.server.lua:46` scales the triggering player's character absolutely, sets stage health, preserves health fraction on progression, clamps armor to the new stage cap, retains world WalkSpeed 16, and scales jump height. Stages 0–3 use avatar scales 1/.65/.40/.22, health 100/80/60/40, strength 1/.8/.6/.4, and armor 60/48/36/24 (`Config.lua`).
- `onDoor` at line 221 validates match phase, team, next stage, alive/not-downed/loading state, physical distance and line of sight. Destination preparation rechecks round/player/stage after yielding. It advances **only the triggering member's** stage/checkpoint; other teammates keep their existing stage. Respawns retain individual progression.
- Attack handling at line 344 accepts a finite target vector, then server-checks active membership, tool/carrier permission, cooldown, reload and ammunition. The server casts from the character head, determines the actual victim and scales damage with the attacker's configured strength. Friendly fire and spawn-protected attacks/targets are rejected. Melee reach scales with body size; firearm range currently does not. Armor absorbs damage before health; lethal accepted damage downs the victim before timed death/revive handling.
- Lobby readiness accepts configured team sizes 3/4/5; the server waits for twice the requested team size, orders by UserId and alternates Amber/Cyan membership (`begin`, line 393). This is readiness matchmaking rather than player-selected teams. Studio-only solo practice remains separate.
- The Vote phase elects one firearm carrier per team and allows Rifle/SMG preference. Candidates are sorted by UserId, so the lowest UserId wins equal/no votes. This is **carrier voting**, not map or match-settings voting. `Config.ActiveMap` selects Detroit or the existing legacy fallback through Arena; the requested two-large/two-medium/one-small map selection and category voting are still pending.
- Team victory requires every required teammate to reach stage 3, extract, remain connected and not be downed (`Rules.allFinished`; server `checkWin`, line 165). Extraction requires matching team, active match, correct stage and distance; the half-second loop clears extraction on movement away or blocked state. Disconnect reservations block victory for the 45-second rejoin window. Expired reservations are removed and no longer counted. An empty team cannot win.
- Match length is 480 seconds plus one 90-second overtime, then draw if no qualifying team has won. Results return players to lobby. Current winner/carrier fallback behavior and timers were preserved.

## Resolved team-shrinking rule

After this audit, the user explicitly confirmed preserving individual shrinking and whole-team extraction. No gameplay change is required. The historical ambiguity below is resolved by that confirmation.

The current design checklist explicitly requests **independent player shrink/progress** with whole-team extraction. The latest master instruction says every team member must follow the established team-shrinking rules, which could mean independent progress under shared rules or synchronized shrinking of all members. Source currently implements the former. There is no inspected approved specification establishing a synchronized-team transition, lagging-player teleport policy or size reset policy. Do not silently change this: preserve per-player progression and ask for a concrete decision if synchronized shrinking is intended.

Likewise damage is proportional to the **configured strength curve**, not directly to geometric size: the smallest .22-scale avatar has .4 strength. Current Rifle damage is 28/22/17/11, SMG 16/13/10/6, and Knife 40/32/24/16. Changing to linear avatar-size damage would alter existing balance and was not done.

## Focused automated evidence

Added `tests/test_team_rules.py`, loading the actual `Rules.lua` and `Config.lua` in the existing Lupa runtime. Six tests passed in 0.011 seconds using the bundled Python on this run:

1. All four stage tuning rows and all three weapon damage curves.
2. Every supported next-stage gate, wrong team, downed state and nonmatch phase.
3. All configured team sizes, each required teammate's unfinished/disconnected/downed/not-extracted state, and empty roster rejection.
4. Disconnect grace versus no-longer-required member and empty-required-roster rejection.
5. Armor/health damage conservation for every weapon/stage across empty, partial and full armor.
6. Owner/rival/teammate armor eligibility, stage mismatch and inactive ownership.

These are pure gameplay-contract tests. They do not execute the full server event loop or prove network security, movement, actual scaling/collision, aim controls, spawn safety, damage balance acceptance or multiplayer replication. Config exact-value checks deliberately preserve current balance; they are not a statement that current balance is final.

## Pending acceptance and next safe tasks

Run the existing six-client 3v3 acceptance procedure before calling team rules multiplayer-tested: split progression, gate races, enemy prompts, armor stealing, respawn/rejoin, carrier disconnect replacement, revive timing and whole-team extraction. Add forged-remote/rate/range tests in an isolated server harness. Test firearm and melee controls on actual PC/touch/controller. Inspect cancellation during gate destination preparation and simultaneous extraction/downs. Map/category/settings voting and player-selected team UI remain future features, not completed systems. No performance improvement or release-ready status is claimed by this audit.
