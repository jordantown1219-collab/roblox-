# Cash City development-speed inspection and first optimization

## Preservation
v0.12 remains unchanged as the rollback checkpoint, including its source, data, art, generated place and exports. Its place SHA256 is CA8B70FADFF6E5138D6EE101BA06AD0CA6858981784E514237463AB966E12BDB. Work continues in the separate v0.13 folder. No map shrink, landmark replacement, gameplay rewrite, purchase enablement or publication.

## Existing work
Detroit OSM footprint/shoreline and 30-sector foundation; joined road/walk/plaza layers; staging/spawn/loading recovery; shrinking and scale gates; queues, voting, team extraction; reusable authoritative interaction registry; weapon/armor/combat rules; parked/driveable SUVs; landmark interpretations; movable HUD and appearance preview. Solo and offline checks cover subsets. Vehicles, detailed city/interiors, animations, multiplayer, real-device controls and performance are not fully accepted.

## Three biggest bottlenecks
1. Whole-district geometry and XML/export pipeline. generate_geometry.py always scans/builds every source feature and rewrites geometry.json. build.py embeds both server storage and edit preview; create_rojo_project.py re-parses the full place and rewrites large model assets. There is no per-block Luau editor generator in the existing project.
2. Coarse Studio transfer/startup: about50.44 MB place and19,965 geographic primitives. Arena.build clones the complete city subtree in one operation. Prior live imports needed50 bounded source transfers. This is structural evidence of coarse work granularity; build-time speedup has not been benchmarked.
3. Slow validation: repeated local samples approximately9-10 FPS even with106 loaded lobby parts; low graphics did not help. Prior profile identifies presentation delay as dominant. Three Studio processes remain, two without visible titles. Exact root cause and standalone performance unresolved.

## First safe optimization implemented
src/CityBlockGenerator.lua is a dormant editor/bake utility, not a runtime replacement. build(parent,{id=...,records=...},templates,batchSize) accepts ordered existing primitive records (name/cls/size/pos/matrix/color/material/collide/trans), or template records (template/name/pos/matrix). All positions are studs, matching geometry.json. Same inputs reproduce the same transforms; no random global state. Templates retain cloned descendants, prompts, attributes and reusable mesh references. Do not supply active per-object Scripts; use the existing centralized InteractionRegistry contracts.

Use a dedicated generated-block parent, and select records for one source sector. For example: Generator.build(blockRoot,{id="Sector_Test",records={{name="Walk",size={12,.2,40},pos={0,0,0},material="Concrete",color={158,155,146}}}},{},100). Existing real street footprints must come from geography records, not rectangular replacements. Templates are trusted authored Model/BasePart instances supplied by the caller. Accessible building interiors and parameterized architectural templates are subsequent slices, not implemented by this first utility.

Only previously owned blocks can be replaced. A manual-name collision fails. Same-block overlapping calls are rejected. Plans validate before replacement, large plans yield every400 records, templates are capped at400 descendants including root, and batch size adapts to the largest template subtree. New content is staged; old owned content is removed only after all batches succeed. Exceptions destroy staging and release the lock. Existing landmarks and other blocks retain identity. Generate into ServerStorage for editor baking so incomplete staging is not visible or collidable.

No city-wide runtime activation has been added. Existing live systems and layout remain. Full-city clone optimization, dataset export/editor workflow, building/window/prop templates and reusable accessible interiors remain next steps.

## Engine test
First missing-module test failed as expected. Final module tested in a temporary ServerStorage folder:120 records,3 batches,2 observed heartbeat intervals,0.3049 seconds. Tested deterministic positions, owned-block replacement, preservation of another block and landmark, preservation of a cloned prompt/motion attribute, missing-template recovery and refusal to replace a manually named model. Temporary content removed. This is a workflow test, not a before/after speed or FPS improvement claim.

Initial offline embedding check caught a source/build mismatch after the final validation-yield edit. Rebuilt the place from final source before rerunning. Record final suite outcome in HANDOFF.md. Device/controller and multiplayer tests remain pending. No persistent profiler is running.
