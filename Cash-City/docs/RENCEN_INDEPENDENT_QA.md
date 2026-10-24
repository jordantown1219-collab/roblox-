# Independent RenCen accent and promenade QA

## Podium and glass-facet extension recheck

The subsequent stable extension has **304 accents, 216 source guards and 24 explicit source finish changes**, within the 420-detail ceiling. Five focused detail tests passed in 4.735 seconds. Independent XZ rectangle/overlapping-height checks found **zero source Facade_ intersections and zero vertical-accent contacts with existing FacadeMullion Parts**. All 24 finish records exactly match original indexed records and target only Facade_1307210646; source hashes match. New grid accents are 18 horizontal rails plus six verticals on six of ten guarded glass candidate facets. This does not establish a curved roof or definitive real-world atrium identity.

Runtime integration now validates original-or-owned material/color plus original transparency before finish changes and rechecks CFrame/color/material after the yielding block builds. A concrete remaining preservation gap was reported to Lead: changes to wall Size, Transparency or CanCollide during those yields are not part of the final recheck, despite being guarded initially. Snapshot/recheck these fields before applying finish changes so altered source walls reject consistently. No worker source change was made. Tower/walk commits still remain separate from finish application and can be partial on later failure.

The plan's historical limitation that the podium remains untouched became inaccurate once 24 explicit finish changes were added; author was asked to distinguish unchanged source geometry from intentional finish-only modifications. Real-world photo/material fidelity remains a visual acceptance task. No duplicate glass plane or altered roof record was found in this bounded extension.

## Updated independent recheck after corner fix

The builder subsequently revised generation to inspect all source `Facade_` walls, trim 22 accents and omit nine. Current saved plan has **280 accents**, 31 recorded adjustments and unchanged source hashes. Independent read-only checks confirmed every saved face record still equals its indexed geometry source record and both source hashes match current files. Updated eight RenCen tests passed in 15.394 seconds. The 16 originally reported adjacent facade intersections are resolved by the current all-facade clearance test; the historical report below records the original finding, not the current count.

A separate independent check against **all 19,965 source geometry records**, using all eight oriented box corners projected into XZ plus strict overlapping vertical intervals, found no intersected `Facade_` wall category. It found 497 overlaps with existing `FacadeMullion` Parts and 166 conservative bounding-volume overlaps with five roof WedgePart categories (115 on Roof_1307210646, 16 on Roof_419447162, 14 each on Roof_419447158/164, seven on Roof_419447163). Example: UpperReveal_30258238_00 intersects existing FacadeMullions at indices 11356/11357 by .015106 square studs in XZ. A second categorization found **460 upper-band and 37 lower-band framing crossings, zero new VerticalMullion overlaps with existing FacadeMullion Parts**. Existing mullions occupy face-quarter positions; new vertical accents occupy face centers. No stacked duplicate vertical or coplanar exposed-face flicker was demonstrated. Horizontal framing crossings alone are not defects and do not justify further geometry removal. Wedge boxes overestimate triangular geometry, so the 166 roof results are conservative candidates and must not be claimed as proven solid triangle collisions. Normal native moving-camera visual review remains appropriate; no additional geometry fix is recommended from these broad-phase contacts alone.

Read-only `RenaissanceDetails.lua` integration review: source guards compare facade pose, size, orientation and collision before generation. CityBlockGenerator explicitly anchors new Parts and disables CanTouch; towers additionally disable CanQuery/CastShadow. Walk retains query for the intended collider. Guarding does not compare every source material/color/transparency field or enforce whole-file source hashes in this runtime function; those remain build-time provenance guards. Tower and walk commits happen separately: a late walk-generation failure could leave successfully updated towers with the prior walk. Per-block rollback exists, but this is not an atomic two-block transaction. Lead should report partial completion correctly if that occurs. No runtime or source edits made by this independent review.

October 23, 2026. Read-only review of generators, saved plans and associated tests. Only this report changed. No source, map, Studio or shared build edits. Ran the seven existing `test_rencen*.py` tests with bundled Python: all passed in 13.382 seconds. These are offline data/analytic checks, not native visual or walking acceptance.

## Concrete defect: own-face clearance does not prevent adjacent-facade intersections

An independent analytic probe constructed each accent and guarded facade's oriented XZ rectangle from its exact position/matrix/size, then checked positive-area intersection with other guarded source facades whose vertical extents overlap. It found **16 UpperReveal accents intersect neighboring facade volumes**, four each on towers 100–400. Examples:

| Accent | Own source index | Intersected source index | XZ intersection area (studs squared) |
|---|---:|---:|---:|
| RenCen_UpperReveal_419447171_06 | 15364 | 15361 | .24201 |
| RenCen_UpperReveal_419447171_10 | 15376 | 15379 | .27294 |
| RenCen_UpperReveal_419447172_28 | 15610 | 15613 | .47091 |

The current tests verify a .1-stud gap from each accent's own facade, height limits and face length, but not neighboring faces. The nearly full-face reveal length (source length minus .08 studs) reaches corners where the adjacent angled wall clips it. Collision is disabled, so this is a clipping/detail-integrity risk rather than a new solid obstruction. No screenshot was taken to establish its exact appearance. Safest bounded correction: trim or omit the affected reveal records while retaining source facade geometry, and add an adjacent-volume regression. Lead decides integration; this worker made no correction.

## Source guards and determinism

The detail plan preserves complete face records and source indices, includes source-file hashes, retains seven building records, and has 289 decorative detail records with no source finish changes. Tests compare the saved plan against fresh generation, validate matching source-face records and reject one entirely missing source mass. Stable inputs generate stable output. However, `make_plan` itself selects source faces primarily by name and does not independently enforce arbitrary input matrix orthogonality/finite values or expected face cardinality. Full hash/record checking by the integration consumer is essential; sourceIndices are not durable IDs after a geometry reorder. The `.1` gap guarantee is local to each referenced face, as the defect above demonstrates.

An exploratory comparison also found some accent centers inside the original unsimplified 2D source polygon. This alone is not a defect: rendered facade simplification/chord positions can differ from original footprint rings. It must not be presented as proof of inward normals. The adjacent **rendered facade volume** intersections above are the concrete actionable evidence.

## Promenade review

The walk generator derives an 80-meter straight subsection from the identified source path, keeps a 2.5-meter corridor on land and inside the buffered path, rejects building/road/standing-collider intersections, and emits 81 records: one transparent continuous collider plus 80 noncolliding Concrete panels. Source hashes and saved-plan equivalence are tested; generation does not alter source geometry. Deterministic panel-tone variation has no random seed dependency.

The new top is .41 studs versus the existing estimated .35 path datum, an additive .06-stud rise. This is explicitly an optional material study, not repair of a demonstrated source hole or surveyed terrain. Visible panels share the collision top; narrow joints reveal the older surface below, which needs moving-camera review for seams and depth artifacts. The continuous collision rectangle does not establish safe avatar traversal at its boundaries, exact streamed collider presence or full-height human clearance. Analytic standing-collider filtering is useful but does not replace native raycasts/actual routes or detect every unsupported object class automatically.

## Integration and claims gate

Lead must verify saved source hashes and exact guarded face records against current live geometry before accepting accents; set decorative anchored/CanCollide false/CanTouch false explicitly, preserve panel transparency, and retain only the intended promenade collider. Do not assume `collide:false` in JSON alone disables native CanTouch. Existing manually constructed landmarks and source surfaces must remain outside replacement ownership. Native CityBlockGenerator acceptance and rollback are separate from visual geometry acceptance.

Plans already label colors, spacing, panel layout and flat grade as estimates and leave native/visual acceptance pending. Retain those limitations. References do not make these authentic reconstruction or exact current/as-built geometry. No furnished authentic interior, surveyed ramp/terrace, safe walking route, FPS improvement, device acceptance or multiplayer result is demonstrated here. Hold final visual acceptance for the 16 neighboring-facade intersections until corrected or explicitly reviewed.
