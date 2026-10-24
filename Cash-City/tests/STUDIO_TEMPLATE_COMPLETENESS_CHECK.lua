-- Lead-only native Edit/Server runner. Temporary ServerStorage fixtures; no Workspace changes.
local Generator=require(game.ServerScriptService:WaitForChild("CityBlockGenerator",2))
local results={}
local function primitive() return {size={2,2,2},pos={0,0,0}} end
local function test(name,fn)
 local root=Instance.new("Folder") root.Name="CashCityTemplateCompletenessQA" root.Parent=game.ServerStorage
 local ok,err=pcall(fn,root)
 root:Destroy()
 table.insert(results,{name=name,passed=ok,error=not ok and tostring(err) or nil})
end
local function omission(root,kind)
 local old=Generator.build(root,{id="Preserved",records={primitive()}})
 local template=Instance.new(kind=="attachment" and "Part" or "Model") template.Parent=root
 local excluded
 if kind=="folder" then
  excluded=Instance.new("Folder") excluded.Parent=template
  local child=Instance.new("Part") child.Parent=excluded
 elseif kind=="attachment" then
  excluded=Instance.new("Attachment") excluded.Parent=template
 else
  excluded=Instance.new("Part") excluded.Parent=template
 end
 excluded.Name="RequiredButNotArchivable" excluded.Archivable=false
 local ok,err=pcall(Generator.build,root,{id="Preserved",records={{template="T",pos={0,0,0}}}},{T=template},1)
 assert(not ok,"Template accepted despite non-Archivable descendant; Clone silently omits required content")
 assert(tostring(err):find("non%-Archivable descendant"),"Unexpected rejection: "..tostring(err))
 assert(old.Parent==root and root:FindFirstChild("Preserved")==old,"Previous block changed after rejected template")
 assert(not root:FindFirstChild("Building_Preserved"),"Rejected staging leaked")
 assert(excluded.Parent~=nil and excluded.Archivable==false,"Caller template was modified")
 excluded.Archivable=true
 local retry=Generator.build(root,{id="Preserved",records={{template="T",pos={0,0,0}}}},{T=template},1)
 assert(retry.Parent==root and retry:FindFirstChild("RequiredButNotArchivable",true),"Retry failed or omitted restored descendant")
end
for _,kind in ipairs({"part","folder","attachment"}) do
 test("reject non-Archivable "..kind.." descendant and release lock",function(root) omission(root,kind) end)
end
local function ownership(root,kind)
 local old=Generator.build(root,{id="Owned",records={primitive()}})
 local holding=Instance.new("Folder") holding.Name="Holding" holding.Parent=root
 local state={done=false}
 task.spawn(function()
  state.ok,state.value=pcall(Generator.build,root,{id="Owned",records={primitive(),primitive()}},{},1)
  state.done=true
 end)
 assert(not state.done and root:FindFirstChild("Building_Owned"),"Fixture did not pause at first batch yield")
 local manual
 if kind=="attribute" then old:SetAttribute("CashCityGeneratedBlock",false)
 elseif kind=="name" then old.Name="ExternalRename"
 elseif kind=="parent" then old.Parent=holding
 else manual=Instance.new("Model") manual.Name="Owned" manual.Parent=root end
 local deadline=os.clock()+10
 repeat task.wait() until state.done or os.clock()>deadline
 assert(state.done,"Concurrent build timed out")
 assert(not state.ok,"Build committed after external ownership mutation")
 assert(tostring(state.value):find("changed during build"),"Unexpected failure: "..tostring(state.value))
 assert(not root:FindFirstChild("Building_Owned"),"Rejected staging leaked")
 assert(old.Parent~=nil,"External writer's old block was destroyed")
 if manual then assert(manual.Parent==root,"External manual block destroyed") manual:Destroy() end
 old.Parent=root old.Name="Owned" old:SetAttribute("CashCityGeneratedBlock",true)
 local retry=Generator.build(root,{id="Owned",records={primitive()}})
 assert(retry.Parent==root,"Commit rejection leaked block lock")
end
for _,kind in ipairs({"attribute","name","parent","sibling"}) do
 test("commit rejects external "..kind.." mutation",function(root) ownership(root,kind) end)
end
local passed=0 for _,result in ipairs(results) do if result.passed then passed=passed+1 end end
return {passed=passed,total=#results,results=results,scope="template completeness and commit ownership; native temporary fixtures only"}
