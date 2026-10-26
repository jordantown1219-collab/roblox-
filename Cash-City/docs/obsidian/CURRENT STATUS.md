# Cash City — current status

Updated 2026-10-26. This summary supersedes older entries that say the project is still unsaved. Read [[BACKUP RECEIPT]] for the verified upload and file hashes.

## Current project
- Local working folder: `C:\Users\jorda\AppData\Local\SmallSignalsProjects\Detroit_Riverfront_v0_14`
- Working place: `CashCity_RiverWalk_Section2.rbxl`; local Studio save verified on 2026-10-26 at 10:37:50 EDT.
- Saved place: 839,313 bytes; SHA256 `C5B59E8A36443A2910EE1D31E729FE2DF80BA1F6CA284F45748193A7AD4CE272`.
- GitHub: [Cash City project](https://github.com/jordantown1219-collab/roblox-/tree/main/Cash-City). Upload receipt identifies the exact commit; do not assume an older commit is current.
- Open the working `.rbxl` for the map. The root `.rbxlx` and exported Rojo geometry assets are older exports, not the current map. `scripts.project.json` is the code-only sync path.

## Implemented and observed
- Detroit/RiverWalk map foundation and prior core gameplay retained.
- Current residential Tower A: 39 furnished floor layouts, 156 apartment layouts, connected stairs through Level 39.
- Separate kitchen/bathroom, living/bedroom, corridor and stair finish modules; 76 added landing lights and 76 signs.
- Fresh startup counted 468 doors, 156 windows, 624 enabled prompts and 38 upper stair connections without ValidationFailure flags. This does not verify every activation.
- Existing 22% walking fixture passed 120 waypoints from Level 11 to Level 39; lower routes have separate earlier records.
- Individual shrinking and whole-team extraction remain the approved design.

## Still unfinished or unverified
- Kitchen/bathroom appliance-use interactions are not implemented; those fixture details are decorative.
- Other towers, complete Renaissance Center/interior authenticity and other remaining Map 1 work are not automatically complete because Tower A is copied.
- Full-size/descent coverage of every upper route, actual player interactions, manual visual acceptance, phones/tablets/consoles, real multiplayer and release acceptance remain pending.
- Outdoor desktop samples were about 60.1 FPS on the RiverWalk and 58.1 near the approach; the latter had a 106 ms worst frame. These are not device-wide or long-session benchmarks.
- No publication was performed. On 2026-10-26 the immutable checkpoint was reopened in a separate Studio window: all 39 floors, 38 upper stair connections, 76 landing lights and 76 signs were present; ten key saved scripts matched current source files after line-ending/trailing-whitespace normalization. The original working scene remained open with 39 floors. This verifies persistence, not a new gameplay or release acceptance pass.

See [[TEST RESULTS]], [[NEXT TASKS]], [[WORKING RULES]] and the archived project docs for evidence.

## Latest task attempt — checkpoint reopen pending, 2026-10-26
Canonical place and immutable checkpoint both still hash C5B59E8A36443A2910EE1D31E729FE2DF80BA1F6CA284F45748193A7AD4CE272; GitHub main matches8e92f728. Studio Ctrl+O opened Open Roblox File, but filename element83064 was unavailable to cached automation on both click and set_value, even after refreshing state. Stopped aftertwoUI failures; no map/source changes and disk reload remainsUNVERIFIED. File dialog leftopen on originalcanonicalStudio1442798; original scene remainsopen. Owner should manually enter checkpointpath andOpen, then replyReady. NextagentmustnotrepeatUI retries or addparser/captureharness; inspectreopenedStudio throughMCP afterowneropensit.
Checkpointpath: C:\Users\jorda\AppData\Local\SmallSignalsProjects\Detroit_Riverfront_v0_14\checkpoints\CashCity_39Floors_saved_20261026T103750.rbxl

## Checkpoint reopen passed — 2026-10-26
The owner manually opened the immutable saved copy after the UI automation stopped. Its new Studio window25363350 connected as8391d5d3-a4f8-440e-aa37-0ee5a6a2d264. Read-only Edit inspection found39floors/15756baseparts(404each)/38upperstairs/76landinglights/76signs, missingfloorsnone. TenkeymodulesmatchedlocalSources(normalizedEOL/trailingwhitespace):Arena,FloorA01,RemainingFloors,FloorBatch,CorridorFinish,ApartmentFinish,LivingFinish,StairWayfinding,Lift,Access. OriginalStudio847a66dfstillhas39floors. Backupverificationiscomplete; previousblocked/pendingreopenentriesarehistorical. Keep backupimmutable andcontinueeditingthecanonicalworkingplace. Next ownervisualacceptance andremainingfunctional/device/multiplayerwork; no newdistrict orfloorreplication.

## Visual review started — 2026-10-26
Original workingStudio847a66df nowframesTowerA Level01Apartment01living/dining inEdit; onlycamera/selectionchanged, geometry/scriptsunchanged andimmutablebackupuntouched. Ownerreviewquestionpending: Looks good / Needs more detail or realism / Something looks wrong. Do not markvisualacceptancePASSuntilowneranswers. Keepthisviewuntilfeedback; nextkitchen/bedroom/stairviews canfollowafterward. GitHubstill6c9e871 atstart, no newerremoteedits.

## Owner visual direction and TV request — 2026-10-26
Owner firstsaid living/diningneededmoredetail/realism. OneRoom01Level01pilot(40parts/1light,17originalsretained) built andexisting22percent4waypointroutepassedhealth100. Ownerthenanswered 'Better—keep this direction'; approved visualdirection, not releaseacceptance. Approvedsample savedasCashCity_RealismPilot_20261026T112700.rbxl SHA256BC8D4628DCA8000790C4CB653961CD53025BCD44D9A1761ACA0659CEC311545C (843890bytes); C5baselinepreserved. Reusingstylethroughremainingapartmentsinboundedbatches isactive.
OwnerrequestedworkingTVwithYouTubelinksanddeclinedRobloxassetIDs('I only want YouTube links'). OfficialVideoFramerequiresRobloxuploadedvideo; arbitraryYouTubeURLplaybackunsupportedbybuilt-inplayers. NoTVasset-IDreplacement/proxy/uploads/Robuxspending authorizedorimplemented. KeepTVrequestmarkedunsupported; donotpretendlinkinputplaysYouTube. Approvedapartmentfinishcontinuesindependently.

## 2026-10-26 — Approved apartment living/dining finish integrated and saved
Owner approved the revised sample direction. Reused ResidentialRealismPilot across 39 floors/156 apartments; added 6240 anchored detail parts and 156 localized lights, retaining 2652 references to original objects. Runtime counts verified before stopping Play; existing 22% walking probe previously passed four waypoints in Level39 Apartment04, health100. Edit integration verified identical counts and retained references. Arena now applies all finishes on startup; this final integrated startup is awaiting fresh Play validation. Source syntax test BuildAcceptance.test_lua_sources PASS. No new FPS result available; do not infer performance acceptance from counts. Individual room, full-size, mobile, multiplayer and release acceptance remain UNVERIFIED. YouTube-only TV declined/unsupported; no TV substitute implemented.
Saved canonical CashCity_RiverWalk_Section2.rbxl at 2026-10-26 11:44:32 EDT, 853211 bytes, SHA256 AFDDD61B0DF67CA90CD1254EF879ACB1BC9C8B7278A6036752162D6EC30D25B9. Immutable checkpoint checkpoints/CashCity_ApprovedApartmentFinish_20261026T114432.rbxl and Obsidian Backups copy created. Baseline39-floor checkpoint and approved one-room pilot retained. Original Studio847a66df is stopped in Edit, Level01 Apartment01 living/dining framed; backup Studio untouched. No publishing/helpers/paid credits. Included usage97% used at checkpoint; stop before1% reserve. Next: fresh startup of all156 finishes, foreground existing performance sample, then next room visual pass. Do not recopy floors or revisit Wintergarden doors.