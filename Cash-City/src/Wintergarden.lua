-- Original, source-guarded renovation. Complete assemblies precede Registry.start.
local Garden={}
local function frame(r) return CFrame.new(r.pos[1],r.pos[2],r.pos[3],table.unpack(r.matrix)) end
local function matches(part,r)
 local cf=frame(r)
 return part.Name==r.name and (part.Position-cf.Position).Magnitude<.05
  and (part.Size-Vector3.new(table.unpack(r.size))).Magnitude<.05
  and (part.CFrame.RightVector-cf.RightVector).Magnitude<.001 and (part.CFrame.UpVector-cf.UpVector).Magnitude<.001
end
function Garden.build(root,plan)
 plan=plan or require(script.Parent.WintergardenData)
 local archive=root:FindFirstChild("WintergardenSourceArchive")
 local archiveMarker=archive and archive:FindFirstChild("CashCityWintergardenArchiveManifest")
 assert(not archive or archive:GetAttribute("CashCityWintergardenArchive")==true or (archiveMarker and archiveMarker:IsA("StringValue") and archiveMarker.Value=="Wintergarden"),"Preserve manual source archive")
 local previous=root:FindFirstChild(plan.id)
 local marker=previous and previous:FindFirstChild("CashCityGeneratedBlockManifest")
 assert(not previous or previous:GetAttribute("CashCityGeneratedBlock")==true or (marker and marker:IsA("StringValue") and marker.Value==plan.id),"Preserve manual Wintergarden")
 if archive then
  for _,part in ipairs(archive:GetChildren()) do if part:IsA("BasePart") and part:GetAttribute("WG_SourceIndex")==nil then
   local saved=part:FindFirstChild("WGOriginalState") assert(saved and saved:IsA("StringValue"),"Missing archived source flags")
   local original=game:GetService("HttpService"):JSONDecode(saved.Value)
   for _,key in ipairs({"CanCollide","CanQuery","CanTouch","CastShadow"}) do
    local value=original[key] if value==nil then value=key~="CanTouch" else value=value=="true" end
    part:SetAttribute("WG_Original"..key,value)
   end
   part:SetAttribute("WG_OriginalTransparency",tonumber(original.Transparency) or 0) part:SetAttribute("WG_SourceIndex",original.index)
  end end
 end
 local byName={}
 for _,part in ipairs(root:GetDescendants()) do if part:IsA("BasePart") then
  byName[part.Name]=byName[part.Name] or {} table.insert(byName[part.Name],part)
 end end
 local originals={}
 for _,guard in ipairs(plan.replacements) do
  local found
  for _,part in ipairs(byName[guard.record.name] or {}) do
   if matches(part,guard.record) then
    local archived=archive and part:IsDescendantOf(archive)
    local collision=archived and part:GetAttribute("WG_OriginalCanCollide") or part.CanCollide
    assert(collision==guard.record.collide,"Source collision modified; preserve current work")
    assert(not archived or part:GetAttribute("WG_SourceIndex")==guard.sourceIndex,"Archive identity changed")
    found=part break
   end
  end
  assert(found,"Wintergarden source missing or modified: "..guard.record.name)
  table.insert(originals,{part=found,index=guard.sourceIndex,cf=found.CFrame,size=found.Size,parent=found.Parent})
 end
 if previous then previous:SetAttribute("CashCityGeneratedBlock",true) end
 if archive then archive:SetAttribute("CashCityWintergardenArchive",true) end
 local model,stats=require(script.Parent.CityBlockGenerator).build(root,plan,nil,80)
 -- The generated blocks commit separately; no full-city transaction is claimed.
 for _,original in ipairs(originals) do
  local p=original.part
  assert(p.Parent==original.parent and p.CFrame==original.cf and p.Size==original.size,"Source changed during renovation")
 end
 if not archive then
  archive=Instance.new("Folder") archive.Name="WintergardenSourceArchive"
  archive:SetAttribute("CashCityWintergardenArchive",true) archive.Parent=root
 end
 for _,original in ipairs(originals) do
  local p=original.part
  if not p:IsDescendantOf(archive) then
   for _,key in ipairs({"CanCollide","CanQuery","CanTouch","CastShadow","Transparency"}) do p:SetAttribute("WG_Original"..key,p[key]) end
   p:SetAttribute("WG_SourceIndex",original.index) p.Parent=archive
  end
  p.Transparency=1 p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false
 end
 for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then part.CastShadow=false end end
 for index,anchor in ipairs(plan.doorAnchors or {}) do
  local width=anchor.apertureWidth or anchor.width
  local height=anchor.apertureHeight or anchor.height
  local door=require(script.Parent.BuildingInteractions).door({apertureWidth=width,apertureHeight=height,color=Color3.fromRGB(126,142,146)})
  door.Name="WintergardenDoor_"..tostring(anchor.name or index)
  local cf=frame(anchor) door:PivotTo(cf)
  door.Control.CFrame=cf*CFrame.new(-width/2+.05,-height/2+1.2,-.65)
  door:SetAttribute("IntegrationStatus","AwaitingNativeSizeAndPromptAcceptance")
  door.Parent=model
 end
 model:SetAttribute("ReferenceStatus","Original barrel-vault interpretation; roof rise and interiors estimated")
 require(script.Parent.ArrivalLounge).build(model)
 return model,stats
end
return Garden
