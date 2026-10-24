# Bounded authoritative Action validation audit

October 23, 2026. Read current DEVELOPMENT_STATUS and LESSONS_LEARNED before work. Individual shrinking and whole-team extraction remain approved. No existing server, Config, Rules, balance, Studio or shared files changed. No multi-client launch.

## Concrete finding: unsupported action strings grow per-player throttle state

`SmallSignalsServer.server.lua` Action callback rejects nonstring action values, then indexes `lastAction[p][action]` and stores its timestamp **before checking whether the action is supported**. The rate limit is per action string, so distinct arbitrary strings do not share a throttle bucket. A bounded diagnostic executed the actual callback with 1,000 distinct unsupported strings at the same timestamp: all 1,000 keys remained in that player's throttle table and no raycast occurred. Player removal eventually clears the table, but it has no size bound while connected. This is a source-extracted memory/dispatch abuse finding, not measured network exploit throughput or a demonstrated crash.

Recommended smallest follow-up: reject actions against a fixed server allowlist before allocating/indexing per-action state. Consider a bounded aggregate request budget as an additional layer only if measured traffic warrants it. Lead must own any server change and test it separately; this task intentionally preserves source. Unknown strings do not currently change gameplay state, but their retained bookkeeping is unnecessary.

## Actual-source automated evidence

Added `tests/test_server_request_validation.py`. Five tests passed in 0.061 seconds using bundled Python/Lupa. The harness extracts the existing `active`/`close`/`blocked` functions, finite-vector predicate and complete `Action.OnServerEvent` callback from current server source. It uses actual Config and captures the callback through a stub signal. Checks cover:

- Wrong-type, NaN, infinite and boundary/oversized aim vectors rejected without consuming ammo or firing.
- Nonmatch, nonmember, dead, downed and loading clients rejected.
- Missing/ineligible equipment, noncarrier firearm use, wrong firearm, empty ammo, reloading, missing head and zero-length aim rejected.
- Per-action request throttling plus actual weapon cooldown reject repeated fire; accepted raycast length is server weapon range regardless of client aim distance.
- Noncarrier knife attacks remain permitted at configured stage-scaled reach and do not consume ammunition.

The 1,000-key diagnostic was run separately; a passing permanent regression must eventually assert rejection/bounded state after the proposed fix rather than enshrine current growth as desired behavior.

## Inspection of gate/transit boundaries

`onDoor` validates membership, blocked state, next team/stage/phase, proximity and line of sight before requesting stream preparation. Its completion validator rechecks player membership identity, round, phase, expected stage and downed state. `onTransit` additionally checks server cooldown and computes destination from server route data. Both mark extraction false on accepted transfer. These were source-reviewed only in this slice; previous pure Rules tests and loading-recovery tests do not prove concurrent engine behavior here.

High-priority untested native cases remain death/character replacement during prefetch, overlapping gate/transit callbacks, round cancellation during yield, blocked raycasts, recovery after failure, and actual destination collision. No new weakness is asserted from these pending tests alone. Existing source-authoritative range/cooldown checks do not substitute for six-client forged-event/replication tests.

## Harness limits and next validation

This is actual callback execution with synthetic vectors/type tags, character/health stubs, clock and a raycast recorder returning no hit. It does not reproduce Roblox Vector3/typeof, real input replication, network queueing, Humanoid physics, raycast visibility, damage-to-victim behavior, ProximityPrompt semantics, streaming or character ownership. Therefore passing tests prove the extracted control flow under these inputs, not complete RemoteEvent security or multiplayer acceptance. No API compatibility, device, balance or performance improvement claim follows from these five tests.

Next safe Lead task is the bounded allowlist fix and fresh isolated native rejection test, followed by native valid/invalid combat and transfer cases when memory permits. Keep six-client launch pending while available RAM is low; do not close processes automatically.
