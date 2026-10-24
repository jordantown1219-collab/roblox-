local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local TextChatService = game:GetService("TextChatService")
local C = require(ReplicatedStorage.SmallSignals.Config)
local Rules = require(ReplicatedStorage.SmallSignals.Rules)
local Arena = require(script.Parent.Arena)
local WeaponVisuals=require(script.Parent.WeaponVisuals)
local WorldLoading = require(script.Parent.WorldLoading)
Players.CharacterAutoLoads = false
local remote = ReplicatedStorage.SmallSignals.Action
local state = ReplicatedStorage.SmallSignals.State
local phase, deadline, message = "Lobby", 0, "Choose team size and ready up."
local roundId, practice = 0, false
local members, reservations, queue, votes, lastAction = {}, {}, {}, {}, {}
local function now() return workspace:GetServerTimeNow() end
for _, name in ipairs({"Amber","Cyan"}) do
    local team = Instance.new("Team")
    team.Name, team.AutoAssignable = name, false
    team.TeamColor = BrickColor.new(name == "Amber" and "Bright orange" or "Cyan")
    team.Parent = Teams
end
-- Block message delivery in addition to hiding the client chat UI.
local function block(channel)
    if channel:IsA("TextChannel") then channel.ShouldDeliverCallback = function() return false end end
end
for _, child in ipairs(TextChatService:GetDescendants()) do block(child) end
TextChatService.DescendantAdded:Connect(block)
Arena.build()
local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
local function humanoid(p) return p.Character and p.Character:FindFirstChildOfClass("Humanoid") end
local function active(p) return phase == "Match" and members[p] ~= nil end
local function close(p, position, distance)
    local r = root(p)
    return r and (r.Position-position).Magnitude <= distance
end
local function blocked(p)
    local h = humanoid(p)
    return not h or h.Health <= 0 or p:GetAttribute("Downed") == true or p:GetAttribute("RiverfrontLoading") == true
end
local function setArmor(p, amount)
    local m = members[p]
    local cap = C.Armor[(m and m.stage or 0)+1]
    if m then m.armor = math.clamp(amount, 0, cap) end
    p:SetAttribute("Armor", m and m.armor or 0)
    p:SetAttribute("MaxArmor", cap)
end
local function setStage(p, stage, preserve)
    local char, h = p.Character, humanoid(p)
    if not char or not h then return end
    local fraction = h.Health/math.max(1,h.MaxHealth)
    -- Absolute model scale avoids repeatedly multiplying an already shrunk avatar.
    char:ScaleTo(C.Scales[stage+1])
    h.MaxHealth = C.Health[stage+1]
    h.Health = preserve and math.max(1, h.MaxHealth*fraction) or h.MaxHealth
    h.WalkSpeed = 16 -- Keep world travel speed: shrinking increases speed relative to body size.
    h.UseJumpPower = false
    h.JumpHeight = 7.2*C.Scales[stage+1]
    p:SetAttribute("Stage", stage)
    p:SetAttribute("Scale", C.Scales[stage+1])
    p:SetAttribute("MaxHealth", h.MaxHealth)
    local m = members[p]
    setArmor(p, m and m.armor or 0)
end
local function equip(p)
    local backpack = p:FindFirstChildOfClass("Backpack")
    if not backpack then return end
    backpack:ClearAllChildren()
    if p.Character then
        for _, tool in ipairs(p.Character:GetChildren()) do if tool:IsA("Tool") then tool:Destroy() end end
    end
    if not members[p] then return end
    local names = {"Knife"}
    if members[p].carrier then table.insert(names, members[p].weapon) end
    for _, name in ipairs(names) do
        local tool = Instance.new("Tool")
        tool.Name, tool.RequiresHandle, tool.CanBeDropped = name, true, false
        WeaponVisuals.build(tool,name,C.Scales[members[p].stage+1])
        tool.Parent=backpack
    end
end
local spawning = {}
local function spawn(p)
    if spawning[p] or not p.Parent then return end
    spawning[p] = true
    local ok, err = pcall(function() p:LoadCharacterAsync() end)
    if not ok then spawning[p]=nil warn("Character load failed",err) return end
    if not p.Parent or not p.Character then spawning[p]=nil return end
    local character=p.Character
    local h = humanoid(p)
    if not h then spawning[p]=nil return end
    p:SetAttribute("Downed",false)
    local m = members[p]
    local stage = m and m.stage or 0
    setArmor(p,0)
    setStage(p,stage,false)
    local position = m and (m.checkpoint or Arena.spawns[m.team]) or Arena.lobby
    local expectedRound,expectedStage=roundId,stage
    local prepared=not m or WorldLoading.prepare(p,position,function()
        return members[p]==m and roundId==expectedRound and m.stage==expectedStage
    end)
    if not p.Parent or p.Character~=character or not h.Parent or h.Health<=0 then spawning[p]=nil return end
    if not prepared then
        -- Persistent staging is the recovery destination; retain current squad
        -- membership/checkpoint so a failed request cannot reset match progress.
        position=Arena.lobby
        m=members[p]
        setArmor(p,0)
        setStage(p,m and m.stage or 0,false)
        warn("Riverfront spawn recovered to staging after destination loading was cancelled or failed")
    end
    p:SetAttribute("RiverfrontSpawnRecovery",not prepared)
    character:PivotTo(CFrame.new(position))
    local shield = Instance.new("ForceField")
    shield.Parent = p.Character
    p:SetAttribute("ProtectedUntil",now()+C.SpawnProtection)
    task.delay(C.SpawnProtection,function() if shield.Parent then shield:Destroy() end end)
    equip(p)
    h.Died:Connect(function()
        local current = members[p]
        if current then current.extracted = false end
        p:SetAttribute("Downed",false)
        task.delay(C.RespawnSeconds,function() spawn(p) end)
    end)
    spawning[p]=nil
end
local function roster(team,viewerTeam)
    local result = {}
    for p,m in pairs(members) do
        if m.team == team then
            local row={id=p.UserId,name=p.DisplayName,stage=m.stage,carrier=m.carrier,downed=p:GetAttribute("Downed")==true,extracted=m.extracted}
            if team==viewerTeam then
                local h=humanoid(p)
                row.health,row.maxHealth=h and h.Health or 0,h and h.MaxHealth or C.Health[m.stage+1]
                row.armor,row.maxArmor=m.armor or 0,C.Armor[m.stage+1]
            end
            table.insert(result,row)
        end
    end
    return result
end
local function broadcast()
    Arena.folder:SetAttribute("MatchActive",phase=="Match")
    local data = {phase=phase, deadline=deadline, message=message, practice=practice, stages=C.Stages,
        teams={}, round=roundId}
    for _, p in ipairs(Players:GetPlayers()) do
        local viewerTeam=members[p] and members[p].team
        data.teams={Amber=roster("Amber",viewerTeam),Cyan=roster("Cyan",viewerTeam)}
        data.ready = queue[p] ~= nil
        data.teamSize = queue[p] or 3
        local waiting=0
        for queued,choice in pairs(queue) do
            if queued.Parent and choice==queue[p] then waiting=waiting+1 end
        end
        data.queueCount=waiting
        state:FireClient(p,data)
    end
end
local function finish(team)
    if phase ~= "Match" then return end
    phase, message, deadline = "Results", team and (team.." wins — everyone extracted!") or "Time expired — draw.", now()+8
    broadcast()
end
local function checkWin(team)
    local required = {}
    for p,m in pairs(members) do
        if m.team == team then table.insert(required,{required=true,connected=true,stage=m.stage,extracted=m.extracted,downed=p:GetAttribute("Downed")==true}) end
    end
    for _, saved in pairs(reservations) do
        if saved.team == team and saved.untilTime > now() then table.insert(required,{required=true,connected=false}) end
    end
    if Rules.allFinished(required,C.Stages) then finish(team) end
end
local armorPickups = {}
local armorRng = Random.new()
local function clearArmorPickup(owner)
    local pickup = armorPickups[owner]
    if pickup then pickup:Destroy() armorPickups[owner] = nil end
end
local function spawnArmor(owner)
    local assigned = members[owner]
    if phase ~= "Match" or not assigned or armorPickups[owner] or blocked(owner) then return end
    -- Curated open shop floors, away from counters, shelves and door approaches.
    local x = ({-46,0,46})[armorRng:NextInteger(1,3)]
    local z = ({-32,32})[armorRng:NextInteger(1,2)]
    local armorStage = assigned.stage
    local scale = C.Scales[armorStage+1]
    local pickup = Instance.new("Part")
    pickup.Name = "ArmorCache"
    pickup.Size = Vector3.new(1.4,1.6,0.55)*scale
    if Arena.armorPositions then
        pickup.Position=Arena.armorPositions[armorRng:NextInteger(1,#Arena.armorPositions)]+Vector3.new(0,.8*scale+.4,0)
    else pickup.Position = Vector3.new((x + armorRng:NextNumber(-3,3))*C.MapStretch,0.8*scale+0.2,z*C.MapStretch) end
    pickup.Anchored, pickup.CanCollide = true, false
    pickup.Color = Color3.fromRGB(138,153,88)
    pickup.Material = Enum.Material.Metal
    pickup:SetAttribute("OwnerId",owner.UserId)
    pickup:SetAttribute("OwnerTeam",assigned.team)
    pickup:SetAttribute("Stage",assigned.stage)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText, prompt.ObjectText = "Equip armor", "Field armor"
    prompt.HoldDuration, prompt.MaxActivationDistance = 0.6, 6*scale
    prompt.RequiresLineOfSight = true
    prompt.Parent = pickup
    pickup.Parent = Arena.interactions
    armorPickups[owner] = pickup
    local claimed = false
    prompt.Triggered:Connect(function(player)
        local m = members[player]
        local currentOwner = members[owner]
        if claimed or phase ~= "Match" or not m or blocked(player) or not currentOwner then return end
        if not Rules.canTakeArmor(player.UserId,m.team,m.stage,owner.UserId,currentOwner.team,armorStage,currentOwner.stage==armorStage) then return end
        if (m.armor or 0) >= C.Armor[m.stage+1] or not close(player,pickup.Position,6*C.Scales[m.stage+1]) then return end
        local rp = RaycastParams.new()
        rp.FilterType, rp.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude,{player.Character}
        local hit = workspace:Raycast(root(player).Position,pickup.Position-root(player).Position,rp)
        if hit and hit.Instance ~= pickup then return end
        claimed = true
        setArmor(player,C.Armor[m.stage+1])
        clearArmorPickup(owner)
    end)
end
local function onDoor(p, team, stage, door, destination)
    local m = members[p]
    if not m or blocked(p) or not Rules.canEnter(m.stage,stage,m.team,team,p:GetAttribute("Downed"),phase) then return end
    if not close(p,door.Position,math.max(3.5,7*C.Scales[m.stage+1])) then return end
    local ray = RaycastParams.new()
    ray.FilterType, ray.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {p.Character}
    local hit = workspace:Raycast(root(p).Position,door.Position-root(p).Position,ray)
    if hit and hit.Instance ~= door and not hit.Instance:IsDescendantOf(door) then return end
    local expectedRound,expectedStage=roundId,m.stage
    if not WorldLoading.prepare(p,destination,function()
        return members[p]==m and roundId==expectedRound and phase=="Match" and m.stage==expectedStage
            and p:GetAttribute("Downed")~=true
    end) then return end
    clearArmorPickup(p)
    local armorFraction = (m.armor or 0)/C.Armor[m.stage+1]
    m.stage, m.checkpoint, m.extracted = stage, destination, false
    m.armor = C.Armor[stage+1]*armorFraction
    setStage(p,stage,true)
    p.Character:PivotTo(CFrame.new(destination))
    equip(p)
    broadcast()
end
local function onTransit(p,door,destination)
    local m=members[p]
    if not active(p) or blocked(p) or now()<(m.transitUntil or 0) then return end
    local position=door.Position-Vector3.new(0,2.4,0)
    if not close(p,position,7) then return end
    local rp=RaycastParams.new()
    rp.FilterType,rp.FilterDescendantsInstances=Enum.RaycastFilterType.Exclude,{p.Character}
    local hit=workspace:Raycast(root(p).Position,position-root(p).Position,rp)
    if hit and hit.Instance~=door and not hit.Instance:IsDescendantOf(door) then return end
    local expectedRound,expectedStage=roundId,m.stage
    local landing=destination+Vector3.new(0,4*C.Scales[m.stage+1],0)
    if not WorldLoading.prepare(p,landing,function()
        return members[p]==m and roundId==expectedRound and phase=="Match" and m.stage==expectedStage
            and p:GetAttribute("Downed")~=true
    end) then return end
    m.transitUntil=now()+C.TransitCooldown
    m.extracted=false
    p.Character:PivotTo(CFrame.new(landing))
end
local function onExit(p, team, exit)
    local m = members[p]
    if not active(p) or blocked(p) or m.team ~= team or m.stage ~= C.Stages or not close(p,exit.Position,4) then return end
    -- Must physically stay at extraction; moving away clears the flag in the tick loop.
    m.extracted, m.exit = true, exit
    checkWin(team)
    broadcast()
end
local function down(p)
    if p:GetAttribute("Downed") then return end
    local h, r, m = humanoid(p), root(p), members[p]
    if not h or not r or not m then return end
    m.extracted = false
    p:SetAttribute("Downed",true)
    h.Health, h.WalkSpeed, h.JumpHeight = 1, 0, 0
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name, prompt.ActionText, prompt.ObjectText = "Revive", "Revive", "Teammate"
    prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = C.ReviveHold, 7, true
    prompt.Parent = r
    local held = {}
    prompt.PromptButtonHoldBegan:Connect(function(helper) held[helper] = now() end)
    prompt.PromptButtonHoldEnded:Connect(function(helper) task.delay(0.1,function() held[helper]=nil end) end)
    prompt.Triggered:Connect(function(helper)
        local hm = members[helper]
        if helper==p or phase~="Match" or not hm or hm.team~=m.team or blocked(helper) or not p:GetAttribute("Downed") then return end
        if not held[helper] or now()-held[helper]<C.ReviveHold-0.15 or not close(helper,r.Position,7) then return end
        local rp = RaycastParams.new()
        rp.FilterType, rp.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude,{helper.Character,p.Character}
        if workspace:Raycast(root(helper).Position,r.Position-root(helper).Position,rp) then return end
        p:SetAttribute("Downed",false)
        setStage(p,m.stage,false)
        h.Health = h.MaxHealth*0.5
        prompt:Destroy()
        broadcast()
    end)
    local character, thisRound = p.Character, roundId
    task.delay(C.ReviveWindow,function()
        if p.Parent and p.Character==character and roundId==thisRound and p:GetAttribute("Downed") then h.Health=0 end
    end)
    broadcast()
end
local function damage(attacker,target,amount)
    if not active(attacker) or not active(target) or blocked(attacker) or blocked(target) then return end
    if members[attacker].team==members[target].team then return end
    if (attacker:GetAttribute("ProtectedUntil") or 0)>now() or (target:GetAttribute("ProtectedUntil") or 0)>now() then return end
    local h = humanoid(target)
    local remainingArmor, healthDamage = Rules.absorbDamage(members[target].armor or 0,amount)
    setArmor(target,remainingArmor)
    if healthDamage>=h.Health then down(target) elseif healthDamage>0 then h:TakeDamage(healthDamage) end
end
local function vectorFinite(v)
    return typeof(v)=="Vector3" and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<1e6 and math.abs(v.Y)<1e6 and math.abs(v.Z)<1e6
end
local supportedActions={Ready=true,Unready=true,Practice=true,Nominate=true,Weapon=true,Reload=true,Attack=true}
remote.OnServerEvent:Connect(function(p, action, arg)
    if typeof(action)~="string" or not supportedActions[action] then return end
    local t = now()
    lastAction[p] = lastAction[p] or {}
    local rate = action=="Attack" and 0.05 or 0.15
    if t-(lastAction[p][action] or 0)<rate then return end
    lastAction[p][action]=t
    if action=="Ready" and phase=="Lobby" then
        if table.find(C.TeamSizes,arg) then queue[p]=arg end
    elseif action=="Unready" then queue[p]=nil
    elseif action=="Practice" and phase=="Lobby" and RunService:IsStudio() then
        queue[p]=1
    elseif action=="Nominate" and phase=="Vote" and members[p] then
        for target,m in pairs(members) do
            if target.UserId==arg and m.team==members[p].team then votes[p]=target end
        end
    elseif action=="Weapon" and phase=="Vote" and (arg=="Rifle" or arg=="SMG") then
        p:SetAttribute("WeaponChoice",arg)
    elseif action=="Reload" and active(p) and not blocked(p) then
        local m=members[p]
        local w=C.Weapons[m.weapon]
        local tool=p.Character and p.Character:FindFirstChild(m.weapon)
        if m.carrier and tool and not m.reloadAt then m.reloadAt=t+w.Reload WeaponVisuals.reload(tool,w.Reload) end
    elseif action=="Attack" and active(p) and not blocked(p) and vectorFinite(arg) then
        local m = members[p]
        local tool = p.Character and p.Character:FindFirstChildOfClass("Tool")
        if not tool then return end
        local name = tool.Name
        if name~="Knife" and (not m.carrier or name~=m.weapon) then return end
        local w = C.Weapons[name]
        if not w or t-(m.lastShot or 0)<w.Cooldown or m.reloadAt then return end
        if name~="Knife" and m.ammo<=0 then return end
        local head = p.Character:FindFirstChild("Head")
        if not head then return end
        local delta=arg-head.Position
        if delta.Magnitude<0.01 then return end
        m.lastShot=t
        if name~="Knife" then m.ammo=m.ammo-1 WeaponVisuals.fire(tool) end
        local range = name=="Knife" and w.Range*C.Scales[m.stage+1] or w.Range
        local rp = RaycastParams.new()
        rp.FilterType, rp.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude,{p.Character}
        local hit=workspace:Raycast(head.Position,delta.Unit*range,rp)
        if hit then
            local model=hit.Instance:FindFirstAncestorOfClass("Model")
            local target=model and Players:GetPlayerFromCharacter(model)
            if target then damage(p,target,Rules.damage(w.Damage,C.Strength[m.stage+1])) end
        end
    end
end)
local function addPlayer(p)
    p.Neutral=true
    p:SetAttribute("Stage",0)
    p:SetAttribute("Downed",false)
    p:SetAttribute("WeaponChoice","Rifle")
    local saved=reservations[p.UserId]
    if phase=="Match" and saved and saved.untilTime>now() then
        members[p]=saved.member
        reservations[p.UserId]=nil
        p.Team=Teams:FindFirstChild(members[p].team)
    end
    task.spawn(spawn,p)
    broadcast()
end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(p)
    clearArmorPickup(p)
    local m=members[p]
    if phase=="Match" and m then
        reservations[p.UserId]={team=m.team,member=m,untilTime=now()+C.RejoinWindow}
        m.extracted=false
    end
    members[p],queue[p],votes[p],lastAction[p]=nil,nil,nil,nil
    for voter,target in pairs(votes) do if target==p then votes[voter]=nil end end
end)
for _,p in ipairs(Players:GetPlayers()) do addPlayer(p) end
local function begin(selected, solo)
    roundId, practice = roundId+1, solo
    members, votes, reservations = {},{},{}
    for i,p in ipairs(selected) do
        local team=i%2==1 and "Amber" or "Cyan"
        members[p]={team=team,stage=0,carrier=false,weapon="Rifle",ammo=20,armor=0,extracted=false}
        queue[p]=nil
        p.Team=Teams:FindFirstChild(team)
    end
    phase,message,deadline="Vote","Vote for your team's gun carrier; choose your preferred gun.",now()+C.VoteSeconds
    broadcast()
end
local function startMatch()
    for _,team in ipairs({"Amber","Cyan"}) do
        local candidates={}
        for p,m in pairs(members) do if m.team==team then table.insert(candidates,p) end end
        table.sort(candidates,function(a,b) return a.UserId<b.UserId end)
        local winner,best=nil,-1
        for _,p in ipairs(candidates) do
            local count=0
            for voter,target in pairs(votes) do if members[voter] and members[voter].team==team and target==p then count=count+1 end end
            if count>best then winner,best=p,count end
        end
        if winner then
            local m=members[winner]
            m.carrier,m.weapon=true,winner:GetAttribute("WeaponChoice") or "Rifle"
            m.ammo=C.Weapons[m.weapon].Magazine
        end
    end
    for owner in pairs(armorPickups) do clearArmorPickup(owner) end
    Arena.routes(C,onDoor,onExit,onTransit)
    phase,message,deadline="Match","Find your doors. Guide your team. Reach the tiny exit together.",now()+C.MatchSeconds
    for p,m in pairs(members) do m.nextArmorAt=now()+C.ArmorSpawnSeconds task.spawn(spawn,p) end
    broadcast()
end
while true do
    task.wait(0.5)
    if phase=="Lobby" then
        for _,size in ipairs({1,3,4,5}) do
            local selected={}
            for p,choice in pairs(queue) do if choice==size and p.Parent then table.insert(selected,p) end end
            local needed=size==1 and 1 or size*2
            if #selected>=needed and (size~=1 or RunService:IsStudio()) then
                table.sort(selected,function(a,b) return a.UserId<b.UserId end)
                while #selected>needed do table.remove(selected) end
                begin(selected,size==1)
                break
            end
        end
    elseif phase=="Vote" and now()>=deadline then startMatch()
    elseif phase=="Match" then
        for p,m in pairs(members) do
            if now()>=(m.nextArmorAt or math.huge) then
                m.nextArmorAt=now()+C.ArmorSpawnSeconds
                if armorRng:NextNumber()<C.ArmorSpawnChance then spawnArmor(p) end
            end
            if m.reloadAt and now()>=m.reloadAt then m.ammo=C.Weapons[m.weapon].Magazine m.reloadAt=nil end
            p:SetAttribute("Ammo",m.carrier and m.ammo or 0)
            p:SetAttribute("Carrier",m.carrier)
            p:SetAttribute("Weapon",m.weapon)
            local r=root(p)
            if m.extracted and (not m.exit or not close(p,m.exit.Position,4) or blocked(p)) then m.extracted=false end
            if r and r.Position.Y < -15 then local h=humanoid(p) if h then h.Health=0 end end
        end
        for id,saved in pairs(reservations) do
            if now()>=saved.untilTime then reservations[id]=nil end
        end
        -- Assign a replacement only after the disconnected carrier's rejoin window ends.
        for _,team in ipairs({"Amber","Cyan"}) do
            local hasCarrier=false
            for _,m in pairs(members) do if m.team==team and m.carrier then hasCarrier=true end end
            for _,saved in pairs(reservations) do if saved.team==team and saved.member.carrier then hasCarrier=true end end
            if not hasCarrier then
                for p,m in pairs(members) do
                    if m.team==team then
                        m.carrier,m.weapon=true,p:GetAttribute("WeaponChoice") or "Rifle"
                        m.ammo=C.Weapons[m.weapon].Magazine
                        equip(p)
                        break
                    end
                end
            end
            checkWin(team)
        end
        if phase=="Match" and now()>=deadline then
            if not state:GetAttribute("Overtime") then
                state:SetAttribute("Overtime",true)
                deadline,message=now()+C.OvertimeSeconds,"Overtime — door clues are visible from farther away."
            else finish(nil) end
        end
    elseif phase=="Results" and now()>=deadline then
        phase,message,deadline="Lobby","Choose team size and ready up.",0
        members,reservations,votes={},{},{}
        state:SetAttribute("Overtime",false)
        for owner in pairs(armorPickups) do clearArmorPickup(owner) end
        if Arena.interactions then Arena.interactions:Destroy() end
        for _,p in ipairs(Players:GetPlayers()) do p.Neutral=true task.spawn(spawn,p) end
    end
    broadcast()
end
