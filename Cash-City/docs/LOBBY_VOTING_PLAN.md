# Lobby and voting — paused by user scope change; do not resume
1. Preserve current queues, carrier/loadout vote, Extraction rules, map and settings; checkpoint before implementation and integrate only through Lead.
2. Add server-owned mode/map catalogs and lobby state with validated requests, queue counts for 3v3/4v4/5v5, balanced teams, and automatic start when full.
3. After a proposed90-second wait, queued players may vote by strict majority to start with fewer players; require equal teams and at least one player per side. No placeholder bots.
4. Vote only on available, validated maps; cards show configured size/recommended teams. Resolve ties deterministically; reject stale/duplicate/invalid votes and handle departures.
5. Preserve carrier voting after lobby selection; lock Extraction as the only playable mode until a real multiplayer lobby test passes. Define shared mode interfaces; defer other modes.
6. Persist only validated last-used mode/team-size defaults on the server, with safe loading/failure fallbacks. Build large touch targets, responsive layouts and controller focus.
7. Test queue/vote/departure/security/persistence pieces in isolation, then native UI and at least one six-client3v3 lifecycle; check PC/touch/controller layouts and remaining device gaps.
8. Update DEVELOPMENT_STATUS.md and Studio test checklist; verify GitHub checkpoint before pauses/low allowance. At most3helpers, exclusive files; no game publication.
