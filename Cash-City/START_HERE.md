# Cash City Map1 — current resume guide
Read HANDOFF.md/latest DEVELOPMENT_STATUS.md/docs/LESSONS_LEARNED.md. Verify fresh GitHub before edits.
Working place: CashCity_RiverWalk_Section2.rbxl,697054bytes.
SHA256 ACB7CAFF81360E07A33B0176FD28DA287C13D91687D105446EF1CAAC7945340D.
Last working Studio6beb19f8-2e46-4f3c-b2de-3c3387505131; rediscover IDs each run. Do not touch old hidden983d9191.
Cross-session snapshot:docs/CASH_CITY_MEMORY_HANDOFF.md; current guide/status/user instructions supersede stale snapshot facts.

## Rules
Map1 only: RenCen/Wintergarden/RiverWalk/park and needed roads/edges. No other districts.
One numbered task per run, checkpoint/GitHub before and after, then stop for next.
No helpers unless user asks. No paid credits. Check live usage; preserve save buffer.
Never publish, including privately, without separate explicit approval. Never close/kill Studio.
Stop failed flow after2command/test/UI failures; report evidence. No new test/capture harnesses.
Reuse existing fixtures; no giant XML/data/generated-module dumps or unnecessary full rebuild.
Preserve manual work. Fix generated data through generator. Do not weaken checks to hide failure.
Camera: do not override Play camera or use unreliable automated E input. Earlier Fixed camera recovered by freshPlay.
If showing work, user-approved Edit framing only. Door interaction needs clear swing path, streamed model, normal input and verifiedOpen; fail fast if precondition fails.
Manual local saves must be verified by timestamp/hash then backed up. Autosave is not proof.
Engram is parked at user's request2026-10-25; do not keep inspecting it unless asked.

## Current status
1 PASS: source-derived approach/inset stair sample; completed geometry preserved.
2 Mechanical containment PASS; visual road-screen/sightline approval stillPENDING.
  BoundsX[-1850,750],Z[-650,1250]; expanded-bound recovery PASS6/6 (four sides, below, above); physical escape resistance still unverified.
3 Park connection:68originalrecords preserved+4cornerinfill=72;87routepoints.
  All4size baseline walks passed348waypoints. Corner repair then22%87/87+Edit/runtime9048floor/width+9048headroom each0failures.
4 Solo flow PASS; real6player3v3 DEFERRED to later approved private playtest. Do not launch6localclients again on unchangedRAM.
5 PARTIAL: StreamingEnabled true. Foreground desktop60.045FPS,p9518.343ms; NOT phone/multiplayer/improvement evidence.
  Other streaming settings/manualProperties review and actualphoneFPS remainPENDING; see Map1_Task5_MANUAL_CHECKLIST.md.
6 PARTIAL: offline83/83PASS. XML sources39exact/unique/correctcontainers; legacy serverInteractionRules archived intact.
  NEW PASS2026-10-25: original80m+two40m RiverWalk at100/65/40/22%,33waypointseach=132;3393floor/width+3393headroom checks0failures.
  Evidence docs/Map1_Task6_RIVERWALK_160M.json. No map/player/camera changes; temporary objects removed,Playstopped.
7 PENDING: tested rollback/release/private-publish instructions; no release-ready claim.

## Next independent native checks
- Remaining interior/access routes. Boundary recovery PASS6/6; see docs/Map1_Task6_BOUNDARY_FALLBACK.json.
- Wintergarden/RenCen interiors, access ramp/stairs still need complete all4size route acceptance.
- Never repeat failed door setup blindly; no forcedOpen attributes or collision disabling to manufacture a pass.
- Real phone controls/FPS and six-player private match testing remain required before public release.
- Tall road screens still need human visual approval.
Root SmallSignals_DetroitRiverfront_v0_14.rbxlx is source-consistent but its static preview is NOT the canonical saved map; do not replace the working .rbxl with it.
Postlaunch only: extra districts/maps/modes, voting polish, extra interiors, full vehicles, console polish.


Latest access QA:2532floor/width+2532headroom checks PASS; walks awaiting normal Wintergarden entrance opening. Play left running, player/camera unchanged; no temporary rigs. See docs/Map1_Task6_ACCESS_ROUTES.json.

CURRENT PRIORITY: map construction, no more door tests unless explicitly requested. Roof finish visible in Edit:11new pieces,15focused tests PASS; manual place SAVE PENDING. See docs/MAP1_ROOF_GLAZING_FINISH.md. Original binary/hash is before roof; olderXML now also stale in source. Do not overwrite liveEdit.

Latest Map1 change:2low plantingbeds/10parts behind benches in farther40m RiverWalk section;79originalparts preserved;8offline tests and849floor+849headroom native checks PASS. Roof remainslive. BOTH roof+bed place SAVE PENDING; pressCtrlS thenverifyhash/backup. See docs/MAP1_RIVERWALK_PLANTING_BEDS.json. Continueconstruction, not door tests.

LATEST: Roof+RiverWalkbeds saved/backedup a1af498; canonicalC0FA9161/708037bytes. NEW77tower framing accents nowvisible/framed in Edit;280existingliveaccents preserved;10focusedtestsPASS. Newframing SAVE PENDING untilCtrlS. Evidence docs/MAP1_TOWER_FRAMING_FINISH.md. Source/data backedup separately; olderXML remainsstale. Nextverifynewsave thencontinueMap1construction.

LATEST: tower detail SAVE VERIFIED EA30D895/711811bytes;canonicalbackedup660aa79. Atwater/Beaubien marking task BLOCKED after2generatorclearancefailures;zero livechanges. Candidate quarantinedpending/Map1AtwaterCrossing;readREADME before anyretry. Nextreviewjunctiongeometry. No doorwork.

LATEST: Atwater crossing RESOLVED/BUILT23paintparts;207nativepavementchecks+7offline testsPASS. Selected/framedinEdit. ActiveStudio e2c0b334-5bfc-46b8-b9b8-07104a1fce89 downtownthink,place82361696555229;old6bebclosed. SAVE TO FILE AS canonical .rbxl required before newbinarybackup;CtrlScloudplace maynotupdatelocalEA30. Evidence docs/MAP1_ATWATER_CROSSING.md. No publish. Previouspendingcandidatehistorical;activegeneratorunder tools.

LATEST: junction signs/lights BUILT14newparts;23paintpartspreserved. Nativefactory37parts/8two-sidedlabels/2lights+idempotencePASS,8placementraysPASS,Lua syntaxPASS. JunctionFurnitureselected/framed. Roadpaint+furniturelocalSAVE PENDING (canonicalEA30);useFileSaveToFileAs. Evidence docs/MAP1_ATWATER_STREETSCAPE.md. No newFPS/device/visualacceptanceclaim.

LATEST: RiverfrontAppearance applied/live;77waterpieces geometry/material/physics unchanged,daylight/reflectivewater/haze nowframed. Nativeidempotence/freshArena/source syntaxPASS;FPS+visual/deviceacceptancePENDING. Sourcebackedup. Crossings+furniture+appearance LOCAL SAVE PENDING;canonicalstillEA30;FileSaveToFileAs required. Evidence docs/MAP1_WATERFRONT_APPEARANCE.json.

SAVE BLOCKED: requestedagentUI save failedtwice (clickgeometryunavailable;AltFdidnotopenmenu);stopped. UsermustFileSaveToFileAscanonicalproject .rbxl. Thenverifyhash/backupGitHub beforecontinuingMap1. LastlocalhashEA30;newestsourcebackedupd776ec8.

CURRENT: userSAVED TO ROBLOX;latestcloudsaveNOTverified. Studiohome reopened(ecd239d8,name null);usermustopen downtownthink/place82361696555229. Verify37partcrossing/furniture+RiverfrontAppearance beforecontinuing. DO NOT overwritecloudwitholdlocalEA30. Sourcebackupretained;localbinaryexport/GitHubbackupstillpending.

CLOUD SAVE VERIFIED: activeecd239d8,place82361696555229,universe10772964773. Latest37partcrossing/8labels/2lamps/77riverfinish+3sourcesmatchtestedlocalafterreopen. CloudFilemenu=Download a Copy (earlierSaveToFileAsinstructionsobsolete). Downloadlocationpendinguserfullpath;canonicalEA30unchanged. DoNOToverwritecloudwitholdlocal. Evidence docs/CLOUD_SAVE_VERIFIED_20261025.json.

LOCAL SAVE COMPLETE: canonical718546bytes,2026-10-25 17:56:01EDT,SHA5B67464ABB2C600166FA0CAD26BB6FF01F9C87E7702B400AA98694FD7AE94FD9. Includes37partcrossing/furniture+77riverfinish/currentArena+roof/tower/beds. CorrectlocalStudio847a66df-2e33-4cce-b51f-33f1d2e3f6ac,window1442798. CtrlSafterfocusingexactlocalwindowverifieddiskchange. Supersedesalllocalsavependingnotes. Cloudecd239d8untouched. Completebinary+checkpointGitHubbackupnow. NextMap1constructionauthorized.

LATEST SAVED: park107609230 now5originalyoungtrees/25parts,50nativeplacementchecks+build/sourcechecksPASS. Canonical719684bytes/18:04:35EDT/SHA7B412EC319A07A61681807700D63BB633E2CA3216A39213325C8A5FFE2EB4600. Savedlocal847a66df/window1442798+GitHub;cloudecd239d8olderwithoutgrove. SelectionMap1RiverfrontParkframed;see docs/MAP1_RIVERFRONT_PARK.md. Existingpaths/roads/buildings retained. No FPS/visualreleaseacceptance claim.

LATEST SAVED: parknow5trees+4nativebenches+4lowlights/65parts. New40parts,48placementchecksPASS,actual22%seating4/4healthyPASSusingexistingfixture. Original25treepartspreserved. Canonical722053bytes/18:21:51EDT/SHA7090B4B4C7FD5F1F39AA3ACD12DEB9A5ED2F32C37AA1D3FF2FE612B670275E59. Saved+GitHub. ParkSeatingframedEdit;Playstopped/rigscleaned. See docs/MAP1_PARK_SEATING.json. Otherdevices/sizes/FPSacceptancepending;cloudolder.

LATEST SAVED: Franklin/Beaubien35newmarking/coverparts,315pavementchecks+freshPlayruntimePASS;Atwater37andpark65retained. Fixturesnotplacedbecausecornersunsafe. Canonical724469bytes/18:38:18EDT/SHA A18EC83D4EA1FF837E2DE670D4527C2385777C62585DFB5775527077766659F9;local847a66dfauthoritative/GitHubbackedup/cloudolder. Newjunctionselected/framedEdit. See docs/MAP1_FRANKLIN_JUNCTION.md. No publish.

LATEST SAVED: podium30newtrim/nameplate/lightparts;381oldrecords+357oldliveparts preserved. Raw411under420budget. 11offlinechecks+freshPlay387parts/4nameplates/4lightsPASS. Portalfacesexcluded. Localcanonical728778bytes/18:54:17EDT/SHA8B29618824B8E96068A135FBD45723317AEC3CBCB4C48176A81A4F48FBCCE8B5+GitHubbackup;cloudolder. CameraframesriversidenameplateEdit. Evidence docs/MAP1_PODIUM_EXTERIOR.md;visual/FPSacceptancepending.
