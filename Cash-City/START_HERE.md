# Map 1 release preparation — START HERE
Working place: CashCity_RiverWalk_Section2.rbxl. Never publish.
Cross-session memory: docs/CASH_CITY_MEMORY_HANDOFF.md (snapshot; verify fresh GitHub/live state and latest user instructions).
Visible Studio6beb19f8-2e46-4f3c-b2de-3c3387505131, CashCity_RiverWalk_Section2.rbxl, reopened after included allowance reset.
## Rules
Map1 only: RenCen, RiverWalk, surrounding park. No other districts/helpers/paid credits.
One numbered task per run; save/checkpoint GitHub before and after; stop for "next".
Latest user override: use remaining INCLUDED five-hour allowance this continuation; no paid credits. Preserve save buffer. UI failure twice: stop.
Map1 roads/edges/necessary full rebuild approved; preserve originals.
## Status
1 PASS: inset stair-top + source-derived approach;6 offline +5064 native checks.
2 MECHANICAL PASS; visual screens unverified. New boundary adjusted duringTask3 to retain actual park/complex footprints.
  Previous reset tests passed at old extents; containment unit checks and573 current-extent barrier rays passed. Recheck current-extent player escape cases duringTask6.
3 PASS: 68-part park path joins completed160m RiverWalk to existing Hart Plaza path over428.786m.
  Fixed boundary cropping: limitsX[-1850,750],Z[-650,1250];1098 previously screened preview parts restored.
  12 focused offline tests;87 native floor samples;22% avatar completed ALL87 waypoints,health100/supportPASS.
  573 updated barrier rays:0 misses. Park-facing desktop sample59.99FPS,p9518.48ms; not mobile/multiplayer/improvement proof.
4 PARTIAL: actual solo Practice -> Match -> shrink gates -> extraction -> Results -> Lobby PASS.
  NormalReady(3) with1player stayedLobby. Real multiplayer stopped at2clients/446MBfreeRAM;6player3v3 BLOCKED.
  LiveEdit/source has verified CASH CITY/Extraction/Detroit header metadata;7team-rule tests+panel regressionPASS.
  SAVE VERIFIED: user manually saved2026-10-24 17:20:52;696633bytes.
  SHA256 AE6AA260681DEAB439CF809D4FE6F3FA44FC0F072842355B70E8795418625E68.
  Actual disk-reload now PASS: all3production sources equal tested version; boundary/park modules and preview present; noarmedQAfixtures.
  Canonical savedplace plus immutable manual-save checkpoint backed up; save blocker cleared.
  Playstopped,observerremoved,noarmedQAfixtures. See docs/Map1_Task4_ACCEPTANCE.md and bothTask4JSONresults.
  User approved deferring real3v3 to a later private six-player playtest and advancingTask5. No publication authorized. Do not relaunch6localclients under unchangedRAMconditions.
  Latest recheck2026-10-24 18:15:4.4GBfree, essentially unchanged;0newclients launched.
  Waitingforuser tofreeRAM/choosehowtoproceed. Resource evidence:docs/Map1_Task4_RESOURCE_RECHECK.json.
  User chose stayTask4/freememory. Latestready:7183MBfree before reopening,5140-5390MBafter;6clienttest notlaunched.
  Savedplace reloaded/connected;3v3stillBLOCKED. NewStudioIDabove supersedes92bb. See docs/Map1_Task4_REOPEN_CHECK.json.
  Output error traced to preserved Workspace.FlayoDev Admin Messages, missingStarterGui.Messages; presetadminallowlist requiresreview beforeactivation.
5 PARTIAL: StreamingEnabled true; fresh foreground desktop60.045FPS,p9518.343ms,10.009s/601frames,viewport1223x710,Automaticquality.
  Engine memory2904->2799MB;6128loadedparts/44unanchored. Notmobile/multiplayer/gainproof. No rendering/codechanges justified by this sample.
  Other streaming controls nonscriptable/unreadable here; manualProperties review pending. Low-endmobileFPS UNVERIFIED.
  Playstopped,camera/renderlistener restored/removed. Evidence docs/Map1_Task5_DESKTOP.json and Map1_Task5_NOTES.md.
  UIreview blocked: click failed coordinategeometry, Tabhadnoeffect; stoppedthisUIflow at2failedinputs.
  Properties filterset successfully toStreaming; Workspace selected. Nativeinspect returnedemptyproperties.
  Read docs/Map1_Task5_MANUAL_CHECKLIST.md. SettingsvaluesandactualphoneFPSrequirehumanverification; no settingschanged.
6 PARTIAL: offline repair PASS. Full82/82tests98.817s; strictbuild4/4tests5.495s. Sourceembedding covers39productionfiles exactlyonce/correctcontainers.
  OlderXMLsources synced; legacyserverInteractionRules preserved as ServerStorage.ArchivedInteractionRules_ServerCopy_RF09_5. Physicalgeometry unchanged41216nodes.
  WorkingcanonicalrbxlUNCHANGED; XMLstaticpreview still not reconciled withsavedworkingmap. Olderfailedcandidate retainedas history pending/Map1Task6.
  All4size nativewalks/phone/private3v3 stillPENDING. See docs/Map1_Task6_OFFLINE_QA.md, Map1_Task6_REPAIR.json and Map1_Task6_CHECKLIST.md.
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

