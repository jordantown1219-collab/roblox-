# Map 1 Task 4 acceptance

Status: PARTIAL. Actual solo flow passed; real 3v3 blocked by RAM. No publication.

## Verified
- Ready(3) with one real player stays in the normal Lobby queue.
- Single-client Practice enters Vote/Match, normal E gates yield physical scales1/.65/.4/.22 and health100/80/60/40.
- Normal tiny extraction E produces Results, then Lobby cleanup after8seconds.
- Controlled positioning near prompts only; no continuous route-navigation proof.
- Visible-side approach resolved an offscreen prompt; extraction code unchanged.
- Seven offline team-rule tests and existing panel regression passed.
- Temporary observer removed, Play stopped, no armed Edit QA fixtures.

## Limits
- Official multiplayer run aborted at2clients/446MBfreeRAM before6players.
- No 3v3, whole-team extraction, mobile/tablet/controller or FPS acceptance from this run.
- Manual save confirmed2026-10-24 17:20:52:696633bytes; SHA256 AE6AA260681DEAB439CF809D4FE6F3FA44FC0F072842355B70E8795418625E68. LiveEdit production sources match tested version; no separate disk-reload test.
- No claim the entire Output panel is error-free; unrelated visible errors were not attributed.

## Next Studio checks
1. DONE: manual save verified by changed timestamp/hash; canonical place and immutable checkpoint backed up to GitHub.
2. Play: check CASH CITY and TEAM EXTRACTION / DETROIT RIVERFRONT (MAP 1).
3. On sufficient resources, connect6realclients, queue3v3, confirm3perteam and1carrier/team.
4. One player shrinks: teammates retain sizes. All players use gates sequentially.
5. One teammate extracts: Match continues. All3extract: both teams see Results, then clean Lobby.
6. Phone follow-up: visible extraction prompt, touch hold, readable labels. Still untested.

Evidence: Map1_Task4_SOLO_RESULTS.json and Map1_Task4_MULTICLIENT_ABORT.json.
