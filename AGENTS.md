# Cash City: rules for Codex (read this first, it is short on purpose)

Project folder: `Cash-City/`. Read `Cash-City/START_HERE.md` for the current goal.
Do NOT read the long status docs unless the task says to.

## Save credits
- Smallest change that works. One task at a time.
- Open only the files the task names. Do not scan the whole repo.
- NEVER open, search, grep, or print these (huge):
  - `*.rbxlx` (place files, ~50 MB each) and `checkpoints/`
  - `data/geometry.json`, `data/osm_raw.json`, `data/detroit_geography.json`
  - `data/city_blocks/*`, `data/river_raw.json`
  - generated data modules: `src/RenaissanceData.lua`, `src/WintergardenData.lua`,
    `src/CivicFacadeData.lua`, `src/RenaissanceLobbyData.lua`, `src/RiverAccessData.lua`
  - `docs/DEVELOPMENT_STATUS.md` (46 KB) unless told to
- To change a generated data module, edit its generator in `tools/` and
  rerun that one generator. Don't hand-edit or read the output.
- Do NOT rebuild the whole map unless I ask. Run only the one generator
  and the one test for the thing you changed.
- No helper agents for small tasks.

## Credits and testing
- One task per session. Finish it, save to GitHub, stop, and report.
- Never use paid credits unless I say so for that specific task.
- Test ONE size (22%) and one route per change, not every size and route.
- Don't claim progress I can't see. Always say exactly where to look in Studio.

## Stop wasting time on errors
- If a command or test fails TWICE, STOP and tell me: what failed, the
  error, and your best guess. Do not keep patching.
- Do not write new test harnesses, screenshot tools, or capture workarounds.
  White MCP/screen captures are a capture limitation, not a map bug.
  I check visuals in Studio myself.
- Never weaken or delete a test to get a pass.
- Before editing, say in 2-3 lines: files you'll change, and how I check it in Studio.
- After the change, report in 5 lines or less: what changed, what you ran,
  what I should look at.

## Safety (from earlier decisions)
- Never publish the game. Never close or kill Studio.
- Back up the current place before any rebuild.
- Keep shrink scales 1 / .65 / .40 / .22, speed 16, and existing
  health/damage/armor balance unless I ask to change them.
- Don't invent a git identity or change global git config.
- Ask before: stairs, roads, RiverWalk, edges, Step 2, lobby/voting/modes/other maps.

## Where things are
- `src/`: runtime game code (Lua). Hand-written files are small and safe to open:
  `Arena.lua`, `ArrivalLounge.lua`, `Wintergarden.lua`, `RenaissanceLobby.lua`,
  `InteractionRegistry.lua`, `SmallSignalsServer.server.lua`,
  `SmallSignalsClient.client.lua`, `SmallSignalsHUD.lua`, `Config.lua`, `Rules.lua`.
- `tools/`: Python generators that make the data modules and place files
  (e.g. `generate_wintergarden.py`, `generate_arrival_lounge.py`,
  `generate_rencen_lobby.py`, `generate_river_access.py`).
- `build.py`: assembles the place. Slow. Only run when I ask.
- `tests/`: `test_*.py` are fast offline checks (run just the one for your area).
  `STUDIO_*.lua` run inside Studio; only run one if I ask.
- `docs/`: notes. Look up by name only when needed.
- `paused/`: archived lobby work. Ignore.
- `tasks/plan.md`, `tasks/todo.md`: short task lists.
- Hard-won lessons: `docs/LESSONS_LEARNED.md` (short, skim once).

## User-designated Obsidian workflow (2026-10-26)
Read D:\cash city\roblox\Roblox\Cash City\START HERE.md and WORKING RULES.md for current Cash City continuity, then verify repository handoff/status and GitHub. Current direct human instructions take priority; other games and historical notes do not authorize actions. See docs/OBSIDIAN_WORKFLOW.md.
