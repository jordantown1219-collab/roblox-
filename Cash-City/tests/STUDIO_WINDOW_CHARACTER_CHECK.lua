-- Server Play only, isolated solo QA. Temporarily transforms the sole actual character; always restores.
local players=game:GetService("Players"):GetPlayers()
assert(#players==1,"Run only in isolated Server Play with exactly one player")
local player=players[1]
local char=assert(player.Character,"Character missing")
local hrp=assert(char:FindFirstChild("HumanoidRootPart"),"Root missing")
assert(char:FindFirstChildOfClass("Humanoid"),"Humanoid missing")
local server=game:GetService("ServerScriptService")
local components=require(server.BuildingInteractions)
local registry=require(server.InteractionRegistry)
local config=require(game:GetService("ReplicatedStorage").SmallSignals.Config)
local original={pivot=char:GetPivot(),scale=char:GetScale(),attribute=player:GetAttribute("Scale"),anchored=hrp.Anchored,linear=hrp.AssemblyLinearVelocity,angular=hrp.AssemblyAngularVelocity}
local collisions={}
for _,part in ipairs(char:GetDescendants()) do
 if part:IsA("BasePart") then collisions[part]=part.CanCollide end
end
local root=Instance.new("Folder") root.Name="WindowCharacterCheckTemporary" root.Parent=workspace
local ok,result=pcall(function()
 hrp.Anchored=true
 -- Isolate Registry's explicit noncollidable character-root check, not its physical-part query.
 for part in pairs(collisions) do part.CanCollide=false end
 local window=components.slidingWindow()
 window:PivotTo(CFrame.new(26000,22000,26000)*CFrame.Angles(0,math.rad(29),0)) window.Parent=root
 local record=assert(registry.start(root)[window],"Window did not register")
 local count=0
 local function putRootAt(cf)
  assert(player.Character==char and hrp.Parent==char,"Original character identity changed")
  char:PivotTo(cf*hrp.CFrame:ToObjectSpace(char:GetPivot()))
  assert((hrp.Position-cf.Position).Magnitude<.001,"Root placement failed")
 end
 for _,scale in ipairs(config.Scales) do
  char:ScaleTo(scale) player:SetAttribute("Scale",scale)
  -- ScaleTo may recalculate geometry; keep every body collider excluded from physical query.
  for part in pairs(collisions) do if part.Parent then part.CanCollide=false end end
  assert(math.abs(char:GetScale()-scale)<.0001,"Character scale differs")
  putRootAt(record.frame(.5))
  assert(not record.clear(0,1),"Actual character root did not block opening at scale "..scale)
  assert(not record.clear(1,0),"Actual character root did not block closing at scale "..scale)
  putRootAt(record.frame(.5)*CFrame.new(0,0,-20))
  assert(record.clear(0,1) and record.clear(1,0),"Sweep remained blocked after actual character moved away")
  count=count+1
 end
 return "PASS: actual noncollidable character-root blocking/recovery at "..count.." configured scales; no input/crush/multiplayer acceptance"
end)
-- Independent cleanup steps ensure one restoration error cannot skip listener cleanup or other state.
local failures={}
local function restore(label,callback)
 local success,err=pcall(callback) if not success then table.insert(failures,label..": "..tostring(err)) end
end
restore("character scale/pivot",function()
 assert(char.Parent and hrp.Parent==char,"Original character no longer exists")
 char:ScaleTo(original.scale) char:PivotTo(original.pivot)
end)
restore("collisions",function() for part,value in pairs(collisions) do if part.Parent then part.CanCollide=value end end end)
restore("player scale attribute",function() player:SetAttribute("Scale",original.attribute) end)
restore("root physics",function()
 hrp.Anchored=original.anchored
 hrp.AssemblyLinearVelocity=original.linear hrp.AssemblyAngularVelocity=original.angular
end)
restore("registry cleanup",function() root:Destroy() end)
assert(#failures==0,"RESTORATION FAILURE: "..table.concat(failures,"; ").."; test result: "..tostring(result))
assert(ok,result)
return result
