# Task5 manual checks still required

Desktop baseline passed; Task5 remains PARTIAL. No public or private publishing is authorized by this checklist.

## Read streaming settings
1. In the open CashCity_RiverWalk_Section2.rbxl, select Workspace in Explorer.
2. Open Properties; search Streaming. The filter was left at Streaming.
3. Report current values for StreamingMinRadius, StreamingTargetRadius, StreamingIntegrityMode, StreamOutBehavior, ModelStreamingBehavior, and StreamingEnabled.
4. If a field is absent, report absent. Do not guess or change it merely to match guidance.

Only StreamingEnabled=true is verified through current tools. Workspace selection is verified. UI automation could set the Properties filter, but clicking failed with coordinate input geometry unavailable and Tab did not move focus; stopped after two failed inputs. UI tree exposed MeshStreamingAndImprovedLods=Default but did not expose required controls. Native inspect_instance also returned an empty properties list. These are tool-observation limits, not proof the settings are absent from Studio.

Official reference already researched in Map1_Task5_NOTES.md: streaming conversion guidance recommends minimum64, target1024, PauseOutsideLoadedArea, Improved model streaming and Opportunistic stream-out. These are reference values, NOT verified settings or a change applied.

## Actual phone baseline (later approved private playtest)
- Record real device model, operating system, Roblox graphics setting and test duration.
- Measure actual device FPS/frame times with an available performance display; report the measurement method.
- Walk lobby -> RenCen/Wintergarden -> stairs -> RiverWalk -> park; check loading gaps and missing collision.
- Use normal gates to reach22%; test small-avatar navigation and touch interactions.
- Record stalls, crashes, overheating or worsening performance over time.
- Test real3v3 with six real players: individual shrinking, whole-team extraction, Results and next Lobby.

Desktop viewport/device emulation does not establish low-end phone performance. No phone or six-player acceptance is claimed.

## Resume
Do not repeat the failed UI-input flow without a changed condition or human-provided values. Independent offline QA can be the next numbered task; preserve these unresolved performance checks in the release checklist. No map/source/settings changes were made in this review.
