
local function armyStyle(object,radius)
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,radius or 10)
    corner.Parent=object
    local stroke=Instance.new("UIStroke")
    stroke.Color=Color3.fromRGB(29,40,25)
    stroke.Thickness=3
    stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    stroke.Parent=object
end
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local player = Players.LocalPlayer
local package = RS:WaitForChild("SmallSignals")
local remote, state = package:WaitForChild("Action"), package:WaitForChild("State")
local config = require(package.Config)
local fieldHUD = require(script.Parent:WaitForChild("SmallSignalsHUD")).new(player,config)
local selectedSize, selectedWeapon = 3, "Rifle"
local snapshot = {phase="Lobby",message="Connecting…",deadline=0,teams={Amber={},Cyan={}}}
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "SmallSignalsUI", false, false
gui.Parent = player:WaitForChild("PlayerGui")
local function label(parent,text,size,pos,height)
    local v=Instance.new("TextLabel")
    v.BackgroundTransparency=1
    v.TextColor3=Color3.fromRGB(255,246,211)
    v.Font=size>=20 and Enum.Font.FredokaOne or Enum.Font.GothamBold
    v.TextSize=size
    v.TextStrokeColor3=Color3.fromRGB(29,40,25)
    v.TextStrokeTransparency=0.65
    v.TextWrapped=true
    v.TextXAlignment=Enum.TextXAlignment.Left
    v.Size,v.Position=UDim2.new(1,-32,0,height or 32),UDim2.fromOffset(16,pos)
    v.Text,v.Parent=text,parent
    return v
end
local function frame(size,pos)
    local f=Instance.new("Frame")
    f.Size,f.Position=size,pos
    f.BackgroundColor3=Color3.fromRGB(73,94,49)
    f.BackgroundTransparency=0
    f.Parent=gui
    armyStyle(f,14)
    return f
end
local menu=frame(UDim2.fromOffset(560,400),UDim2.new(0.05,0,0.5,-200))
local constraint=Instance.new("UISizeConstraint") constraint.MaxSize=Vector2.new(560,440) constraint.Parent=menu
menu.AnchorPoint=Vector2.new(0.5,0.5) menu.Position=UDim2.fromScale(0.5,0.5)
label(menu,"CASH CITY",30,12)
label(menu,(config.ModeLabel or "TEAM EXTRACTION").." • "..config.MapLabel.." (MAP 1)",15,48)
local status=label(menu,"",16,82,60)
local function button(parent,text,x,y,w,callback)
    local b=Instance.new("TextButton")
    b.Size,b.Position=UDim2.new(w, -8,0,42),UDim2.new(x,4,0,y)
    b.Text,b.Font,b.TextSize=text,Enum.Font.FredokaOne,17
    b.BackgroundColor3,b.TextColor3=Color3.fromRGB(118,145,67),Color3.fromRGB(240,245,250)
    b.Parent=parent
    armyStyle(b,10)
    b.Activated:Connect(callback)
    return b
end
local sizeButtons={}
for i,n in ipairs({3,4,5}) do
    sizeButtons[n]=button(menu,n.." vs "..n,(i-1)/3,155,1/3,function()
        selectedSize=n
        for size,b in pairs(sizeButtons) do
            b.BackgroundColor3=size==n and Color3.fromRGB(194,158,64) or Color3.fromRGB(118,145,67)
            b.Text=(size==n and "★ " or "")..size.." vs "..size
        end
    end)
end
sizeButtons[3].BackgroundColor3=Color3.fromRGB(194,158,64)
sizeButtons[3].Text="★ 3 vs 3"
local ready=button(menu,"READY TO DEPLOY",0,212,0.5,function() remote:FireServer("Ready",selectedSize) end)
local unready=button(menu,"LEAVE QUEUE",0.5,212,0.5,function() remote:FireServer("Unready") end)
local practiceButton=button(menu,"SOLO STUDIO TEST",0,266,1,function() remote:FireServer("Practice") end)
practiceButton.Visible=RunService:IsStudio()
label(menu,"3 DOORS • ONE SQUAD • EVERYONE EXTRACTS",14,321,34)
local queueHint=label(menu,"3v3 needs 6 ready players. Solo testing is Studio-only.",12,357,32)
local vote=frame(UDim2.fromOffset(560,440),UDim2.fromScale(0.5,0.5))
vote.AnchorPoint=Vector2.new(0.5,0.5)
local vc=Instance.new("UISizeConstraint") vc.MaxSize=Vector2.new(560,440) vc.Parent=vote
label(vote,"★ GEAR UP! ★",22,12,38)
label(vote,"Pick your preferred gun, then vote for your squad carrier.",14,56,38)
local weaponButtons={}
local function chooseWeapon(name)
    selectedWeapon=name
    remote:FireServer("Weapon",name)
    for weapon,b in pairs(weaponButtons) do
        b.Text=(weapon==name and "★ " or "")..string.upper(weapon)
        b.BackgroundColor3=weapon==name and Color3.fromRGB(194,158,64) or Color3.fromRGB(118,145,67)
    end
end
weaponButtons.Rifle=button(vote,"★ RIFLE",0,100,0.5,function() chooseWeapon("Rifle") end)
weaponButtons.SMG=button(vote,"SMG",0.5,100,0.5,function() chooseWeapon("SMG") end)
weaponButtons.Rifle.BackgroundColor3=Color3.fromRGB(194,158,64)
local weaponLabel=label(vote,"Your preferred weapon: Rifle",14,149)
local nominees=Instance.new("Frame")
nominees.BackgroundTransparency=1 nominees.Size=UDim2.new(1,0,0,250) nominees.Position=UDim2.fromOffset(0,188) nominees.Parent=vote
local lastNominees=""
local menuScale=Instance.new("UIScale") menuScale.Parent=menu
local voteScale=Instance.new("UIScale") voteScale.Parent=vote
menu.Visible,vote.Visible=true,false
local lobbyClosed,voteClosed=false,false
local reopen
local function refreshPanels()
    local lobbyAvailable=snapshot.phase=="Lobby" or (snapshot.phase=="Match" and player.Neutral)
    local voteAvailable=snapshot.phase=="Vote" and not player.Neutral
    menu.Visible=lobbyAvailable and not lobbyClosed
    vote.Visible=voteAvailable and not voteClosed
    if reopen then
        reopen.Visible=(lobbyAvailable and lobbyClosed) or (voteAvailable and voteClosed)
        if voteAvailable then
            local seconds=math.max(0,math.ceil((snapshot.deadline or 0)-workspace:GetServerTimeNow()))
            reopen.Text="GEAR UP • "..seconds.."s"
        elseif snapshot.ready then
            local needed=snapshot.teamSize==1 and 1 or (snapshot.teamSize or 3)*2
            reopen.Text="WAITING • "..(snapshot.queueCount or 0).."/"..needed
        else reopen.Text="SQUAD LOBBY" end
    end
end
local function closeButton(panel,callback)
    local b=button(panel,"X",0,0,0.1,callback)
    b.Name,b.AnchorPoint,b.Size,b.Position="ClosePanel",Vector2.new(1,0),UDim2.fromOffset(40,34),UDim2.new(1,-10,0,10)
    b.BackgroundColor3=Color3.fromRGB(157,77,53)
end
closeButton(menu,function() lobbyClosed=true refreshPanels() end)
closeButton(vote,function() voteClosed=true refreshPanels() end)
reopen=button(gui,"SQUAD LOBBY",0,110,0.2,function()
    if snapshot.phase=="Vote" and not player.Neutral then voteClosed=false else lobbyClosed=false end
    refreshPanels()
end)
reopen.Name,reopen.Size,reopen.Position,reopen.Visible="ReopenSquadPanel",UDim2.fromOffset(210,42),UDim2.fromOffset(14,110),false

local banner=label(gui,"",20,0,70)
banner.TextXAlignment=Enum.TextXAlignment.Center banner.Position=UDim2.new(0.1,0,0.7,0) banner.Size=UDim2.new(0.8,0,0,70)
local crosshair=label(gui,"+",22,0,28)
crosshair.TextXAlignment=Enum.TextXAlignment.Center crosshair.Size=UDim2.fromOffset(28,28) crosshair.Position=UDim2.new(0.5,-14,0.5,-14)
local hint=label(gui,"Equip: 1 / 2 • Fire: click • Reload: R • Enter / revive: hold E",13,0,30)
hint.Visible=false
hint.Position=UDim2.new(0.03,0,1,-35) hint.Size=UDim2.new(0.94,0,0,30)
crosshair.Name="Crosshair"
banner.Name="RoundNotice"
fieldHUD:RegisterPanel(crosshair)
fieldHUD:RegisterPanel(banner)
local mouse=player:GetMouse()
local firing=false
local function shoot()
    if fieldHUD:IsEditing() then return end
    if snapshot.phase~="Match" then return end
    local camera=workspace.CurrentCamera
    if not camera then return end
    local position=UIS:GetMouseLocation()
    if UIS.TouchEnabled then position=camera.ViewportSize/2 end
    local ray=camera:ViewportPointToRay(position.X,position.Y)
    local params=RaycastParams.new()
    params.FilterType,params.FilterDescendantsInstances=Enum.RaycastFilterType.Exclude,{player.Character}
    local hit=workspace:Raycast(ray.Origin,ray.Direction*500,params)
    remote:FireServer("Attack",hit and hit.Position or ray.Origin+ray.Direction*500)
end
UIS.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 then firing=true
    elseif input.KeyCode==Enum.KeyCode.R and not fieldHUD:IsEditing() then remote:FireServer("Reload") end
end)
UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then firing=false end end)
local fire=button(gui,"FIRE",0.79,0,0.18,shoot)
fire.Position=UDim2.new(0.79,0,0.65,0) fire.Visible=UIS.TouchEnabled
local reload=button(gui,"RELOAD",0.79,0,0.18,function() if not fieldHUD:IsEditing() then remote:FireServer("Reload") end end)
reload.Position=UDim2.new(0.79,0,0.65,52) reload.Visible=UIS.TouchEnabled
fire.Name,reload.Name="FireControl","ReloadControl"
fieldHUD:RegisterPanel(fire)
fieldHUD:RegisterPanel(reload)
state.OnClientEvent:Connect(function(data)
    if data.phase~=snapshot.phase then
        if data.phase=="Vote" then voteClosed=false end
        if data.phase=="Lobby" then lobbyClosed=false end
    end
    snapshot=data
    refreshPanels()
    ready.Text=data.ready and "QUEUED — "..data.teamSize.."v"..data.teamSize or "READY TO DEPLOY"
    queueHint.Text=selectedSize.."v"..selectedSize.." needs "..(selectedSize*2).." ready players. Solo testing is Studio-only."
    local needed=data.teamSize==1 and 1 or (data.teamSize or 3)*2
    status.Text=data.message..(data.ready and ("\nWaiting: "..(data.queueCount or 0).." / "..needed.." ready. Close this panel to explore.") or "")
    weaponLabel.Text="Your preferred weapon: "..selectedWeapon
    local team=player.Team and player.Team.Name
    local rows=team and data.teams[team] or {}
    local signature=""
    for _,row in ipairs(rows) do signature=signature..row.id..":" end
    if signature~=lastNominees then
        lastNominees=signature
        nominees:ClearAllChildren()
        for i,row in ipairs(rows) do
            button(nominees,row.name,0,(i-1)*46,1,function()
                remote:FireServer("Nominate",row.id)
                weaponLabel.Text="Voted for "..row.name.." • your gun: "..selectedWeapon
            end)
        end
    end
end)
local elapsed=0
RunService.RenderStepped:Connect(function(dt)
    elapsed=elapsed+dt
    if firing and elapsed>=0.08 then elapsed=0 shoot() end
    local camera=workspace.CurrentCamera
    if camera then
        local viewport=camera.ViewportSize
        menuScale.Scale=math.max(0.35,math.min(1,(viewport.X-40)/560,(viewport.Y-90)/400))
        voteScale.Scale=math.max(0.35,math.min(1,(viewport.X-40)/560,(viewport.Y-90)/440))
    end
    refreshPanels()
    local phase=snapshot.phase
    local team=player.Team and player.Team.Name or "Spectator"
    local stage=player:GetAttribute("Stage") or 0
    local char=player.Character
    local h=char and char:FindFirstChildOfClass("Humanoid")
    local r=char and char:FindFirstChild("HumanoidRootPart")
    local remaining=math.max(0,math.ceil((snapshot.deadline or 0)-workspace:GetServerTimeNow()))
    fieldHUD:Update(snapshot)
    crosshair.Visible=phase=="Match"
    banner.Text=player:GetAttribute("Downed") and "DOWNED — a teammate can revive you" or phase=="Results" and snapshot.message or ""
    if workspace.CurrentCamera then
        player.CameraMinZoomDistance=math.max(0.15,0.5*(player:GetAttribute("Scale") or 1))
        player.CameraMaxZoomDistance=math.max(3,16*(player:GetAttribute("Scale") or 1))
    end
    -- Each client sees clues for its own next door, not a teammate's later door.
    local arena=workspace:FindFirstChild("SmallSignalsArena")
    local interactions=arena and arena:FindFirstChild("RoundInteractions")
    if interactions then
        for _,door in ipairs(interactions:GetChildren()) do
            local prompt=door:FindFirstChildWhichIsA("ProximityPrompt",true)
            local valid=phase=="Match" and door:GetAttribute("Team")==team and not player:GetAttribute("Downed")
            if door.Name=="ArmorCache" then
                local ownerId=door:GetAttribute("OwnerId")
                local ownerTeam=door:GetAttribute("OwnerTeam")
                valid=phase=="Match" and not player.Neutral and not player:GetAttribute("Downed")
                    and door:GetAttribute("Stage")==stage and (ownerId==player.UserId or ownerTeam~=team)
                local distance=r and (r.Position-door.Position).Magnitude or math.huge
                door.LocalTransparencyModifier=valid and distance<24 and 0 or 1
                valid=valid and (player:GetAttribute("Armor") or 0)<(player:GetAttribute("MaxArmor") or 0)
                if prompt then prompt.ActionText=ownerId==player.UserId and "Equip armor" or "Steal armor" end
            elseif door.Name=="TransitDoor" then
                valid=phase=="Match" and not player.Neutral and not player:GetAttribute("Downed")
            elseif door.Name=="Door" then
                valid=valid and door:GetAttribute("Stage")==stage+1
                local distance=r and (r.Position-door.Position).Magnitude or math.huge
                local reveal=state:GetAttribute("Overtime") and 110 or 50
                local visible=valid and distance<reveal
                door.LocalTransparencyModifier=visible and 0 or 1
                for _,piece in ipairs(door:GetDescendants()) do
                    if piece:IsA("BasePart") then piece.LocalTransparencyModifier=visible and 0 or 1 end
                    if piece:IsA("BillboardGui") then piece.Enabled=visible end
                end
            else valid=valid and stage==config.Stages end
            if prompt then prompt.Enabled=valid end
        end
    end
end)
-- UI hiding is supplemental: server TextChannels also reject delivery.
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat,false) end)
pcall(function()
    TextChatService.ChatWindowConfiguration.Enabled=false
    TextChatService.ChatInputBarConfiguration.Enabled=false
    TextChatService.BubbleChatConfiguration.Enabled=false
end)

pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,false) end)
