# Cash City checkpoint — October 23, 2026

Open `SmallSignals_DetroitRiverfront_v0_14.rbxlx` in Studio. Source, map data, reference notes, tests and rebuild baseline are included. Read HANDOFF.md, latest DEVELOPMENT_STATUS.md and docs/LESSONS_LEARNED.md before work; check GitHub for newer edits before changing the local project.

Current focus is Step1 Renaissance Center/Wintergarden only. Tested curved roof, accessible atrium and server-controlled entrance are saved. Main hotel/Jefferson lobby, interior finish and visual refinement remain unfinished. No Step2stairs, RiverWalk extension, roads or map edges have been started. No game publication.

62 offline tests and11bounded native checks passed. Actual avatar geometry walks passed at1/.65/.4/.22; actual E prompt opened at full size and closed/reopened at .22. These do not establish multiplayer/device or real gate-progression acceptance. Final foreground sample60.04FPS at1169x584; read status for limitations.

Place SHA256:0991036B4544D61859A7D00E3FD2D0AD4454B7C282C32C51032A47601A81C088

Original replaced atrium parts are recoverable in WintergardenSourceArchive and local checkpoints. Paused lobby source/tests/docs are preserved under `paused/paused_lobby_20261023T205549`; they are NOT active/build-integrated. Do not revive that work under current scope.

For rebuilding, install requirements-dev.txt in a Python environment, run `python build.py`, then `python -m unittest discover -s tests -p "test_*.py" -v`. Native Studio checks remain separate. The included data/base_v0_8.rbxlx removes the external baseline-file dependency. Do not spend credits; verify included allowance before resuming.

Arrival lounge update:4functionalnativeSeats,2lights,genericatriumsign.2newfocusedtests+4buildchecks+11nativechecksPASS. HealthySeatOccupantverified;realhardware/tinyseataccessibilityandnewlightingFPSremainpending. Mainhotel/Jeffersonlobbyunfinished;Step1stillopen.
