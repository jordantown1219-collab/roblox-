-- Reversible Map 1 enclosure; original parts remain in place with restoration metadata.
-- Rounded outward from Hart Plaza and completed RenCen footprints with >=64stud margin.
local Boundary={limits={minX=-1850,maxX=750,minZ=-650,maxZ=1250,floorY=-20,resetY=-8,ceilingY=1200}}
function Boundary.contains(p)
 local b=Boundary.limits
 return p.X>=b.minX and p.X<=b.maxX and p.Z>=b.minZ and p.Z<=b.maxZ and p.Y>=b.resetY and p.Y<=b.ceilingY
end
function Boundary.build(root)
 local old=root:FindFirstChild('CashCityMap1Boundary')
 assert(not old,'Existing Map 1 boundary: preserve and review before replacing')
 local b=Boundary.limits
 local model=Instance.new('Model') model.Name='CashCityMap1Boundary'
 model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 model:SetAttribute('Scope','Map1 RenCen, RiverWalk and existing park/team routes; estimated enclosure')
 local function part(name,size,cf,color,transparency)
  local p=Instance.new('Part') p.Name=name p.Size=size p.CFrame=cf p.Anchored=true p.CanTouch=false
  p.Material=Enum.Material.Concrete p.Color=color or Color3.fromRGB(102,117,111)
  p.Transparency=transparency or 0 p.CastShadow=false p.Parent=model return p
 end
 local faces={
  {axis='X',fixed=b.minX,a=b.minZ,z=b.maxZ},{axis='X',fixed=b.maxX,a=b.minZ,z=b.maxZ},
  {axis='Z',fixed=b.minZ,a=b.minX,z=b.maxX},{axis='Z',fixed=b.maxZ,a=b.minX,z=b.maxX},
 }
 -- Continuous collision curtains meet at overlapping corners; opaque hoarding below
 -- 180 studs screens road ends from all currently accessible lobby/ground levels.
 for _,face in ipairs(faces) do
  local count=math.ceil((face.z-face.a)/900)
  for i=1,count do
   local length=(face.z-face.a)/count local middle=face.a+(i-.5)*length
   local pos=face.axis=='X' and Vector3.new(face.fixed,80,middle) or Vector3.new(middle,80,face.fixed)
   local size=face.axis=='X' and Vector3.new(4,200,length+4) or Vector3.new(length+4,200,4)
   part('OpaqueRoadEndScreen',size,CFrame.new(pos))
   pos=Vector3.new(pos.X,(b.floorY+b.ceilingY)/2,pos.Z)
   size=face.axis=='X' and Vector3.new(4,b.ceilingY-b.floorY,length+4) or Vector3.new(length+4,b.ceilingY-b.floorY,4)
   part('InvisiblePerimeter',size,CFrame.new(pos),nil,1)
  end
 end
 -- Split large planes to stay below Roblox's per-part dimension limit.
 local count=math.ceil((b.maxX-b.minX)/1000)
 for i=1,count do
  local width=(b.maxX-b.minX)/count local x=b.minX+(i-.5)*width
  for _,y in ipairs({b.floorY,b.ceilingY}) do
   part(y==b.floorY and 'FallCatchFloor' or 'MapCeiling',Vector3.new(width+4,2,b.maxZ-b.minZ+4),CFrame.new(x,y,(b.minZ+b.maxZ)/2),nil,1)
  end
 end
 local hidden,bank,restored=0,0,0
 local existing=root:GetDescendants()
 for index,p in ipairs(existing) do
  if p:IsA('BasePart') then
   local pos=p.Position
   if p.Name=='EstimatedRiverSafetyRail' and pos.X>b.minX and pos.X<b.maxX and pos.Z>b.minZ and pos.Z<b.maxZ then
    part('InvisibleWaterEdge',Vector3.new(math.max(.8,p.Size.X),240,p.Size.Z+.8),p.CFrame*CFrame.new(0,80,0),nil,1)
    bank=bank+1
   end
   -- Preserve geometry, collision and hierarchy. Only restore-able rendering state
   -- is changed; broad water/substrate surfaces are retained for the horizon.
   if p.Name~='DetroitRiver' and p.Name~='SourceLand' and (pos.X<b.minX or pos.X>b.maxX or pos.Z<b.minZ or pos.Z>b.maxZ) then
    if p:GetAttribute('Map1PriorTransparency')==nil then
     p:SetAttribute('Map1PriorTransparency',p.Transparency) p:SetAttribute('Map1PriorCastShadow',p.CastShadow)
    end
    p.Transparency=1 p.CastShadow=false hidden=hidden+1
   elseif p:GetAttribute('Map1PriorTransparency')~=nil then
    p.Transparency=p:GetAttribute('Map1PriorTransparency') p.CastShadow=p:GetAttribute('Map1PriorCastShadow')
    p:SetAttribute('Map1PriorTransparency',nil) p:SetAttribute('Map1PriorCastShadow',nil) restored=restored+1
   end
  end
  if index%1000==0 then task.wait() end
 end
 assert(bank>0,'No existing shoreline rails found; water edge unverified')
 model:SetAttribute('HiddenExteriorParts',hidden) model:SetAttribute('WaterEdgeBlockers',bank)
 model.Parent=root
 if game:GetService('RunService'):IsRunning() then
  local Players=game:GetService('Players') local config=require(script.Parent.CityConfig)
  task.spawn(function()
   while model.Parent do
    task.wait(.5)
    if not model.Parent then break end
    local arena=workspace:FindFirstChild('SmallSignalsArena')
    if arena and arena:GetAttribute('MatchActive')==true then
     for _,player in ipairs(Players:GetPlayers()) do
      local char=player.Character local hrp=char and char:FindFirstChild('HumanoidRootPart')
      local hum=char and char:FindFirstChildOfClass('Humanoid')
      if hrp and hum and hum.Health>0 and player:GetAttribute('RiverfrontLoading')~=true and not Boundary.contains(hrp.Position) then
       local spawn=player.Team and config.Spawns[player.Team.Name]
       if spawn then char:PivotTo(CFrame.new(spawn)) hrp.AssemblyLinearVelocity=Vector3.zero end
      end
     end
    end
   end
  end)
 end
 return model,{hidden=hidden,waterEdges=bank,restored=restored}
end
return Boundary
