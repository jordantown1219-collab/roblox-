-- Execute this entire chunk in Studio's SERVER datamodel (Edit or Play).
-- Reads actual ModuleScripts; creates no Instances and never touches match state.
-- Local roster mutations exercise pure predicates, not server callbacks or replication.
local shared=game:GetService("ReplicatedStorage"):FindFirstChild("SmallSignals")
assert(shared,"Missing ReplicatedStorage.SmallSignals; open the candidate place")
local rulesModule=shared:FindFirstChild("Rules")
local configModule=shared:FindFirstChild("Config")
assert(rulesModule and rulesModule:IsA("ModuleScript"),"Missing actual Rules ModuleScript")
assert(configModule and configModule:IsA("ModuleScript"),"Missing actual Config ModuleScript")
local Rules=require(rulesModule)
local C=require(configModule)
assert(type(C.Stages)=="number" and C.Stages>=1 and C.Stages%1==0,"Invalid stage configuration")
assert(type(C.TeamSizes)=="table" and #C.TeamSizes>0,"Missing configured team sizes")

local checks=0
local function check(condition,label)
    assert(condition,"TEAM RULES FAIL: "..label)
    checks=checks+1
end
local function finished()
    return {required=true,connected=true,stage=C.Stages,extracted=true,downed=false}
end
local function rosterOf(size)
    local roster={}
    for i=1,size do roster[i]=finished() end
    return roster
end

check(not Rules.allFinished({},C.Stages),"empty team cannot win")
check(not Rules.allFinished({spectator={required=false}},C.Stages),"no required members cannot win")
for _,size in ipairs(C.TeamSizes) do
    assert(type(size)=="number" and size>=2 and size<=16 and size%1==0,"Unsupported harness team size")
    local roster=rosterOf(size)
    check(Rules.allFinished(roster,C.Stages),"all "..size.." required members finished")
    for memberIndex=1,size do
        -- Each required member must independently satisfy every completion condition.
        for stage=0,C.Stages-1 do
            roster[memberIndex].stage=stage
            check(not Rules.allFinished(roster,C.Stages),"unfinished member "..memberIndex.." stage "..stage)
        end
        roster[memberIndex]=finished()
        roster[memberIndex].extracted=false
        check(not Rules.allFinished(roster,C.Stages),"finished gates but not extracted")
        roster[memberIndex]=finished()
        roster[memberIndex].downed=true
        check(not Rules.allFinished(roster,C.Stages),"downed required member")
        roster[memberIndex]=finished()
        roster[memberIndex].connected=false
        check(not Rules.allFinished(roster,C.Stages),"disconnected required member")
        roster[memberIndex]=finished()
    end
    -- A disconnected reservation projected exactly as checkWin projects it.
    roster.reservation={required=true,connected=false}
    check(not Rules.allFinished(roster,C.Stages),"in-grace reservation blocks "..size.."-member team")
    roster.reservation=nil -- Server removes expired reservations; no timer is exercised here.
    check(Rules.allFinished(roster,C.Stages),"expired reservation omitted from roster")
    roster.spectator={required=false,connected=false,stage=0,extracted=false,downed=true}
    check(Rules.allFinished(roster,C.Stages),"nonrequired member ignored")
    for _,member in pairs(roster) do member.required=false end
    check(not Rules.allFinished(roster,C.Stages),"all nonrequired roster cannot win")

    -- Simulated assignment below mirrors onDoor's per-member stage write. It does
    -- not invoke onDoor: only canEnter/allFinished are production functions here.
    local progress={}
    for i=1,size do progress[i]={required=true,connected=true,stage=0,extracted=false,downed=false} end
    for chosen=1,size do
        for door=1,C.Stages do
            local member=progress[chosen]
            check(Rules.canEnter(member.stage,door,"Amber","Amber",false,"Match"),"next ordered gate allowed")
            check(not Rules.canEnter(member.stage,door,"Amber","Cyan",false,"Match"),"enemy gate denied")
            check(not Rules.canEnter(member.stage,door,"Amber","Amber",true,"Match"),"downed gate denied")
            for _,phase in ipairs({"Lobby","Vote","Results"}) do
                check(not Rules.canEnter(member.stage,door,"Amber","Amber",false,phase),"nonmatch gate denied")
            end
            for candidateDoor=1,C.Stages do
                if candidateDoor~=door then
                    check(not Rules.canEnter(member.stage,candidateDoor,"Amber","Amber",false,"Match"),"out-of-order gate denied")
                end
            end
            member.stage=door
            for other=1,size do
                if other~=chosen then
                    local expected=other<chosen and C.Stages or 0
                    check(progress[other].stage==expected,"other member's local progression unchanged")
                end
            end
            check(not Rules.allFinished(progress,C.Stages),"gates alone never extract team")
        end
        progress[chosen].extracted=true
        check(Rules.allFinished(progress,C.Stages)==(chosen==size),"only last required extraction completes team")
    end
end
-- Dictionary keys model server-side roster construction without array assumptions.
check(Rules.allFinished({playerA=finished(),playerB=finished()},C.Stages),"dictionary roster supported")
return {status="PASS",checks=checks,scope="Native Rules/Config ModuleScript predicates only",multiplayerVerified=false,
    note="No server callbacks, physical extraction, grace timer, movement, or replication exercised"}
