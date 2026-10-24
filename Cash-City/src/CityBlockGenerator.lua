-- Editor/bake utility. Nothing runs until build is explicitly called.
-- Existing geography records are accepted; templates retain their interaction contracts.
local Generator={}
local locks=setmetatable({},{__mode="k"})
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
local function vector(values,positive)
 assert(type(values)=="table" and #values==3,"Expected three vector components")
 for _,n in ipairs(values) do assert(finite(n) and (not positive or (n>0 and n<=2048)),"Invalid vector component") end
 return Vector3.new(values[1],values[2],values[3])
end
local function transform(record)
 local pos=vector(record.pos)
 if not record.matrix then return CFrame.new(pos) end
 assert(#record.matrix==9,"Expected 3x3 rotation")
 for _,n in ipairs(record.matrix) do assert(finite(n),"Invalid rotation") end
 local cf=CFrame.new(pos.X,pos.Y,pos.Z,table.unpack(record.matrix))
 local axes={cf.RightVector,cf.UpVector,-cf.LookVector}
 for i=1,3 do for j=1,3 do assert(math.abs(axes[i]:Dot(axes[j])-(i==j and 1 or 0))<.0001,"Rotation must be orthonormal") end end
 assert(axes[1]:Cross(axes[2]):Dot(axes[3])>.999,"Rotation must be right handed")
 return cf
end
function Generator.build(parent,block,templates,batchSize)
 assert(typeof(parent)=="Instance","Missing generated-block parent")
 assert(type(block)=="table" and type(block.id)=="string" and block.id:match("^[%w_%-]+$"),"Invalid block id")
 assert(type(block.records)=="table","Missing ordered records")
 local blockId=block.id
 templates=templates or {} batchSize=batchSize or 100
 assert(finite(batchSize) and batchSize%1==0 and batchSize>=1 and batchSize<=400,"Batch size must be 1..400")
 local busy=locks[parent] or {} locks[parent]=busy
 assert(not busy[blockId],"This block is already building")
 local old=parent:FindFirstChild(blockId)
 assert(not old or old:GetAttribute("CashCityGeneratedBlock")==true,"Refusing to replace manually built content")
 busy[blockId]=true
 local staged
 local snapshots={}
 local ok,result,stats=pcall(function()
  -- Snapshot/validate all consumed input synchronously before the first yield.
  -- This upfront O(records + unique template descendants) cost is not frame bounded.
  local count,maxIndex=0,0
  for index in pairs(block.records) do
   assert(finite(index) and index%1==0 and index>=1,"Records must be a dense ordered array")
   count=count+1 maxIndex=math.max(maxIndex,index)
  end
  assert(count==maxIndex,"Records must not contain gaps")
  local plan={} local costs={} local maxCost=1
  for _,record in ipairs(block.records) do
   assert(type(record)=="table","Expected record table")
   assert(record.name==nil or type(record.name)=="string","Invalid object name")
   assert(record.collide==nil or type(record.collide)=="boolean","Invalid collision flag")
   local entry={name=record.name,cf=transform(record)}
   if record.template then
    local template=templates[record.template]
    assert(typeof(template)=="Instance" and (template:IsA("Model") or template:IsA("BasePart")) and template.Archivable,"Missing/noncloneable template")
    if not snapshots[template] then
     local descendants=template:GetDescendants()
     assert(#descendants+1<=400,"Split large templates into smaller reusable assemblies")
     for _,descendant in ipairs(descendants) do
      assert(descendant.Archivable,"Template contains non-Archivable descendant: "..descendant.Name)
     end
     local snapshot=template:Clone()
     assert(snapshot,"Template clone failed")
     snapshots[template]=snapshot -- Register immediately so every failure cleans it up.
     costs[template]=#snapshot:GetDescendants()+1
     assert(costs[template]<=400,"Split large templates into smaller reusable assemblies")
    end
    entry.template=snapshots[template]
    maxCost=math.max(maxCost,costs[template])
   else
    assert(record.cls==nil or record.cls=="Part" or record.cls=="WedgePart","Unsupported primitive class")
    entry.cls=record.cls or "Part"
    entry.collide=record.collide~=false
    entry.size=vector(record.size,true)
    local rgb=record.color or {143,141,130} vector(rgb)
    for _,n in ipairs(rgb) do assert(n>=0 and n<=255,"Invalid color") end
    entry.color=Color3.fromRGB(rgb[1],rgb[2],rgb[3])
    entry.material=Enum.Material[record.material or "Concrete"]
    assert(entry.material,"Unknown material")
    assert(record.trans==nil or (finite(record.trans) and record.trans>=0 and record.trans<=1),"Invalid transparency")
    entry.trans=record.trans or 0
   end
   table.insert(plan,entry)
  end
  batchSize=math.min(batchSize,math.max(1,math.floor(400/maxCost)))
  staged=Instance.new("Model") staged.Name="Building_"..blockId
  staged:SetAttribute("CashCityGeneratedBlock",true)
  staged:SetAttribute("BlockId",blockId)
  staged:SetAttribute("GeneratorVersion",1)
  staged.Parent=parent
  local total,batches=0,0
  for first=1,#plan,batchSize do
   local chunk=Instance.new("Folder") chunk.Name="Batch_"..(batches+1)
   local built,err=pcall(function()
    for index=first,math.min(#plan,first+batchSize-1) do
      local entry=plan[index] local obj
     if entry.template then
      obj=entry.template:Clone() obj.Parent=chunk obj:PivotTo(entry.cf)
     else
      obj=Instance.new(entry.cls) obj.Parent=chunk
      obj.Size,obj.CFrame=entry.size,entry.cf
      obj.Color,obj.Material=entry.color,entry.material
      obj.Anchored,obj.CanTouch=true,false
      obj.CanCollide=entry.collide
      obj.Transparency=entry.trans
     end
     obj.Name=entry.name or obj.Name
     total=total+1
    end
   end)
   if not built then chunk:Destroy() error(err) end
   chunk.Parent=staged batches=batches+1
   task.wait() -- One yield per bounded subtree insertion, never one per object.
  end
  -- Commit only after every batch succeeds. All other blocks/landmarks retain identity.
  assert(staged.Parent==parent,"Staged block was moved or destroyed during build")
  if old then assert(old.Parent==parent and old.Name==blockId and old:GetAttribute("CashCityGeneratedBlock")==true,"Previous block ownership changed during build") end
  for _,child in ipairs(parent:GetChildren()) do
   assert(child==old or child==staged or child.Name~=blockId,"Block destination changed during build")
  end
  if old then old:Destroy() end
  staged.Name=blockId
  return staged,{parts=total,batches=batches}
 end)
 for _,snapshot in pairs(snapshots) do snapshot:Destroy() end
 busy[blockId]=nil
 if not ok then if staged then staged:Destroy() end error(result,2) end
 return result,stats
end
return Generator
