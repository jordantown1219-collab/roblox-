# Map 1 Task 3 — connection acceptance
Status: PASS for the implemented connection and the checks below. Map is not release-ready.

## Changes
- Source-derived park connection:68 anchored paving parts,428.786011m,87 waypoints. It follows existing OSM RiverWalk69706033 then an original short join into the existing Hart Plaza path106403203. Flat grade is estimated.
- Existing80m walk and both40m extensions unchanged; no other district developed.
- Corrected enclosure that cropped the existing park and a portion of the completed complex. NewX[-1850,750],Z[-650,1250] derives from Hart Plaza/completed-complex footprints plus outward margin; ceiling/fall rules unchanged.
- Existing park paving atZ1119 was outside the formerZ850 cutoff. New bounds restored1098 preview parts using their original saved render states.13625 exterior parts remain screened;17 water blockers now cover includedbank.
- Old38partboundary and old modules preserved in ServerStorage.Map1Task3Before_1792858704; entirebefore-place checkpoint is onGitHub.

## Passed evidence
- test_playable_block.py:5/5PASS1.497s, including all Hart Plaza bounds/completed RenCen face footprints/current gameplay anchors within new enclosure.
- test_rencen_walk.py:7/7PASS15.105s, including unchanged existing paving, endpoints meeting, bounded part count and waypoint spacing.
- Native preview:87/87 floor rays supported route within.16stud expected tolerance (allows existing.55 road vs.41 paving).
- Native runtime:573 updated perimeter/water rays,0 misses.
- Existing STUDIO_RIVER_ACCESS_WALK fixture reused in memory forone fresh22% scriptless rig overtheENTIRE87-waypoint route. WalkSpeed16,JumpHeight7.2*.22;all87 reached,health100,supportfloorchecksPASS. Full result JSON retained separately. No realplayer scale/stats changed; rig/template/progress objects removed.
- Native park paving visible after restoration; both finished extensions remain present.

## Measurements
Native connection/enclosure assembly0.4184043s.
Foreground park-facing desktop:10.001097s,600frames,59.993421FPS,p9518.475100ms,worst21.569099ms.
Camera-1100/100/1220 looks-1260/2/1020; viewport1593x710,qualityAutomatic,StreamingEnabledtrue,600loadedparts duringthisstreamed sample. Tiny rig was running. Not a matched baseline orlow-end mobile result.
Measurement connection/camera binding removed, prior camera restored, Playstopped. Final Edit camera points at park join.

## Unverified / next
All-four-size/all-route traversal, reverse full route, realinput/multiplayer/device acceptance remain forTask6. Current-expanded-boundary realplayer reset positions should be rerun there; old-extents live resets already passed but not relabeled as new-extents tests. Road-screen visual approval remains pending. Fullmatchloop isTask4, not performed here. Fullbuild preview/embedding needs reconciliation beforeTask6; working binary iscanonical.

## Ancillary PNG request
User asked for a marked PNG duringTask3. Renderer failed twice (empty roadsegment, then Studio numeric-key object/array conversion); stopped underprojectrule. Userthenexplicitlycanceled the PNG request andauthorizedcontinuingTask3. NoPNGexists/noPNGclaim. Renderer/native coordinates remain localwork files only.
