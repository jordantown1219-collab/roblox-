# Map 1 release preparation — START HERE
Working place: CashCity_RiverWalk_Section2.rbxl. Never publish.
Visible Studio92bb2bd5-f0e8-4fe0-9300-40cf8d01dfb0 (MCP may report old AutoRecovery name).
## Rules
Map1 only: RenCen, RiverWalk, surrounding park. No other districts/helpers/paid credits.
One numbered task per run; save/checkpoint GitHub before and after; stop for "next".
Stop before90%USED five-hour allowance, leaving10%remaining. UI failure twice: stop.
Map1 roads/edges/necessary full rebuild approved; preserve originals.
## Status
1 PASS: inset stair-top + source-derived approach;6 offline +5064 native checks.
2 MECHANICAL PASS; visual screens unverified. New boundary adjusted duringTask3 to retain actual park/complex footprints.
  Previous reset tests passed at old extents; containment unit checks and573 current-extent barrier rays passed. Recheck current-extent player escape cases duringTask6.
3 PASS: 68-part park path joins completed160m RiverWalk to existing Hart Plaza path over428.786m.
  Fixed boundary cropping: limitsX[-1850,750],Z[-650,1250];1098 previously screened preview parts restored.
  12 focused offline tests;87 native floor samples;22% avatar completed ALL87 waypoints,health100/supportPASS.
  573 updated barrier rays:0 misses. Park-facing desktop sample59.99FPS,p9518.48ms; not mobile/multiplayer/improvement proof.
4 NEXT: fullmatchloop incl3v3 minimum,mode/team/map/shrink/extraction/results; fix only blockers. Start only after"next".
5 PENDING: streaming + desktop/low-end mobile performance acceptance.
6 PENDING: all routes/all4sizes/full offline suite + phone/multiplayer checklist.
7 PENDING: tested rollback/release/private-test publish instructions; NEVER publish automatically.
## Evidence and remaining work
See docs/Map1_Task3_ACCEPTANCE.md and Map1_Task3_WALK_RESULTS.json.
Task2 visual concealment approval still pending; no claim of release readiness.
Full-build preview/source embedding for newly added modules must be reconciled beforeTask6 fullsuite; old .rbxlx is NOT current working place.
PNG request was canceled by user after renderer failed twice; no PNG produced. Do not resume renderer unless asked.
## Where to look
Camera atpark join:target-1480/1/1120,eye-1415/36/1195;selectionclear.
## Postlaunch only
Newdistricts,votingpolish,extra interiors,vehicles,console tuning.
