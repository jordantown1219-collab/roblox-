from pathlib import Path
import json
p=Path.cwd();legacy=(p/'src/Arena.lua').read_text(encoding='utf-8-sig');(p/'src/LegacyArena.lua').write_text(legacy,encoding='utf-8')
g=json.loads((p/'data/detroit_geography.json').read_text(encoding='utf-8'));S=g['studsPerMeter']
def vec(v,y=0):return 'Vector3.new('+','.join(str(round(x,5)) for x in [v[0]*S,y,v[1]*S])+')'
lines=['return {',' MapId="detroit_riverfront",',' Attribution="© OpenStreetMap contributors / ODbL 1.0",',' Spawns={']
for team,t in g['gameplay'].items():lines.append(f'  {team}={vec(t["spawn"],4)},')
lines+=[' },',' Exits={']
for team,t in g['gameplay'].items():lines.append(f'  {team}={vec(t["exit"],.1)},')
lines+=[' },',' Sockets={']
for team,t in g['gameplay'].items():lines.append('  '+team+'={'+','.join(vec(v) for v in t['sockets'])+'},')
lines+=[' },','}'];(p/'src/CityConfig.lua').write_text('\n'.join(lines),encoding='utf-8')
# Reuse the original progression-door geometry helper, with world rather than stretched units.
a=legacy.index('local function doorway');b=legacy.index('function Arena.routes',a)
helper=legacy[a:b]
s='''local Legacy=require(script.Parent.LegacyArena)
local Config=require(game:GetService("ReplicatedStorage").SmallSignals.Config)
if Config.ActiveMap=="MonroeBlock" then return Legacy end
local City=require(script.Parent.CityConfig)
local Registry=require(script.Parent.InteractionRegistry)
local Arena={}
local colors={Amber=Color3.fromRGB(255,181,60),Cyan=Color3.fromRGB(55,211,236)}
local function part(parent,name,size,position,color)
 local p=Instance.new("Part")
 p.Name,p.Size,p.Position,p.Color=name,size,position,color
 p.Anchored,p.Parent=true,parent
 return p
end
function Arena.build()
 local preview=workspace:FindFirstChild("DetroitCityPreview")
 if preview then preview:Destroy() end
 Legacy.build()
 local folder=Legacy.folder
 -- Preserve the original staging room outside the real-world map boundary.
 local shift=Vector3.new(-3800,0,-2800)
 for _,obj in ipairs(folder:GetChildren()) do
  if obj:IsA("BasePart") then
   if obj.Position.Z<150 then obj:Destroy() else obj.Position=obj.Position+shift end
  end
 end
 Arena.lobby=Legacy.lobby+shift
 Arena.folder,Arena.spawns=folder,City.Spawns
 local city=game:GetService("ServerStorage"):WaitForChild("DetroitCityRoot"):Clone()
 city.Parent=folder
 Arena.records=Registry.start(folder)
 Arena.armorPositions={}
 for _,spots in pairs(City.Sockets) do for _,spot in ipairs(spots) do table.insert(Arena.armorPositions,spot) end end
 folder:SetAttribute("MapId",City.MapId)
 return folder
end
'''+helper+'''
function Arena.routes(config,onDoor,onExit,onTransit)
 if Arena.interactions then Arena.interactions:Destroy() end
 local folder=Instance.new("Folder") folder.Name,folder.Parent="RoundInteractions",Arena.folder
 Arena.interactions=folder
 local rng=Random.new()
 for _,team in ipairs({"Amber","Cyan"}) do
  local spots=table.clone(City.Sockets[team])
  for i=#spots,2,-1 do local j=rng:NextInteger(1,i) spots[i],spots[j]=spots[j],spots[i] end
  for stage=1,config.Stages do
   local spot=spots[stage]
   local normal=Vector3.new(0,0,1)
   local door,text=doorway(folder,"Door",spot,config.Scales[stage],colors[team],normal)
   door:SetAttribute("Team",team) door:SetAttribute("Stage",stage)
   text.Text=string.upper(team).." SIGNAL "..stage
   local prompt=Instance.new("ProximityPrompt")
   prompt.ActionText,prompt.ObjectText="Enter signal gate",team.." stage "..stage
   prompt.MaxActivationDistance,prompt.HoldDuration=math.max(3,6*config.Scales[stage]),.3
   prompt.Parent=door
   local destination=spot+Vector3.new(0,4*config.Scales[stage+1],4)
   prompt.Triggered:Connect(function(player) onDoor(player,team,stage,door,destination) end)
  end
  local exit=part(folder,"Extraction",Vector3.new(3,.15,3),City.Exits[team],colors[team])
  exit:SetAttribute("Team",team)
  local prompt=Instance.new("ProximityPrompt") prompt.ActionText,prompt.ObjectText="Gather here","Team extraction"
  prompt.MaxActivationDistance,prompt.HoldDuration=4,.5 prompt.Parent=exit
  prompt.Triggered:Connect(function(player) onExit(player,team,exit) end)
 end
 for _,team in ipairs({"Amber","Cyan"}) do
  local source=City.Spawns[team]+Vector3.new(12,-4,0)
  local dest=City.Spawns[team=="Amber" and "Cyan" or "Amber"]+Vector3.new(12,-4,5)
  local door,text=doorway(folder,"TransitDoor",source,1,Color3.fromRGB(97,192,160),Vector3.new(0,0,1))
  text.Text="DISTRICT TRANSIT"
  local control=Instance.new("Attachment") control.Position=Vector3.new(0,-2.4,.3) control.Parent=door
  local prompt=Instance.new("ProximityPrompt") prompt.ActionText,prompt.ObjectText="Cross district","Gameplay transit gate"
  prompt.MaxActivationDistance,prompt.HoldDuration=7,.5 prompt.Parent=control
  prompt.Triggered:Connect(function(player) onTransit(player,door,dest) end)
 end
end
return Arena
'''
(p/'src/Arena.lua').write_text(s,encoding='utf-8')
f=p/'src/SmallSignalsServer.server.lua';s=f.read_text(encoding='utf-8')
s=s.replace('local function broadcast()','local function broadcast()\n    Arena.folder:SetAttribute("MatchActive",phase=="Match")')
old='pickup.Position = Vector3.new((x + armorRng:NextNumber(-3,3))*C.MapStretch,0.8*scale+0.2,z*C.MapStretch)'
assert old in s
s=s.replace(old,'''if Arena.armorPositions then
        pickup.Position=Arena.armorPositions[armorRng:NextInteger(1,#Arena.armorPositions)]+Vector3.new(0,.8*scale+.4,0)
    else pickup.Position = Vector3.new((x + armorRng:NextNumber(-3,3))*C.MapStretch,0.8*scale+0.2,z*C.MapStretch) end''')
# Preload static collidable landing floors through persistent small anchor models in the built file.
(p/'src/SmallSignalsServer.server.lua').write_text(s,encoding='utf-8')
print('Integrated riverfront map adapter with legacy map fallback and existing stage/team callbacks.')
