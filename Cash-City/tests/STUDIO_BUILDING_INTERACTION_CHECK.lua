local components=require(game.ServerScriptService.BuildingInteractions)
local buildings=require(game.ServerScriptService.BuildingTemplates)
local fixtures=Instance.new("Folder") fixtures.Name="BuildingInteractionChecks" fixtures.Parent=workspace
local ok,result=pcall(function()
 local checked=0
 for _,dimensions in ipairs({{6,9},{5,8},{8,11}}) do
  local w,h=table.unpack(dimensions)
  local component=components.door({apertureWidth=w,apertureHeight=h})
  assert(component:GetPivot().Position.Magnitude<.0001,"Component pivot must be centered")
  assert(game:GetService("CollectionService"):HasTag(component,"SSInteractable"))
  local building=buildings.storefront({doorWidth=w,doorHeight=h,height=14,cframe=CFrame.new(0,10000+checked*100,0)},component)
  component:Destroy() building.Parent=fixtures
  local door=building.EntranceDoor local moving=door.Moving local leaf=moving.Leaf
  assert(door.MotionPivot:IsA("BasePart") and door.Control:FindFirstChildOfClass("ProximityPrompt"))
  assert(door:GetAttribute("Motion")=="Hinge" and door:GetAttribute("Axis")=="Y" and not door:GetAttribute("LobbyInteraction"))
  local home=moving:GetPivot() local hinge=door.MotionPivot.CFrame local offset=hinge:ToObjectSpace(home)
  local initial=leaf.CFrame local control=door.Control.Position
  local params=OverlapParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={door}
  params.RespectCanCollide=true
  for i=0,24 do
   local frame=hinge*CFrame.Angles(0,math.rad(door:GetAttribute("Travel")*i/24),0)*offset
   moving:PivotTo(frame)
   assert(#workspace:GetPartBoundsInBox(leaf.CFrame,leaf.Size-Vector3.new(.02,.02,.02),params)==0,"Door sweep intersects shell")
   local p=leaf.CFrame:PointToObjectSpace(control)
   assert(math.abs(p.X)>leaf.Size.X/2+.01 or math.abs(p.Z)>leaf.Size.Z/2+.01,"Control inside sweep")
  end
  local _,angle=initial:ToObjectSpace(leaf.CFrame):ToAxisAngle()
  assert(math.abs(math.deg(angle)-90)<.01,"Open angle differs")
  moving:PivotTo(home)
  assert((leaf.CFrame.Position-initial.Position).Magnitude<.0001,"Closed pose not restored")
  for _,part in ipairs(door:GetDescendants()) do
   assert(not part:IsA("LuaSourceContainer"),"Per-instance script found")
   if part:IsA("BasePart") then assert(part.Anchored and not part.CanTouch) end
  end
  building:Destroy() checked=checked+1
 end
 for _,config in ipairs({{apertureWidth=0},{travel=95},{duration=math.huge},{apertureHeight=0/0}}) do
  assert(not pcall(components.door,config),"Invalid configuration accepted")
 end
 return "PASS: "..checked.." door contracts, closed/open poses and 25 sweep samples per shell"
end)
fixtures:Destroy() assert(ok,result) return result
