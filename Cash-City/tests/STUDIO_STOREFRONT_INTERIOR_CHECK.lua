-- Lead supplies fresh temporary module returns; no cached module or permanent fixture.
return function(Templates,Components,Interior)
 local owned={} local checks=0
 local function check(v,message) assert(v,message) checks=checks+1 end
 local function track(v) owned[#owned+1]=v return v end
 local ok,result=xpcall(function()
  local door=track(Components.door())
  local window=track(Components.slidingWindow({width=6,height=5}))
  for _,config in ipairs({{}, {width=24,depth=16},
    {width=40,depth=34,cframe=CFrame.new(85,10,-40)*CFrame.Angles(0,.73,0)}}) do
   local shell=track(Templates.storefront(config,door,window))
   local floor=shell.Floor local base=floor.CFrame*CFrame.new(0,floor.Size.Y/2,0)
   local before={} for _,obj in ipairs(shell:GetDescendants()) do before[obj]=obj.Parent end
   local interior=Interior.build(shell)
   check(interior.Parent==shell,"Interior committed")
   for obj,parent in pairs(before) do check(obj.Parent==parent,"Exterior/component identity preserved") end
   for _,p in ipairs(interior:GetDescendants()) do
    check(p:IsA("BasePart"),"Only declarative Parts, no scripts/prompts")
    check(p.Anchored and not p.CanTouch and p:GetAttribute("Decorative")==true,"Static decorative contract")
    local low,high=math.huge,-math.huge
    local minZ=math.huge
    for _,x in ipairs({-.5,.5}) do for _,y in ipairs({-.5,.5}) do for _,z in ipairs({-.5,.5}) do
     local point=base:PointToObjectSpace(p.CFrame*Vector3.new(p.Size.X*x,p.Size.Y*y,p.Size.Z*z))
     check(math.abs(point.X)<floor.Size.X/2-.5 and math.abs(point.Z)<floor.Size.Z/2-.5,"Furniture within shell")
     check(point.Y>=-.001 and point.Y<12,"Furniture above floor and below roof")
     low=math.min(low,point.X) high=math.max(high,point.X) minZ=math.min(minZ,point.Z)
    end end end
    check(high<=-3 or low>=3,"Six-stud full-depth corridor clear")
    check(minZ>=-floor.Size.Z/2+6-.001,"Front window/control and door-sweep region clear")
   end
   local count=#interior:GetDescendants()
   check(not pcall(function() Interior.build(shell) end),"Existing interior protected")
   check(interior.Parent==shell and #interior:GetDescendants()==count,"Rejected rebuild preserved content")
   local copy=track(Templates.storefront(config,door,window))
   local second=Interior.build(copy)
   local a,b=interior:GetChildren(),second:GetChildren()
   check(#a==#b,"Repeat layout count")
   for i,p in ipairs(a) do
    check(p.Name==b[i].Name and p.Size==b[i].Size and p.CFrame==b[i].CFrame and p.Material==b[i].Material,"Deterministic furniture")
   end
  end
  local manual=track(Templates.storefront())
  local furniture=Instance.new("Model") furniture.Name="Furniture" furniture.Parent=manual
  check(not pcall(function() Interior.build(manual) end),"Manual furniture blocks addition")
  check(furniture.Parent==manual and not manual:FindFirstChild("StorefrontInterior"),"Manual furniture preserved")
  local invalid=track(Templates.storefront())
  check(not pcall(function() Interior.build(invalid,{woodColor="bad"}) end),"Invalid config rejected")
  check(not invalid:FindFirstChild("StorefrontInterior"),"No partial invalid layout")
  return {checks=checks,status="PASS",scenarios=3,scope="Native geometry only; no seat/interaction/device claims"}
 end,debug.traceback)
 for _,obj in ipairs(owned) do obj:Destroy() end
 if not ok then error(result) end
 return result
end
