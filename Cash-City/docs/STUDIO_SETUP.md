> v0.10 continuation: see docs/STUDIO_RESULTS.md for current native MCP and partial solo acceptance. Historical pending statements below describe v0.9; unchecked rows remain pending. Rojo live sync is still unverified.

# Studio setup and working agreement

Rojo's official guide: https://rojo.space/docs/v7/getting-started/installation/
Sync behavior/limitations: https://rojo.space/docs/v7/sync-details/

## What is installed
Rojo CLI 7.7.1 under tools/rojo/rojo.exe. Downloaded from the official rojo-rbx/rojo GitHub release. The ZIP SHA256 matched GitHub's published digest: d4dfa3493a1613a43fc87312d6dac660d7c8bf38e6a99aa5dcd0d26154ba0b82. Metadata: tools/rojo/release.json.
Studio plugin file: %LOCALAPPDATA%/Roblox/Plugins/RojoManagedPlugin.rbxm. File installation is verified. Toolbar loading and connection are NOT yet verified. No account/password/cookie is needed for local sync; nothing has been published.

## Your Studio step
1. Save any current Studio work. Reopen Studio if its Plugins toolbar does not yet show Rojo.
2. Open this project's SmallSignals_DetroitRiverfront_v0_9.rbxlx. Stop Play before syncing.
3. Run Start-Studio-Sync.cmd if the local server is not already running.
4. In Studio choose Plugins > Rojo. Connect to localhost port 34872. Review that the project is SmallSignals Detroit - Code Sync before accepting its sync preview.
5. If Studio requests a plugin permission or localhost connection permission, approve it yourself. Computer Use cannot handle system/app security prompts.
6. Confirm the Rojo panel says Connected. Then modify a harmless source comment, confirm it appears in Studio, and undo that comment. Only this demonstrates live sync.

The server binds only to 127.0.0.1. The code-only project includes named shared/server/client scripts and remote definitions, and uses ignoreUnknownInstances. Other Studio objects are retained. Named synced scripts are controlled from source.

## Geometry and Studio edits
Use code-only sync while hand building. Save Studio work to a separate place or export models into studio_edits/. Those edits are not automatically copied into src or data. Tell Codex which exported files to integrate. Use the full project only when ready to apply generated geometry too.
Do not publish over your main game until private Studio/multiplayer acceptance passes. This setup does not automatically install an MCP connector into chat or allow direct Studio tool calls. A separate Roblox connector would need to be added and its available permissions/tools verified.

## Stop the local server
The agent-started process ID is recorded in data/rojo-server.pid. Closing a manually started console stops that server. If stopping the recorded process, verify its executable is this project's tools/rojo/rojo.exe before terminating it. Do not kill all Rojo processes.

## Native Studio MCP status
User confirmed signed in and Enable Studio as MCP server ON. Studio mcp.bat exists and the existing Roblox_Studio registration was verified. The direct tools are still absent from this running chat. Official Roblox setup instructions require a new chat to load them; no duplicate registration was created. HANDOFF.md preserves the next steps.
