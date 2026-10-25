-- Source-guarded exterior pass. Lead is the sole caller during city assembly.
local Details={}
local function colorNear(a,b) return math.abs(a.R-b.R)+math.abs(a.G-b.G)+math.abs(a.B-b.B)<.005 end
function Details.finish(model,records)
 local byName={}for _,r in ipairs(records) do byName[r.name]=r end
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then
  p.CastShadow=false;p.CanQuery=false
  local r=byName[p.Name]
  if r and r.plaqueText and not p:FindFirstChild('CashCityBuildingName') then
   local gui=Instance.new('SurfaceGui');gui.Name='CashCityBuildingName';gui.Face=Enum.NormalId[r.plaqueFace];gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=40;gui.Parent=p
   local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text=r.plaqueText;label.TextScaled=true;label.Font=Enum.Font.GothamMedium;label.TextColor3=Color3.fromRGB(238,237,225);label.Parent=gui
  end
  if r and r.lightFace and not p:FindFirstChild('PodiumAccentLight') then
   local light=Instance.new('SurfaceLight');light.Name='PodiumAccentLight';light.Face=Enum.NormalId[r.lightFace];light.Brightness=.3;light.Range=12;light.Angle=90;light.Color=Color3.fromRGB(255,235,199);light.Shadows=false;light.Parent=p
  end
 end end
end
function Details.build(root)
 local plan=require(script.Parent.RenaissanceData)
 local byName={}
 for _,obj in ipairs(root:GetDescendants()) do
  if obj:IsA("BasePart") and obj.Name:match("^Facade_") then
   byName[obj.Name]=byName[obj.Name] or {} table.insert(byName[obj.Name],obj)
  end
 end
 local finishes={}
 for _,guard in ipairs(plan.guards) do
  local r=guard.record
  local cf=CFrame.new(r.pos[1],r.pos[2],r.pos[3],table.unpack(r.matrix))
  local found=false
  for _,wall in ipairs(byName[r.name] or {}) do
   if (wall.Position-cf.Position).Magnitude<.05 and (wall.Size-Vector3.new(table.unpack(r.size))).Magnitude<.05
    and (wall.CFrame.RightVector-cf.RightVector).Magnitude<.001 and (wall.CFrame.UpVector-cf.UpVector).Magnitude<.001
    and wall.CanCollide==r.collide then
     if guard.finish then
      local color=Color3.fromRGB(table.unpack(guard.finish.color))
      local material=assert(Enum.Material[guard.finish.material],"Invalid podium finish")
      local original=wall.Material==Enum.Material[r.material] and colorNear(wall.Color,Color3.fromRGB(table.unpack(r.color)))
      local owned=wall.Material==material and colorNear(wall.Color,color)
      assert((original or owned) and math.abs(wall.Transparency-(r.trans or 0))<.001,"Preserve custom podium finish")
      table.insert(finishes,{wall=wall,color=color,material=material,priorColor=wall.Color,priorMaterial=wall.Material,priorCF=wall.CFrame,priorSize=wall.Size,priorTransparency=wall.Transparency,priorCollision=wall.CanCollide})
     end
     found=true break
    end
  end
  assert(found,"RenCen source changed; preserve existing details: "..r.name)
 end
 local generator=require(script.Parent.CityBlockGenerator)
 for _,block in ipairs({plan.towers,plan.walk}) do
  local old=root:FindFirstChild(block.id)
  local marker=old and old:FindFirstChild("CashCityGeneratedBlockManifest")
  assert(not old or old:GetAttribute("CashCityGeneratedBlock")==true or (marker and marker:IsA("StringValue") and marker.Value==block.id),"Preserve manually built RenCen content")
 end
 for _,block in ipairs({plan.towers,plan.walk}) do
  local old=root:FindFirstChild(block.id)
  if old then old:SetAttribute("CashCityGeneratedBlock",true) end
 end
 local tower,towerStats=generator.build(root,plan.towers,nil,80)
 Details.finish(tower,plan.towers.records)
 tower:SetAttribute("ReferenceStatus","Original exterior interpretation; estimated framing spacing")
 local walk,walkStats=generator.build(root,plan.walk,nil,80)
 for _,part in ipairs(walk:GetDescendants()) do
  if part:IsA("BasePart") then part.CastShadow=false end
 end
 walk:SetAttribute("ReferenceStatus",plan.walk.referenceStatus)
 -- Recheck before touching body finishes; generation yields between independent blocks.
 for _,entry in ipairs(finishes) do
  assert(entry.wall:IsDescendantOf(root) and entry.wall.CFrame==entry.priorCF and entry.wall.Size==entry.priorSize and entry.wall.Transparency==entry.priorTransparency and entry.wall.CanCollide==entry.priorCollision and entry.wall.Color==entry.priorColor and entry.wall.Material==entry.priorMaterial,"Podium changed during generation; preserve manual finish")
 end
 for _,entry in ipairs(finishes) do entry.wall.Color=entry.color entry.wall.Material=entry.material end
 return {towerParts=towerStats.parts,walkParts=walkStats.parts}
end
return Details
