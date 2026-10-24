# Block generator mutable-input review

Initial production-source review of `src/CityBlockGenerator.lua`, with three native regression cases in `tests/STUDIO_BLOCK_MUTATION_CHECK.lua`. Following Lead authorization, the reviewer implemented the source fixes described below; no live Studio execution, builds or exports were performed by this reviewer. Native RED/GREEN results are pending Lead execution. These are caller-concurrency problems in an editor utility, not a demonstrated client exploit. Line references below describe the original reviewed source, before the fix.

## Implemented candidate fix

`blockId` is captured once and used for locks, lookup, attributes, staging and final naming. The entire dense primitive plan is validated and converted to private scalar/Vector3/CFrame/Color3/Enum values without yielding. No caller record references survive into insertion. `name` must be nil/string and `collide` nil/boolean. Arbitrary metadata is neither copied nor traversed.

Each unique source template is cloned once into private unparented storage before the first yield; source and private clone subtree sizes must be at most 400 instances. Batches clone only that private snapshot. All private snapshots are destroyed after the protected operation on both success and failure. Objects are parented into their unparented batch before property assignment so batch failure cleanup also covers partially configured objects.

Template completeness follow-up: every source descendant must also have `Archivable=true` before any clone is made. Roblox otherwise silently excludes that descendant (and a non-Archivable Folder's subtree). The generator rejects this input without modifying its flags or committing a partial replacement; this applies to Model and BasePart templates, including Attachments. It retains the existing 400-instance bound.

Before commit, the generator checks staged parent identity, previous block parent/name/generated ownership, and unexpected destination-name siblings. A concurrent external writer therefore causes staged rollback instead of silently replacing that writer's content. Same-ID generator calls still use the existing lock. This commit check is implemented but has no new native acceptance result yet.

**Cost:** input validation/snapshot is synchronous O(record count + unique template descendants), including up to about 20,000 records; there is no first-yield frame-time guarantee. This cost buys an entry-time input snapshot for ordinary non-yielding tables/Instances. Bounded insertion still yields once per batch, with template-adjusted maximum 400 inserted descendants per batch. Actual import latency and device rendering/FPS remain unmeasured for this change.

## Concrete source findings

1. **Block ID can change between lock and commit.** Lines 29–32 reserve the caller's original `block.id`; lines 97 and 100 reread the mutable table after batch yields. Changing `StableId` to `Manual` at the first yield commits a second child named `Manual` despite the ownership precheck and releases the wrong lock. The original block ID then remains locked. The test preserves a manual model and checks both committed identity and a subsequent original-ID build. Current source is expected to fail this case.
2. **Validated records are retained by reference.** Line 44 retains `record`; lines 80, 84–87 reread class, collision, transparency and name after yields. Mutating the second record while the first batch waits silently changes its baked result. A class change to `WedgePart`, collision false, transparency 1 and renamed part requires no invalid Roblox values and demonstrates the problem without relying on an engine error. Current source is expected to fail the immutable-snapshot expectation.
3. **Validated template subtree is not a snapshot.** Lines 48–51 cache a mutable Instance and its current descendant count; line 78 clones that Instance after yields. Adding 401 Parts after the first clone makes the second batch exceed the documented 400-instance bound. Current source is expected to fail both subtree bound and stable-template assertions. Destroying or making the template non-Archivable can also fail a later clone; the existing staged rollback should preserve the old block, but that separate failure path has not been executed here.

At validation's 400-record yield, the caller may also mutate unvisited records or the `block.records` table itself. Capturing only values as each record is visited does not establish an entry-time snapshot of the entire input.

## Smallest fix direction

Capture `local blockId=block.id` before reserving its lock and use that local for every name, attribute, lookup, commit and cleanup. Copy the entire dense records array and its consumed nested arrays before the first yield; validate/build only that private plan. Do not freeze caller tables. Validate and snapshot every consumed scalar including class/name/collision/transparency; the build loop must not reference the originals.

For templates, make a private clone of each unique referenced template before the first yield, validate clone descendants/Archivable and calculate budget from that clone; clone only the private snapshot during construction. Destroy snapshots on success and all failure paths. Keep these copies unparented. A synchronous snapshot is necessary for deterministic input; its upfront cost remains a separate performance limitation. Do not silently claim a per-frame bound for the snapshot operation itself.

Original rollback retained the original until commit when an exception occurred. That did not prevent successful commits with mutated inputs. External deletion/replacement/reparenting of the old block during yields is another writer-conflict risk; the candidate now checks this at commit as described above. That added guard is outside the three focused caller-mutation cases and remains unexecuted.

## Exact native runner

Lead installs the current `src/CityBlockGenerator.lua` as `ServerScriptService.CityBlockGenerator` ModuleScript in an Edit/Server context. Pass the **entire contents** of `tests/STUDIO_BLOCK_MUTATION_CHECK.lua` as `code` to native `execute_luau`, with the selected Studio ID. If using Studio manually, paste the test body into the server Command Bar wrapped as `print((function() ...test contents... end)())`; inspect the returned table using native MCP for detailed results.

The runner creates only temporary `ServerStorage.CashCityMutationQA` folders, uses `task.spawn` to pause each build at its first insertion yield, mutates the caller-owned input synchronously, awaits completion up to 10 seconds, and destroys each fixture. It does not touch Workspace, gameplay, generated production blocks or files. Run while other code is not manipulating these QA fixtures.

**Before fix expected:** `passed=0,total=3`, each case reports its corresponding snapshot/ID/budget assertion. These expectations come from source inspection and have not been measured in Studio. **After fix expected:** `passed=3,total=3`; also rerun existing `tests/STUDIO_BLOCK_GENERATOR_ADVERSARIAL.lua` to protect rollback, ownership, array validation and lock behavior. Multiplayer, rendering and device/FPS acceptance do not follow from these utility tests.

## Template completeness and ownership regression runner

Pass the entire `tests/STUDIO_TEMPLATE_COMPLETENESS_CHECK.lua` contents as native `execute_luau` code with the selected Studio ID, in Edit/Server with the current generator ModuleScript loaded. Same manual Command Bar wrapper as above applies. It uses only temporary `ServerStorage.CashCityTemplateCompletenessQA` folders and destroys its fixtures.

Three cases construct a non-Archivable Part, nested Folder containing a Part, or Attachment under a BasePart template. Each requires explicit rejection, unchanged original block/template, no staging residue, and a successful retry after the caller restores Archivable. Four additional cases mutate old-block generated ownership, name, parent, or insert a manual same-ID sibling while construction is yielded; each requires commit rejection, external-content preservation, no staging, and lock release on retry.

**RED expectation on snapshot-fixed source before this completeness patch:** `passed=4,total=7`. The three descendant tests fail because missing content is silently accepted; four commit-guard cases should pass. **GREEN expectation with completeness patch:** `passed=7,total=7`. This worker wrote the runner before the production patch but did not execute either version; Lead owns native RED/GREEN and reporting actual counts. These tests do not establish gameplay/multiplayer/device/FPS acceptance.

## Lead validation — 2026-10-23
Native current-source RED reproduced all three failures (0/3). Fixed candidate GREEN passed3/3 using isolated temporary ModuleScript. Existing native adversarial suite passed11/11. Focused offline generator suite passed6/6. Fixed source integrated into selected v0.14 Studio Edit model; disk place rebuilt separately. No gameplay or FPS acceptance follows. Commit external-writer conflict guard remains an additional check not specifically exercised by these three mutation cases.

## Lead completeness acceptance2026-10-23
Isolated prior sourceRED4/7; fixed fresh-moduleGREEN7/7 in nativeEdit. Three template completeness failures reproduced and repaired; four commit ownership scenarios passed. Use fresh module copies because existing Edit requires can remain cached after Source edits.
