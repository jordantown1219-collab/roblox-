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
