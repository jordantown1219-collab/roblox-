# Server lobby defaults persistence

`LobbyPreferences.lua` is a server-only injected-store cache, with no Roblox services, networking or hidden background loop. Lead supplies `DataStoreService:GetDataStore("CashCityLobbyPreferences_v1")` through protected acquisition, or nil when unavailable. The only preferences are `mode="Extraction"` and `teamSize` 3/4/5. Default is Extraction/3. It does not store progression, money, votes, other players' data or arbitrary nested payloads.

## API

- `Preferences.new(storeOrNil)` returns an independent cache. Nil safely uses session defaults; reads/writes report failure without crashing startup.
- `:get(userId)` returns a detached current/default snapshot, without yielding or reading storage.
- `:load(userId)` returns snapshot and `loaded`, `default`, `invalidData`, `loadFailed`, or `loading`. One store read per cache lifetime; concurrent calls return the present cache. A late load never overwrites a choice made while/before loading.
- `:set(userId, {mode="Extraction",teamSize=3|4|5})` validates the entire plain table. Extra keys, missing keys, nested values, metatables and unavailable modes are rejected with nil/`invalidPreferences`. Success returns snapshot/`accepted`. It performs no datastore call. Repeated unchanged values after a successful load do not create dirty writes. An explicit default choice before/during load or after read failure remains a meaningful dirty choice.
- `:save(userId)` performs at most one protected UpdateAsync call only when dirty. Returns boolean/status (`saved`, `unchanged`, `newerChoicePending`, `saving`, `saveFailed`, `saveRefused`). Concurrent calls are guarded. A newer choice during a save remains dirty; failed/refused saves retain current dirty preferences.
- `:forget(userId)` clears clean idle cache entries. It refuses pending/dirty/loading/saving entries, returning false/`pendingPreferences`; it never silently discards a failed save.

User IDs must be finite nonzero integers within exact numeric integer range, including negative synthetic IDs used by native Studio multiplayer. Keys are `u_<userId>`; negative identities remain isolated. Stored payload is exactly `{version=1,mode="Extraction",teamSize=...}`. Unknown/future version, corrupt shape or unrelated stored fields load as safe defaults and UpdateAsync refuses to overwrite them. No opportunistic migration or data deletion occurs.

All GetAsync/UpdateAsync calls are inside pcall. There is no automatic retry or per-request write, but native datastore throttling can yield; this module does not promise to cancel a platform call. Lead owns bounded leave/shutdown orchestration and any sparse retry policy. Failed-leave entries remain retained until explicit successful save; do not call a forced discard or present failure as persisted. Consider bounded retention/reporting in the integration rather than an unbounded retry loop.

## Integration and review findings

Only call `set` after a validated lobby join; never trust UI defaults as match settings. Call `load` asynchronously on join, broadcast its completed state, and use `get` for nonyield snapshots. A player's choice made during load takes priority. Do not broadcast initial session defaults as confirmed stored defaults: the current LobbyUI applies `snapshot.defaults` once and would otherwise ignore the later loaded preference. Omit defaults until loading completes or explicitly expose a loaded flag. This issue was reported to Lead; worker did not edit UI/controller.

Additional read-only review: LobbyUI initially establishes gamepad selection only when `SetVisible` is invoked; ensure constructor's first visible presentation gets focus. Map-vote cards appear active for nonparticipants although server membership rejects their vote; consider an explicit waiting state. These are source-review findings, not runtime failures. Existing Controller validates phase/epoch/member IDs and catalogs; actual integration, source-current tests and multiplayer are Lead responsibilities.

## Validation

Ten deterministic Lupa tests execute the actual module with injected stores: default/copy isolation and no unnecessary writes; valid load/set/save; whole-payload rejection; late/concurrent load choice preservation; failed-save retry with dirty retention; unknown version/unrelated data preservation; concurrent save/new choice; nil-store fallback; explicit default after read failure; and isolated negative Studio identities. Coroutines model yields. They do not test live DataStore availability, shutdown deadline, Studio API access, actual Roblox network behavior, multiple-server last-writer races or devices. Those remain pending before claiming persistence accepted.
