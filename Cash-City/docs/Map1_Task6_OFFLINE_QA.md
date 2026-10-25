# Task6 offline QA — BLOCKED / PARTIAL

Before-run remote81098b8 matched clean checkout. GitHub before-place checkpoint66be7aa/checkpoints/Map1_Task6_before_20261024.rbxl.
Canonical working place CashCity_RiverWalk_Section2.rbxl preserved throughout; SHA256 AE6AA260681DEAB439CF809D4FE6F3FA44FC0F072842355B70E8795418625E68.

## Actual tests
1. Full existing unittest suite:82tests,65.244seconds;81PASS,1FAIL. test_build.test_embedding found stale Config in the older XML export.
2. Source-only XML candidate sync plus four newer map modules in existing embedding test:82/82PASS in68.726seconds.
3. Added strict unique-source/container assertions, removed two UI-helper duplicates created by the candidate sync while retaining their original client copies. Final focused build check:3/4PASS,1FAIL in4.667seconds. InteractionRules under ServerScriptService violates expected ReplicatedStorage.SmallSignals placement. Native working-place inventory confirms shared placement.

The stronger check caught a packaging issue missed by source equality alone. Best explanation: a legacy duplicate server-side InteractionRules remains in the older export. Do not claim the final candidate passed all checks.

## Preservation and stop
User AGENTS: if a command or test fails twice, STOP. Repair stopped after the second failing test execution; no further patch/retest loop.
Unverified candidate XML, stronger test and sync evidence archived under pending/Map1Task6 in GitHub and work/task6_candidate locally. Candidate first-pass source sync mistakenly created duplicate UI helpers under server; only those newly created duplicates were removed before final check. All pre-existing geometry remained unchanged.
Physical-node fingerprint before/after candidate:41216nodes, SHA25621a6124c3055cd2e41c53e5e30c389959fafd685ea1d4cbb1781dddb0fdbfd99.
Pre-run XML export restored from work/task6_before_source_sync.rbxlx by hash; active test_build.py restored byte-identically from pre-run upload checkout. This is rollback, not weakening a check to claim success. The stronger check remains preserved in the candidate. Known baseline still has81/82 outcome; no post-rollback test rerun was performed.
No map rebuild, live Studio/source change, publication, helper or actual player manipulation. Working binary and previously passed gameplay unchanged.

## Next safe repair
Review legacy InteractionRules duplication and preserve the original module before correcting candidate container layout. Retain strong uniqueness/server-client checks; rerun focused build tests, then full suite before integration. Do not replace the saved working binary with the older XML candidate.

## Still unverified
Actual routes at all four sizes, expanded-boundary escape checks, phone/device performance and real six-player private playtest. Task5 streaming-detail review remains manual. No release-ready claim.
