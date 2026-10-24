-- Original training-shop furnishings. No authentic interior or scripted prop claims.
local Interior={}
local shellNames={Floor=true,Roof=true,RearWall=true,SideWall=true,DoorHeader=true,
 DoorPier=true,CornerPier=true,WindowSillWall=true,WindowHeader=true,WindowInfill=true,
 WindowPane=true,WindowTrim=true,EntranceDoor=true,LeftSlidingWindow=true,RightSlidingWindow=true}
function Interior.build(building,config)
 assert(typeof(building)=="Instance" and building:IsA("Model"),"Expected storefront Model")
 config=config or {} assert(type(config)=="table","Expected interior config")
 assert(config.seats==nil or config.seats==false,"Seating is not offered by this decorative layout")
 local floor=building:FindFirstChild("Floor")
 assert(floor and floor:IsA("Part") and floor.Anchored,"Expected anchored rectangular Floor")
 local width,depth=floor.Size.X,floor.Size.Z
 assert(width>=24 and width<=80 and depth>=16 and depth<=80,"Unsupported floor dimensions")
 local roof=building:FindFirstChild("Roof")
 assert(roof and roof:IsA("BasePart"),"Expected shell Roof")
 local base=floor.CFrame*CFrame.new(0,floor.Size.Y/2,0)
 local roofBottom=base:PointToObjectSpace(roof.Position).Y-roof.Size.Y/2
 assert(roofBottom>=12,"Insufficient interior height")
 for _,child in ipairs(building:GetChildren()) do
  assert(shellNames[child.Name],"Existing or unreviewed content must be preserved: "..child.Name)
 end
 local wood=config.woodColor or Color3.fromRGB(116,78,49)
 assert(typeof(wood)=="Color3","Expected wood Color3")
 local staged=Instance.new("Model") staged.Name="StorefrontInterior"
 staged.WorldPivot=base
 local ok,err=xpcall(function()
  staged:SetAttribute("InteriorVersion",1)
  staged:SetAttribute("Layout","OriginalTrainingShop")
  staged:SetAttribute("ClearCorridorWidth",6)
  staged:SetAttribute("FrontClearDepth",6)
  local function part(name,size,pos,material,color,collide)
   local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=base*CFrame.new(pos)
   p.Anchored=true p.CanTouch=false p.CanCollide=collide~=false
   p.Material=material p.Color=color p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
   p:SetAttribute("Decorative",true) p.Parent=staged return p
  end
  -- All furnishings remain outside the central six-stud aisle and first six studs of depth.
  local sideX=width/2-2.3
  local shelfLength=math.min(10,depth-10)
  local rearZ=depth/2-3
  local shelfZ=depth/2-2-shelfLength/2
  for _,sign in ipairs({-1,1}) do
   part("DecorativeFloorInset",Vector3.new(3,.025,depth-8),Vector3.new(sign*sideX,.018,2),Enum.Material.WoodPlanks,Color3.fromRGB(105,91,73),false)
   part("DecorativeShelfBack",Vector3.new(.18,5.5,shelfLength),Vector3.new(sign*(width/2-1),2.75,shelfZ),Enum.Material.Wood,wood,true)
   for level=1,3 do
    part("DecorativeShelf",Vector3.new(2, .18,shelfLength),Vector3.new(sign*sideX,level*1.5,shelfZ),Enum.Material.Wood,wood,true)
   end
   for _,offset in ipairs({-1,1}) do
    part("DecorativeShelfPost",Vector3.new(.18,5.5,.18),Vector3.new(sign*(sideX-.85),2.75,shelfZ+offset*(shelfLength/2-.15)),Enum.Material.Metal,Color3.fromRGB(58,61,58),true)
   end
   for i=1,3 do
    part("DecorativeStockBox",Vector3.new(.9,.8,.85),Vector3.new(sign*sideX,1.99,shelfZ+(i-2)*1.5),Enum.Material.SmoothPlastic,Color3.fromRGB(139+i*9,126+i*5,98),true)
   end
  end
  -- Counter occupies a rear side bay rather than crossing the entrance aisle.
  local counterX=width/2-6
  part("DecorativeCounterBase",Vector3.new(3,2.6,2.5),Vector3.new(counterX,1.3,rearZ),Enum.Material.Wood,wood,true)
  part("DecorativeCounterTop",Vector3.new(3.3,.22,2.8),Vector3.new(counterX,2.71,rearZ),Enum.Material.WoodPlanks,Color3.fromRGB(170,136,92),true)
  part("DecorativeCounterMat",Vector3.new(1.5,.03,.9),Vector3.new(counterX,2.84,rearZ),Enum.Material.Fabric,Color3.fromRGB(49,62,55),false)
  -- Commit is last; no yields and no edits to shell/components/manual content.
  assert(not building:FindFirstChild(staged.Name),"Interior already exists")
  staged.Parent=building
 end,debug.traceback)
 if not ok then staged:Destroy() error(err,2) end
 return staged
end
return Interior
