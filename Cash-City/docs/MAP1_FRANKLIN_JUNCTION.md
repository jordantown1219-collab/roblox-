# Beaubien/Franklin road detail pass - 2026-10-25

Added35 noncolliding detail parts at the mapped junction near(368.134,.55,-234.129):3crosswalks(8/5/7stripes),3approach stop lines,3original service-cover assemblies(outer/inner discs and2slots each). Geometry follows source ways8759335/52637838 and actual rendered pavement. Marking positions/two-way assumptions/cover locations are artistic estimates, not surveyed current traffic markings. Existing roads, sidewalks, structures, park and landmarks unchanged.

Initial complete-streetscape candidate failed once because the source junction offers no four safe sidewalk fixture sites. Read-only ground-building and wider-land checks confirmed the constraint. No sign/light geometry was installed there; the completed batch is road markings/covers only. Safe fixture design remains a separate future review. Existing Atwater signs/lights are retained.

All315native center/edge/corner pavement rays PASS before insertion. Native build35parts/6round cover discs PASS; allanchored/no collision/query/touch/shadows. Cover layers vertically separated, no coplanar duplicates or physical snag surfaces. Shared street builder now accepts a plan; existing default Atwater data is byte-semantically unchanged and generated wrappers reuse the same consumer.

Fresh Play runtime confirmed Atwater37parts/8signfaces/2lights, Franklin35parts, park65parts/4Seats/4lights. Play stopped, no player movement/resizing/camera overrides. Both saved plans deterministic; existing all-source Lua syntax test PASS0.053s. No fullmatch/fullsuite/device/FPS/visual-acceptance claim. New selection Workspace.DetroitCityPreview.Map1FranklinCrossing framed Edit.

Files: extended tools/generate_map1_road_markings.py with --junction option, new data/map1_franklin_plan.json and src/Map1FranklinDetails.lua; generated shared Map1RoadMarkings.lua updated; oneArena hook andbuild/Rojo/embedding mappings. Native source checks used fresh ModuleScript to avoid Edit require-cache staleness. Rollback: before2129332,work/agent_checkpoints/franklin_junction_20261025,ServerStorage.RoadMarkingsBeforeFranklin_20261025 andArenaBeforeFranklinJunction_20261025.

Localsave verified:724469bytes,modified2026-10-25 18:38:18America/New_York,SHA256A18EC83D4EA1FF837E2DE670D4527C2385777C62585DFB5775527077766659F9. CorrectlocalStudio847a66df/window1442798, cloudcopyolder. Currentbinary+immutablecheckpoint backedupGitHub. No separatepostsave diskreload, olderXMLstale. Nohelpers/paidfallback/publish.
