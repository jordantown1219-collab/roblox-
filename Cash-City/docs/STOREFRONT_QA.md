# Optional storefront-window QA

Read `LESSONS_LEARNED.md` and latest development status before this bounded review. Generator mutation/completeness fixes are existing work and were not duplicated.

Independent harness: `tests/STUDIO_STOREFRONT_WINDOW_ADVERSARIAL.lua`. Lead must run it with fresh current candidate `BuildingTemplates` and `BuildingInteractions` modules under `script.Parent`; do not require cached original modules. All generated Instances are held in one temporary ServerStorage folder and cleaned up after outcomes are collected.

Interface agreed with City Builder: `Templates.storefront(config, doorTemplate, windowTemplate)` is backwards compatible. The optional sliding-window template is cloned for both front apertures. Without it, existing fixed panes remain. With it, static panes must be absent; smaller components need aperture fillers. No runtime registry architecture changes are implied.

The supplied component must satisfy the existing Slide/X registry contract, fit its frame across its complete travel, fit the storefront aperture, preserve anchored geometry, retain its prompt and tag, contain no embedded scripts and have cloneable descendants. Default opening height is 6.5 studs, with center 6.75 above the floor; default building front is local Z=-14. The existing window factory permits width6..12 and height4..8; not every factory configuration fits every storefront. Minimum frontage width24 with doorway8 leaves only5 studs per aperture and must reject even a minimum-width6 window.

Prepared 17 checks cover default shell/door behavior; two independent cloned windows; no static double glazing; transformed placement; 25 moving-sash sweep samples; malformed contract, oversized moving pane, unsafe anchoring, embedded scripts, non-Archivable descendants, mismatched frame metadata, and incompatible frontage. The independent native harness has not yet been executed. Offline Lua syntax parsing passed; this is separate evidence only. After City Builder reported source ready, QA read the current implementation and confirmed the agreed third-argument interface and direct-child clone topology match the independent harness. No source change was made by QA.

Physical review: existing factory panes are parallel at local Z±0.18 with thickness0.12, leaving0.24 separation; moving pane is width/2-0.3 and travels exactly that distance, remaining inside the frame. Existing registry obstruction and character-root tests provide prior bounded evidence; this optional storefront placement still needs fresh registry sweep, real keyboard, scaled-player reach/line-of-sight, moving-character obstruction, multiplayer simultaneous use, and touch/controller checks. No FPS or playability gain is claimed. Generated shell/window components are original training fixtures, not authentic Detroit interiors.

QA owns only this document and the new harness. No source changes, live Studio mutations, purchases, or spawned agents were used.
