-- Existing owned temporary fixture: actual queue/gates/team extraction/results.
if not game:GetService('RunService'):IsStudio() then return end
local Players=game:GetService('Players') local RS=game:GetService('ReplicatedStorage')
local STS=game:GetService('StudioTestService')
local okArgs,args=pcall(function() return STS:GetTestArgs() end)
local runId=script:GetAttribute('RunId')
if not okArgs or type(args)~='table' or args.runId~=runId then return end
local marker=RS:FindFirstChild('SS_MulticlientQA')
if not marker or marker:GetAttribute('RunId')~=runId or marker:GetAttribute('Armed')~=true then return end
local reports={} local finished=false local started=os.clock() local reportConnection
local evidence={controlledPositioning=true,normalReadyAndPromptInputs=true,stages={},progressionVerified=false,extractionVerified=false}
local function finish(status,reason)
 if finished then return end finished=true marker:SetAttribute('ServerReady',false)
 if reportConnection then reportConnection:Disconnect() end
 STS:EndTest({status=status,runId=runId,reason=reason,elapsedSeconds=os.clock()-started,evidence=evidence,
  scope='Six-client full round using controlled positioning and normal server-authorized prompt inputs'})
end
task.delay(240,function() finish('FAIL','240-second watchdog expired') end)
local function waitFor(fn,seconds,label)
 local untilTime=os.clock()+seconds
 repeat if finished then error('Test already ended') end if fn() then return end task.wait(.1) until os.clock()>untilTime
 error(label..' timed out')
end
local function allReports(phase)
 local list=Players:GetPlayers() if #list~=6 then return false end
 for _,p in ipairs(list) do local r=reports[p] if not r or r.phase~=phase then return false end end
 return true
end
local ok,err=xpcall(function()
 reportConnection=marker.Reports.OnServerEvent:Connect(function(player,payload)
  if type(payload)~='table' or payload.runId~=runId then return end
  if payload.phase~='Lobby' and payload.phase~='Vote' and payload.phase~='Match' and payload.phase~='Results' then return end
  reports[player]=payload
 end)
 marker:SetAttribute('ServerReady',true)
 waitFor(function()
  local list=Players:GetPlayers() if #list~=6 or not allReports('Match') then return false end
  local arena=workspace:FindFirstChild('SmallSignalsArena') if not arena or arena:GetAttribute('MatchActive')~=true then return false end
  local counts={Amber=0,Cyan=0} local carriers={Amber=0,Cyan=0}
  local spawns=require(game.ServerScriptService.Arena).spawns
  for _,p in ipairs(list) do
   local r=reports[p] local name=p.Team and p.Team.Name local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
   local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
   if not counts[name] or p.Neutral or p:GetAttribute('RiverfrontLoading')==true or p:GetAttribute('RiverfrontSpawnRecovery')==true
    or p:GetAttribute('Stage')~=0 or p:GetAttribute('Scale')~=1 or not h or h.Health~=100 or h.MaxHealth~=100 or not root
    or (root.Position-spawns[name]).Magnitude>16 or r.practice~=false or r.mode~='Extraction' or r.map~='DetroitRiverfront' then return false end
   if not r.teams or #r.teams.Amber~=3 or #r.teams.Cyan~=3 then return false end
   counts[name]=counts[name]+1 if p:GetAttribute('Carrier')==true then carriers[name]=carriers[name]+1 end
  end
  return counts.Amber==3 and counts.Cyan==3 and carriers.Amber==1 and carriers.Cyan==1
 end,100,'Six-client normal3v3 deployment')
 evidence.players=6 evidence.amber=3 evidence.cyan=3 evidence.clientMatchReports=6
 local list=Players:GetPlayers() table.sort(list,function(a,b)return a.UserId<b.UserId end)
 local amber={} for _,p in ipairs(list) do evidence.stages[tostring(p.UserId)]={0} if p.Team.Name=='Amber' then table.insert(amber,p) end end
 local arena=workspace.SmallSignalsArena local city=arena.DetroitCityRoot
 local function promptFor(p,kind,stage)
  local target
  for _,v in ipairs(arena.RoundInteractions:GetChildren()) do
   if v:GetAttribute('Team')==p.Team.Name and ((kind=='Gate' and v.Name=='Door' and v:GetAttribute('Stage')==stage) or (kind=='Exit' and v.Name=='Extraction')) then target=v break end
  end
  assert(target,'Missing production prompt target')
  waitFor(function()return p:GetAttribute('RiverfrontLoading')~=true end,15,'Destination prefetch')
  local char=p.Character local h=assert(char:FindFirstChildOfClass('Humanoid')) local root=char.HumanoidRootPart
  local ray=RaycastParams.new() ray.FilterType=Enum.RaycastFilterType.Include ray.FilterDescendantsInstances={city} ray.RespectCanCollide=true
  local pos=target.Position+Vector3.new(0,0,-1.8)
  local ground=assert(workspace:Raycast(Vector3.new(pos.X,12,pos.Z),Vector3.new(0,-40,0),ray),'No supported prompt approach')
  char:PivotTo(CFrame.new(pos.X,ground.Position.Y+h.HipHeight+root.Size.Y/2+.05,pos.Z)) root.AssemblyLinearVelocity=Vector3.zero
  task.wait(.4)
  marker:SetAttribute('PromptUser',p.UserId) marker:SetAttribute('PromptKind',kind) marker:SetAttribute('PromptStage',stage or 3)
  marker:SetAttribute('PromptPos',target.Position) marker:SetAttribute('PromptSerial',(marker:GetAttribute('PromptSerial') or 0)+1)
 end
 local function gate(p,stage)
  promptFor(p,'Gate',stage)
  waitFor(function()return p:GetAttribute('Stage')==stage and p:GetAttribute('RiverfrontLoading')~=true end,12,'Gate '..stage..' '..p.Name)
  local expected=({1,.65,.4,.22})[stage+1]
  assert(math.abs(p:GetAttribute('Scale')-expected)<.001 and math.abs(p.Character:GetScale()-expected)<.001,'Wrong physical scale')
  table.insert(evidence.stages[tostring(p.UserId)],stage)
 end
 gate(amber[1],1)
 for i=2,3 do assert(amber[i]:GetAttribute('Stage')==0,'Whole team shrank when one player passed a gate') end
 evidence.individualShrinkingVerified=true
 for _,p in ipairs(list) do for stage=p:GetAttribute('Stage')+1,3 do gate(p,stage) end end
 evidence.progressionVerified=true
 local function extracted(p)
  for _,report in pairs(reports) do
   local rows=report.teams and report.teams.Amber
   for _,row in ipairs(rows or {}) do if row.id==p.UserId and row.extracted then return true end end
  end
  return false
 end
 promptFor(amber[1],'Exit')
 waitFor(function()return extracted(amber[1]) end,8,'First teammate extraction')
 task.wait(1)
 assert(arena:GetAttribute('MatchActive')==true,'Premature victory before entire team finished')
 evidence.waitsForWholeTeam=true
 promptFor(amber[2],'Exit') waitFor(function()return extracted(amber[2]) end,8,'Second teammate extraction')
 promptFor(amber[3],'Exit') waitFor(function()return allReports('Results') end,12,'Replicated Results')
 for _,report in pairs(reports) do assert(string.find(report.message or '','Amber wins',1,true),'Wrong result message') end
 evidence.extractionVerified=true evidence.resultsClients=6
 waitFor(function()
  if not allReports('Lobby') then return false end
  for _,p in ipairs(Players:GetPlayers()) do if not p.Neutral or p:GetAttribute('Stage')~=0 or p:GetAttribute('Scale')~=1 then return false end end
  return true
 end,20,'Return to Lobby')
 evidence.returnedToLobby=true
 finish('PASS','Actual3v3 queue ->4sizes -> whole-team extraction -> Results -> Lobby')
end,debug.traceback)
if not ok then finish('FAIL',tostring(err)) end
