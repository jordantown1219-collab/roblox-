-- TEMPORARY QA fixture only. Installer sets RunId attribute before parenting.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local STS=game:GetService("StudioTestService")
local argsOK,args=pcall(function() return STS:GetTestArgs() end)
local runId=script:GetAttribute("RunId")
if not argsOK or type(args)~="table" or type(runId)~="string" or #runId<12 or args.runId~=runId then return end
local marker=RS:FindFirstChild("SS_MulticlientQA")
if not marker or marker:GetAttribute("RunId")~=runId or marker:GetAttribute("Armed")~=true then return end
local reportsRemote=marker:FindFirstChild("Reports")
if not reportsRemote or not reportsRemote:IsA("RemoteEvent") then
    STS:EndTest({status="FAIL",runId=runId,reason="Missing owned QA Reports RemoteEvent"}) return
end
local finished=false
local reports={}
local reportConnection
local started=os.clock()
local function finish(status,reason,evidence)
    if finished then return end
    finished=true
    marker:SetAttribute("ServerReady",false)
    if reportConnection then reportConnection:Disconnect() end
    STS:EndTest({status=status,runId=runId,reason=reason,elapsedSeconds=os.clock()-started,
        scope="Six-client matchmaking, initial deployment and replicated snapshot only",evidence=evidence,
        progressionVerified=false,extractionVerified=false})
end
-- Independent deadline still runs if the main observer throws or stops progressing.
task.delay(180,function() finish("FAIL","180-second watchdog expired") end)
local ok,err=xpcall(function()
    reportConnection=reportsRemote.OnServerEvent:Connect(function(player,payload)
        if finished or reports[player] or type(payload)~="table" or payload.runId~=runId then return end
        -- This owned diagnostic channel grants no game authority and changes no production state.
        if payload.phase~="Match" or payload.practice~=false or payload.stage~=0 or payload.scale~=1 then return end
        if payload.team~="Amber" and payload.team~="Cyan" then return end
        if type(payload.teams)~="table" then return end
        local seen={} local ids={Amber={},Cyan={}}
        for _,name in ipairs({"Amber","Cyan"}) do
            local rows=payload.teams[name]
            if type(rows)~="table" or #rows~=3 then return end
            for index=1,3 do
                local id=rows[index]
                if type(id)~="number" or seen[id] then return end
                seen[id]=true ids[name][index]=id
            end
        end
        reports[player]={team=payload.team,ids=ids}
    end)
    marker:SetAttribute("ServerReady",true)
    while not finished do
        local players=Players:GetPlayers()
        if #players>6 then finish("FAIL","More than six players; refusing ambiguous session") return end
        local arena=workspace:FindFirstChild("SmallSignalsArena")
        local ready=#players==6 and arena and arena:GetAttribute("MatchActive")==true
        local spawnPositions
        if ready then
            spawnPositions=require(game:GetService("ServerScriptService").Arena).spawns
            if not spawnPositions then ready=false else
                marker:SetAttribute("SpawnAmber",spawnPositions.Amber)
                marker:SetAttribute("SpawnCyan",spawnPositions.Cyan)
            end
        end
        local teams={Amber={},Cyan={}}
        local carriers={Amber=0,Cyan=0}
        local unique={}
        for _,player in ipairs(players) do
            local team=player.Team and player.Team.Name
            local character=player.Character
            local h=character and character:FindFirstChildOfClass("Humanoid")
            local root=character and character:FindFirstChild("HumanoidRootPart")
            local report=reports[player]
            if unique[player.UserId] then finish("FAIL","Duplicate Player UserId") return end
            unique[player.UserId]=true
            if teams[team] then
                teams[team][player.UserId]=true
                if player:GetAttribute("Carrier")==true then carriers[team]=carriers[team]+1 end
            else ready=false end
            if player.Neutral or not report or report.team~=team or player:GetAttribute("Stage")~=0
                or player:GetAttribute("Scale")~=1 or player:GetAttribute("RiverfrontLoading")==true
                or player:GetAttribute("RiverfrontSpawnRecovery")==true or not h or not root
                or root.Anchored or h.Health~=100 or h.MaxHealth~=100 then ready=false end
            local destination=spawnPositions and spawnPositions[team]
            if not destination or not root or (root.Position-destination).Magnitude>16 then ready=false end
            if character and math.abs(character:GetScale()-1)>.001 then ready=false end
        end
        if ready then
            local counts={Amber=0,Cyan=0}
            for name,ids in pairs(teams) do for _ in pairs(ids) do counts[name]=counts[name]+1 end end
            if counts.Amber~=3 or counts.Cyan~=3 then finish("FAIL","Match not three versus three") return end
            if carriers.Amber~=1 or carriers.Cyan~=1 then ready=false end
            for _,player in ipairs(players) do
                for name,ids in pairs(reports[player].ids) do
                    for _,id in ipairs(ids) do if not teams[name][id] then ready=false end end
                end
            end
            if ready then
                finish("PASS","Six clients queued through actual Ready remote and observed normal Match deployment",
                    {players=6,amber=counts.Amber,cyan=counts.Cyan,amberCarriers=carriers.Amber,
                    cyanCarriers=carriers.Cyan,clientMatchReports=6,allStageZero=true,allScaleOne=true,allHealth100=true})
                return
            end
        end
        task.wait(.25)
    end
end,debug.traceback)
if not ok then finish("FAIL",tostring(err)) end

