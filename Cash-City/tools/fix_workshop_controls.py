from pathlib import Path
p=Path('src/InteractionWorkshop.lua');s=p.read_text(encoding='utf-8-sig').replace('1-center.Y+origin.Y','origin.Y-3-center.Y').replace('Vector3.new(3.4,-.25,0)','Vector3.new(3.65,-.25,0)');p.write_text(s,encoding='utf-8')
