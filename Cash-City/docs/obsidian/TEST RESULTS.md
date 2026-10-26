# Cash City — evidence and acceptance limits

## Verified records
- Source syntax tests passed after the latest module/Arena changes.
- Tower A normal startup: 39 floors, 156 apartment layouts, 468 doors, 156 windows, 624 enabled prompts, 38 upper stair connections. No ValidationFailure flags observed at that check.
- Added upper stairs were walked at 22% size in two segments: 60 waypoints from Level 11 to 25, and 60 from 25 to 39; health 100 throughout.
- Earlier dining-seat check verified native Occupant, SeatPart, SeatWeld and release on a fresh 22% rig; exact seat geometry stayed unchanged. This was not player-input testing.
- Lights/signs: 228 new noncolliding/nonquery parts, 76 enabled shadow-free SurfaceLights, 76 labels; existing 53,328 preview BasePart positions/sizes stayed unchanged.

## Desktop Studio performance
All listed samples use the existing 10-second fixture at 1223x710. They do not prove mobile, multiplayer, long-session or release performance.

| View | Mean FPS | 95th frame time | Worst frame | Client memory at end |
|---|---:|---:|---:|---:|
| 39-floor build, controlled corridor view | 60.06 | 18.35 ms | 19.83 ms | 2746.86 MB |
| Level 39 landing with stair lighting | 60.18 | 17.91 ms | 22.96 ms | 2806.86 MB |
| RiverWalk, Studio foreground | 60.06 | 18.79 ms | 24.46 ms | 2909.95 MB |
| Renaissance Center approach, foreground | 58.10 | 23.32 ms | 106.20 ms | 2923.93 MB |

An initial uncontrolled-focus outdoor sample was 14.98 FPS. Activating Studio was followed by a 60 FPS sample, consistent with background throttling, but camera drift prevents isolating focus as the sole cause. No geometry was deleted based on that result.

## Evidence files
The GitHub `Cash-City/docs/` folder and this project's copied docs contain:
- `REMAINING_APARTMENTS_RESULTS.json`
- `RESIDENTIAL_STAIR_WAYFINDING_RESULTS.json`
- `OUTDOOR_PERFORMANCE_39_FLOORS.json`
- Earlier batch result files for Levels 03–11.

## Still required
Manual visual/brightness acceptance; reproducible approach-spike investigation if it persists; remaining size/descent/interaction coverage; real phone/tablet/console and multiplayer tests. Do not equate source generation, enabled prompts or a stationary desktop sample with a finished game.

## 2026-10-26 — Approved apartment living/dining finish integrated and saved
Owner approved the revised sample direction. Reused ResidentialRealismPilot across 39 floors/156 apartments; added 6240 anchored detail parts and 156 localized lights, retaining 2652 references to original objects. Runtime counts verified before stopping Play; existing 22% walking probe previously passed four waypoints in Level39 Apartment04, health100. Edit integration verified identical counts and retained references. Arena now applies all finishes on startup; this final integrated startup is awaiting fresh Play validation. Source syntax test BuildAcceptance.test_lua_sources PASS. No new FPS result available; do not infer performance acceptance from counts. Individual room, full-size, mobile, multiplayer and release acceptance remain UNVERIFIED. YouTube-only TV declined/unsupported; no TV substitute implemented.
Saved canonical CashCity_RiverWalk_Section2.rbxl at 2026-10-26 11:44:32 EDT, 853211 bytes, SHA256 AFDDD61B0DF67CA90CD1254EF879ACB1BC9C8B7278A6036752162D6EC30D25B9. Immutable checkpoint checkpoints/CashCity_ApprovedApartmentFinish_20261026T114432.rbxl and Obsidian Backups copy created. Baseline39-floor checkpoint and approved one-room pilot retained. Original Studio847a66df is stopped in Edit, Level01 Apartment01 living/dining framed; backup Studio untouched. No publishing/helpers/paid credits. Included usage97% used at checkpoint; stop before1% reserve. Next: fresh startup of all156 finishes, foreground existing performance sample, then next room visual pass. Do not recopy floors or revisit Wintergarden doors.