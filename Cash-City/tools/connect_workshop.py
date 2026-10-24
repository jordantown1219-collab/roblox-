from pathlib import Path
p=Path('src/Arena.lua');s=p.read_text(encoding='utf-8').replace(' Arena.records=Registry.start(folder)',' require(script.Parent.InteractionWorkshop).build(folder,Arena.lobby)\n Arena.records=Registry.start(folder)');p.write_text(s,encoding='utf-8')
