-- Run once in owned candidate Edit context AFTER temporary fixture installation.
-- Does not install fixtures. Review machine memory before executing this launch.
assert(game:GetService("RunService"):IsStudio(),"Studio only")
local RS=game:GetService("ReplicatedStorage")
local marker=RS:FindFirstChild("SS_MulticlientQA")
assert(marker and marker:GetAttribute("Armed")==true,"Missing armed owned QA marker")
local runId=marker:GetAttribute("RunId")
assert(type(runId)=="string" and #runId>=12,"Missing unique RunId")
assert(marker:GetAttribute("LaunchState")=="Prepared","Run already launched or marker not prepared")
local server=game:GetService("ServerScriptService"):FindFirstChild("SS_MulticlientQA_Server")
local client=game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("SS_MulticlientQA_Client")
assert(server and server:IsA("Script") and server:GetAttribute("RunId")==runId and not server.Disabled,"Server fixture not armed")
assert(client and client:IsA("LocalScript") and client:GetAttribute("RunId")==runId and not client.Disabled,"Client fixture not armed")
assert(marker:FindFirstChild("Reports") and marker.Reports:IsA("RemoteEvent"),"Missing owned QA channel")
local STS=game:GetService("StudioTestService")
assert(STS.EditModeActive==true,"A test is already running")
marker:SetAttribute("LaunchState","Launching")
marker:SetAttribute("ResultJSON",nil)
task.spawn(function()
    local ok,result=pcall(function()
        local initial=marker:GetAttribute('InitialClients') or 6
        assert(initial>=1 and initial<=6,'Invalid staged launch count')
        return STS:ExecuteMultiplayerTestAsync(initial,{runId=runId,expectedPlayers=6,timeoutSeconds=240})
    end)
    if marker.Parent and marker:GetAttribute("RunId")==runId then
        local valid=ok and type(result)=="table" and result.runId==runId and (result.status=="PASS" or result.status=="FAIL")
        if not valid then result={status="FAIL",runId=runId,reason=ok and "Test ended without owned result" or tostring(result)} end
        marker:SetAttribute("ResultJSON",game:GetService("HttpService"):JSONEncode(result))
        marker:SetAttribute("LaunchState","Completed")
        marker:SetAttribute("Armed",false)
    end
end)
return {status="LAUNCH_QUEUED",runId=runId,note="Not a result; inspect owned Edit marker ResultJSON after return to Edit"}
