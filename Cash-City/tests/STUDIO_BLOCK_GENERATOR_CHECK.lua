local Generator=require(game.ServerScriptService:WaitForChild("CityBlockGenerator",2))
local root=Instance.new("Folder") root.Name="BlockGeneratorAcceptance" root.Parent=game.ServerStorage
local function check()
 local landmark=Instance.new("Part") landmark.Name="PreservedLandmark" landmark.Parent=root
 local template=Instance.new("Model")
 local door=Instance.new("Part") door.Name="Door" door:SetAttribute("Motion","Hinge") door.Parent=template
 local prompt=Instance.new("ProximityPrompt") prompt.Parent=door
 local records={}
 for i=1,120 do records[i]={name="Road_"..i,size={4,.2,8},pos={i*5,0,0},color={49,52,55},material="Asphalt",collide=true} end
 local frames=0 local connection=game:GetService("RunService").Heartbeat:Connect(function() frames=frames+1 end)
 local started=os.clock()
 local first,stats=Generator.build(root,{id="Test_A",records=records},{},40)
 local elapsed=os.clock()-started connection:Disconnect()
 assert(stats.parts==120 and stats.batches==3 and frames>=2,"bounded batches must yield")
 local other=Generator.build(root,{id="Test_B",records={{template="Door",pos={0,0,0}}}},{Door=template},40)
 assert(other:FindFirstChild("Door",true):GetAttribute("Motion")=="Hinge","template contract retained")
 assert(other:FindFirstChildOfClass("Folder"):FindFirstChild("Model"):FindFirstChild("Door"):FindFirstChildOfClass("ProximityPrompt"),"prompt retained")
 local replacement=Generator.build(root,{id="Test_A",records=records},{},40)
 assert(first.Parent==nil and replacement~=first,"replace owned block")
 assert(other.Parent==root and landmark.Parent==root,"unrelated objects preserved")
 local positions={}
 for _,p in ipairs(replacement:GetDescendants()) do if p:IsA("BasePart") then positions[p.Name]=p.Position end end
 local again=Generator.build(root,{id="Test_A",records=records},{},40)
 for _,p in ipairs(again:GetDescendants()) do if p:IsA("BasePart") then assert(p.Position==positions[p.Name],"deterministic reconstruction") end end
 local ok=pcall(function() Generator.build(root,{id="Test_A",records={{template="Missing"}}},{},40) end)
 assert(not ok and again.Parent==root,"failed build preserves previous block")
 local userModel=Instance.new("Model") userModel.Name="UserBlock" userModel.Parent=root
 assert(not pcall(function() Generator.build(root,{id="UserBlock",records=records},{},40) end),"must reject manual-name collision")
 assert(userModel.Parent==root,"manual object preserved")
 template:Destroy()
 return {passed=true,parts=stats.parts,batches=stats.batches,yieldFrames=frames,seconds=elapsed}
end
local ok,result=pcall(check) root:Destroy() if not ok then error(result) end return result

