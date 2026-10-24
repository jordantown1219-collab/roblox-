from pathlib import Path
import zipfile
p=Path.cwd()
f=p/'docs/MAP_QUALITY_REPORT.md';s=f.read_text(encoding='utf-8-sig').replace('clearance for 20 anchors','clearance for 24 anchor/arrival positions');f.write_text(s,encoding='utf-8')
f=p/'docs/STUDIO_SETUP.md';s=f.read_text(encoding='utf-8-sig');s+='\n## Native Studio MCP status\nUser confirmed signed in and Enable Studio as MCP server ON. Studio mcp.bat exists and the existing Roblox_Studio registration was verified. The direct tools are still absent from this running chat. Official Roblox setup instructions require a new chat to load them; no duplicate registration was created. HANDOFF.md preserves the next steps.\n';f.write_text(s,encoding='utf-8')
exclude={'rojo_code_check.rbxlx','rojo_full_check.rbxlx','sourcemap.json','rojo-server.pid','rojo-server.log','rojo-server-errors.log','release.zip'}
out=p.parent/'SmallSignals_DetroitRiverfront_v0_9_StudioSetup.zip'
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for f in p.rglob('*'):
  if not f.is_file() or '.git' in f.relative_to(p).parts or '__pycache__' in f.relative_to(p).parts or f.name in exclude:continue
  z.write(f,f.relative_to(p))
print('Saved package:',out.name,round(out.stat().st_size/1024/1024,2),'MB')
