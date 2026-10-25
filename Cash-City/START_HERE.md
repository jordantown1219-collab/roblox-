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
