# Optional reusable storefront sash integration

The existing call `BuildingTemplates.storefront(config, doorTemplate)` is unchanged. The optional third parameter is a model produced by the existing `BuildingInteractions.slidingWindow(config)` factory. For example:

```lua
local sash = BuildingInteractions.slidingWindow({width=8,height=5})
local shell = BuildingTemplates.storefront({}, nil, sash)
sash:Destroy() -- The shell owns two independent clones.
shell.Parent = authoredRoot
-- Build/parent all tagged components before starting the central controller:
local records = InteractionRegistry.start(authoredRoot)
```

With no third argument the original two static panes and trim remain unchanged. With a supplied model, both facade apertures receive clones named LeftSlidingWindow and RightSlidingWindow. The decorative panes/trim are omitted rather than left behind as invisible blockers. Solid infill closes the unused area around smaller component frames. The component factory and central controller are reused without additional scripts/remotes or new registry lifecycle behavior.

Existing facade apertures are `(width/2 - doorWidth/2 - 3)` studs wide and6.5studs tall. A supplied frame must fit inside that rectangle. The current sash factory supports width6..12 and height4..8, so the effective integrated height is4..6.5. The minimum24stud shell with default6stud doorway supports a6stud sash exactly. A24stud shell with an8stud doorway has only5stud window apertures and rejects this optional component before creating a shell; use a wider shell or keep static glazing. An80stud shell can accept at most12stud frames, with infill on each side. No scaling of interaction geometry is performed.

The third argument must preserve the current Slide/X contract, exact travel `FrameWidth/2-.3`, Moving Model, MotionPivot BasePart and Control+ProximityPrompt. Its pivot is the frame center and its Moving pivot axes must align with the component. Every descendant must be Archivable, anchored if a BasePart, and free of per-instance scripts. Geometry at closed/open endpoints must fit within the declared frame X/Y bounds and one stud in depth; straight X motion makes those endpoint bounds cover its full sweep. This is a bounded adapter for the current two-track sash, not a general importer for arbitrary animated windows. Metadata, interaction tags, leaf sizes and collision properties are preserved on clones.

No authentic Detroit interior is claimed. These remain original procedural training shells. Opening a sash provides only its left half opening, not a full-height door or a claimed player-size traversal route. The central entrance/interior path remains the access route.

`tests/STUDIO_STOREFRONT_WINDOW_CHECK.lua` checks default/minimum/maximum shells with rotated placement,25samples per component against shell collision, actual opened pane clearance, source preservation, default static behavior, unchanged door API and invalid input rejection. Lead must run this native harness with fresh candidate ModuleScripts because require caches can retain old source. Actual prompt use from both sides, obstruction behavior, multiplayer and device acceptance remain separate pending checks. This change neither inserts buildings into the Detroit map nor starts a registry.
