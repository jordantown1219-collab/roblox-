# Task5 performance — PARTIAL

User approved advancingTask5 while deferring real3v3 to a private six-player playtest. Publishing still requires separate approval. Latest budget override uses remaining included five-hour allowance only; no paid credits.

Before-place backup c1b9f27/checkpoints/Map1_Task5_before_20261024.rbxl. Canonical binary unchanged: SHA256 AE6AA260681DEAB439CF809D4FE6F3FA44FC0F072842355B70E8795418625E68.

Existing native sampler ran in normal Practice, foreground desktop, fixed RenCen camera:60.045FPS over10.009seconds/601callbacks; p9518.343ms, worst21.301ms. Viewport1223x710,Automaticquality,6128loadedparts/44unanchored,engine memory2904->2799MB. Camera position verified start/end. No causal improvement or low-end device prediction. Earlier samples used a different viewport/streamed set.

StreamingEnabled verified true in Edit and Client. Initial direct read of StreamingMinRadius failed as unavailable; protected individual reads found radius/integrity/stream-out/model controls unreadable in this command context. No settings changed and no repeated blind patch. Official docs identify these as non-scriptable Studio properties:
[Workspace](https://create.roblox.com/docs/reference/engine/classes/Workspace), [streaming conversion guidance](https://create.roblox.com/docs/workspace/streaming/techniques).
Reference guidance: review Improved model streaming, PauseOutsideLoadedArea, min64/target1024 and Opportunistic stream-out in Studio Properties. These are documentation recommendations, NOT verified current values or changes applied.

Desktop sample shows no sustained frame-rate blocker. No production optimization applied without a measured offender. Actual low-end mobile FPS, loading delay, real multiplayer load and device controls remain unverified. No release-ready claim.

Cleanup: sampler listener disconnected, temporary render binding removed, camera restored, Play stopped. No permanent test objects/source/map edits; saved binary retained and backed up. Existing sampler is the actual test; no new harness or full playtest.

Next: manual streaming Properties review, low-end phone measurement on the same route/view, then optimize a demonstrated bottleneck and compare under matched conditions. Task4 real3v3 remains pending private test; no automatic publishing.
