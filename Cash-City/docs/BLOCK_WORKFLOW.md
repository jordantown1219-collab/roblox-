# Independent Detroit block export

`tools/export_city_blocks.py` reads the existing `data/geometry.json` without changing it. It writes one deterministic JSON plan per existing source sector under `data/city_blocks/`. This is an editor/bake preparation step; it does not rebuild or mutate the active city. Existing manually constructed landmarks and separately stored art are outside this export and must remain outside the generated-block parent.

Export all sectors with `python tools/export_city_blocks.py`. Export only one with `python tools/export_city_blocks.py --sector=-1_0`; repeat `--sector` for multiple selections. `--source` and `--output` allow a scratch export for review. Run only one exporter against a given output directory at a time. Existing temporary files cause a safe failure rather than overwriting another writer's staging file. No output files are deleted, including obsolete sectors or unrelated hand-authored files.

Each file contains `id`, `records`, `schemaVersion`, and `sourceIndices`. IDs use `Sector_` plus the unchanged source sector, such as `Sector_-1_0`. All source records retain their original fields and numeric precision, in their original within-sector order. `sourceIndices` are zero-based positions in the original full geometry list, so merging all exported records by these indices reconstructs that list exactly. They are provenance, not persistent object IDs; inserting source records changes later indices. Stable source order and canonical JSON key ordering produce identical bytes on repeat export. Byte-identical output is skipped, preserving its modification time. Selecting one sector never writes other sectors.

The current Luau integration interface is:

```lua
local block = game:GetService("HttpService"):JSONDecode(jsonText)
local model, stats = CityBlockGenerator.build(generatedBlocks, block, {}, 100)
```

`jsonText` must be supplied by the Lead's approved import/bake path; local JSON files do not automatically appear inside Roblox. Do not point this at a parent containing an existing manually authored child with the same block ID. The generator refuses that replacement. Import and placement in the actual map are pending Lead integration and Studio validation.

Current primitive fields consumed by CityBlockGenerator: `cls`, `name`, `size`, `pos`, `matrix`, `color`, `material`, `collide`, `trans`. It also supports explicit `template` references, but these exports preserve existing primitives rather than inventing template substitutions. Source `sector` and `meta` remain in each record but are currently ignored by the generator. Block `schemaVersion` and `sourceIndices` likewise are not consumed. In particular, metadata is not yet applied as Roblox attributes or interaction tags. Preserve it until an explicit adapter is implemented; do not assume exported doors/windows acquire working interactions merely from their metadata.

This first exporter supports the existing Part/WedgePart geometry only. It rejects unsupported classes rather than silently dropping meshes. Separately built vehicles, artwork, CityDetails and interaction systems are not recreated by these JSON plans. No claim of FPS improvement, active-map speed improvement, multiplayer functionality or device acceptance follows from export tests.

Focused checks: `python -m unittest discover -s tests -p test_block_export.py -v`. Tests cover exact reconstruction of real source geometry, primitive contract shape, repeatable hashes, unchanged-file skips, selected-sector isolation, source preservation and invalid-sector rejection before output creation.
