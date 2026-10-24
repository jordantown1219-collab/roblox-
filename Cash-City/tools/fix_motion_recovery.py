from pathlib import Path
p=Path('src/InteractionRegistry.lua');s=p.read_text(encoding='utf-8-sig').replace('open=false,last=-100','open=false,position=0,last=-100')
s=s.replace('local from,to=r.open and 1 or 0,r.open and 0 or 1','local from,to=r.position,r.open and 0 or 1')
s=s.replace('r.moving:PivotTo(r.frame(alpha))','r.moving:PivotTo(r.frame(alpha))\n   r.position=alpha')
s=s.replace('r.open=to==1\n    else','r.open=r.position>0\n    else')
s=s.replace('r.moving:PivotTo(r.frame(to)) r.open=to==1','r.moving:PivotTo(r.frame(to)) r.position=to r.open=to==1')
p.write_text(s,encoding='utf-8')
