-- Additive static facade dressing. No per-building scripts or physics work.
local Civic={}
function Civic.build(root,plan)
 plan=plan or require(script.Parent.CivicFacadeData)
 local existing=root:FindFirstChild("CivicFacadeDetails")
 local marker=existing and existing:FindFirstChild("CashCityReferenceDecorManifest")
 assert(not existing or existing:GetAttribute("CashCityReferenceDecor")==true or (marker and marker:IsA("StringValue") and marker.Value==plan.reference),"Preserve manual facade details")
 local source={}
 for _,obj in ipairs(root:GetDescendants()) do
  if obj:IsA("BasePart") and (obj.Name=="Facade_69000343" or obj.Name=="Facade_320396455") then table.insert(source,obj) end
 end
 local walls={} local finishes={}
 for index,face in ipairs(plan.faces) do
  local expected=CFrame.new(face.pos[1],face.pos[2],face.pos[3],table.unpack(face.matrix))
  finishes[index]={color=Color3.fromRGB(table.unpack(face.color)),material=assert(Enum.Material[face.material],"Invalid facade material")}
  for _,wall in ipairs(source) do
   if wall.Name==face.name and (wall.Position-expected.Position).Magnitude<.05 and (wall.Size-Vector3.new(table.unpack(face.size))).Magnitude<.05 and (wall.CFrame.RightVector-expected.RightVector).Magnitude<.001 and (wall.CFrame.UpVector-expected.UpVector).Magnitude<.001 then walls[index]=wall break end
  end
  assert(walls[index],"Source facade missing or modified; keep previous details")
 end
 assert(#plan.details<=450,"Facade detail budget exceeded")
 local staged=Instance.new("Folder") staged.Name="CivicFacadeDetails"
 staged:SetAttribute("CashCityReferenceDecor",true)
 staged:SetAttribute("ReferenceStatus",plan.status)
 staged:SetAttribute("ReferenceURL",plan.reference)
 local manifest=Instance.new("StringValue") manifest.Name="CashCityReferenceDecorManifest" manifest.Value=plan.reference manifest.Parent=staged
 staged.Parent=root
 local ok,err=pcall(function()
  for first=1,#plan.details,80 do
   local batch=Instance.new("Folder") batch.Name="FacadeBatch_"..first batch.Parent=staged
   for index=first,math.min(first+79,#plan.details) do
    local record=plan.details[index]
    local p=Instance.new("Part") p.Name=record.name p.Size=Vector3.new(table.unpack(record.size))
    p.CFrame=CFrame.new(record.pos[1],record.pos[2],record.pos[3],table.unpack(record.matrix))
    p.Color=Color3.fromRGB(table.unpack(record.color)) p.Material=Enum.Material[record.material]
    p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false
    p:SetAttribute("SourceOSM",record.osm) p.Parent=batch
   end
   task.wait()
  end
  for index,finish in ipairs(finishes) do walls[index].Color=finish.color walls[index].Material=finish.material end
 end)
 if not ok then staged:Destroy() error(err) end
 if existing then existing:Destroy() end
 return staged,#plan.details
end
return Civic
