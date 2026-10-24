# Original training sliding window candidate

`BuildingInteractions.slidingWindow({width=8,height=5,duration=.8})` returns an unparented tagged Model. Width supports6..12studs, height4..8, duration.25..2seconds. Model origin is the full frame center. Place with `window:PivotTo(cframe)`, parent into the intended registry root BEFORE `InteractionRegistry.start(root)`. No per-window script, remote, registry changes or automatic city placement. LobbyInteraction remains unset; existing match/team/alive/range/LOS/obstruction validation applies. For an isolated lobby QA fixture only, Lead may explicitly set LobbyInteraction=true before registry start.

The original two-track horizontal sash uses Motion=Slide, Axis=X. Frame rails run along localX; travel is exactly width/2-.3studs. The sash and fixed pane share width=travel,height=height-.6,thickness=.12, with respective track centers Z=-.18and+.18. At full opening the sash sits behind the fixed pane with.24stud surface clearance. Side and upper/lower frame clearances remain.1stud at endpoints. Colliding frame and panes are anchored; prompts/hidden markers are noncolliding and nonqueryable. This assembly is for an isolated original training opening only, not a claim that Detroit commercial glazing opens. Existing storefront fixed panes and hinged entrance factory are unchanged. No sound or authentic city interior supplied.

## Evidence

Focused native check was written first. Offline export assertion failed initially with `AssertionError: slidingWindow factory missing`. After implementation: factory export assertion and syntax parsing of both changed/new Lua files passed using the existing Lupa dependency. Independent numeric checks passed75 rail samples across6x4,8x5,12x8sizes. These are source/numeric checks, not Roblox engine validation.

## Native acceptance still required

Lead should execute `tests/STUDIO_SLIDING_WINDOW_CHECK.lua` with updated BuildingInteractions ModuleScript. It creates3temporary rotated fixtures high above map, checks25motion samples each against its actual frame/fixed pane and external collision geometry, verifies exact endpoint travel/restoration, invalid config rejection, tag/permission contract and no per-instance scripts; fixtures clean up even on failure. No actual engine test was run by this worker.

Then register an isolated fixture before Registry.start, activate its actual ProximityPrompt and verify server open/close, both approach sides/LOS, obstruction and recovery, duplicate requests/cooldown, scales1/.65/.4/.22, and two-client replication. Touch/controller, audio, authentic window deployment and publication remain pending. Do not install in the existing storefront aperture without removing its fixed glazing and checking shell clearance; this task deliberately adds no placement integration.

## Registry transform/clearance review (source only)

The actual Slide controller computes `home*CFrame.new(Vector3.new(1,0,0)*travel*alpha)`. Moving.PrimaryPart is the sash, whose original rotation matches the frame, so its localX remains the rail direction after the complete assembly is rotated/positioned. The native geometry check uses the same transform. MotionPivot is required by the common contract but its position is unused for Slide.

`record.clear` excludes the ENTIRE window Model, so its FixedPane, SideFrame and Rail parts will NOT cause a registry obstruction rejection. This also means registry acceptance alone cannot validate internal clearance. The independent25-sample check explicitly includes fixed-frame/pane boxes; the source-derived gaps are.1stud at rails/jamb endpoints and.24stud between pane surfaces. Native geometry verification is still required.

Concrete acceptance risks: (1) ProximityPrompt.RequiresLineOfSight=true uses native visibility while the server ray excludes the whole assembly; the control sits near the left frame at localZ=-.65, so rear approach may be hidden by the frame even though server validation would allow it. Test rear/front actual prompt visibility before calling this usable from both sides. (2) Existing registry external obstruction boxes shrink dimensions by.12, clamped to.05; a.12-thick sash is therefore probed at.05thickness. A thin external obstacle touching the outer.035stud of a face can be missed by that approximate probe. This is inherited controller tolerance, not proof of exact physical clearance. (3) Explicit character-root sweep margins can intentionally reject activation if a player is standing too near the sliding panel; step away alongZ before diagnosing a broken window. No source changes made during this review.

## Lead native evidence —2026-10-23

Lead reported actual Studio geometry PASS for3sizes×25samples, plus an isolated temporary server-registry fixture opened and closed using actual keyboardE. Camera was explicitly directed toward Control to satisfy prompt LOS. Lead stopped Play and discarded the fixture. This establishes native geometry and one keyboard open/close path only. No city window was deployed. Character scales, multiplayer replication, touch/controller input, moving/static obstruction recovery, and rear approach visibility remain pending. Earlier source-only notes above describe the worker's own checks; this paragraph records Lead's subsequent native verification.

## Registry safety harness (pending Lead execution)

`tests/STUDIO_WINDOW_SAFETY_CHECK.lua` is a native Server/Edit harness requiring BuildingInteractions, InteractionRegistry and InteractionRules in ServerScriptService plus ReplicatedStorage.SmallSignals.Config. It constructs a separate rotated fixture at(25000,20000,25000), starts a registry for its temporary root, verifies actual registry closed/open frame endpoints, accepts an empty forward/reverse sweep, rejects a colliding external stationary Part for each Config.Scales-sized probe and recovers after each probe is destroyed. It also checks pure range outputs for every configured scale. The probe is a scaled anchored physical Part, NOT a real scaled character. No player state or production modules are changed. No duplicated3x25frame geometry sweep.

The temporary root is destroyed on assertions or success; Registry's root.Destroying handler disconnects its listeners. Lead should execute with current modules in an isolated Studio session/context and save the returned PASS or exact failure. Syntax parsing passed offline; native assertions have not yet been executed. Real character-root margins, actual scaling, moving obstruction recovery during tween, multiplayer and platform inputs remain pending even if this harness passes.

## Actual-character harness (pending native execution)

Lead reported physical-probe registry safety PASS at all4configured scales. The new `tests/STUDIO_WINDOW_CHARACTER_CHECK.lua` targets the separate explicit HumanoidRootPart safety branch. Run its text in Server Play with EXACTLY1player and current server modules; it refuses multiplayer sessions. The synchronous harness captures original character identity, pivot/GetScale, player Scale attribute (including unset), root anchoring/linear/angular velocity and every character BasePart.CanCollide. It temporarily anchors that root and disables body collisions to ensure physical overlap queries cannot short-circuit the explicit noncollidable character-root branch. It places an isolated window at(26000,22000,26000), scales the actual character through Config.Scales, positions its root in the sash sweep and asserts both directions blocked; then moves the root20studs along localZ and asserts both directions clear.

Every restoration step is independently protected; original scale/pivot, collision values, attribute, anchoring/velocities and registry root/listeners are restored on success or assertions. No stage/progress/health/Humanoid settings are changed. The test refuses an unexpected character identity change during placement, reports cleanup failures explicitly, and does not move a replacement character. Avoid respawning or other concurrent character actions during execution.

Offline syntax parsing passed. Native actual-character assertions remain pending Lead execution. Even a PASS establishes the explicit root-blocker branch at actual scales only: it does not establish physical crush prevention, tween interruption/recovery, native input at scale, normal body-collision movement, multiplayer or mobile/controller behavior.

## Lead acceptance update2026-10-23
Physical probe safety harness passed at4configured sizes. Actual solo character-root safety harness passed at4configured scales with scoped body-collision disablement to exercise the explicit root branch, then restored state. This is not animation/crush, touch/controller or multiplayer acceptance.
