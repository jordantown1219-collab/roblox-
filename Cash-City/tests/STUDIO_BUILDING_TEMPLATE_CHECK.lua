-- Lead runs after explicitly importing BuildingTemplates. Cleans up on success/failure.
local factory=require(game.ServerScriptService.BuildingTemplates)
local fixtures=Instance.new("Folder") fixtures.Name="BuildingTemplateChecks" fixtures.Parent=workspace
local checked=0
local ok,result=pcall(function()
 for _,dimensions in ipairs({{32,28,14},{24,16,12},{80,80,24}}) do
  local w,d,h=table.unpack(dimensions)
  local origin=CFrame.new(0,10000+checked*100,0)*CFrame.Angles(0,.4,0)
  local model=factory.storefront({width=w,depth=d,height=h,cframe=origin})
  model.Parent=fixtures
  assert(model:GetAttribute("DoorIntegration")=="OpenApertureNoDoor")
  assert(not model:FindFirstChild("EntranceDoor"),"Door functionality falsely advertised")
  local params=OverlapParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={model}
  local opening=workspace:GetPartBoundsInBox(origin*CFrame.new(0,4.5,-d/2),Vector3.new(5.8,8.8,2),params)
  assert(#opening==0,"Entrance aperture obstructed")
  local inside=workspace:GetPartBoundsInBox(origin*CFrame.new(0,4.5,0),Vector3.new(5,8,d-2),params)
  assert(#inside==0,"Interior traversal corridor obstructed")
  assert(model.Floor.CanCollide and model.Roof.CanCollide,"Missing floor/roof collision")
  local windows=0
  for _,part in ipairs(model:GetDescendants()) do
   assert(not part:IsA("LuaSourceContainer"),"Per-building scripts added")
   if part:IsA("BasePart") then
    assert(part.Anchored and not part.CanTouch,"Unexpected physics/touch work")
    assert(part.Size.X>0 and part.Size.Y>0 and part.Size.Z>0,"Invalid geometry")
    if part.Name=="WindowPane" then windows=windows+1 assert(part.Material==Enum.Material.Glass) end
    if part.Name=="WindowTrim" then assert(not part.CanCollide,"Trim obstructs traversal") end
   end
  end
  assert(windows==2,"Expected two storefront windows")
  model:Destroy() checked=checked+1
 end
 for _,bad in ipairs({{width=0},{width=0/0},{height=math.huge},{stories=2},{doorWidth=20},{material="MissingMaterial"}}) do
  assert(not pcall(factory.storefront,bad),"Invalid configuration accepted")
 end
 local invalid=Instance.new("Model")
 assert(not pcall(factory.storefront,{},invalid),"Invalid door component accepted")
 invalid:Destroy()
 return "PASS: "..checked.." storefront configurations, open entry/traversal and parameter failures"
end)
fixtures:Destroy()
assert(ok,result)
return result
