-- Lead requires this fresh harness and calls returned function(factory, plan).
-- factory is a freshly required CivicFacades candidate, plan is decoded candidate data.
return function(factory,plan)
 local storage=game:GetService("ServerStorage")
 local results={}
 local function copy(v) if type(v)~="table" then return v end local out={} for k,x in pairs(v) do out[k]=copy(x) end return out end
 local function frame(r) return CFrame.new(r.pos[1],r.pos[2],r.pos[3],table.unpack(r.matrix)) end
 local function snapshot(p) return {cf=p.CFrame,size=p.Size,color=p.Color,material=p.Material,anchored=p.Anchored,collide=p.CanCollide,touch=p.CanTouch,query=p.CanQuery} end
 local function unchanged(p,s,finish)
  assert(p.CFrame==s.cf and p.Size==s.size and p.Anchored==s.anchored and p.CanCollide==s.collide and p.CanTouch==s.touch and p.CanQuery==s.query,"Source geometry/physics changed")
  if not finish then assert(p.Color==s.color and p.Material==s.material,"Unexpected finish change") end
 end
 local function test(name,fn)
  local root=Instance.new("Folder") root.Name="CivicFacadeQATemporary" root.Parent=storage
  local walls={}
  for i,face in ipairs(plan.faces) do
   local p=Instance.new("Part") p.Name=face.name p.Size=Vector3.new(table.unpack(face.size)) p.CFrame=frame(face)
   p.Anchored=true p.CanCollide=true p.CanTouch=false p.Color=Color3.fromRGB(80,90,100) p.Material=Enum.Material.Concrete p.Parent=root walls[i]=p
  end
  local sentinel=Instance.new("Part") sentinel.Name="ManualLandmarkSentinel" sentinel.Anchored=true sentinel.CFrame=CFrame.new(1,2,3) sentinel.Parent=root
  local snap=snapshot(sentinel)
  local ok,err=pcall(fn,root,walls)
  local preserved,preserveErr=pcall(function() assert(sentinel.Parent==root,"Manual sentinel lost") unchanged(sentinel,snap,false) end)
  root:Destroy()
  table.insert(results,{name=name,passed=ok and preserved,error=not ok and tostring(err) or (not preserved and tostring(preserveErr) or nil)})
 end
 local function oldDetails(root)
  local folder=Instance.new("Folder") folder.Name="CivicFacadeDetails" folder:SetAttribute("CashCityReferenceDecor",true) folder.Parent=root
  local kept=Instance.new("Part") kept.Name="PreviousAcceptedAccent" kept.Parent=folder
  return folder,kept
 end
 local function rejectPreserve(root,old,kept,p)
  local ok=pcall(factory.build,root,p or plan)
  assert(not ok,"Changed/malformed source plan was accepted")
  assert(old.Parent==root and kept.Parent==old,"Previous accepted content lost")
  local count=0 for _,obj in ipairs(root:GetChildren()) do if obj.Name=="CivicFacadeDetails" then count=count+1 end end
  assert(count==1,"Staging folder leaked")
 end
 test("repeat build preserves walls without accumulation",function(root,walls)
  local snapshots={} for i,w in ipairs(walls) do snapshots[i]=snapshot(w) end
  local first,count=factory.build(root,plan) assert(count==#plan.details)
  local second,n=factory.build(root,plan) assert(n==#plan.details and first.Parent==nil and second.Parent==root)
  local folders,parts=0,0
  for _,obj in ipairs(root:GetChildren()) do if obj.Name=="CivicFacadeDetails" then folders=folders+1 end end
  for _,obj in ipairs(second:GetDescendants()) do
   assert(not obj:IsA("LuaSourceContainer"),"Decor script added")
   if obj:IsA("BasePart") then
    parts=parts+1 assert(obj.Anchored and not obj.CanCollide and not obj.CanTouch and not obj.CanQuery and not obj.CastShadow,"Decor physics flags")
    assert(obj:GetAttribute("SourceOSM")~=nil,"Missing source provenance")
   end
  end
  assert(folders==1 and parts==#plan.details,"Decor accumulation/count mismatch")
  for i,w in ipairs(walls) do unchanged(w,snapshots[i],true) assert(w.Parent==root)
   assert(w.Color==Color3.fromRGB(table.unpack(plan.faces[i].color)) and w.Material==Enum.Material[plan.faces[i].material],"Wrong intended finish")
  end
 end)
 test("manual named folder refused",function(root)
  local old=Instance.new("Folder") old.Name="CivicFacadeDetails" old.Parent=root
  local kept=Instance.new("Part") kept.Parent=old rejectPreserve(root,old,kept)
 end)
 for _,kind in ipairs({"missing","position","size","orientation"}) do
  test("changed source "..kind.." rejected",function(root,walls)
   local old,kept=oldDetails(root)
   if kind=="missing" then walls[1]:Destroy()
   elseif kind=="position" then walls[1].CFrame=walls[1].CFrame+Vector3.new(2,0,0)
   elseif kind=="size" then walls[1].Size=walls[1].Size+Vector3.new(1,0,0)
   else walls[1].CFrame=walls[1].CFrame*CFrame.Angles(0,.2,0) end
   rejectPreserve(root,old,kept)
  end)
 end
 test("generated preview manifest adopted",function(root)
  local old=Instance.new("Folder") old.Name="CivicFacadeDetails" old.Parent=root
  local marker=Instance.new("StringValue") marker.Name="CashCityReferenceDecorManifest" marker.Value=plan.reference marker.Parent=old
  local new=factory.build(root,plan) assert(old.Parent==nil and new.Parent==root and new:GetAttribute("CashCityReferenceDecor")==true)
 end)
 test("foreign preview manifest refused",function(root)
  local old=Instance.new("Folder") old.Name="CivicFacadeDetails" old.Parent=root
  local kept=Instance.new("StringValue") kept.Name="CashCityReferenceDecorManifest" kept.Value="Foreign/manual source" kept.Parent=old
  rejectPreserve(root,old,kept)
 end)
 test("failed staged decor preserves prior details",function(root)
  local old,kept=oldDetails(root) local bad=copy(plan)
  bad.details[2].material="NotARobloxMaterial"
  rejectPreserve(root,old,kept,bad)
 end)
 test("failed body finish is transactional",function(root,walls)
  local old,kept=oldDetails(root) local bad=copy(plan)
  local before={} for i,w in ipairs(walls) do before[i]=snapshot(w) end
  bad.faces[2].material="NotARobloxMaterial"
  rejectPreserve(root,old,kept,bad)
  for i,w in ipairs(walls) do unchanged(w,before[i],false) end
 end)
 local passed=0 for _,r in ipairs(results) do if r.passed then passed=passed+1 end end
 return {passed=passed,total=#results,results=results,scope="isolated native geometry/rollback checks; no live map mutations, visual or FPS acceptance"}
end
