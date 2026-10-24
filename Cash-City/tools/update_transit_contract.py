from pathlib import Path
import json
p=Path.cwd();g=json.loads((p/'data/detroit_geography.json').read_text(encoding='utf-8'));S=g['studsPerMeter']
f=p/'src/CityConfig.lua';s=f.read_text(encoding='utf-8')
lines=[' Transit={']
for team,d in g['gameplay'].items():lines.append(f' {team}=Vector3.new({d["transit"][0]*S:.5f},0,{d["transit"][1]*S:.5f}),')
lines+=[' },']
s=s.replace(' Exits={','\n'.join(lines)+'\n Exits={');f.write_text(s,encoding='utf-8')
f=p/'src/Arena.lua';s=f.read_text(encoding='utf-8').replace('local source=City.Spawns[team]+Vector3.new(12,-4,0)','local source=City.Transit[team]').replace('local dest=City.Spawns[team=="Amber" and "Cyan" or "Amber"]+Vector3.new(12,-4,5)','local dest=City.Transit[team=="Amber" and "Cyan" or "Amber"]+Vector3.new(0,0,4)');f.write_text(s,encoding='utf-8')
f=p/'build.py';s=f.read_text(encoding='utf-8-sig').replace("[data['spawn'],data['exit']]+data['sockets']","[data['spawn'],data['exit'],data['transit']]+data['sockets']");s=s.replace('if index==0:','if index==2:').replace("point[0]*S+12,-.3,point[1]*S+5","point[0]*S,-.3,point[1]*S+4");f.write_text(s,encoding='utf-8')
f=p/'tests/test_build.py';s=f.read_text(encoding='utf-8-sig').replace("[d['spawn'],d['exit']]+d['sockets']","[d['spawn'],d['exit'],d['transit'],[d['transit'][0],d['transit'][1]+4*.28]]+d['sockets']");f.write_text(s,encoding='utf-8')
