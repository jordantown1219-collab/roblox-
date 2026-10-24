
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
-- Local preferences, preserved through respawn for this play session.
local Settings={}
function Settings.new(player,panels)
    local UIS=game:GetService("UserInputService")
    local GuiService=game:GetService("GuiService")
    local Lighting=game:GetService("Lighting")
    local SoundService=game:GetService("SoundService")
    local gui=Instance.new("ScreenGui")
    gui.Name,gui.ResetOnSpawn,gui.DisplayOrder="SmallSignalsSettings",false,30
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset=false
    gui.Parent=player:WaitForChild("PlayerGui")
    local root=Instance.new("Frame")
    root.Size,root.BackgroundTransparency=UDim2.fromScale(1,1),1
    root.Parent=gui
    local connections={}
    local function connect(signal,fn) local c=signal:Connect(fn) table.insert(connections,c) return c end
    local editing,muted,low=false,false,false
    local drag=nil
    local defaults,handles={},{}
    local function button(parent,name,label,x,y,w,fn)
        local b=Instance.new("TextButton")
        b.Name,b.Text,b.Position,b.Size=name,label,UDim2.fromOffset(x,y),UDim2.fromOffset(w,32)
        b.BackgroundColor3,b.TextColor3=Color3.fromRGB(118,145,67),Color3.fromRGB(255,246,211)
        b.BorderSizePixel,b.Font,b.TextSize=0,Enum.Font.GothamBold,13
        b.Parent=parent
        armyStyle(b,9)
        connect(b.Activated,fn)
        return b
    end
    local window=Instance.new("Frame")
    window.Name,window.AnchorPoint,window.Position="SettingsPanel",Vector2.new(0.5,0.5),UDim2.fromScale(0.5,0.5)
    window.Size,window.BackgroundColor3,window.Visible=UDim2.fromOffset(310,290),Color3.fromRGB(73,94,49),false
    window.Parent=root
    armyStyle(window,14)
    local title=Instance.new("TextLabel")
    title.Size,title.Position,title.BackgroundTransparency=UDim2.fromOffset(280,32),UDim2.fromOffset(15,8),1
    title.Text,title.TextColor3,title.Font,title.TextSize="★ FIELD SETTINGS ★",Color3.fromRGB(250,207,87),Enum.Font.FredokaOne,20
    title.Parent=window
    local editButton,musicButton,graphicsButton,squadButton
    local squadWanted=true
    local function setEditing(value)
        editing=value drag=nil
        for _,handle in pairs(handles) do handle.Visible=value end
        if editButton then editButton.Text=value and "FINISH MOVING HUD" or "MOVE HUD PANELS" end
        window.Visible=not value
    end
    local open=button(root,"SettingsTab","SETTINGS",14,64,104,function()
        if editing then setEditing(false) else window.Visible=not window.Visible end
    end)
    connect(GuiService.MenuOpened,function()
        if editing then setEditing(false) end
        window.Visible=false
        gui.Enabled=false
    end)
    connect(GuiService.MenuClosed,function() gui.Enabled=true end)
    gui.Enabled=not GuiService.MenuIsOpen
    editButton=button(window,"EditHUD","MOVE HUD PANELS",15,49,280,function() setEditing(not editing) end)
    local musicSaved=setmetatable({},{__mode="k"})
    local graphicsSaved=setmetatable({},{__mode="k"})
    local function musicObject(obj)
        return (obj:IsA("SoundGroup") and obj.Name=="Music") or
            (obj:IsA("Sound") and (obj:GetAttribute("IsMusic")==true or obj.Name=="Music" or obj.Name=="BackgroundMusic"))
    end
    local function muteObject(obj)
        if muted and musicObject(obj) then
            if musicSaved[obj]==nil then musicSaved[obj]=obj.Volume end
            obj.Volume=0
        end
    end
    local function restoreMusic()
        for obj,value in pairs(musicSaved) do if obj.Parent then obj.Volume=value end musicSaved[obj]=nil end
    end
    musicButton=button(window,"MuteMusic","MUSIC: ON",15,89,280,function()
        muted=not muted
        musicButton.Text=muted and "MUSIC: MUTED" or "MUSIC: ON"
        if muted then for _,obj in ipairs(game:GetDescendants()) do muteObject(obj) end else restoreMusic() end
    end)
    local function reduce(obj)
        if not low then return end
        local prop
        if obj==Lighting then prop="GlobalShadows"
        elseif obj:IsA("PostEffect") then prop="Enabled"
        elseif obj:IsA("BasePart") then prop="CastShadow"
        elseif (obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")) and obj:GetAttribute("LowGraphicsOptional")==true then prop="Enabled" end
        if prop then
            if not graphicsSaved[obj] then graphicsSaved[obj]={property=prop,value=obj[prop]} end
            obj[prop]=false
        end
    end
    local function restoreGraphics()
        for obj,saved in pairs(graphicsSaved) do
            if obj.Parent then obj[saved.property]=saved.value end
            graphicsSaved[obj]=nil
        end
    end
    graphicsButton=button(window,"LowGraphics","LOW GRAPHICS: OFF",15,129,280,function()
        low=not low
        graphicsButton.Text=low and "LOW GRAPHICS: ON" or "LOW GRAPHICS: OFF"
        if low then reduce(Lighting) for _,obj in ipairs(game:GetDescendants()) do reduce(obj) end else restoreGraphics() end
    end)
    squadButton=button(window,"ShowSquad","SQUAD PANEL: ON",15,169,280,function()
        squadWanted=not squadWanted
        squadButton.Text=squadWanted and "SQUAD PANEL: ON" or "SQUAD PANEL: OFF"
    end)
    button(window,"ResetLayout","RESET HUD POSITIONS",15,209,280,function()
        for panel,saved in pairs(defaults) do panel.AnchorPoint=saved.anchor panel.Position=saved.position panel:SetAttribute("CustomHUDPosition",false) end
    end)
    button(window,"Close","CLOSE",15,249,280,function() window.Visible=false end)
    local function clampPosition(panel,x,y)
        local size=root.AbsoluteSize
        return math.clamp(x,0,math.max(0,size.X-panel.AbsoluteSize.X)),math.clamp(y,0,math.max(0,size.Y-panel.AbsoluteSize.Y))
    end
    local function registerPanel(panel)
        defaults[panel]={anchor=panel.AnchorPoint,position=panel.Position}
        local handle=Instance.new("TextButton")
        handle.Name,handle.Size,handle.BackgroundColor3="MoveHandle",UDim2.new(1,0,0,22),Color3.fromRGB(196,155,60)
        handle.Text,handle.TextColor3,handle.Font,handle.TextSize="DRAG: "..string.upper(panel.Name),Color3.fromRGB(255,255,235),Enum.Font.GothamBold,12
        handle.ZIndex,handle.Visible,handle.Parent=20,false,panel
        armyStyle(handle,6)
        handles[panel]=handle
        connect(handle.InputBegan,function(input)
            if not editing or (input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch) then return end
            drag={panel=panel,input=input,start=input.Position,origin=panel.AbsolutePosition-root.AbsolutePosition,touch=input.UserInputType==Enum.UserInputType.Touch}
        end)
    end
    for _,panel in ipairs(panels) do registerPanel(panel) end
    connect(UIS.InputChanged,function(input)
        if not drag then return end
        if drag.touch and input~=drag.input then return end
        if not drag.touch and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local point=drag.origin+Vector2.new(input.Position.X-drag.start.X,input.Position.Y-drag.start.Y)
        local x,y=clampPosition(drag.panel,point.X,point.Y)
        drag.panel.AnchorPoint=Vector2.new(0,0)
        drag.panel.Position=UDim2.fromScale(x/math.max(1,root.AbsoluteSize.X),y/math.max(1,root.AbsoluteSize.Y))
        drag.panel:SetAttribute("CustomHUDPosition",true)
    end)
    connect(UIS.InputEnded,function(input)
        if drag and (input==drag.input or (not drag.touch and input.UserInputType==Enum.UserInputType.MouseButton1)) then drag=nil end
    end)
    connect(game.DescendantAdded,function(obj) muteObject(obj) reduce(obj) end)
    -- UI-only preferences. Studio preview is deliberately disabled in live releases.
    local dim,accent=1,nil
    local styleSaved=setmetatable({},{__mode="k"})
    local function themeObject(obj)
        if not obj:IsA("GuiObject") then return end
        local saved=styleSaved[obj]
        if not saved then
            saved={background=obj.BackgroundColor3}
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then saved.text=obj.TextColor3 end
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then saved.image=obj.ImageColor3 end
            styleSaved[obj]=saved
        end
        local base=saved.background
        if accent and obj.BackgroundTransparency<1 then
            local _,_,value=base:ToHSV()
            local hue,saturation=accent:ToHSV()
            base=Color3.fromHSV(hue,saturation*.65,value)
        end
        obj.BackgroundColor3=Color3.new(base.R*dim,base.G*dim,base.B*dim)
        if saved.text then obj.TextColor3=Color3.new(saved.text.R*dim,saved.text.G*dim,saved.text.B*dim) end
        if saved.image then obj.ImageColor3=Color3.new(saved.image.R*dim,saved.image.G*dim,saved.image.B*dim) end
    end
    local function applyTheme()
        for _,panel in ipairs(panels) do
            themeObject(panel)
            for _,obj in ipairs(panel:GetDescendants()) do themeObject(obj) end
        end
    end
    for _,panel in ipairs(panels) do connect(panel.DescendantAdded,function(obj) task.defer(function() if obj.Parent then themeObject(obj) end end) end) end
    window.Size=UDim2.fromOffset(310,410)
    window.ClipsDescendants=false
    local scale=Instance.new("UIScale") scale.Parent=window
    local function fitSettings() scale.Scale=math.min(1,math.max(.45,(root.AbsoluteSize.Y-30)/410),math.max(.45,(root.AbsoluteSize.X-20)/310)) end
    connect(root:GetPropertyChangedSignal("AbsoluteSize"),fitSettings) task.defer(fitSettings)
    local dimLevels={1,.85,.7,.55}
    local dimIndex=1
    local dimButton
    dimButton=button(window,"DimHUD","HUD BRIGHTNESS: 100%",15,249,280,function()
        dimIndex=dimIndex%#dimLevels+1 dim=dimLevels[dimIndex]
        dimButton.Text="HUD BRIGHTNESS: "..math.floor(dim*100+.5).."%"
        applyTheme()
    end)
    local wheel=Instance.new("Frame")
    wheel.Name,wheel.Size,wheel.Position,wheel.Visible="ColorWheel",UDim2.fromOffset(154,154),UDim2.fromOffset(78,49),false
    wheel.BackgroundColor3=Color3.fromRGB(28,34,30) wheel.ZIndex=40 wheel.Parent=window
    armyStyle(wheel,77)
    local selected=Instance.new("TextLabel")
    selected.Name,selected.Size,selected.Position="ColorPreview",UDim2.fromOffset(52,52),UDim2.fromOffset(51,51)
    selected.BackgroundColor3=Color3.fromRGB(118,145,67) selected.Text="UI" selected.TextColor3=Color3.new(1,1,1)
    selected.Font=Enum.Font.GothamBold selected.ZIndex=43 selected.Parent=wheel armyStyle(selected,26)
    -- Actual radial HSV selector; each swatch supports mouse, touch and gamepad activation.
    for ring=1,3 do for index=0,23 do
        local hue=index/24 local angle=hue*math.pi*2
        local swatch=Instance.new("TextButton")
        swatch.Name="Hue_"..ring.."_"..index swatch.Text="" swatch.Size=UDim2.fromOffset(16,16)
        swatch.AnchorPoint=Vector2.new(.5,.5)
        swatch.Position=UDim2.fromOffset(77+math.cos(angle)*(31+ring*12),77+math.sin(angle)*(31+ring*12))
        local color=Color3.fromHSV(hue,ring/3,1)
        swatch.BackgroundColor3=color swatch.BorderSizePixel=0 swatch.ZIndex=42 swatch.Parent=wheel
        local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(1,0) corner.Parent=swatch
        connect(swatch.Activated,function() accent=color selected.BackgroundColor3=color applyTheme() end)
    end end
    local colorButton
    colorButton=button(window,"UIColor","UI COLOR: STUDIO PREVIEW",15,289,280,function()
        if not game:GetService("RunService"):IsStudio() then
            colorButton.Text="COLOR PASS: COMING AT RELEASE"
            return
        end
        wheel.Visible=not wheel.Visible
    end)
    if not game:GetService("RunService"):IsStudio() then colorButton.Text="UI COLOR: RELEASE PASS (LOCKED)" end
    button(window,"ResetAppearance","RESET UI APPEARANCE",15,329,280,function()
        dimIndex,dim,accent=1,1,nil wheel.Visible=false
        dimButton.Text="HUD BRIGHTNESS: 100%" applyTheme()
    end)
    window.Close.Position=UDim2.fromOffset(15,369)

    local self={}
    function self:RegisterPanel(panel)
        table.insert(panels,panel) registerPanel(panel)
        themeObject(panel) for _,obj in ipairs(panel:GetDescendants()) do themeObject(obj) end
        connect(panel.DescendantAdded,function(obj) task.defer(function() if obj.Parent then themeObject(obj) end end) end)
    end
    function self:IsEditing() return editing end
    function self:ShowSquad() return squadWanted or editing end
    function self:Update()
        open.Text=editing and "DONE" or "SETTINGS"
        -- Re-clamp custom panels after window resize/phone rotation.
        for _,panel in ipairs(panels) do
            if panel:GetAttribute("CustomHUDPosition") then
                local relative=panel.AbsolutePosition-root.AbsolutePosition
                local x,y=clampPosition(panel,relative.X,relative.Y)
                panel.Position=UDim2.fromScale(x/math.max(1,root.AbsoluteSize.X),y/math.max(1,root.AbsoluteSize.Y))
            end
        end
    end
    function self:Destroy()
        for _,c in ipairs(connections) do c:Disconnect() end
        dim,accent=1,nil applyTheme()
        restoreMusic() restoreGraphics() gui:Destroy()
    end
    return self
end
return Settings
