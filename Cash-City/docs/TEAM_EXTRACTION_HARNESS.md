# Team progression and extraction predicate harness

`tests/STUDIO_TEAM_EXTRACTION_CHECK.lua` reads the actual `ReplicatedStorage.SmallSignals.Rules` and `Config` ModuleScripts. Run the complete file as one native Studio `execute_luau` chunk in the **Server** datamodel of the candidate place. It can run in Edit or Play; it does not start a match, alter players, create Instances, send remotes, or leave listeners/tasks behind. All changed rosters are local test tables. It does not install a ModuleScript or change production source.

## Exact execution

The lead should select the candidate's currently listed `studio_id`, verify its working design version, read the UTF-8 file, and submit its full content as the execution `code`. Do not use an old Studio ID or require an unreviewed downloaded asset. With the current native tool schema, the call is:

```javascript
await tools.mcp__Roblox_Studio__execute_luau({
  studio_id: currentCandidateStudioId,
  code: harnessFileContents,
  datamodel_type: "Server"
});
```

`datamodel_type: "Server"` requires an available Play server; use `datamodel_type: "Edit"` when Studio is stopped. Check available datamodels through `get_studio_state` first. The exact **Luau code** to execute is the entire checked-in file, starting `local shared=game:GetService("ReplicatedStorage"):FindFirstChild("SmallSignals")`. No fixture setup or cleanup is required. Alternatively paste the file into Studio's server Command Bar. Do not insert it into a production Script.

Expected return under current Config (`Stages=3`, `TeamSizes={3,4,5}`):

```lua
{
    status = "PASS",
    checks = 540,
    scope = "Native Rules/Config ModuleScript predicates only",
    multiplayerVerified = false,
    note = "No server callbacks, physical extraction, grace timer, movement, or replication exercised"
}
```

A failed assertion includes `TEAM RULES FAIL:` and its condition. Missing modules or invalid configuration fail before the scenarios. The count intentionally follows actual configuration rather than hardcoding balance.

## Coverage and limits

- All configured team sizes, with every required member independently unfinished at each stage, downed, disconnected, or not extracted.
- Empty roster, no required members, dictionary roster, and ignored nonrequired/spectator entries.
- In-grace disconnected reservation in the exact `{required=true, connected=false}` shape used by server `checkWin`, then its omission after expiry. This checks the predicate input contract; it does **not** execute the 45-second timer, rejoin handler, or reservation projection code.
- Each member's ordered gate eligibility, wrong gate/team, downed state, and Lobby/Vote/Results rejection through actual `Rules.canEnter`.
- Local simulated per-member progression, unchanged teammates, and team completion only after the final required local extraction. The stage write is a test simulation mirroring `onDoor`; it is **not** proof that the live callback changes only one member.

Server inspection confirmed `onDoor` writes only `members[p]` after destination preparation; `onExit` checks team/stage/distance; `checkWin` projects active members and live reservations into `Rules.allFinished`; the tick clears extraction after movement/blocked states. These callbacks and asynchronous race behavior remain outside this pure harness.

## Evidence on this worker run

- Offline execution of the full harness using Lupa and actual source Rules/Config, with a minimal mocked module lookup: **540 assertions passed**. This validates harness syntax/expectations in Lua, not native Luau or Roblox runtime.
- Existing focused `test_team_rules.py`: **6/6 passed** in 0.022 seconds.
- Native Studio execution, **2026-10-23**: lead observed **PASS, 540 assertions** in the Edit datamodel using the actual Rules/Config ModuleScripts. This is native Luau predicate evidence; it does not execute server callbacks or a multiplayer session. This worker did not mutate or execute live Studio.
- Actual multiplayer: **pending**. Run `tests/STUDIO_ACCEPTANCE.md` with six clients for independent movement/gates, all-member physical extraction, a downed/missing/unfinished teammate, disconnect grace and rejoin/expiry, simultaneous downs, leaving the pad, and replication. One-player practice or this harness cannot establish those results.


