-- TEMPORARY QA fixture only. Never autoqueues without the explicit owned run marker.
if not game:GetService("RunService"):IsStudio() then return end
local RS=game:GetService("ReplicatedStorage")
local player=game:GetService("Players").LocalPlayer
local runId=script:GetAttribute("RunId")
if type(runId)~="string" or #runId<12 then return end
local deadline=os.clock()+170
local marker=RS:WaitForChild("SS_MulticlientQA",10)
if not marker or marker:GetAttribute("RunId")~=runId or marker:GetAttribute("Armed")~=true then return end
local shared=RS:WaitForChild("SmallSignals",10)
local state=shared and shared:WaitForChild("State",10)
local action=shared and shared:WaitForChild("Action",10)
local reports=marker:FindFirstChild("Reports")
if not state or not action or not reports or not reports:IsA("RemoteEvent") then return end
local snapshot
local sentReady=false
local connection=state.OnClientEvent:Connect(function(data)
    if type(data)=="table" then snapshot=data end
end)
while os.clock()<deadline and marker.Parent and marker:GetAttribute("RunId")==runId and marker:GetAttribute("Armed")==true do
    if marker:GetAttribute("ServerReady")==true and game:IsLoaded() and snapshot then
        if snapshot.phase=="Lobby" and not sentReady then
            sentReady=true
            action:FireServer("Ready",3)
        end
        local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local destination=player.Team and marker:GetAttribute("Spawn"..player.Team.Name)
        if sentReady and snapshot.phase=="Match" and snapshot.practice==false and player.Team and not player.Neutral
            and player:GetAttribute("Stage")==0 and player:GetAttribute("Scale")==1
            and player:GetAttribute("RiverfrontLoading")~=true and h and h.Health==100 and h.MaxHealth==100
            and root and typeof(destination)=="Vector3" and (root.Position-destination).Magnitude<=16 then
            local teams={Amber={},Cyan={}}
            local complete=true
            for _,name in ipairs({"Amber","Cyan"}) do
                local rows=snapshot.teams and snapshot.teams[name]
                if type(rows)~="table" or #rows~=3 then complete=false break end
                for index=1,3 do teams[name][index]=rows[index].id end
            end
            if complete then
                reports:FireServer({runId=runId,phase=snapshot.phase,practice=snapshot.practice,
                    stage=player:GetAttribute("Stage"),scale=player:GetAttribute("Scale"),team=player.Team.Name,teams=teams})
                break
            end
        end
    end
    task.wait(.25)
end
connection:Disconnect()

