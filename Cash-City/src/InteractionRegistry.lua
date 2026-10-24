-- One authoritative controller per tagged assembly; geometry supplies exact local motion.
local CollectionService=game:GetService("CollectionService")
local ProximityPromptService=game:GetService("ProximityPromptService")
local TweenService=game:GetService("TweenService")
local Rules=require(script.Parent.InteractionRules)
local Registry={}
function Registry.start(root)
 local records={}
 local connections={}
 local function register(model)
  if not model:IsDescendantOf(root) or records[model] then return end
  local moving=model:FindFirstChild("Moving")
  local pivot=model:FindFirstChild("MotionPivot")
  local control=model:FindFirstChild("Control")
  local prompt=control and control:FindFirstChildOfClass("ProximityPrompt")
  local motion=model:GetAttribute("Motion")
  local axis=model:GetAttribute("Axis")
  local travel=model:GetAttribute("Travel")
  if not moving or not moving:IsA("Model") or not pivot or not prompt or not Rules.finite(travel)
   or not (motion=="Hinge" or motion=="Slide") or not (axis=="X" or axis=="Y" or axis=="Z") then
   warn("Invalid interaction assembly",model:GetFullName())
   if prompt then prompt.Enabled=false end
   model:SetAttribute("ValidationFailure","Missing or invalid geometry/motion contract")
   return
  end
  local home=moving:GetPivot()
  local hinge=pivot.CFrame
  local offset=hinge:ToObjectSpace(home)
  local record={moving=moving,home=home,hinge=hinge,offset=offset,prompt=prompt,control=control,busy=false,open=false,position=0,last=-100,model=model}
  record.parts={}
  for _,part in ipairs(moving:GetDescendants()) do
   if part:IsA("BasePart") then record.parts[part]={cf=home:ToObjectSpace(part.CFrame),collide=part.CanCollide} end
  end
  local vector=axis=="X" and Vector3.new(1,0,0) or axis=="Y" and Vector3.new(0,1,0) or Vector3.new(0,0,1)
  record.frame=function(alpha)
   if motion=="Hinge" then return hinge*CFrame.fromAxisAngle(vector,math.rad(travel*alpha))*offset end
   return home*CFrame.new(vector*travel*alpha)
  end
  record.clear=function(from,to)
   local params=OverlapParams.new()
   params.FilterType=Enum.RaycastFilterType.Exclude
   params.FilterDescendantsInstances={model}
   params.RespectCanCollide=true
   for sample=0,12 do
    local cf=record.frame(from+(to-from)*sample/12)
    for part,info in pairs(record.parts) do
     if info.collide then
      local size=Vector3.new(math.max(.05,part.Size.X-.12),math.max(.05,part.Size.Y-.12),math.max(.05,part.Size.Z-.12))
      if #workspace:GetPartBoundsInBox(cf*info.cf,size,params)>0 then return false end
     end
    end
   end
   -- Characters can have noncollidable body parts; explicitly test their roots against swept boxes.
   for _,p in ipairs(game:GetService("Players"):GetPlayers()) do
    local char=p.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
     for sample=0,12 do
      local cf=record.frame(from+(to-from)*sample/12)
      for part,info in pairs(record.parts) do
       if info.collide then
        local localPoint=(cf*info.cf):PointToObjectSpace(hrp.Position)
        local margin=math.max(.4,(p:GetAttribute("Scale") or 1)*1.1)
        if math.abs(localPoint.X)<part.Size.X/2+margin and math.abs(localPoint.Y)<part.Size.Y/2+margin and math.abs(localPoint.Z)<part.Size.Z/2+margin then return false end
       end
      end
     end
    end
   end
   return true
  end
  -- Keep a separate handle per assembly and hold the last safe pose on interrupted transitions.
  model:SetAttribute("InteractionState","Closed")
  records[model]=record
 end
 for _,model in ipairs(CollectionService:GetTagged("SSInteractable")) do register(model) end
 table.insert(connections,CollectionService:GetInstanceAddedSignal("SSInteractable"):Connect(register))
 table.insert(connections,ProximityPromptService.PromptTriggered:Connect(function(prompt,player)
  local model=prompt:FindFirstAncestorWhichIsA("Model")
  local r=model and records[model]
  if not r or r.prompt~=prompt or r.busy then return end
  local char=player.Character
  local hrp=char and char:FindFirstChild("HumanoidRootPart")
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  local range=Rules.range(model:GetAttribute("Range") or 9,player:GetAttribute("Scale") or 1)
  local arena=workspace:FindFirstChild("SmallSignalsArena")
  local inLobby=model:GetAttribute("LobbyInteraction")==true
  local active=inLobby or (arena and arena:GetAttribute("MatchActive")==true and not player.Neutral)
  local allowed=model:GetAttribute("Team")
  local params=RaycastParams.new()
  params.FilterType,params.FilterDescendantsInstances=Enum.RaycastFilterType.Exclude,{char,model}
  local unobstructed=hrp and workspace:Raycast(hrp.Position,r.control.Position-hrp.Position,params)==nil
  local from,to=r.position,r.open and 0 or 1
  local t=workspace:GetServerTimeNow()
  local valid=Rules.request({valid=model.Parent~=nil,active=active,alive=hum and hum.Health>0 and not player:GetAttribute("Downed"),allowed=allowed==nil or (player.Team and player.Team.Name==allowed),distance=hrp and (hrp.Position-r.control.Position).Magnitude or math.huge,range=range or 0,busy=r.busy,elapsed=t-r.last,cooldown=.65,clear=unobstructed})
  if not valid then return end
  if not r.clear(from,to) then model:SetAttribute("LastFailure","Motion blocked - step clear") return end
  r.busy,r.last=true,t
  model:SetAttribute("InteractionState",r.open and "Closing" or "Opening")
  prompt.Enabled=false
  local value=Instance.new("NumberValue") value.Value=from
  local duration=model:GetAttribute("Duration") or .8
  local failed=false
  local watcher=value.Changed:Connect(function(alpha)
   if not model.Parent or failed then return end
   -- Stop if a player walks into the remaining sweep while the animation is running.
   if not r.clear(r.position,to) then failed=true return end
   r.moving:PivotTo(r.frame(alpha))
   r.position=alpha
  end)
  local tween=TweenService:Create(value,TweenInfo.new(duration,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value=to})
  tween:Play()
  task.spawn(function()
   tween.Completed:Wait()
   watcher:Disconnect()
   if model.Parent then
    if failed then
     -- Hold the last safe pose instead of snapping a leaf through someone.
     model:SetAttribute("InteractionState","Blocked")
     model:SetAttribute("LastFailure","Obstruction during movement; retry to recover")
     -- Store the actual partial pose as a temporary endpoint for a controlled retry.
     r.open=r.position>0
    else
     r.moving:PivotTo(r.frame(to)) r.position=to r.open=to==1
     model:SetAttribute("InteractionState",r.open and "Open" or "Closed")
    end
    prompt.ActionText=r.open and "Close" or "Open"
    prompt.Enabled=true
   end
   r.busy=false value:Destroy()
  end)
 end))
 table.insert(connections,root.Destroying:Connect(function()
  for _,c in ipairs(connections) do c:Disconnect() end
  table.clear(records)
 end))
 return records
end
return Registry
