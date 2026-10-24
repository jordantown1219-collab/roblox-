from pathlib import Path
p=Path('src/InteractionRegistry.lua');s=p.read_text(encoding='utf-8').replace('if not r.clear(alpha,to) then','if not r.clear(r.position,to) then').replace('recover to closed on interrupted transitions','hold the last safe pose on interrupted transitions');p.write_text(s,encoding='utf-8')
