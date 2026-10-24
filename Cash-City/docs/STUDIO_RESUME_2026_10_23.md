# Studio resume test — 2026-10-23

Target c4139803-f786-4d97-8483-816a277d6b29, open filename v0.10; Workspace.WorkingDesignVersion confirmed 0.14. Existing sources and scenery were preserved. Started and stopped Play; returned to Edit. No publishing or Rojo synchronization.

## Observed passes
- Barracks lobby and cartoon army UI rendered. Solo Studio Test button was activated through native mouse input. A runtime-only button rename allowed unambiguous targeting and was discarded on Stop.
- City deployed; server arena contained 20,810 descendants and four registered workshop interactables. StreamingEnabled true.
- Actual keyboard E held at each Amber gate in order. Results: stage 1 scale .65 health80; stage2 scale .40 health60; stage3 scale .22 health40. WalkSpeed16 throughout.
- Both extraction pads passed native raycast ground-clearance and enabled-prompt checks.
- Actual keyboard extraction prompt produced: Amber wins — everyone extracted!

## Limits and outstanding issues
Solo character was repositioned with server PivotTo near gates/extraction; this does not validate walking navigation or the full streamed route. No gameplay attributes, stage or health were artificially advanced. Solo victory does not validate multiplayer team requirements. No touch/controller acceptance.
Client diagnostic samples remained around8–10FPS; no improvement or real-device benchmark claimed. Output repeated asset203785492 type mismatch; reference not found in project source search, origin unresolved. One GetPivot-on-Attachment error was caused by the inspection command itself, corrected to WorldPosition, not by game scripts. No game-script exception observed during this bounded run.

Next: investigate presentation/frame pacing and warning origin; complete real-block workflow, accessible interior/windows, and six-client regression tests. Keep reserve30 credits and do not assume old Rojo server matches current source.
