-- Lead: import current candidate modules under a fresh container, then run this
-- source as its child Script/ModuleScript (or bind script.Parent accordingly).
-- Fresh requires avoid accepting old Studio ModuleScript caches.
local modules=script.Parent
local Templates=require(modules:WaitForChild("BuildingTemplates",2))
local Components=require(modules:WaitForChild("BuildingInteractions",2))
local fixtures=Instance.new("Folder") fixtures.Name="StorefrontWindowAdversarialTemporary" fixtures.Parent=game.ServerStorage
local results={}
local function own(obj) obj.Parent=fixtures return obj end
local function test(name,fn)
 local ok,err=pcall(fn)
 table.insert(results,{name=name,passed=ok,error=not ok and tostring(err) or nil})
end
local function partsNamed(model,name)
 local list={} for _,obj in ipairs(model:GetDescendants()) do if obj.Name==name then table.insert(list,obj) end end return list
end
local function component() return own(Components.slidingWindow({width=8,height=5})) end
local function rejected(window,config)
 local before=window and window.Parent
 local ok,result=pcall(Templates.storefront,config or {},nil,window)
 if ok and typeof(result)=="Instance" then result:Destroy() end
 assert(not ok,"Malformed/incompatible supplied window accepted")
 assert(not window or window.Parent==before,"Caller component ownership changed")
end
test("default shell keeps fixed windows and open doorway",function()
 local shell=own(Templates.storefront())
 assert(#partsNamed(shell,"WindowPane")==2,"Default glazing changed")
 assert(shell:GetAttribute("DoorIntegration")=="OpenApertureNoDoor")
 assert(not shell:FindFirstChild("EntranceDoor"))
end)
test("optional windows retain independent door contract",function()
 local window=component() local door=own(Components.door())
 local shell=own(Templates.storefront({},door,window))
 local entrance=assert(shell:FindFirstChild("EntranceDoor"))
 assert(entrance~=door and entrance:FindFirstChild("Moving") and entrance.Control:FindFirstChildOfClass("ProximityPrompt"))
 assert(shell:GetAttribute("DoorIntegration")=="ComponentProvidedAwaitingRegistry")
 assert(window.Parent==fixtures and door.Parent==fixtures,"Caller templates reparented")
end)
test("two window clones without static double panes",function()
 local window=component()
 local origin=CFrame.new(100,200,300)*CFrame.Angles(0,.47,0)
 local shell=own(Templates.storefront({cframe=origin},nil,window))
 assert(#partsNamed(shell,"WindowPane")==0,"Static pane remains behind functional window")
 local clones={}
 for _,child in ipairs(shell:GetChildren()) do if child:IsA("Model") and child:GetAttribute("Motion")=="Slide" then table.insert(clones,child) end end
 assert(#clones==2 and clones[1]~=clones[2],"Expected two independent supplied-window clones")
 for _,clone in ipairs(clones) do
  assert(clone~=window and clone:GetAttribute("Axis")=="X")
  assert(game:GetService("CollectionService"):HasTag(clone,"SSInteractable"),"Window not tagged for registry")
  assert(clone.Control:FindFirstChildOfClass("ProximityPrompt"),"Prompt lost")
  local center=origin:PointToObjectSpace(clone:GetPivot().Position)
  assert(math.abs(center.Y-6.75)<.001 and math.abs(center.Z+14)<.001,"Window aperture alignment differs")
  local frame=clone:GetPivot()
  local width,height=clone:GetAttribute("FrameWidth"),clone:GetAttribute("FrameHeight")
  local travel=clone:GetAttribute("Travel")
  for _,desc in ipairs(clone:GetDescendants()) do
   assert(not desc:IsA("LuaSourceContainer"),"Embedded component script")
   if desc:IsA("BasePart") then assert(desc.Anchored and not desc.CanTouch,"Unexpected physical component") end
  end
  for sample=0,24 do
   for _,part in ipairs(clone.Moving:GetDescendants()) do if part:IsA("BasePart") then
    for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
     local world=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)+frame.RightVector*travel*sample/24
     local point=frame:PointToObjectSpace(world)
     assert(math.abs(point.X)<=width/2+.001 and math.abs(point.Y)<=height/2+.001,"Moving pane leaves frame during sweep")
    end end end
   end end
  end
 end
end)
local mutations={
 {"missing Moving",function(w) w.Moving:Destroy() end},
 {"missing prompt",function(w) w.Control:FindFirstChildOfClass("ProximityPrompt"):Destroy() end},
 {"wrong motion",function(w) w:SetAttribute("Motion","Hinge") end},
 {"invalid travel",function(w) w:SetAttribute("Travel",math.huge) end},
 {"travel exceeds frame",function(w) w:SetAttribute("Travel",30) end},
 {"oversized moving pane",function(w) w.Moving.Sash.Size=Vector3.new(40,5,.12) end},
 {"unanchored moving pane",function(w) w.Moving.Sash.Anchored=false end},
 {"unanchored fixed pane",function(w) w.FixedPane.Anchored=false end},
 {"embedded script",function(w) local s=Instance.new("Script") s.Parent=w.Moving end},
 {"nonarchivable descendant",function(w) w.Moving.Sash.Archivable=false end},
 {"frame metadata mismatch",function(w) w:SetAttribute("FrameWidth",6) end},
}
for _,entry in ipairs(mutations) do
 test("reject "..entry[1],function() local w=component() entry[2](w) rejected(w) end)
end
test("reject window wider than frontage",function() rejected(component(),{width=24}) end)
test("reject unsupported narrow frontage even with minimum window",function()
 rejected(own(Components.slidingWindow({width=6,height=5})),{width=24,doorWidth=8})
end)
test("minimum aperture accepts matching component",function()
 local w=own(Components.slidingWindow({width=6,height=4}))
 local shell=own(Templates.storefront({width=24,height=12},nil,w))
 assert(#partsNamed(shell,"WindowPane")==0)
end)
fixtures:Destroy()
local passed=0 for _,result in ipairs(results) do if result.passed then passed=passed+1 end end
return {passed=passed,total=#results,results=results,scope="native component validation and geometric contract only; no input/multiplayer/crush/FPS acceptance"}
