# Detroit riverfront design pass

User direction: preserve the current city layout; blend roads/ground without flicker; improve load smoothness; complete parked and driveable vehicles; realistic modern gun visuals; show edits in the visible Studio window. v0.10 disk files stay intact. Work is v0.11.

Build order: joined street surfaces -> bounded world loading -> city street detail -> complete vehicle -> modern weapon visuals -> engine acceptance. Each addition must have an end-to-end test before calling it complete.

| Capability | Acceptance |
| --- | --- |
| street-surfaces | Buffered source road/path corridors are joined before triangulation. Surface priorities remove overlapping same-height faces. Ground does not share top faces with roads. Source shoreline/positions remain intact. Intersection and riverwalk inspected from moving cameras. |
| loading | Retain streaming; no unbounded waits or giant atomic city. Record baseline and final measurements. Landing safety is verified with real client/server state. |
| city-detail | Street furniture, paving and road treatments follow reference photographs/Detroit guide; original estimated details labeled in source. Paths and game gate clearances remain usable. |
| vehicles | Matching original parked and driveable vehicle art. Driver entry/exit, forward/reverse/steering/braking, collision stability, lights, return/reset and scale restrictions checked. Doors/hood/interior and sound acceptance explicitly recorded. An unfinished prop must not be described as finished. |
| weapons | Realistic original rifle/SMG silhouettes, receiver/stock/grip/magazine/barrel/sights, correct muzzle and hand alignment at every supported scale. Existing server-authoritative damage/ammo/reload kept. Functional firing and reload visuals checked in Studio. |

Code: src/*.lua; offline geography/geometry: tools/*.py and data/*.json; tests: existing Python unittest/Lupa plus Studio acceptance scripts. Build: bundled python build.py, then tools/create_rojo_project.py. Re-run tests affected by each slice; complete suite after integration. Do not publish or overwrite unrelated Studio work. Native scripts/primitive geometry preferred; no opaque marketplace executable scripts. No new balance/persistence/monetization scope.

References (design reference, no copying branded artwork):
- https://www.detroitriverfront.org/map
- https://detroitmi.gov/departments/department-public-works/complete-streets/transportation-planning-resources/street-design-guidelines
- https://create.roblox.com/docs/workspace/streaming
- https://create.roblox.com/docs/performance-optimization/improve
- https://www.ford.com.pr/en/crossovers-suvs/explorer/design/
- https://www.colt.com/wp-content/uploads/2026/02/25-COLT-1930-COLLATERAL-2026-MLE-Catalog-RND7-FINAL-Paperturn-Single-Pages.pdf

Visual direction: realistic downtown material palette, dark asphalt, warm concrete, restrained markings, curb/planting separation, modern dark-metal firearms, unbranded contemporary Detroit SUV. No real landmark interiors invented as authentic.
