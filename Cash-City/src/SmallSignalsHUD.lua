
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
-- Small Signals field HUD. Presentation only; server owns every gameplay value.
local HUD={}
function HUD.new(player,config)
    local gui=Instance.new("ScreenGui")
    gui.Name,gui.ResetOnSpawn,gui.DisplayOrder="SmallSignalsFieldHUD",false,5
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset=false
    gui.Parent=player:WaitForChild("PlayerGui")
    gui.Enabled=false
    local ink=Color3.fromRGB(73,94,49)
    local muted=Color3.fromRGB(227,218,171)
    local white=Color3.fromRGB(255,246,211)
    local olive=Color3.fromRGB(250,207,87)
    local blue=Color3.fromRGB(86,190,225)
    local function box(name,size,pos,anchor)
        local f=Instance.new("Frame")
        f.Name,f.Size,f.Position,f.AnchorPoint=name,size,pos,anchor or Vector2.new(0,0)
        f.BackgroundColor3,f.BackgroundTransparency,f.BorderSizePixel=ink,0,0
        f.Parent=gui
        armyStyle(f,12)
        local insignia=Instance.new("TextLabel")
        insignia.Name,insignia.Text,insignia.Font="ArmyBadge","★",Enum.Font.FredokaOne
        insignia.Size,insignia.Position=UDim2.fromOffset(22,22),UDim2.new(1,-26,0,-10)
        insignia.BackgroundColor3,insignia.TextColor3=Color3.fromRGB(52,68,36),olive
        insignia.TextSize,insignia.Parent=18,f
        armyStyle(insignia,6)
        return f
    end
    local function text(parent,name,value,x,y,w,h,size,color)
        local t=Instance.new("TextLabel")
        t.Name,t.Text,t.Position,t.Size=name,value,UDim2.fromOffset(x,y),UDim2.fromOffset(w,h)
        t.BackgroundTransparency,t.Font,t.TextSize=1,Enum.Font.GothamBold,size or 14
        t.TextColor3,t.TextXAlignment,t.TextYAlignment=color or white,Enum.TextXAlignment.Left,Enum.TextYAlignment.Center
        t.TextTruncate=Enum.TextTruncate.AtEnd
        t.TextStrokeColor3=Color3.fromRGB(29,40,25)
        t.TextStrokeTransparency=0.65
        if (size or 14)>=18 then t.Font=Enum.Font.FredokaOne end
        t.Parent=parent
        return t
    end
    local vital=box("Vitals",UDim2.fromOffset(330,138),UDim2.new(0,18,1,-48),Vector2.new(0,1))
    local callsign=text(vital,"Callsign","TOY SOLDIER",14,6,300,22,14,olive)
    local body=text(vital,"BodyScale","SIZE 100%",14,29,300,19,12,muted)
    local function bar(name,y,color)
        local title=text(vital,name.."Label",name,14,y,90,20,12,muted)
        local value=text(vital,name.."Value","0 / 0",215,y,100,20,14)
        value.TextXAlignment=Enum.TextXAlignment.Right
        local track=Instance.new("Frame")
        track.Name,track.Position,track.Size=name.."Track",UDim2.fromOffset(14,y+22),UDim2.fromOffset(301,9)
        track.BackgroundColor3,track.BorderSizePixel=Color3.fromRGB(38,54,32),0
        track.Parent=vital
        armyStyle(track,5)
        track.ClipsDescendants=true
        local fill=Instance.new("Frame")
        fill.Name,fill.Size,fill.BackgroundColor3,fill.BorderSizePixel="Fill",UDim2.fromScale(0,1),color,0
        fill.Parent=track
        return fill,value
    end
    local hpFill,hpText=bar("HEALTH",51,Color3.fromRGB(139,218,80))
    local apFill,apText=bar("ARMOR",91,blue)
    local objective=box("Objective",UDim2.fromOffset(350,66),UDim2.new(0.5,0,0,12),Vector2.new(0.5,0))
    local mission=text(objective,"Mission",(config.MapLabel or "MONROE BLOCK • DETROIT"),14,5,320,19,12,muted)
    local progress=text(objective,"Progress","DOORS 0 / 3",14,26,230,30,19)
    local timer=text(objective,"Timer","00:00",244,26,90,30,20,olive)
    timer.TextXAlignment=Enum.TextXAlignment.Right
    local ammo=box("Loadout",UDim2.fromOffset(220,88),UDim2.new(1,-18,1,-48),Vector2.new(1,1))
    local gun=text(ammo,"Weapon","KNIFE",14,7,190,21,14,muted)
    local rounds=text(ammo,"Ammo","MELEE",14,30,190,40,28)
    local squad=box("Squad",UDim2.fromOffset(272,320),UDim2.new(1,-18,0,92),Vector2.new(1,0))
    text(squad,"Header","SQUAD / HEALTH / ARMOR",14,6,246,21,12,olive)
    local rows={}
    for i=1,5 do
        local y=32+(i-1)*56
        local row=Instance.new("Frame")
        row.Name,row.Size,row.Position="Member"..i,UDim2.fromOffset(244,52),UDim2.fromOffset(14,y)
        row.BackgroundTransparency,row.Parent=1,squad
        local name=text(row,"Name","",0,0,244,19,12)
        local values=text(row,"Values","",0,18,244,17,11,muted)
        local fills={}
        for index,color in ipairs({olive,blue}) do
            local track=Instance.new("Frame")
            track.Size,track.Position=UDim2.fromOffset(116,5),UDim2.fromOffset((index-1)*126,39)
            track.BackgroundColor3,track.BorderSizePixel,track.Parent=Color3.fromRGB(38,54,32),0,row
            local fill=Instance.new("Frame")
            fill.Size,fill.BackgroundColor3,fill.BorderSizePixel,fill.Parent=UDim2.fromScale(0,1),color,0,track
            fills[index]=fill
        end
        rows[i]={frame=row,name=name,values=values,hp=fills[1],armor=fills[2]}
    end
    local scales={}
    for _,panel in ipairs({vital,objective,ammo,squad}) do
        local scale=Instance.new("UIScale") scale.Parent=panel scales[panel]=scale
    end
    local settings=require(script.Parent:WaitForChild("SmallSignalsSettings")).new(player,{vital,objective,ammo,squad})
    local self={Gui=gui}
    function self:RegisterPanel(panel) settings:RegisterPanel(panel) end
    function self:IsEditing() return settings:IsEditing() end
    function self:Update(snapshot)
        local phase=snapshot.phase
        settings:Update()
        gui.Enabled=((phase=="Match" or phase=="Results") and not player.Neutral) or settings:IsEditing()
        if not gui.Enabled then return end
        local camera=workspace.CurrentCamera
        local width=camera and camera.ViewportSize.X or 1280
        scales[vital].Scale=math.clamp((width-48)/570,0.55,1)
        scales[ammo].Scale=scales[vital].Scale
        scales[objective].Scale=math.clamp((width-30)/350,0.65,1)
        scales[squad].Scale=math.clamp((width-30)/560,0.55,1)
        squad.Visible=settings:ShowSquad()
        local stage=player:GetAttribute("Stage") or 0
        local team=player.Team and player.Team.Name or "OPERATIVE"
        local char=player.Character
        local humanoid=char and char:FindFirstChildOfClass("Humanoid")
        local hp,maxHp=humanoid and humanoid.Health or 0,humanoid and humanoid.MaxHealth or 100
        local ap,maxAp=player:GetAttribute("Armor") or 0,player:GetAttribute("MaxArmor") or (config.Armor and config.Armor[stage+1]) or 0
        local down=player:GetAttribute("Downed")
        callsign.Text=string.upper(team).." / "..(down and "DOWNED" or "TOY SOLDIER")
        callsign.TextColor3=down and Color3.fromRGB(231,104,83) or olive
        body.Text=string.format("BODY SCALE %d%%  /  STAGE %d",math.floor((player:GetAttribute("Scale") or 1)*100+0.5),stage)
        hpFill.Size=UDim2.fromScale(math.clamp(hp/math.max(1,maxHp),0,1),1)
        hpFill.BackgroundColor3=hp/math.max(1,maxHp)<=0.25 and Color3.fromRGB(204,76,58) or Color3.fromRGB(139,218,80)
        hpText.Text=string.format("%d / %d",math.ceil(hp),math.ceil(maxHp))
        apFill.Size=UDim2.fromScale(math.clamp(ap/math.max(1,maxAp),0,1),1)
        apText.Text=string.format("%d / %d",math.ceil(ap),math.ceil(maxAp))
        mission.Text=snapshot.practice and "STUDIO TRAINING / DETROIT" or (config.MapLabel or "MONROE BLOCK • DETROIT")
        progress.Text=stage>=config.Stages and "TEAM EXTRACTION" or string.format("DOORS %d / %d",stage,config.Stages)
        local remaining=math.max(0,math.ceil((snapshot.deadline or 0)-workspace:GetServerTimeNow()))
        timer.Text=string.format("%02d:%02d",math.floor(remaining/60),remaining%60)
        timer.TextColor3=remaining<=30 and Color3.fromRGB(231,104,83) or olive
        local tool=char and char:FindFirstChildOfClass("Tool")
        local carrier=player:GetAttribute("Carrier")
        local weapon=tool and tool.Name or "HOLSTERED"
        gun.Text=string.upper(weapon)..(carrier and " / CARRIER" or "")
        rounds.Text=weapon=="Knife" and "MELEE" or weapon=="HOLSTERED" and "EQUIP 1 / 2" or tostring(player:GetAttribute("Ammo") or 0).." RDS"
        for i=1,5 do
            local row=((snapshot.teams or {})[team] or {})[i]
            rows[i].frame.Visible=row~=nil
            if row then
                local state=row.downed and "DOWN" or row.extracted and "EXIT" or tostring(row.stage).."/"..config.Stages
                rows[i].name.Text=state.."  "..row.name..(row.carrier and " *" or "")
                rows[i].name.TextColor3=row.downed and Color3.fromRGB(231,104,83) or white
                local known=type(row.health)=="number" and type(row.maxHealth)=="number"
                rows[i].values.Text=known and string.format("HP %d/%d   AR %d/%d",math.ceil(row.health),math.ceil(row.maxHealth),math.ceil(row.armor or 0),math.ceil(row.maxArmor or 0)) or "HP --   AR --"
                rows[i].hp.Size=UDim2.fromScale(known and math.clamp(row.health/math.max(1,row.maxHealth),0,1) or 0,1)
                rows[i].armor.Size=UDim2.fromScale(math.clamp((row.armor or 0)/math.max(1,row.maxArmor or 0),0,1),1)
            end
        end
    end
    function self:Destroy() settings:Destroy() gui:Destroy() end
    return self
end
return HUD
