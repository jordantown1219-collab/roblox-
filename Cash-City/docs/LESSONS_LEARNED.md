# Project decisions and mistakes to avoid

Updated2026-10-23. Read with DEVELOPMENT_STATUS.md before edits.

- Preserve originalv0.1, previous variants, and a backup of the current generated place before rebuilds. Never publish or close/kill Studio automatically.
- Current workingfolder Detroit_Riverfront_v0_14; Studio target c4139803-f786-4d97-8483-816a277d6b29 has oldv0.10 filename but Workspace.WorkingDesignVersion0.14. Rediscover target every session; filename alone is insufficient.
- User approved individual player shrinking and whole-team extraction. Keep scales1/.65/.40/.22, speed16 and existing health/damage/armor balance unless asked to change them.
- Lead owns liveStudio/build/integration/shared status. Helpers have exclusive named files. Reuse helpers for bounded tasks; no simultaneous writes to the same module. Four total active slots including lead.
- Studio ModuleScript require caches survive source edits within the same DataModel. Test candidate source in a fresh temporary ModuleScript, then destroy it. The first completeness RED against cached original reported0/7; isolated previous snapshot version correctly reported4/7. Do not confuse stale cached execution with current source.
- Static/offline assertions are not multiplayer, physical gameplay, visual or device acceptance. Actual solo gate+extraction and window keyboard tests are separate evidence. Report untouched pending checks explicitly.
- Native profile snapshots can contain paused/stitch history. An initial mixed-history mean was invalid; do not report it as FPS. Use contiguous fresh complete frames with regular and absoluteIDs and separate pause/spike exclusions.
- LowFPS occurs even in sparse lobby; measured Present stalls do not prove a GPU workload cause. Do not delete geography based on this alone. Three Studio processes and limited freeRAM require inspection before launching6clients; no process termination without user action.
- City footprint/road source accuracy is distinct from estimated widths/flat elevations/original training fixtures. No authentic interior claim for procedural training components.
- Template generator must snapshot inputs before yields, use stable blockID, protect manual content/commit ownership, reject non-Archivable descendants and clean private clones. Tests must exercise rollback+lock release.
- Ordinary allowance and credits are distinct. Keep30credit reserve; do not buy or redeem resets. No hourly automation configured.
- Git commit currently blocked by missing authoridentity. Do not invent user identity or alter global config; saved source/standalone place/backups remain the checkpoint.


Latest2026-10-24: Model:ScaleTo also scales Humanoid.WalkSpeed (16->3.52at22%). Match production's explicit16 reset in navigation fixtures before diagnosing timeouts as geometry bugs. Never scale a seated/welded character: SeatWeld can scale connected furniture; use fresh scriptless rigs and destroy them between seat cases. Wait for WorldLoading spawn placement to finish before relocating a real player for prompt checks; verify serverdistance/LOS first. Hold testcamera using temporaryLast-priority binding, verify actualstart/end, unbind afterward. User's normal localscreen is distinct fromwhiteMCP images/WGCtimeouts; do not change geometry/lighting merely to repair a broken capture.

2026-10-25cloudsave: currentStudioFilemenu shows Download a Copy forlocalexport;do notkeepinstructingSaveToFileAswhenabsent. Userphotoverifiedmenu. Cloud save andlocaldownloadareseparate;freshreopen+source/geometrymarkersverifycloudpersistence,localfilehashverifieslocalcopy. Currentcloudplace82361696555229/universe10772964773;protectnewercloudworkfromoldEA30localbaseline.

2026-10-25park: rawJoinedParkmaylieunderhigherJoinedWalk. Subtractrenderedpavedpolygons beforeplanting;nativegroundraysmusthitexposedgrass. Exactlocal-windowCtrlS canfinishafterthefirstimmediatefilestatread;allowboundedI/O waitbeforeassumingfailureorissuinganotherSave.
