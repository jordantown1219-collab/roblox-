-- Fresh-import candidate modules; Lead records native execution separately.
local buildings=require(game.ServerScriptService.BuildingTemplates)
local interactions=require(game.ServerScriptService.BuildingInteractions)
local fixtures=Instance.new("Folder") fixtures.Name="StorefrontWindowChecks" fixtures.Parent=workspace
local ok,result=pcall(function()
 local checked=0
 for _,case in ipairs({{32,28,14,8,5},{24,16,12,6,4},{80,80,24,12,6.5}}) do
  local w,d,h,fw,fh=table.unpack(case)
  local cf=CFrame.new(0,15000+checked*100,0)*CFrame.Angles(0,.63,0)
  local source=interactions.slidingWindow({width=fw,height=fh}) source.Parent=fixtures
  local model=buildings.storefront({width=w,depth=d,height=h,cframe=cf},nil,source) model.Parent=fixtures
  assert(not model:FindFirstChild("WindowPane") and not model:FindFirstChild("WindowTrim"),"Static glazing duplicates component")
  assert(source.Parent==fixtures and source.Moving.Sash.Parent==source.Moving,"Source component changed")
  local shellParams=OverlapParams.new() shellParams.FilterType=Enum.RaycastFilterType.Include shellParams.FilterDescendantsInstances={model}
  assert(#workspace:GetPartBoundsInBox(cf*CFrame.new(0,4.5,-d/2),Vector3.new(5.8,8.8,2),shellParams)==0,"Entry blocked")
  assert(#workspace:GetPartBoundsInBox(cf*CFrame.new(0,4.5,0),Vector3.new(5,8,d-2),shellParams)==0,"Access corridor blocked")
  for _,name in ipairs({"LeftSlidingWindow","RightSlidingWindow"}) do
   local component=model[name] local moving=component.Moving local sash=moving.Sash
   assert(game:GetService("CollectionService"):HasTag(component,"SSInteractable"))
   assert(component:GetAttribute("Motion")=="Slide" and component:GetAttribute("Axis")=="X")
   assert(component.Control:FindFirstChildOfClass("ProximityPrompt") and component.MotionPivot:IsA("BasePart"))
   local home=moving:GetPivot() local travel=component:GetAttribute("Travel")
   local params=OverlapParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={component,source}
   params.RespectCanCollide=true
   for sample=0,24 do
    moving:PivotTo(home*CFrame.new(travel*sample/24,0,0))
    assert(#workspace:GetPartBoundsInBox(sash.CFrame,sash.Size-Vector3.new(.02,.02,.02),params)==0,"Sash hits shell/infill")
   end
   -- Open left half must contain no glass or added shell blocker (frames excluded by margins).
   local origin=component:GetPivot()
   local openParams=OverlapParams.new() openParams.FilterType=Enum.RaycastFilterType.Include openParams.FilterDescendantsInstances={model}
   local gap=workspace:GetPartBoundsInBox(origin*CFrame.new(-travel/2,0,0),Vector3.new(travel-.5,fh-.7,.65),openParams)
   for _,part in ipairs(gap) do assert(not part.CanCollide,"Open sash aperture blocked by "..part.Name) end
   moving:PivotTo(home)
  end
  model:Destroy() source:Destroy() checked=checked+1
 end
 local plain=buildings.storefront() plain.Parent=fixtures
 local panes=0 for _,part in ipairs(plain:GetChildren()) do if part.Name=="WindowPane" then panes=panes+1 end end
 assert(panes==2 and plain:GetAttribute("WindowIntegration")==nil and not plain:FindFirstChild("LeftSlidingWindow"),"Default behavior changed")
 local door=interactions.door() door.Parent=fixtures
 local withDoor=buildings.storefront({},door) withDoor.Parent=fixtures
 assert(withDoor.EntranceDoor and not withDoor:FindFirstChild("LeftSlidingWindow"),"Existing door API changed")
 local source=interactions.slidingWindow() source.Parent=fixtures
 assert(not pcall(buildings.storefront,{width=24,doorWidth=8},nil,source),"Oversized frame accepted")
 source:SetAttribute("Travel",math.huge)
 assert(not pcall(buildings.storefront,{},nil,source),"Invalid travel accepted")
 source:SetAttribute("Travel",3.7) source.Moving.Sash.Archivable=false
 assert(not pcall(buildings.storefront,{},nil,source),"Incomplete clone accepted")
 return "PASS: "..checked.." rotated storefront/window sizes; clear sweeps/openings/defaults/invalid inputs"
end)
fixtures:Destroy() assert(ok,result) return result
