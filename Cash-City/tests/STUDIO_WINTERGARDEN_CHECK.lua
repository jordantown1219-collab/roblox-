-- Lead runs after integration: require(freshHarness)(integratedRoot,decodedPlan).
-- Production geometry is read-only. Blocker probes use isolated cloned doors.
return function(root,plan)
 assert(typeof(root)=="Instance" and type(plan)=="table","Expected root and Wintergarden plan")
 local results={}
 local scales={1,.65,.4,.22}
 local function check(name,fn) local ok,err=pcall(fn) table.insert(results,{name=name,passed=ok,error=not ok and tostring(err) or nil}) end
 local function vec(v) return Vector3.new(table.unpack(v)) end
 local function frame(r) return CFrame.new(r.pos[1],r.pos[2],r.pos[3],table.unpack(r.matrix)) end
 local function nearFrame(a,b)
  return (a.Position-b.Position).Magnitude<.01 and a.RightVector:Dot(b.RightVector)>.99999 and a.UpVector:Dot(b.UpVector)>.99999
 end
 local archive=root:FindFirstChild("WintergardenSourceArchive",true)
 check("recoverable source archive",function()
  assert(archive and archive:GetAttribute("CashCityWintergardenArchive")==true,"Missing marked source archive")
  local indexed={}
  for _,p in ipairs(archive:GetDescendants()) do if p:IsA("BasePart") then
   local index=p:GetAttribute("WG_SourceIndex") assert(index~=nil and not indexed[index],"Missing/duplicate archive source index") indexed[index]=p
   assert(p.Transparency==1 and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p.CastShadow,"Archived part still active")
   for _,key in ipairs({"CanCollide","CanQuery","CanTouch","CastShadow","Transparency"}) do assert(p:GetAttribute("WG_Original"..key)~=nil,"Missing rollback "..key) end
  end end
  for _,replacement in ipairs(assert(plan.replacements,"Missing replacement guards")) do
   local p=assert(indexed[replacement.sourceIndex],"Missing guarded original") local r=replacement.record
   assert(p.Name==r.name and (p.Size-vec(r.size)).Magnitude<.01 and nearFrame(p.CFrame,frame(r)),"Archived original shape changed")
   assert(p.Material==Enum.Material[r.material],"Archived original material changed")
   if r.color then local c=Color3.fromRGB(table.unpack(r.color)) assert(math.abs(p.Color.R-c.R)<.001 and math.abs(p.Color.G-c.G)<.001 and math.abs(p.Color.B-c.B)<.001,"Archived original color changed") end
  end
 end)
 local doors={}
 for _,obj in ipairs(root:GetDescendants()) do if obj:IsA("Model") and obj.Name:match("^WintergardenDoor_") then table.insert(doors,obj) end end
 local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={root} ray.RespectCanCollide=true
 local overlap=OverlapParams.new() overlap.FilterType=Enum.RaycastFilterType.Exclude
 local excluded={archive} for _,d in ipairs(doors) do table.insert(excluded,d) end
 -- Other city geometry remains in occupancy checks; only closed moving doors
 -- are excluded so route tests do not pretend they are already open.
 overlap.FilterDescendantsInstances=excluded overlap.RespectCanCollide=true
 check("declared route samples exist",function() assert(type(plan.routeSamples)=="table" and #plan.routeSamples>=3,"No source-derived navigation route") end)
 for _,scale in ipairs(scales) do
  check("route floor/headroom physical probe scale "..scale,function()
   for _,sample in ipairs(plan.routeSamples or {}) do
    local p=vec(sample.posXYZ or sample.pos) local floor=sample.floorY or p.Y
    local hit=workspace:Raycast(Vector3.new(p.X,floor+2,p.Z),Vector3.new(0,-4,0),ray)
    assert(hit and math.abs(hit.Position.Y-floor)<.08 and hit.Normal.Y>.99,"Missing/tilted route floor")
    local size=Vector3.new(2*scale,5*scale,2*scale)
    local center=Vector3.new(p.X,floor+size.Y/2+.08,p.Z)
    local blockers=workspace:GetPartBoundsInBox(CFrame.new(center),size,overlap)
    assert(#blockers==0,"Route occupancy obstruction: "..(blockers[1] and blockers[1]:GetFullName() or ""))
   end
  end)
 end
 check("door assembly contract and approach reach",function()
  assert(#doors>0,"No functional Wintergarden doors")
  for _,door in ipairs(doors) do
   assert(game:GetService("CollectionService"):HasTag(door,"SSInteractable"),"Door lacks registry tag")
   assert(door:GetAttribute("LobbyInteraction")~=true,"Production door bypasses match permissions")
   local control=assert(door:FindFirstChild("Control")) assert(control:FindFirstChildOfClass("ProximityPrompt"),"Door prompt missing")
   assert(door:FindFirstChild("Moving") and door:FindFirstChild("MotionPivot"),"Door geometry contract missing")
   for _,obj in ipairs(door:GetDescendants()) do assert(not obj:IsA("LuaSourceContainer"),"Per-door script") end
  end
 end)
 check("roof above declared navigation route",function()
  local metadata=assert(plan.metadata)
  for _,sample in ipairs(plan.routeSamples) do
   local p=vec(sample.pos)
   local hit=workspace:Raycast(Vector3.new(p.X,metadata.profilePeakStuds+3,p.Z),Vector3.new(0,-metadata.profilePeakStuds-5,0),ray)
   assert(hit and hit.Instance.Name=="Wintergarden_CurvedGlassRoof","Missing curved roof above route")
   assert(hit.Position.Y>=metadata.profileSpringlineStuds-.3 and hit.Position.Y<=metadata.profilePeakStuds+.3,"Roof outside declared profile")
  end
 end)
 for index,anchor in ipairs(plan.doorAnchors or {}) do
  check("declared door approaches "..index,function()
   for _,point in ipairs(anchor.approachPoints) do
    local p=vec(point)
    for _,scale in ipairs(scales) do
     local size=Vector3.new(2,5,2)*scale
     local blockers=workspace:GetPartBoundsInBox(CFrame.new(p+Vector3.new(0,size.Y/2+.08,0)),size,overlap)
     assert(#blockers==0,"Solid blocker at declared approach scale "..scale)
     local hit=workspace:Raycast(p+Vector3.new(0,2,0),Vector3.new(0,-4,0),ray)
     assert(hit and math.abs(hit.Position.Y-p.Y)<.08 and hit.Normal.Y>.99,"Approach has no level support")
    end
   end
  end)
 end
 check("low control within scaled near-approach range",function()
  for _,door in ipairs(doors) do
   local control=door.Control
   local anchor,nearest
   for _,a in ipairs(plan.doorAnchors) do local distance=(door:GetPivot().Position-vec(a.pos)).Magnitude if not nearest or distance<nearest then anchor,nearest=a,distance end end
   assert(anchor,"No matching door anchor")
   local floor=anchor.pos[2]-anchor.height/2
   local normal=vec(anchor.outwardNormal)
   for _,scale in ipairs(scales) do for _,sign in ipairs({-1,1}) do
    local near=Vector3.new(control.Position.X,floor+2.5*scale,control.Position.Z)+normal*sign*1.25
    local range=math.max(3,(door:GetAttribute("Range") or 9)*scale)
    assert((near-control.Position).Magnitude<=range,"Low-scale control unreachable from nearby approach")
   end end
  end
 end)
 check("isolated door physical blockers all scales",function()
  local fixture=Instance.new("Folder") fixture.Name="WintergardenDoorQATemporary" fixture.Parent=workspace
  local ok,err=pcall(function()
   -- Fresh module copies avoid cache and give root cleanup sole ownership of listeners.
   local server=game:GetService("ServerScriptService")
   local registryModule=server.InteractionRegistry:Clone() registryModule.Parent=fixture
   local rulesModule=server.InteractionRules:Clone() rulesModule.Parent=fixture
   local copies={}
   for i,door in ipairs(doors) do
    local copy=door:Clone() copy:PivotTo(CFrame.new(24000+i*100,20000,24000)) copy.Parent=fixture table.insert(copies,copy)
   end
   local registry=require(registryModule).start(fixture)
   for _,door in ipairs(copies) do
    local record=assert(registry[door],"Clone not registered")
    assert(record.clear(0,1) and record.clear(1,0),"Isolated sweep unexpectedly blocked")
    local leaf,info
    for part,data in pairs(record.parts) do if data.collide then leaf,info=part,data break end end
    assert(leaf,"No colliding moving leaf")
    for _,scale in ipairs(scales) do
     local blocker=Instance.new("Part") blocker.Name="SolidScaleProbe" blocker.Anchored=true blocker.CanCollide=true blocker.CanTouch=false
     blocker.Size=Vector3.new(2,5,2)*scale blocker.CFrame=record.frame(.5)*info.cf blocker.Parent=fixture
     assert(not record.clear(0,1) and not record.clear(1,0),"Solid blocker ignored at scale "..scale)
     blocker:Destroy()
     assert(record.clear(0,1) and record.clear(1,0),"Sweep did not recover")
    end
   end
  end)
  fixture:Destroy()
  assert(ok,err)
 end)
 local passed=0 for _,r in ipairs(results) do if r.passed then passed=passed+1 end end
 return {passed=passed,total=#results,results=results,scope="static physical probes only; closed doors excluded from navigation; not real avatar/input/multiplayer acceptance"}
end
