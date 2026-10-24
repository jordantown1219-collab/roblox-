-- Run in native Studio with BuildingInteractions in ServerScriptService.
local components=require(game.ServerScriptService.BuildingInteractions)
assert(type(components.slidingWindow)=="function","slidingWindow factory missing")
local fixtures=Instance.new("Folder") fixtures.Name="SlidingWindowChecks" fixtures.Parent=workspace
local ok,result=pcall(function()
 local checked=0
 for _,size in ipairs({{8,5},{6,4},{12,8}}) do
  local w,h=table.unpack(size)
  local window=components.slidingWindow({width=w,height=h})
  window:PivotTo(CFrame.new(0,12000+checked*100,0)*CFrame.Angles(0,math.rad(37),0)) window.Parent=fixtures
  assert(game:GetService("CollectionService"):HasTag(window,"SSInteractable"))
  assert(window:GetAttribute("Motion")=="Slide" and window:GetAttribute("Axis")=="X")
  assert(not window:GetAttribute("LobbyInteraction"),"Production permission bypass")
  local moving=window.Moving local sash=moving.Sash local home=moving:GetPivot()
  local travel=window:GetAttribute("Travel")
  assert(math.abs(travel-(w/2-.3))<.0001,"Travel must match rail span")
  local initial=sash.CFrame
  local params=OverlapParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={window}
  params.RespectCanCollide=true
  for i=0,24 do
   moving:PivotTo(home*CFrame.new(travel*i/24,0,0))
   -- Include fixed frame/pane explicitly; registry excludes its own assembly.
   for _,part in ipairs(window:GetChildren()) do
    if part:IsA("BasePart") and part.CanCollide then
     local p=part.CFrame:PointToObjectSpace(sash.Position)
     assert(math.abs(p.X)>=(part.Size.X+sash.Size.X)/2-.001 or math.abs(p.Y)>=(part.Size.Y+sash.Size.Y)/2-.001 or math.abs(p.Z)>=(part.Size.Z+sash.Size.Z)/2-.001,"Sash intersects frame or fixed pane")
    end
   end
   assert(#workspace:GetPartBoundsInBox(sash.CFrame,sash.Size-Vector3.new(.01,.01,.01),params)==0,"External obstruction")
  end
  assert((sash.Position-(initial*CFrame.new(travel,0,0)).Position).Magnitude<.0001,"Open travel wrong")
  moving:PivotTo(home) assert((sash.Position-initial.Position).Magnitude<.0001,"Closed pose wrong")
  for _,part in ipairs(window:GetDescendants()) do
   assert(not part:IsA("LuaSourceContainer"))
   if part:IsA("BasePart") then assert(part.Anchored and not part.CanTouch) end
  end
  window:Destroy() checked=checked+1
 end
 for _,config in ipairs({{width=0},{height=0/0},{duration=math.huge},{width=13}}) do
  assert(not pcall(components.slidingWindow,config),"Invalid config accepted")
 end
 return "PASS: "..checked.." training sliding windows, 25 rail samples each, closed/open geometry"
end)
fixtures:Destroy() assert(ok,result) return result
