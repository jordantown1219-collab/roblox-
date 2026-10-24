-- Call with fresh candidate ModuleScript folder; all geometry is isolated and cleaned.
return function(modules)
 local plan=require(modules.RenaissanceData)
 local factory=require(modules.RenaissanceDetails)
 local root=Instance.new("Folder") root.Name="RenCenQATemporary" root.Parent=game.ServerStorage
 local walls={} local cf={}
 for i,guard in ipairs(plan.guards) do
  local r=guard.record local p=Instance.new("Part") p.Name=r.name p.Size=Vector3.new(table.unpack(r.size))
  p.CFrame=CFrame.new(r.pos[1],r.pos[2],r.pos[3],table.unpack(r.matrix))
  p.Anchored=true p.CanCollide=r.collide p.Color=Color3.fromRGB(table.unpack(r.color)) p.Material=Enum.Material[r.material] p.Transparency=r.trans or 0 p.Parent=root walls[i]=p cf[i]=p.CFrame
 end
 local sentinel=Instance.new("Folder") sentinel.Name="ManualLandmark" sentinel.Parent=root
 local results={}
 local function test(name,fn) local ok,err=pcall(fn) table.insert(results,{name=name,passed=ok,error=not ok and tostring(err) or nil}) end
 test("changed source rejected before build",function()
  walls[1].CFrame=cf[1]*CFrame.Angles(0,.2,0)
  local ok=pcall(factory.build,root)
  walls[1].CFrame=cf[1]
  assert(not ok and not root:FindFirstChild(plan.towers.id))
 end)
 test("manual promenade preserved before tower commit",function()
  local manual=Instance.new("Folder") manual.Name=plan.walk.id manual.Parent=root
  local ok=pcall(factory.build,root)
  assert(not ok and manual.Parent==root and not root:FindFirstChild(plan.towers.id)) manual:Destroy()
 end)
 test("repeat generation preserves sources and counts",function()
  local first=factory.build(root) local old=root:FindFirstChild(plan.towers.id)
  local second=factory.build(root) assert(old.Parent==nil)
  assert(first.towerParts==#plan.towers.records and second.walkParts==#plan.walk.records)
  local parts=0 for _,obj in ipairs(root[plan.towers.id]:GetDescendants()) do if obj:IsA("BasePart") then
   parts=parts+1 assert(obj.Anchored and not obj.CanCollide and not obj.CanTouch and not obj.CanQuery and not obj.CastShadow)
  end end assert(parts==#plan.towers.records)
  local collision=0 for _,obj in ipairs(root[plan.walk.id]:GetDescendants()) do if obj:IsA("BasePart") then
   assert(obj.Anchored and not obj.CanTouch and not obj.CastShadow) if obj.CanCollide then collision=collision+1 end
  end end assert(collision==1)
  for i,wall in ipairs(walls) do assert(wall.Parent==root and wall.CFrame==cf[i] and wall.Size==Vector3.new(table.unpack(plan.guards[i].record.size))) end
  assert(sentinel.Parent==root)
 end)
 test("custom podium finish refused and preserved",function()
  local index for i,guard in ipairs(plan.guards) do if guard.finish then index=i break end end
  assert(index,"Podium finish fixture missing") local wall=walls[index] local color=wall.Color
  wall.Color=Color3.new(1,0,1) local old=root:FindFirstChild(plan.towers.id)
  local ok=pcall(factory.build,root)
  assert(not ok and wall.Color==Color3.new(1,0,1) and root:FindFirstChild(plan.towers.id)==old)
  wall.Color=color
 end)
 test("changed podium during yielded build preserves finish",function()
  local index for i,guard in ipairs(plan.guards) do if guard.finish then index=i break end end
  local wall=walls[index] local guard=plan.guards[index] local size=wall.Size
  wall.Color=Color3.fromRGB(table.unpack(guard.record.color)) wall.Material=Enum.Material[guard.record.material]
  local color,material=wall.Color,wall.Material
  task.defer(function() wall.Size=size+Vector3.new(1,0,0) end)
  local ok=pcall(factory.build,root)
  assert(not ok and wall.Color==color and wall.Material==material,"Changed wall was refinished during generation")
  wall.Size=size
 end)
 root:Destroy()
 local passed=0 for _,r in ipairs(results) do if r.passed then passed=passed+1 end end
 return {passed=passed,total=#results,results=results}
end
