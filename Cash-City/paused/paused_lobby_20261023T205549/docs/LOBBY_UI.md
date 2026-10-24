# Cash City lobby presentation

`LobbyUI.new(player,remote)` creates `CashCityLobby` in PlayerGui and returns `Update(snapshot)`, `SetAvailable(bool)`, `SetVisible(bool)`, and `Destroy()`. Lead owns source integration. This module changes no settings, combat or server behavior.

```lua
local lobby=require(script.Parent.LobbyUI).new(player,actionRemote)
-- Call when the server delivers the lobby table, not the whole match packet:
lobby:Update(snapshot.lobby)
lobby:SetAvailable(lobbyAvailable) -- phase availability; safe to call repeatedly
-- SetVisible is reserved for user open/close, not per-frame phase refresh.
-- Before removing/replacing the owning client:
lobby:Destroy()
```

Outbound existing action remote contract: `LobbyJoin,{mode="Extraction",teamSize=3|4|5}`, `LobbyLeave,{}`, `LobbyStartVote,{epoch=...}`, and `LobbyMapVote,{epoch=...,mapId=...}`. Readiness, confirmed map vote, votes and start eligibility come exclusively from snapshots; local selection never claims a confirmed server vote. Maps are rendered only from server-supplied cards. Other mode cards are visible but disabled; Extraction alone is selectable through ready-up. No fictitious maps, map-size categories or paid options are introduced.

Queue cards always show3/4/5 per-team options and their server counts. Ready users can leave. The90-second smaller-match message is explanatory; the button is enabled only by server `canStartSmall`. Map cards show configured size, recommended team size, votes and unavailable state. Countdown uses `Workspace:GetServerTimeNow()`; Lead confirmed matching server clock. Defaults apply once when supplied, only before the user chooses a team. A Studio-only solo-practice button sends existing `Practice` action; it is absent outside Studio. Locked mode cards explain their gameplay is not ready.

The original dark slate/gold design uses scrolling content with fixed56px minimum main buttons and52px close/reopen controls. Tiny viewports scroll rather than shrinking touch targets. Controller buttons have explicit vertical focus links and selectable states; opening with a gamepad selects the first action. Closed UI retains its own reopen button. No RenderStepped connection; cached countdown updates every0.5s, task cancelled on Destroy. Snapshot content rebuilds only when non-deadline data changes; old controls are destroyed, local team choice and scroll position retained.

Native UI rendering, tiny-phone layout, controller focus navigation, actual touch, server integration and multiplayer snapshots remain awaiting Lead validation. No publish action or visual/performance acceptance claim.

Followup: constructor/redraw repairs lost gamepad focus after creating/parenting controls. MapVote cards require explicit `canVoteMap==true` as well as map availability; generic queued/ready status grants no vote UI access. Nonparticipants see a waiting message. Local team choice sets a durable `userChosen` flag, preventing snapshots/default loading from changing that selection. Server omits `defaults` until loading finishes; when first supplied, they apply once unless user-chosen. A queued player's current team size takes precedence only when `ready` is true.

`SetAvailable` is idempotent and disables the entire ScreenGui, including reopen, outside eligible phases. It preserves the user's open/closed state when availability returns. `SetVisible` controls that user preference and is idempotent; it must not be called every frame by phase integration. Redraw repairs lost controller focus but does not steal another live interface's focus.

Suggested native widget checks: MapVote with ready=true but canVoteMap=false must disable cards; canVoteMap=true enables only available maps. Choose team5, then loaded defaults3 must preserve5. Close, repeatedly SetAvailable(true), verify closed; SetAvailable(false) must hide panel and reopen; returning true restores closed state. Repeated availability refresh must not reset live gamepad selection. First real Update after placeholder construction must recover destroyed selected widget. Destroy removes GUI and owned focus. Instructions only; native/hardware acceptance remains pending.
