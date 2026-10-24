# CC-002 block generator QA

Four offline tests passed using the bundled Python runtime and Lupa on this run. These execute the generator's real validation code with minimal mocks. They cover invalid batch limits, invalid IDs, manual-content refusal, and release of the lock after invalid geometry. They do not simulate Instances, rendering, physics, or multiplayer.

The Lead executed `tests/STUDIO_BLOCK_GENERATOR_ADVERSARIAL.lua` against the candidate module: **9 of 11 native cases passed**. Sparse and dictionary plans failed their rejection/preservation requirements. The Lead is implementing dense-array validation; a post-fix native rerun is pending. This harness creates and cleans up one temporary ServerStorage folder; it does not modify the city. It returns all case outcomes instead of stopping on the first failure.

Native cases executed by the Lead: ownership collision; invalid size; nonfinite position; reflection matrix; missing template; sparse plan; dictionary plan; oversized template; same-block concurrency with independent-block progress; late staged failure recovery and lock release; large-template batch budget and Heartbeat yields. QA did not independently operate Studio.

## Confirmed defect awaiting regression rerun

`CityBlockGenerator.build` accepts any table as `records`, then iterates only its contiguous numeric prefix using `ipairs`. A sparse plan such as `{[1]=validRecord,[3]=validRecord}` silently omits record 3. A dictionary such as `{road=validRecord}` becomes an empty plan. If rebuilding a generated block, either can replace completed content with an incomplete or empty model.

Exact native reproduction is included as cases `sparse records rejected` and `dictionary records rejected`. Expected: reject malformed plans, keep the previous block, leave no staging model, release the lock. Both failures were confirmed in the Lead's native run. Do not remove or weaken those assertions to obtain a passing report.

## Additional native cases for Lead integration

Only this document was changed in the followup, respecting the explicit file restriction. Add these cases inside the existing harness before cleanup, using its existing `test`, `primitive`, and `reject` helpers:

```lua
test("mixed array and dictionary records rejected",function()
 reject("MixedKeys",{[1]=primitive(),road=primitive()})
end)
test("nonpositive and fractional record keys rejected",function()
 for _,key in ipairs({0,-1,1.5}) do
  local records={primitive()} records[key]=primitive()
  reject("InvalidKey",records)
 end
end)
test("nonnumeric string index rejected",function()
 reject("StringIndex",{[1]=primitive(),["2"]=primitive()})
end)
```

Also retain a valid dense-plan regression, and explicitly decide whether a genuinely empty ordered plan is an approved block-clearing operation. Do not accidentally reject valid plans based on table iteration order. Count entries and validate that every key is an integer in `1..count`; Lua's `#` alone is not a reliable sparse-table validator. Table records mutated during generator yields remain a separate risk: caller ownership/immutability should be documented or the validated plan should snapshot every field later consumed during construction.

## Source provenance: pending contract and acceptance

The current generator ignores `record.meta`; therefore source OSM metadata retention is **not implemented or tested**. Do not mark provenance accepted solely because geometry matches. Before integration with source-map records, define the metadata contract with the City Builder (for example OSM type, OSM ID, source feature ID, building classification, and accessible-interior flag). Once names/types are agreed, add a native test that generates a source record, checks the documented attributes on the resulting object, rebuilds that block, and verifies metadata remains identical while neighboring objects retain identity. Do not invent attribute names in a passing test or silently drop provenance requirements.

## Acceptance limits

Passing these cases establishes bounded construction and recovery behavior only. It does not establish client FPS gains, safe execution of arbitrary template scripts, multiplayer functionality, or city integration. Existing tests and the original Studio acceptance harness remain applicable.

No source fixes, shared build changes, live Studio mutations, asset purchases, or subagents were used by this QA worker.
