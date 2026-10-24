> v0.11 design pass: read docs/DESIGN_PASS_RESULTS.md for current implementation and acceptance. Performance and detailed vehicle/art review remain incomplete.

# Small Signals — Detroit riverfront candidate v0.11

This is a geographically sourced exterior blockout and interaction-framework candidate, not the finished realistic city described in the master prompt. Actual Studio, multiplayer and device acceptance remains pending. Earlier project folders are preserved.

## Open in Roblox Studio
Open `SmallSignals_DetroitRiverfront_v0_11.rbxlx`, then Play > SOLO STUDIO TEST. The source preserves the current barracks, queue, carrier voting, HUD/settings, weapons, armor, stage shrinking, respawn and team extraction. A labeled original interaction workshop is in the staging room. The city is reached through the normal match start. `src/Config.lua` defaults to DetroitRiverfront; set ActiveMap to MonroeBlock and MapLabel to MONROE BLOCK to select the earlier compact map instead.

## Work in Studio and from source
Rojo 7.7.1 is installed locally in tools/rojo and its plugin was installed into the user's Roblox Plugins folder. See docs/STUDIO_SETUP.md. Code sync has been prepared; the Studio-side connection is not verified.

- `Start-Studio-Sync.cmd` serves scripts.project.json on 127.0.0.1:34872. Open the generated place first, then Studio > Plugins > Rojo > Connect.
- `Build.cmd` rebuilds the complete place from checked-in source/geometry and refreshes Rojo model exports. No network fetch is needed.
- Code-only sync intentionally leaves Workspace scenery and ServerStorage geometry unmanaged. It preserves unknown instances. It still owns the explicitly named script sources; disconnect before editing those scripts directly in Studio.
- `full.project.json` additionally manages the generated geographic models. Do not connect this to a place containing unsaved hand edits to those models.
- Studio edits do not automatically export to disk. Save a separate .rbxlx, or export your models into a separate studio_edits/ directory for review/merge. The sync bridge is source-to-Studio, not an automatic two-way editor.

## Geographic provenance
Data: © OpenStreetMap contributors, ODbL 1.0, https://www.openstreetmap.org/copyright . Raw query results, query text, derived geography and geometry are included. Read docs/SOURCES_AND_SCALE.md and docs/MAP_QUALITY_REPORT.md.
The district preserves mapped positions. Heights are source tags or labeled estimates; ground terrain is a flat local datum, not surveyed elevation. Protected logos, advertisements, textures and artwork were not imported.

## Build and tests
Python 3.11+ is sufficient for `python build.py` (checked-in generated geometry). Regeneration uses Shapely: `python tools/prepare_geography.py`, `python tools/generate_geometry.py`, then `python build.py` and `python tools/create_rojo_project.py`.
Dev requirements are in requirements-dev.txt. Tests:
- python tests/test_geography.py
- python tests/test_interactions.py
- python tests/test_regressions.py
- python tests/test_build.py
The Python tests add the session's temporary dependency directory if it exists, then use normal installed packages. Lua syntax/pure-rule tests are not Luau engine or physics tests. Studio procedures: tests/STUDIO_ACCEPTANCE.md.

## Major unfinished work
Surveyed terrain and road grades; confirmed sidewalks/entrances/stair dimensions; accessible real interiors; elevators; garage/automatic/double doors; interior/vehicle lights and audio; custom PBR/mesh assets; pedestrian/collision/streaming QA; real phone/tablet/console/PC FPS measurements; settings persistence; published private multiplayer tests. The Workshop fixtures are original test objects, not authentic RenCen interiors or city vehicles.

## v0.10 extraction fix
Extraction pads now follow the local city surface so pavement does not hide their line-of-sight prompts. Read docs/STUDIO_RESULTS.md for observed solo tests and limitations. v0.9 is preserved in its original folder.
