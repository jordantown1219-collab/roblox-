# Civic facade independent QA

Prepared `tests/STUDIO_CIVIC_FACADE_CHECK.lua` as a callable native harness: require a fresh harness ModuleScript, then call its result with `(freshCivicFactory, decodedPlan)`. Lead alone installs/runs fresh candidates. The test constructs only the plan's12 wall fixtures in original source CFrames plus a manual sentinel under temporary ServerStorage; no active-city parts are modified. Every case destroys its fixture folder.

Ten prepared cases: repeat generation/no accumulation with expected body finishes and unchanged source geometry/collision; all decor anchored/noncolliding/nontouch/nonquery/no shadows/no embedded scripts and source IDs; manual named-folder refusal; missing/moved/resized/rotated source rejection with prior details preserved; matching generated-preview manifest adoption; foreign manifest refusal; staged decor error recovery; transactional body-finish failure recovery. Native execution is pending Lead. Syntax parsing alone is not native acceptance.

Read-only source review found two concrete likely defects requiring native reproduction:

1. Source matching compares name/position/size but not orientation. Rotating a wall in place preserves those fields, so stale ornaments may be accepted on a modified wall. Harness case `changed source orientation rejected` requires rejection and preservation.
2. Body finishes are written sequentially inside a protected call without restoring earlier writes on later failure. A plan with invalid material on face2 may change face1 before rejecting, despite retaining the old detail folder. Harness case `failed body finish is transactional` checks all original finishes remain intact.

Additional bounded limitation: no per-root build lock/commit identity revalidation or immutable input snapshot is visible in the reviewed source. Its four yielded detail batches allow overlapping rebuilds or external ownership changes; do not reuse this utility concurrently or claim general transaction safety. This harness focuses on the assigned static source and rollback contract; concurrency hardening remains a Lead decision.

The plan has12 facade bodies and300 noncolliding accents based on preserved OSM shells. Architectural bay spacing is estimated, as the plan states. This does not establish authentic interiors, complete historical accuracy, multiplayer playability, visual quality, or any FPS improvement.

QA changed only this document and the new native harness; no source fixes, live Studio mutation, assets, or purchases.
`nLead native execution update2026-10-23: reproduced8/10 (orientation and partialfinish failures). Added orientation matching and prevalidated finish values before writes. Fresh candidate10/10PASS. No concurrency claims; single-writer restriction retained.
