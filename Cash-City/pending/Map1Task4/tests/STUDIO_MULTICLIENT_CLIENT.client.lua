-- Existing temporary six-client fixture, extended to the complete extraction round.
if not game:GetService('RunService'):IsStudio() then return end
local RS=game:GetService('ReplicatedStorage') local player=game.Players.LocalPlayer
local runId=script:GetAttribute('RunId')
if type(runId)~='string' or #runId<12 then return end
local marker=RS:WaitForChild('SS_MulticlientQA',10)
if not marker or marker:GetAttribute('RunId')~=runId or marker:GetAttribute('Armed')~=true then return end
local shared=RS:WaitForChild('SmallSignals',10)
local snapshot local sentReady=false local serial=0 local lastReport=0
local connection=shared.State.OnClientEvent:Connect(function(data) snapshot=data end)
local deadline=os.clock()+235
while os.clock()<deadline and marker.Parent and marker:GetAttribute('Armed')==true do
 if marker:GetAttribute('ServerReady')==true and snapshot then
  if snapshot.phase=='Lobby' and not sentReady then sentReady=true shared.Action:FireServer('Ready',3) end
  if os.clock()-lastReport>=.25 then
   lastReport=os.clock()
   marker.Reports:FireServer({runId=runId,phase=snapshot.phase,practice=snapshot.practice,
    mode=snapshot.mode,map=snapshot.map,ready=snapshot.ready,queueCount=snapshot.queueCount,
    stage=player:GetAttribute('Stage'),scale=player:GetAttribute('Scale'),team=player.Team and player.Team.Name,
    teams=snapshot.teams,message=snapshot.message})
  end
  local requested=marker:GetAttribute('PromptSerial') or 0
  if requested~=serial and marker:GetAttribute('PromptUser')==player.UserId and snapshot.phase=='Match'
   and player:GetAttribute('RiverfrontLoading')~=true then
   local pos=marker:GetAttribute('PromptPos')
   if typeof(pos)=='Vector3' then player:RequestStreamAroundAsync(pos,3) end
   local arena=workspace:FindFirstChild('SmallSignalsArena')
   local interactions=arena and arena:FindFirstChild('RoundInteractions')
   local target
   for _,v in ipairs(interactions and interactions:GetChildren() or {}) do
    if v:GetAttribute('Team')==(player.Team and player.Team.Name) then
     if marker:GetAttribute('PromptKind')=='Gate' and v.Name=='Door' and v:GetAttribute('Stage')==marker:GetAttribute('PromptStage') then target=v end
     if marker:GetAttribute('PromptKind')=='Exit' and v.Name=='Extraction' then target=v end
    end
   end
   local prompt=target and target:FindFirstChildWhichIsA('ProximityPrompt',true)
   if prompt and prompt.Enabled then
    serial=requested
    prompt:InputHoldBegin() task.wait(prompt.HoldDuration+.15) prompt:InputHoldEnd()
   end
  end
 end
 task.wait(.1)
end
connection:Disconnect()
