-- Native Studio Server/Edit check; requires current server modules. No real players are moved.
local server=game:GetService("ServerScriptService")
local components=require(server.BuildingInteractions)
local registry=require(server.InteractionRegistry)
local config=require(game:GetService("ReplicatedStorage").SmallSignals.Config)
local root=Instance.new("Folder") root.Name="WindowSafetyCheckTemporary" root.Parent=workspace
local ok,result=pcall(function()
 local window=components.slidingWindow()
 window:PivotTo(CFrame.new(25000,20000,25000)*CFrame.Angles(0,math.rad(31),0))
 window.Parent=root -- Assemble before starting central registry.
 local records=registry.start(root)
 local record=assert(records[window],"Window was not registered")
 local home=window.Moving:GetPivot()
 local travel=window:GetAttribute("Travel")
 assert((record.frame(0).Position-home.Position).Magnitude<.0001,"Closed endpoint differs")
 assert((record.frame(1).Position-(home*CFrame.new(travel,0,0)).Position).Magnitude<.0001,"Open endpoint differs")
 assert(record.clear(0,1) and record.clear(1,0),"Isolated empty sweep rejected")
 local count=0
 for _,scale in ipairs(config.Scales) do
  -- Scale-sized PHYSICAL probes only. These are not characters or character safety acceptance.
  assert(type(scale)=="number" and scale>0,"Invalid configured scale")
  local blocker=Instance.new("Part") blocker.Name="ExternalScaleSizedBlocker"
  blocker.Anchored=true blocker.CanCollide=true blocker.CanTouch=false
  blocker.Size=Vector3.new(1.5,3,1.5)*scale
  blocker.CFrame=record.frame(.5) blocker.Parent=root
  assert(not record.clear(0,1),"Opening ignored stationary blocker at scale "..scale)
  assert(not record.clear(1,0),"Closing ignored stationary blocker at scale "..scale)
  blocker:Destroy()
  assert(record.clear(0,1) and record.clear(1,0),"Sweep did not recover after removing blocker")
  count=count+1
 end
 -- Validate range contract separately without claiming scaled-player interaction.
 local rules=require(server.InteractionRules)
 for _,scale in ipairs(config.Scales) do
  assert(math.abs(rules.range(window:GetAttribute("Range"),scale)-math.max(3,9*scale))<.0001,"Scale range differs")
 end
 return "PASS: registry endpoints, empty/recovered sweeps, opening+closing blockers at "..count.." configured probe sizes; no actual character safety test"
end)
root:Destroy() -- Registry root.Destroying disconnects every connection, on success or assertion failure.
assert(ok,result)
return result
