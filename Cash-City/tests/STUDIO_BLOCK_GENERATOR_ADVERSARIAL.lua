-- Run explicitly in Edit/Server by the Lead. Uses only its own temporary storage folder.
local Generator=require(game.ServerScriptService:WaitForChild("CityBlockGenerator",2))
local root=Instance.new("Folder") root.Name="CashCityAdversarialQA" root.Parent=game.ServerStorage
local results={}
local function primitive() return {size={2,2,2},pos={0,0,0}} end
local function test(name,fn)
 local ok,err=pcall(fn)
 table.insert(results,{name=name,passed=ok,error=not ok and tostring(err) or nil})
end
local function reject(id,records,templates)
 local before=Generator.build(root,{id=id,records={primitive()}})
 local ok=pcall(function() Generator.build(root,{id=id,records=records},templates) end)
 assert(not ok,"Malformed plan was accepted")
 assert(before.Parent==root and root:FindFirstChild(id)==before,"Previous block lost")
 assert(not root:FindFirstChild("Building_"..id),"Staging leaked")
 Generator.build(root,{id=id,records={primitive()}}) -- Failed build must release lock.
end
test("manual ownership collision",function()
 local manual=Instance.new("Model") manual.Name="Manual" manual.Parent=root
 assert(not pcall(function() Generator.build(root,{id="Manual",records={primitive()}}) end))
 assert(manual.Parent==root)
end)
test("invalid primitive preserves block",function() local r=primitive() r.size={0,1,1} reject("BadSize",{r}) end)
test("nonfinite position rejected",function() local r=primitive() r.pos={0/0,0,0} reject("BadPosition",{r}) end)
test("reflection rejected",function() local r=primitive() r.matrix={-1,0,0,0,1,0,0,0,1} reject("Reflection",{r}) end)
test("missing template rejected",function() reject("MissingTemplate",{{template="Missing",pos={0,0,0}}}) end)
test("sparse records rejected",function() reject("Sparse",{[1]=primitive(),[3]=primitive()}) end)
test("dictionary records rejected",function() reject("Dictionary",{road=primitive()}) end)
test("template subtree bound",function()
 local template=Instance.new("Model") template.Parent=root
 for i=1,400 do local p=Instance.new("Part") p.Parent=template end
 reject("Oversize",{{template="Huge",pos={0,0,0}}},{Huge=template})
 template:Destroy()
end)
test("same block lock and independent block",function()
 local done,success=false,false
 task.spawn(function()
  success=pcall(function() Generator.build(root,{id="Locked",records={primitive(),primitive()}},{},1) end)
  done=true
 end)
 assert(root:FindFirstChild("Building_Locked"),"Build did not reach yielded stage")
 assert(not pcall(function() Generator.build(root,{id="Locked",records={primitive()}}) end),"Concurrent same-block build accepted")
 local independent=Generator.build(root,{id="Independent",records={primitive()}})
 local deadline=os.clock()+10 repeat task.wait() until done or os.clock()>deadline
 assert(done and success and independent.Parent==root)
end)
test("failure after first batch preserves original",function()
 local old=Generator.build(root,{id="LateFailure",records={primitive()}})
 local bad=primitive() bad.name={} -- Invalid Instance.Name fails during construction, after validation.
 local ok=pcall(function() Generator.build(root,{id="LateFailure",records={primitive(),bad}},{},1) end)
 assert(not ok and old.Parent==root and root:FindFirstChild("LateFailure")==old)
 assert(not root:FindFirstChild("Building_LateFailure"),"Failed staged content leaked")
 Generator.build(root,{id="LateFailure",records={primitive()}})
end)
test("large block yields and respects subtree budget",function()
 local template=Instance.new("Model") template.Parent=root
 for i=1,99 do local p=Instance.new("Part") p.Anchored=true p.Parent=template end
 local records={} for i=1,12 do records[i]={template="Assembly",pos={i*4,0,0}} end
 local frames=0 local conn=game:GetService("RunService").Heartbeat:Connect(function() frames=frames+1 end)
 local ok,model,stats=pcall(Generator.build,root,{id="Large",records=records},{Assembly=template},400)
 conn:Disconnect() template:Destroy()
 assert(ok,tostring(model)) assert(stats.parts==12 and stats.batches==3 and frames>=2)
 for _,batch in ipairs(model:GetChildren()) do assert(#batch:GetDescendants()<=400,"Subtree exceeds budget") end
end)
root:Destroy()
local passed=0 for _,result in ipairs(results) do if result.passed then passed=passed+1 end end
return {passed=passed,total=#results,results=results,scope="temporary native Instances; no gameplay or FPS acceptance"}
