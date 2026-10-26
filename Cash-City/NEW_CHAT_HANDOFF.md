# Cash City resume — 2026-10-25

Project: `C:\Users\jorda\AppData\Local\SmallSignalsProjects\Detroit_Riverfront_v0_14`
Working place: `CashCity_RiverWalk_Section2.rbxl`.
GitHub: https://github.com/jordantown1219-collab/roblox- under `Cash-City/`.

Read HANDOFF.md, START_HERE.md, latest DEVELOPMENT_STATUS.md, docs/LESSONS_LEARNED.md and AGENTS.md. Check GitHub for newer edits before changing local work. Old XML and older cloud copies are not authoritative.

## Current scope
Finish Map 1: Renaissance Center, Wintergarden, RiverWalk and park. User expanded scope to complete public interiors and all tower/apartment interiors as an original fictional residential conversion. No other district, lobby system or new mode now. Never publish without approval.

## Recent progress
RiverWalk planting, railings, trees, benches, park approaches and Franklin markings were added. Two raised road triangles were clipped out of the atrium; their exterior area is exactly preserved and original parts retained. Atrium floor inlays and public reception/circular-lobby finishes were added and checked. Reception walking at 22% passed four waypoints with full health.

Older stationary desktop RiverWalk sample: 60.008 FPS, p95 18.528 ms, about 2404 MB client memory, streaming enabled. This predates the latest interiors and is not mobile or multiplayer acceptance.

## Latest apartment work — unfinished
`ResidentialTowerA_Level01`, source OSM 419447155 within outer tower 419447174, floor Y80. Only level 1 exists. Four apartment shells, floor, ceiling and bedroom/bathroom partitions: 96 parts. Source containment, syntax, fresh Play, 16 floor checks, 16 headroom checks and one 22% living-area route passed. Existing tower exterior unchanged.

Last addition: 29 basic furniture parts in apartment 01, including two native sofa Seats; 125 total records. Edit construction and deterministic generation passed. **The final 125-part version still needs fresh Play and walking validation.** Appliances are static drafts. Doors, working windows/appliances, other apartments, stairs/elevators and public access remain unfinished. Construction phase: `INACCESSIBLE_INTERIOR_IN_PROGRESS`. Do not mark this floor complete or open it to normal play yet.

Next: validate the 125-part build, complete apartment 01 and the other units, then build working vertical access before opening this tower. Reuse the data-driven floor generator one level at a time.

## Execution rules
Continue automatically after relevant checks pass; user does not want to type Next for each task. No helpers unless asked. Stop a flow after two failures. Reuse existing fixtures, and avoid new test/capture harnesses. Do not return to repeated Wintergarden door work; its working door must be preserved.

No paid credits. User's current limit is a 1% reserve of included five-hour usage. Last actual reading: 99% used; credits 29.6661757500 unchanged. Check live usage before new development; do not assume a reset.

Preserve individual shrinking 100/65/40/22%, whole-team extraction, 3v3/4v4/5v5 and server authority. Device, real multiplayer, full-route and current performance acceptance remain pending.

## Studio and tests
Last local MCP ID: `847a66df-2e33-4cce-b51f-33f1d2e3f6ac`; rediscover IDs. Local Edit map is newer than cloud `downtown think` and the legacy hidden instance. Current camera is inside apartment 01, with furniture selected.

Existing `STUDIO_RENCEN_LOBBY_WALK.lua` can be reused with a temporary scriptless avatar clone named `CashCityLobbyRigTemplate`. Restore the original character's Archivable flag, set test WalkSpeed back to 16 after ScaleTo, and remove the probe/template afterward. Never scale a seated rig. Use fresh ModuleScript clones after Source edits to avoid require-cache mistakes. Preserve normal Play camera control.

User explicitly requested this GitHub save, overriding the earlier no-save instruction for this checkpoint. Canonical save verified: 763116 bytes; SHA256 `1A2BBA096616388611EA71CB26D7385F01BF53330D6EA7246BA2FB3643B3415B`. GitHub push must still be verified. This is a work-in-progress backup, not a release or publication.
