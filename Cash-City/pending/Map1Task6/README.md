# UNVERIFIED Task6 candidate — do not deploy
This XML export is NOT the working place. Its source-only sync passed82tests, but the subsequent stronger build check failed: legacy InteractionRules is under ServerScriptService instead of ReplicatedStorage.SmallSignals.
The working CashCity_RiverWalk_Section2.rbxl and active pre-run XML/test were preserved/restored. See ../../docs/Map1_Task6_OFFLINE_QA.md.
The stronger test_build.py is archived here; copy it into an isolated full project tests folder to resume, not run directly in this pending directory. Keep uniqueness/container assertions. Review/preserve the legacy duplicate before any layout change. No release-ready or in-game acceptance is claimed.
Focused result:4tests in4.667seconds,3PASS/1FAIL; test_embedding: AssertionError ServerScriptService != SmallSignals : InteractionRules.
