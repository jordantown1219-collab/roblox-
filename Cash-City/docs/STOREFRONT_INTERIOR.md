# Original game interior component

`StorefrontInterior.build(building, config)` adds one deterministic original training-shop furnishing model to an existing `BuildingTemplates.storefront` shell. It does not create another map, import branding or reproduce an authentic Detroit business interior. Real-world exterior/land reference work is independent. Width/depth come from the provided rectangular Floor (24–80 by 16–80 studs); dimensions are never normalized or rescaled. The component rejects unsupported dimensions and insufficient height rather than altering the shell.

The layout has wood shelving, small decorative stock boxes, a rear-side counter and noncolliding floor-material insets. It keeps the central six-stud corridor clear for the full floor depth and reserves the front six studs for entrance sweep/window controls. Existing floor/exterior/door/window components are preserved. All new objects are explicitly decorative anchored Parts with CanTouch false. No Seat, fake interaction label, per-object script, heartbeat, light or remote is offered. Doors/windows continue to use the existing central registry; they must already be constructed before registry startup.

Optional `woodColor` is a Color3. `seats` may be absent/false; requesting seating rejects clearly rather than supplying an inert chair. This bounded module does not claim functional checkout, stock collection, authentic interior furniture, complete shop gameplay or seating.

## Preservation and integration

The module accepts only the current known shell child names. Existing `StorefrontInterior`, Furniture, or any other unreviewed child rejects the operation; manual content is never deleted/replaced. New furniture is staged unparented and committed last without yields. Errors inside staging destroy the private model. No shell material, CFrame, descendant or component is mutated. Wider manually authored interiors require separate review rather than bypassing this protection automatically.

Lead owns build/Rojo/Studio integration. This module has not been added to the running city by this task. It is a reusable furnishing component, not proof that an authentic accessible Detroit interior is complete.

## Native validation handoff

`tests/STUDIO_STOREFRONT_INTERIOR_CHECK.lua` returns a test function accepting fresh Templates, Components and Interior module returns. It destroys all temporary owned shells/components on success/failure. Checks cover minimum/default/rotated shells, preserved exterior identities, bounds, clear corridor/front region, deterministic regeneration in a separate shell, existing-interior/manual-content protection, invalid config and absence of scripts/prompts. The reserved front slab geometrically separates all furniture from current front-facing component sweeps; actual prompts/window motion and user navigation remain Lead's native acceptance tasks.

Task-local validation: Lua parsing only; no Studio mutation by this worker. Lead must run the native geometry harness, then inspect actual furnished-shell entry/window prompts and obstruction behavior at every approved scale. Native physical movement, visual quality, user comfort, multiplayer, phone/tablet/console controls and any real furniture interaction remain pending. No performance or release-ready claim.
