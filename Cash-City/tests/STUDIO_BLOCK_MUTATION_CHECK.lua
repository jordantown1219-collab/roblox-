-- Lead-only native Edit/Server runner. No Workspace/live-map mutation.
local Generator=require(game.ServerScriptService:WaitForChild("CityBlockGenerator",2))
local results={}
local function primitive(name) return {name=name,size={2,2,2},pos={0,0,0},collide=true,trans=0} end
local function test(name,fn)
 local root=Instance.new("Folder") root.Name="CashCityMutationQA" root.Parent=game.ServerStorage
 local ok,err=pcall(fn,root)
 root:Destroy()
 table.insert(results,{name=name,passed=ok,error=not ok and tostring(err) or nil})
end
local function start(root,block,templates)
 local state={done=false}
 task.spawn(function()
  state.ok,state.model,state.stats=pcall(Generator.build,root,block,templates or {},1)
  state.done=true
 end)
 -- task.spawn runs immediately until Generator's first batch yield.
 assert(not state.done and root:FindFirstChild("Building_"..block.id),"Fixture failed to reach first batch yield")
 return state
end
local function finish(state)
 local deadline=os.clock()+10
 repeat task.wait() until state.done or os.clock()>deadline
 assert(state.done,"Build did not finish within 10 seconds")
 assert(state.ok,tostring(state.model))
 return state.model
end
test("record values are snapshotted before yield",function(root)
 local second=primitive("Original")
 local state=start(root,{id="RecordSnapshot",records={primitive("First"),second}})
 second.cls="WedgePart" second.name="Mutated" second.collide=false second.trans=1
 local model=finish(state)
 local part=model:FindFirstChild("Batch_2"):GetChildren()[1]
 assert(part.ClassName=="Part" and part.Name=="Original" and part.CanCollide and part.Transparency==0,
  "Later batch used caller mutation instead of validated primitive snapshot: "..part.ClassName.."/"..part.Name)
end)
test("block id and original lock survive caller mutation",function(root)
 local manual=Instance.new("Model") manual.Name="Manual" manual.Parent=root
 local block={id="StableId",records={primitive(),primitive()}}
 local state=start(root,block)
 block.id="Manual"
 local model=finish(state)
 local retryOK,retryError=pcall(Generator.build,root,{id="StableId",records={primitive()}})
 assert(model.Name=="StableId" and manual.Parent==root and retryOK,
  "Mutable id changed commit name or leaked original lock: committed="..model.Name.." retry="..tostring(retryError))
end)
test("template snapshot cannot grow after budget validation",function(root)
 local template=Instance.new("Model") template.Name="Template" template.Parent=root
 local base=Instance.new("Part") base.Anchored=true base.Parent=template
 local block={id="TemplateSnapshot",records={{template="T",pos={0,0,0}},{template="T",pos={4,0,0}}}}
 local state=start(root,block,{T=template})
 for _=1,401 do local part=Instance.new("Part") part.Anchored=true part.Parent=template end
 local model=finish(state)
 local second=model:FindFirstChild("Batch_2")
 assert(#second:GetDescendants()<=400,"Mutated template bypassed 400-instance insertion bound: "..#second:GetDescendants())
 assert(#second:GetChildren()[1]:GetDescendants()==1,"Template snapshot changed after yield")
end)
local passed=0 for _,result in ipairs(results) do if result.passed then passed=passed+1 end end
return {passed=passed,total=#results,results=results,scope="mutable input regression; temporary ServerStorage fixtures only"}
