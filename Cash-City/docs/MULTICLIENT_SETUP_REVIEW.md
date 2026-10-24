# Local multi-client setup review

Reviewed2026-10-23. Read-only investigation plus this document only; no Studio calls, test launch, plugin installation, production/test source changes, publishing or external services. Native predicate PASS540 and solo extraction do not establish multiplayer acceptance.

## Supported API and limits

The official [StudioTestService API source](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/classes/StudioTestService.yaml) documents:

| Call | Contract |
| --- | --- |
| `ExecuteMultiplayerTestAsync(numPlayers, args)` | Plugin security; launches1server and1–8clients; yields until completion, returning server `EndTest` value. Rejects an existing test. |
| `GetTestArgs()` | Reads the supplied value; server works, client LocalScript has a documented issue. |
| `EndTest(value)` | Running server only; returns immediately, tears down asynchronously; can end a test launched elsewhere. |
| `CanLeaveTest()` / `LeaveTest()` | Client only; check permission before leaving. |
| `AddPlayers(numPlayers)` | Running multiplayer server only; adds simulated clients. |

`args` is an optional Roblox-serializable value, not executable source. No `serverScript`/`clientScript` injection keys are specified. The launch call is plugin-only and cannot nest inside a test. A coroutine keeps its caller responsive. Individual method summaries for argument retrieval mention solo/run, while the multiplayer method and class example explicitly describe passing arguments into multiplayer. Use server retrieval and verify installed behavior before relying on it.

[Official testing modes](https://create.roblox.com/docs/studio/testing-modes#multi-client-simulation) also provides UI launch: testing dropdown **Server & Clients**, select6, Play/F7. End Session tears down simulated sessions. Ordinary Stop/ShiftF5 restores pretest game state. The authoring Studio session should remain open; do not close its window or kill processes.

There is no documented `StudioTestService:Stop()` or `CancelTest()` in this API. Use the documented server `EndTest` or owned-session UI teardown; do not invent a cancellation method.

Current native MCP metadata exposes only `start_stop_play({studio_id,is_start})`, without client count or script-injection arguments. Its input tools address Client game datamodels, not the Studio ribbon. Therefore a six-client launch through that tool alone is unsupported. Native `execute_luau` plugin privilege and survival across the transition have not been proved; a successful method lookup would not establish either.

## Safe lead approach

### Available now: built-in local simulation

1. Checkpoint candidate sources/place, select the correct Studio instance, confirm stopped Edit state. Stop Rojo sync if it could overwrite fixtures. Do not publish.
2. Use Studio's **Server & Clients** UI with6clients. If this UI is unavailable through current tools, ask the user for this one concrete launch action. Do not substitute undocumented command-line flags or launch Team Test.
3. Rediscover instances and datamodels after launch. Associate sessions by actual server/player identities; never assume old IDs or client ordering. Verify six actual Player instances with unique UserIds. Missing per-client MCP exposure is a tool limitation, not a passed test.
4. Use existing game UI to queue all six for3v3. Preserve manual player control when automation cannot target a particular client. Record server and client evidence separately.
5. End only the owned test through its End Session control. Inspect Output, return to Edit, confirm candidate still open and no QA fixtures remain. `start_stop_play(false)` is not documented here as a guaranteed multi-session end control; verify state rather than assume it ended every simulated process.

### Optional future automation: bounded temporary test runner

This is an implementation proposal, not an installed or verified runner. It uses existing Studio functionality and needs no cloud publishing/service.

- In Edit, add uniquely named, explicitly owned temporary **server Script** and **client LocalScript** fixtures to a disposable copy or reversible checkpoint. Preserve existing children and sources. The official Roblox [EvalRunner implementation guide](https://github.com/Roblox/open-game-eval/blob/main/EvalPlugin/USER_GUIDE.md) uses explicit prelaunch runner injection followed by owned-instance cleanup; argument passing does not inject scripts.
- Server fixture validates a unique run identifier from `GetTestArgs()` before installing a180-second watchdog. It must use `xpcall` and finish with a structured result via `EndTest`; a failure must never be converted into PASS. Client code must not rely on `GetTestArgs`; replicate the validated run identifier and assignments explicitly through a temporary owned channel.
- Example **data only** passed to the launcher: `{runId="CC014-MULTI-<unique-id>", expectedPlayers=6, timeoutSeconds=180}`. Those keys belong to our proposed runner, not Roblox's API schema. There is no automatic timeout merely because this table contains one.
- A real plugin-context launcher runs `ExecuteMultiplayerTestAsync(6,args)` inside a separate coroutine, returns control immediately, and reports startup/completion errors. Do not hold an MCP call open for the whole test. No new plugin should be installed merely to attempt this during the present investigation.
- Server runner waits for six players with a deadline, then executes only bounded cases. A server-side watchdog can call `EndTest({status="TIMEOUT",runId=...})` only for its matching owned run. It cannot recover a server that never started; keep End Session available as the operator fallback.
- On completion or error, wait for Edit state, then remove only fixtures identified by the exact run marker and retained object references. Verify source/geometry hashes. Never restore an entire stale snapshot over unrelated user edits.
- Optional launch-time2client plumbing smoke test is appropriate before6clients, but cannot test current3v3 matchmaking. Do not change TeamSizes to make it pass.

## Highest-value six-client acceptance

These assertions are derived from current server/Config source, not completed runtime results. Use six clients A1/A2/A3 and B1/B2/B3 as labels after reading real team assignment. Server sorts ready UserIds and alternates teams; labels are not client launch indices. Per-case evidence should include Output, server attributes, relevant client HUD snapshots and timing. A temporary observer must be removed afterward.

| Case | Exact expected assertion |
| --- | --- |
| Queue | Five clients ready with choice3 do not enter Vote; sixth ready produces3Amber and3Cyan. Close/reopen while waiting retains readiness. Do not use Studio Practice. |
| Vote | Normal12-second vote transitions to Match. Each team has exactly one Carrier; each noncarrier has Knife. Preferred weapon/carrier vote behavior remains unchanged. |
| Independent gates | A1 completes gate1: Stage(A1)=1, all other player stages remain0. A2 later completes gate1 independently. Gate3 before gate2, Cyan gate by Amber, downed interaction, out-of-range and blocked-line-of-sight attempts leave stage unchanged. |
| Scale and stats | Each accepted stage sets scale1/.65/.40/.22 and health cap100/80/60/40; WalkSpeed stays16. Health fraction preserved, armor fraction rescaled/capped. Observe actual characters and replicate to a second client, not attributes alone. |
| All gates insufficient | A1/A2 atstage3 on extraction with A3unfinished does not end Match. All three atstage3 but A3offpad also does not win. |
| Extraction reset | Extract A1 while A2/A3 stay offpad; move A1more than4studs away. After at least two server ticks(>1second), complete A2/A3 extraction. Match remains active until A1returns and validly extracts. Test downed state similarly before the last member arrives. |
| Team victory | All required connected Amber members stage3, alive/notdowned and physically in their own extraction; final valid prompt produces Results with Amber win. Enemy extraction never satisfies Amber completion. |
| Disconnect grace | In a separate round disconnect one required Amber member while others finish; no win during45-second reservation. Only after expiry and server tick may remaining eligible members win. If the last required member disconnects, an empty team must not win. |
| Carrier replacement | Disconnect carrier: replacement is not granted during live reservation; after45seconds a connected member receives carrier role. Confirm exact weapon/ammo replication and absence of duplicate carriers. |
| Rejoin | Within grace, same UserId resumes saved team/stage/checkpoint, with extraction cleared. `AddPlayers` does not promise reusing the disconnected identity; a newly assigned test UserId cannot verify rejoin. Keep this pending if local identity reuse is unavailable. |
| Armor/rivals | Owner and same-stage rival may claim the single armor cache; same-team nonowner and wrong-stage rival cannot. Simultaneous attempts produce only one grant. Do not depend on random spawn timing as a deterministic assertion. |
| Combat/revive | Wait out4-second spawn protection; accepted enemy attack reduces armor before health, friendly fire unchanged. Downed players cannot enter gates/extract;2-second teammate revive restores movement and half stage health. No revive means death after10seconds and respawn after4seconds at saved stage/checkpoint. |
| Loading/races | Gate activation only once during destination preparation; disconnect/down/round change during preparation must not advance a stale member. Adjacent geometry loads on each receiving client and nobody falls through. |

The180-second runner budget would cover queue/gate/extraction or one disconnect case, not this entire matrix. Split cases into fresh bounded rounds; current match480seconds plus90seconds overtime must not be mistaken for a harness watchdog. Real devices, touch/controller, network latency, streaming coverage and FPS acceptance remain separate pending work.


## Prepared bounded readiness/deployment harness (not launched)

Added three reviewed-source candidates:

- `tests/STUDIO_MULTICLIENT_SERVER.server.lua`
- `tests/STUDIO_MULTICLIENT_CLIENT.client.lua`
- `tests/STUDIO_MULTICLIENT_LAUNCH.lua`

**Current launch blocker:** lead reports approximately1.7GB free machine memory. Do not launch six Studio clients under that condition. No safe memory requirement is asserted; establish sufficient real headroom first. This worker installed no fixtures and ran no Studio calls.

### Exact temporary installation contract for lead review

Use a fresh unique run identifier of at least12characters, e.g. a GUID with a `CC014-` prefix. In stopped Edit, first assert all three names below are absent. Refuse name collisions; never replace existing instances.

| Location | Class and required initial attributes/content |
| --- | --- |
| `ReplicatedStorage.SS_MulticlientQA` | Folder; `RunId`=unique string, `Armed`=false, `ServerReady`=false, `LaunchState`=`Prepared`. Child `Reports` is a RemoteEvent. |
| `ServerScriptService.SS_MulticlientQA_Server` | Script; Source exact server file; `RunId`=same string. Parent only after source/attributes set. Enabled. |
| `StarterPlayer.StarterPlayerScripts.SS_MulticlientQA_Client` | LocalScript; Source exact client file; `RunId`=same string. Parent only after source/attributes set. Enabled. |

Keep exact created instance references for removal and verify source matches disk. Arm the owned Folder last (`Armed=true`). Execute the full launch file in candidate **Edit** through native MCP only if installed API permissions and memory have been reviewed. It schedules the plugin-only service call in `task.spawn` and returns `LAUNCH_QUEUED` immediately; this is never PASS. Plugin-security success and coroutine persistence through the Edit→test→Edit transition remain unverified for native MCP.

Launcher call: `ExecuteMultiplayerTestAsync(6,{runId=runId,expectedPlayers=6,timeoutSeconds=180})`. `expectedPlayers` and `timeoutSeconds` are our diagnostic data, not Roblox configuration keys; six clients and180seconds are enforced by the source itself. No argument contains executable source.

### Run behavior and result

Server fixture only arms when `IsStudio`, server `GetTestArgs().runId`, its own RunId and the owned armed Folder all match. Client requires its own same RunId, armed marker and server-ready flag; it never calls buggy client `GetTestArgs`. Missing markers or ordinary sessions do nothing. Server starts an independent180-second watchdog and catches observer exceptions; failures call structured `EndTest` once. Startup failures before a server exists still require operator End Session.

Each client connects the actual production State event and sends the actual production `Action:FireServer("Ready",3)` once, after a Lobby snapshot and loaded game. It never calls Practice, alters stage, changes teams, or sends synthetic progression. Its only additional network channel is the owned QA `Reports` RemoteEvent. Reports carry diagnostic snapshots only and grant no production state authority.

Server confirms six distinct UserIds, exact3/3teams, one carrier each, normal nonpractice Match snapshots from every client, all Stage0/Scale1, real character scale1, health/maxhealth100, no active loading/spawn recovery, unanchored roots and actual landing within16studs of the production Arena spawn. Client reports also wait for replicated spawn coordinates and actual arrival, preventing stale lobby characters from falsely passing deployment. It cross-checks every client's six roster IDs against the actual server teams. Root proximity accommodates ordinary spawn crowding; it is not collision or streamed-city acceptance.

Expected structured service return: `status="PASS"`, matching `runId`, six players, amber/cyan3, carrier counts1each, six client Match reports, stage/scale/health booleans. The returned scope explicitly excludes progression and extraction. Errors/timeouts return `status="FAIL"`. The launcher persists the JSON result to **Edit** Folder attribute `ResultJSON`, sets `LaunchState="Completed"` and disarms it. A missing/invalid service result is FAIL. Inspect result after Edit resumes; a queued launch or a silent disconnect is not success.

### Teardown

After the owned service ends, confirm Edit state. If launcher never completes, use the owned simulation's End Session UI, preserve errors and mark FAIL; never force-close user Studio. Read/export the owned `ResultJSON` evidence before cleanup. Remove only the exact three installed fixtures whose retained references and RunId match; removing the marker also removes its Reports child. Verify no same-run fixture survived in Edit and production sources/geometry hashes are unchanged. Do not save/publish an armed QA fixture in the game. Remove local script copies in simulated clients by ending the simulation, not by touching production player scripts.

### Validation level

Source prepared and syntax-checked offline only; no native launch, service-security, six-client readiness or deployment result is claimed. Full ordered gates, extraction, disconnect grace, rejoin identity, combat, input, streaming and performance remain pending separately.
