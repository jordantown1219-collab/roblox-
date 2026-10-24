-- Studio Server: actual Humanoid navigation, fresh scriptless rig; no player manipulation.
assert(game:GetService('RunService'):IsStudio())
local data=require(game.ServerScriptService.RiverAccessData)
local useStairs=false
local plan={routeSamples=useStairs and data.routeStairs or data.routeRamp}
local reverse=false
if reverse then local original=plan plan={routeSamples={}} for i=#original.routeSamples,1,-1 do table.insert(plan.routeSamples,original.routeSamples[i]) end end
local template=assert(game.ServerStorage:FindFirstChild('CashCityRiverAccessRigTemplate'))
local rig=template:Clone() local humanoid=rig:FindFirstChildOfClass('Humanoid')
local scale=1 -- Substitute .65, .4, .22 in separate bounded runs.
local results={}
local ok,err=xpcall(function()
 rig:ScaleTo(scale) humanoid.WalkSpeed=16 -- Match production applyScale, which restores world travel speed after ScaleTo.
 humanoid.UseJumpPower=false humanoid.JumpHeight=7.2*scale
 rig.Name='CashCityRiverAccessWalkingProbe'
 local root=rig:FindFirstChild('HumanoidRootPart')
 local first=plan.routeSamples[1].pos
 rig:PivotTo(CFrame.new(first[1],first[2]+humanoid.HipHeight+root.Size.Y/2+.1,first[3]))
 rig.Parent=workspace root:SetNetworkOwner(nil) task.wait(.5)
 for index,sample in ipairs(plan.routeSamples) do
  local target=Vector3.new(table.unpack(sample.pos))
  humanoid:MoveTo(target)
  local deadline=os.clock()+7
  local reached=false
  repeat
   task.wait(.1)
   local delta=root.Position-target
   reached=Vector3.new(delta.X,0,delta.Z).Magnitude<1.6
  until reached or humanoid.Health<=0 or os.clock()>deadline
  table.insert(results,{index=index,reached=reached,health=humanoid.Health,y=root.Position.Y,floor=sample.floorY,speed=humanoid.WalkSpeed,position=tostring(root.Position)})
  assert(reached and humanoid.Health>0,'Route failed at '..index)
  assert(root.Position.Y>=sample.floorY-.1,'Fell below raised path')
  -- Root height alone cannot prove floor support; full rigs can hide shallow drops.
  -- The independent dense STUDIO_RIVER_ACCESS_FLOORS sweep is mandatory as well.
  local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include
  ray.FilterDescendantsInstances={assert(workspace.SmallSignalsArena:FindFirstChild('DetroitCityRoot'))}
  ray.RespectCanCollide=true
  local support=workspace:Raycast(root.Position,Vector3.new(0,-humanoid.HipHeight-root.Size.Y/2-2,0),ray)
  assert(support and math.abs(support.Position.Y-sample.floorY)<.24,'Unexpected actual supporting floor')
 end
end,debug.traceback)
rig:Destroy()
return {scale=scale,passed=ok,error=not ok and tostring(err) or nil,waypoints=results}
