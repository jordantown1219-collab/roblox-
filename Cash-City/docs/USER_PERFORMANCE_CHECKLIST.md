# Performance checklist supplied by the user

Saved2026-10-23. Keep this checklist in mind during optimization. It lists possible causes and diagnostic suggestions; it does not establish which cause applies to this project. Verify current Roblox controls/APIs and measure before changing lighting, geometry, terrain or gameplay. Preserve the geographic/visual requirements and compare before/after results.

## Main Causes of Lag in Roblox Games

- Too Many Parts and Unions: Building with thousands of small, detailed parts, overlapping meshes, or excessive CSG (Constructive Solid Geometry) unions forces the engine to calculate too many triangles and edges.
- Inefficient Scripts and Loops: Running heavy code every single frame via RunService.RenderStepped or writing infinite while true do loops without proper yields chokes the CPU.
- Heavy Lighting and Shadows: Using ShadowMap or Future lighting technologies instead of simpler options like Voxel makes the engine calculate complex shadows for every part.
- Unoptimized Terrain: Heavy use of the terrain editor or leaving massive, unseen layers of terrain underneath the map wastes rendering power.
- Memory Leaks and Idle Assets: Keeping large sound files, textures, or disconnected object instances loaded in memory without cleaning them up causes gradual stuttering.

## How to Diagnose and Fix It

- Use the MicroProfiler: Press Ctrl + F6 inside Roblox Studio to bring up the MicroProfiler and look for red spikes to see which systems are eating up performance.
- Switch Lighting Tech: Go to your Lighting service and change the technology from ShadowMap/Future to Voxel if you do not need ultra-realistic shadows.
- Clean Up Parts: Replace duplicate or overly complex unions with basic parts or imported 3D meshes.
- Optimize Scripts: Remove old/unused scripts, space out your loops, and destroy sound or UI instances when they are no longer needed.

## Project application

Review part/mesh/unions and draw calls, per-frame scripts, lighting/shadows, hidden terrain, asset memory and cleanup independently. Use fresh contiguous profiler data and real client/device measurements. Reusable meshes and simpler collision are options, not an instruction to discard accurate city geometry. Keep essential interactions available in low graphics. No lighting downgrade or geometry deletion was made just by saving this note.
