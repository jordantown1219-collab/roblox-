# v0.12 polish candidate

Preserved v0.11 and earlier folders. Current live MCP target is c4139803-f786-4d97-8483-816a277d6b29, still named v0.10; WorkingDesignVersion is 0.12. Source and generated v0.12 are saved independently. Do not use the old Rojo service.

New work: HUD brightness 100/85/70/55 percent, appearance reset, 72 radial HSV swatches across three saturation rings, selected-color preview. Free dimming is available in release. Wheel is Studio-only preview; all live releases currently lock it. No purchase prompt, pass ID, price, entitlement or persistence is configured yet. Preferences last for this play session. This is not completed paid monetization.

Native UI acceptance: actual clicks opened Settings, changed brightness to 85%, opened wheel, chose blue (0,0,1), and reset brightness to 100% and hid wheel. Initial layout was 310x410. Phone/controller and final visual review remain pending. Full offline suite: 15 cases plus rule and existing panel assertions passed before final paving-only material update.

Street polish: 120 noncolliding glazing/stone-course accents on ten nearby facade segments; warm granite paving on 107 existing plaza primitives. Total geographic budget 19,965/20,000. Existing footprints, collisions, roads and ground top heights retained. Source sectors are retained in generated geometry. Live accents are in StreetLevelPolish folders. These are estimated architectural details, not an authentic reconstruction or completed buildings/interiors.

Reference: Detroit Hart Plaza National Register nomination documents carnelian granite paving: https://detroitmi.gov/sites/detroitmi.localhost/files/2018-08/2018%2007%2031%20Hart%20Plaza%20Draft%20NR%20Nomination%20Form%20FINAL%20w%20maps.pdf . Color is a game approximation. Riverfront route context: https://www.detroitriverfront.org/map . Paid-pass future implementation: https://create.roblox.com/docs/production/monetization/passes . New request authorizes settings/monetization preview despite older DESIGN_PASS.md excluding new monetization.

BLOCKER: user now confirms movement is choppy. Current diagnostic 7 FPS. Previous profiling showed Present/display pacing dominant, exact cause unknown. Three Studio copies were connected. Asked user to close extra copies, retaining visible editing window; response pending. Do not close/kill Studio automatically. Re-list fresh and sample a comparable Play test after isolation. Do not call release ready. Complete vehicle/weapon, authentic city detail, full walking route, mobile/controller, six-player, loading and standalone/device performance acceptance remain pending.

## Fresh isolated-view comparison
Starting room position (-3800,4.04,-2530), streaming enabled. Eight-second default sample: 75 frames, 9.37 FPS, worst186.24ms. Low Graphics ON sample:8.71 FPS, worst205.27ms, only106 BaseParts loaded in Workspace. No improvement demonstrated. Restored Low Graphics and stopped Play. Three Studio copies remained connected. This argues against loaded city geometry as the primary cause in this sample; it does not prove standalone city performance. Need one-Studio/foreground comparison, then device measurements.

Retest after user closed extra visible windows: 9.86FPS/worst139.52ms at106 parts. OS still showed3 Studio processes, onlyPID48296 had visible windowtitle; PID50488 and55916 no title. Did not terminate processes. Current foreground-window sample requested from user and scheduled as temporary client task (ForegroundTestFPS/WorstMs/Done attrs). Rendering settings Automatic/EnableFRM true; no changes made.
