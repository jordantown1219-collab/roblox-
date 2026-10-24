# CC-004 performance investigation

October 22, 2026. This task read prior actual observations and prepared a temporary sampling harness. It did not run Studio, change settings or geometry, close processes, publish a place or collect a new benchmark.

## Existing measured evidence

`docs/DESIGN_PASS_RESULTS.md` records a Studio MicroProfiler capture: 120 engine frames in 3,711 ms, with only 30 main-thread Presents. Present totaled 2,661 ms (about 88.7 ms each). The recorded client-script contribution was about .25 ms per presented game frame and physics about .93 ms. A contemporaneous snapshot had 4,327 streamed BaseParts, 17 draw calls and 25,209 triangles. Multiple open-place render jobs were observed. These historical figures identify the dominant recorded presentation time; they do not identify its driver/window cause.

`POLISH_STATUS.md` records a separate starting-room comparison: 106 loaded BaseParts, default 9.37 FPS/worst 186.24 ms, and Low Graphics 8.71 FPS/worst 205.27 ms. A later sample after the user closed visible extras was 9.86 FPS/worst 139.52 ms, still 106 parts. Three processes remained visible to the earlier OS inspection, with only one titled window; none was terminated. The user confirmed movement was choppy. The historical profile and these samples are different captures, not one interchangeable benchmark.

This evidence makes deleting city scope an unjustified first response. It does not establish that the full city is inexpensive on actual phones or in a standalone client. No FPS improvement has been demonstrated. Current process/window state must be checked afresh by Lead before drawing conclusions from those older observations.

## Temporary measurement tool

`tests/STUDIO_PERFORMANCE_SAMPLE.lua` is a self-contained Client-only execute-Luau sample intended for Lead. It requests 10 seconds and reports actual elapsed wall time, render callbacks, average callbacks per second, median/p95/worst observed render interval, total-memory readings, loaded/unanchored part counts, starting camera position/viewport and streaming flag. It creates no objects, attributes, profiler session or persistent settings. Its one RenderStepped connection disconnects before result construction and also disconnects on synchronous failure.

This harness is prepared, not engine-validated in this task. Lead should first compile and run it in the existing approved Play client, then record the exact returned JSON. Ten seconds may run slightly longer if scheduling is delayed; actual elapsed is authoritative. Memory and descendant scans happen outside the timed render window. The first callback is excluded from frame-interval percentiles because there is no preceding observed render. FPS includes all callbacks divided by elapsed wall time. Worst interval is a callback gap, not GPU execution duration; a final stall after the last callback is reflected in wall FPS but may not appear in the interval table. Missing callbacks produce missing percentile fields rather than invented zero timing.

## Next valid comparisons

1. In the same project/version and starting-room camera, record current visible Studio/session state and quality/resolution. Warm up streaming for at least 15 seconds. Bring the game viewport to the foreground without leaving it covered during capture. Run three separate samples, preserving all results. Do not change geometry or quality between them. Do not mistake an execution-tool overlay/background throttle for an active gameplay measurement.
2. If feasible with the existing authorized local workflow, compare a standalone/local Roblox client with the same project revision, starting position, camera, viewport resolution, graphics quality and warm-up. Do not publish to obtain this comparison without approval. If matching client setup cannot be achieved, label the comparison unavailable rather than substituting a different game/map. Device, power mode and capture/foreground context belong in the record.
3. Only after a usable presentation baseline, measure a fixed walking route through Hart Plaza and dense streets with identical camera/input path. Record server/physics/network timings separately. Ten-second stationary diagnostics cannot replace sustained route and device measurements.

The decision order is evidence-driven: if the sparse lobby remains near 10 FPS in foreground Studio, continue investigating presentation/background/frame pacing. If the same revision performs materially differently standalone, investigate Studio-specific behavior before reducing city scope. If dense-route cost regresses against a stable lobby in the same environment, profile actual render, memory, physics and script costs there before targeted changes. None of these outcomes is assumed.

No new numerical performance result, root-cause diagnosis, mobile/tablet/console result or release acceptance is claimed by this task.
