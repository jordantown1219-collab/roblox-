# UI and voting audit — bounded follow-up

Inspected October 22, 2026. Source inspection plus isolated server-function tests only. No existing game source or Studio changes; no device or multiplayer acceptance claimed.

## Existing systems to retain

The current client has a responsive centered lobby, 3v3/4v4/5v5 readiness queues, close/reopen behavior and Studio-only solo practice. The server selects enough queued players for two teams, alternates team membership, opens a 12-second carrier/loadout vote, then deploys the match. Existing carrier voting and map voting are different capabilities. Rifle/SMG preference belongs to carrier/loadout voting; do not replace it when adding maps. Team assignment is currently automatic, not a manual team-selection system.

`Config.ActiveMap` currently chooses DetroitRiverfront or MonroeBlock via Arena's legacy fallback. These are existing source environments, not proof of two accepted release-ready maps. Neither has a verified large/medium/small category contract. Preserve both IDs and current Detroit selection. The approved expansion target remains two large maps, two medium maps and one small experimental map. Do not fabricate five selectable maps to fill the UI.

The settings source contains dimming, appearance reset, Studio-preview color controls, music, low graphics, squad visibility and HUD movement. Persistence, real paid entitlement and device acceptance remain pending. The color wheel must remain free only as the approved development preview; no invented pass IDs or product prices.

## Minimal additive interface for a later implementation

This is a proposed interface, not an implemented system or permission for major architecture replacement.

1. Add a server-owned map catalog keyed by existing stable map IDs. Each record supplies `id`, `label`, `category` (Large/Medium/Small only when assigned), `available` and `buildValidated`. Initially both known IDs may be listed for development; only a validated, available map is eligible for a live ballot. Planned slots appear as nonselectable roadmap text, not working maps.
2. Preserve the existing `phase` and carrier-vote action semantics. Add a separate optional ballot snapshot `{ballotId, deadline, candidates, selectedMapId, selections, counts}`. Candidate data comes from the server's eligible catalog, never arbitrary client assets. If fewer than two maps are eligible, retain the selected map and skip a fake choice.
3. Add a dedicated `MapVote` request `{ballotId, mapId}`. Server validation must check membership, ballot phase/deadline, current ballot ID, eligible map ID, bounded payload and rate. Each participant has one replaceable vote. Publish accepted vote/count state rather than treating a local button click as confirmed. Reset votes per ballot and resolve ties with a documented deterministic catalog order; do not reuse carrier UserId tie rules accidentally.
4. Keep team-size readiness at 3/4/5. Future match-setting votes must use server-owned allowlisted option IDs; clients cannot submit arbitrary timers, weapon damage, size stages or team values. Do not introduce configurable shrinking rules: the user has confirmed independent shrinking with whole-team extraction.
5. Map integration requires validated spawn, route/gate, interaction, extraction and streaming support for the selected map before deployment. The current Arena module is selected on require, so runtime map switching needs a separate reviewed lifecycle change. A ballot UI alone cannot safely switch the active environment. Keep the existing selected map operational until that integration exists.

## Device gaps visible in source

- Menu and vote buttons use `Activated`; panel scale adjusts with viewport. This is useful groundwork, not controller acceptance. No explicit gamepad focus initialization, focus restoration on reopening or complete directional selection graph is defined in this client.
- PC firing holds MouseButton1; reload uses R. Touch has a separate FIRE button invoking one shot per activation and RELOAD. There is no controller combat binding in the inspected client. Touch hold-fire parity and actual equip/aim ergonomics remain unverified.
- Lobby/vote panels scale as low as .35; a nominal 42-pixel button can become about 15 pixels. Real phone tap targets and text readability need layout review, safe-area checks and tests at portrait/landscape dimensions.
- HUD dragging explicitly handles mouse/touch; controller repositioning is not implemented. Color controls and reset require focus, contrast and input checks. Keyboard-only/controller color adjustment cannot be inferred from mouse/touch code.
- Vehicle controls have keyboard bindings and generated touch actions, but driving, camera, overlapping touch controls and console bindings require separate runtime acceptance. Native prompt defaults do not prove all interactions are usable on every device.

## Automated evidence and acceptance still required

Added `tests/test_vote_contract.py`: three tests passed in 0.006 seconds. They execute the existing server `begin`/`startMatch` function bodies with isolated engine stubs and actual Config. Checks cover balanced selected-team membership while preserving waiting queues, lowest-UserId carrier tie resolution and configured weapon ammunition, and exclusion of opposite-team/nonmember votes from the carrier tally. They do not exercise RemoteEvent handlers, full round lifecycle, engine Team objects or actual networking.

Before acceptance: test queue transitions and acknowledgments with six real clients; all 3/4/5 sizes; closing/reopening through phase changes; carrier ties/departures; rejected stale/invalid nominations; phone/tablet portrait/landscape text and touch targets; gamepad focus, equip/fire/reload and all settings; PC keyboard/mouse; safe-area/inset behavior; UI dimming extremes/readability; and visible rendering against the world. Existing automated panel regression tests remain applicable. Map/settings ballots remain future work until their server and map-lifecycle dependencies are implemented and validated.
