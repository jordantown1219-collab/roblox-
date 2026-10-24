local Arena = {}
local stretch = require(game:GetService("ReplicatedStorage").SmallSignals.Config).MapStretch
local colors = {Amber = Color3.fromRGB(255, 181, 60), Cyan = Color3.fromRGB(55, 211, 236)}
local function part(parent, name, size, position, color)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = Vector3.new(size.X*stretch,size.Y,size.Z*stretch)
    p.Position = Vector3.new(position.X*stretch,position.Y,position.Z*stretch)
    p.Anchored, p.Color, p.TopSurface, p.BottomSurface = true, color, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end
function Arena.build()
    local old = workspace:FindFirstChild("SmallSignalsArena")
    if old then old:Destroy() end
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "SmallSignalsArena", workspace
    local gray = Color3.fromRGB(47, 55, 68)
    local brick = Color3.fromRGB(123, 72, 57)
    part(folder,"BlockFoundation",Vector3.new(160,2,120),Vector3.new(0,-1,0),gray)
    part(folder,"MonroeStreet",Vector3.new(156,0.05,36),Vector3.new(0,0.03,0),Color3.fromRGB(35,39,45))
    for _,z in ipairs({-20,20}) do
        part(folder,"Sidewalk",Vector3.new(156,0.12,6),Vector3.new(0,0.08,z),Color3.fromRGB(153,149,137))
    end
    -- A compact original layout inspired by Greektown's historic streetscape.
    -- Street, six enterable shops, gaps and rear alleys all share one small block.
    for _,sign in ipairs({-1,1}) do
        local z=sign*39
        for i,x in ipairs({-46,0,46}) do
            local tint= i==2 and Color3.fromRGB(161,139,101) or brick
            part(folder,"StoreBack",Vector3.new(34,22,1),Vector3.new(x,11,sign*54),tint)
            for _,dx in ipairs({-17,17}) do
                part(folder,"StoreSide",Vector3.new(1,22,30),Vector3.new(x+dx,11,z),tint)
            end
            -- A full-size doorway stays open in the street-facing facade.
            for _,dx in ipairs({-11,11}) do
                part(folder,"Storefront",Vector3.new(12,22,1),Vector3.new(x+dx,11,sign*24),tint)
                part(folder,"ShopWindow",Vector3.new(7,5,0.2),Vector3.new(x+dx,6,sign*23.4),Color3.fromRGB(75,140,160))
            end
            part(folder,"DoorLintel",Vector3.new(10,12,1),Vector3.new(x,16,sign*24),tint)
            part(folder,"Awning",Vector3.new(35,0.5,4),Vector3.new(x,10,sign*22),Color3.fromRGB(34,95,103))
            part(folder,"Cornice",Vector3.new(35,1,31),Vector3.new(x,22,z),Color3.fromRGB(163,153,133))
            -- No roof in the blockout: easy editor inspection and stable camera.
            part(folder,"ShopCounter",Vector3.new(10,4,3),Vector3.new(x-7,2,z),Color3.fromRGB(83,65,49))
            part(folder,"Shelf",Vector3.new(2,8,12),Vector3.new(x+13,4,z),Color3.fromRGB(75,67,55))
            part(folder,"TinyIndoorCover",Vector3.new(1.8,1.2,2),Vector3.new(x,0.6,z+4),gray)
            for _,dx in ipairs({-10,0,10}) do
                part(folder,"UpperWindow",Vector3.new(4,5,0.2),Vector3.new(x+dx,16,sign*23.4),Color3.fromRGB(81,122,135))
            end
        end
    end
    -- Boundary walls carry randomized door sockets; rear alleys remain open.
    part(folder,"NorthBoundary",Vector3.new(160,20,2),Vector3.new(0,10,-61),brick)
    part(folder,"SouthBoundary",Vector3.new(160,20,2),Vector3.new(0,10,61),brick)
    for _,x in ipairs({-81,81}) do
        part(folder,"EndBoundary",Vector3.new(2,20,120),Vector3.new(x,10,0),gray)
    end
    -- Parked-car blockouts interrupt the longest street sight lines.
    for _,xz in ipairs({{-25,-11},{25,11}}) do
        part(folder,"ParkedCar",Vector3.new(13,3,6),Vector3.new(xz[1],1.5,xz[2]),Color3.fromRGB(73,93,103))
        part(folder,"CarCabin",Vector3.new(7,2,5.5),Vector3.new(xz[1],4,xz[2]),Color3.fromRGB(40,59,70))
    end
    for _,xz in ipairs({{-69,-30},{69,30},{-23,43},{23,-43}}) do
        part(folder,"AlleyCrate",Vector3.new(3,3,3),Vector3.new(xz[1],1.5,xz[2]),Color3.fromRGB(87,78,63))
    end
    -- Covered, tiny-only passages at the ends of the sidewalks.
    for _,x in ipairs({-73,73}) do
        part(folder,"TinyPassageRoof",Vector3.new(3,0.3,12),Vector3.new(x,1.8,0),gray)
        for _,dx in ipairs({-1.6,1.6}) do
            part(folder,"TinyPassageSide",Vector3.new(0.2,1.8,12),Vector3.new(x+dx,0.9,0),gray)
        end
    end
    Arena.folder = folder
    Arena.spawns={Amber=Vector3.new(-72*stretch,4,-43*stretch),Cyan=Vector3.new(72*stretch,4,43*stretch)}
    for name,pos in pairs(Arena.spawns) do
        local pad=part(folder,name.."Spawn",Vector3.new(10,0.1,10),Vector3.new(pos.X/stretch,0.06,pos.Z/stretch),colors[name])
        pad.Material=Enum.Material.Neon
    end
    -- Medium cartoon barracks: 90 x 72 studs at the current 1.5 map stretch.
    local olive=Color3.fromRGB(92,115,57)
    local khaki=Color3.fromRGB(202,183,118)
    local dark=Color3.fromRGB(42,57,33)
    local lobby=part(folder,"Lobby",Vector3.new(60,2,48),Vector3.new(0,-1,180),khaki)
    Arena.lobby=lobby.Position+Vector3.new(0,5,0)
    for _,wall in ipairs({{0,155,62,2},{0,205,62,2},{-31,180,2,48},{31,180,2,48}}) do
        part(folder,"BarracksWall",Vector3.new(wall[3],22,wall[4]),Vector3.new(wall[1],11,wall[2]),olive)
        part(folder,"BarracksTrim",Vector3.new(wall[3],1,wall[4]),Vector3.new(wall[1],3,wall[2]),khaki)
    end
    local roof=part(folder,"BarracksRoof",Vector3.new(64,1,52),Vector3.new(0,22.5,180),dark)
    local light=Instance.new("PointLight")
    light.Brightness,light.Range,light.Shadows=1.5,70,false
    light.Color=Color3.fromRGB(255,239,198)
    light.Parent=roof
    -- A clear central deployment lane leaves the spawn and menu area uncluttered.
    for _,x in ipairs({-3,3}) do
        part(folder,"DeploymentStripe",Vector3.new(0.3,0.06,36),Vector3.new(x,0.04,180),Color3.fromRGB(247,207,83))
    end
    part(folder,"AssemblyMat",Vector3.new(18,0.08,12),Vector3.new(0,0.06,180),olive)
    for _,x in ipairs({-23,23}) do
        for _,z in ipairs({168,192}) do
            part(folder,"SupplyCrate",Vector3.new(5,4,5),Vector3.new(x,2,z),olive)
            part(folder,"CrateBand",Vector3.new(5.2,0.5,5.2),Vector3.new(x,2,z),khaki)
        end
        part(folder,"BarracksBench",Vector3.new(3,1,14),Vector3.new(x,2.5,180),khaki)
        for _,z in ipairs({175,185}) do
            part(folder,"BenchLeg",Vector3.new(2,2,1),Vector3.new(x,1,z),dark)
        end
    end
    local board=part(folder,"CommandBoard",Vector3.new(24,7,0.3),Vector3.new(0,12,156.2),dark)
    local sign=Instance.new("SurfaceGui")
    sign.Face,sign.CanvasSize=Enum.NormalId.Back,Vector2.new(720,210)
    sign.Parent=board
    local heading=Instance.new("TextLabel")
    heading.Size,heading.BackgroundTransparency=UDim2.fromScale(1,1),1
    heading.Text="★ SMALL SIGNALS ★\nSQUAD UP • GEAR UP • DEPLOY"
    heading.TextColor3,heading.Font,heading.TextSize=Color3.fromRGB(250,207,87),Enum.Font.FredokaOne,42
    heading.Parent=sign
    -- Decorative windows only: no openings through the waiting-room boundary.
    for _,x in ipairs({-18,18}) do
        part(folder,"BarracksWindow",Vector3.new(8,5,0.25),Vector3.new(x,12,203.8),Color3.fromRGB(100,185,205))
        part(folder,"WindowCrossbar",Vector3.new(0.35,5,0.3),Vector3.new(x,12,203.6),dark)
    end
    return folder
end
-- Door parts use character dimensions, independent of the map footprint stretch.
local function doorway(parent,name,position,scale,color,normal)
    local slab=Instance.new("Part")
    slab.Name,slab.Anchored,slab.CanCollide=name,true,false
    slab.Size=Vector3.new(4.2,7.5,0.35)*scale
    slab.Position=position+Vector3.new(0,3.75*scale,0)
    slab.Color,slab.Material=color,Enum.Material.WoodPlanks
    slab.Parent=parent
    local function detail(name,size,offset,tint)
        local piece=Instance.new("Part")
        piece.Name,piece.Size,piece.Position=name,size*scale,slab.Position+offset*scale
        piece.Anchored,piece.CanCollide,piece.CanQuery=true,false,false
        piece.Color= tint
        piece.Material=Enum.Material.Metal
        piece.Parent=slab
    end
    local frameColor=Color3.fromRGB(42,46,43)
    detail("LeftJamb",Vector3.new(0.3,7.8,0.65),Vector3.new(-2.25,0.15,0),frameColor)
    detail("RightJamb",Vector3.new(0.3,7.8,0.65),Vector3.new(2.25,0.15,0),frameColor)
    detail("Header",Vector3.new(4.8,0.3,0.65),Vector3.new(0,4.2,0),frameColor)
    detail("UpperPanel",Vector3.new(3.3,2.5,0.12),Vector3.new(0,1.65,normal.Z*0.23),Color3.fromRGB(61,69,58))
    detail("LowerPanel",Vector3.new(3.3,2.3,0.12),Vector3.new(0,-1.45,normal.Z*0.23),Color3.fromRGB(61,69,58))
    detail("Handle",Vector3.new(0.18,0.6,0.3),Vector3.new(1.45,0,normal.Z*0.45),Color3.fromRGB(215,181,103))
    local sign=Instance.new("BillboardGui")
    sign.Name,sign.Size,sign.StudsOffset="DoorSign",UDim2.fromOffset(180,40),Vector3.new(0,5*scale,0)
    sign.AlwaysOnTop,sign.MaxDistance=false,60
    sign.Parent=slab
    local text=Instance.new("TextLabel")
    text.Size,text.BackgroundTransparency=UDim2.fromScale(1,1),0.25
    text.BackgroundColor3,text.TextColor3=frameColor,color
    text.Font,text.TextSize=Enum.Font.GothamBold,14
    text.Text="DOOR"
    text.Parent=sign
    return slab,text
end
function Arena.routes(config, onDoor, onExit, onTransit)
    if Arena.interactions then Arena.interactions:Destroy() end
    local folder=Instance.new("Folder")
    folder.Name,folder.Parent="RoundInteractions",Arena.folder
    Arena.interactions=folder
    local candidates={}
    for _,x in ipairs({-69,-63,-23,0,23,63,69}) do
        table.insert(candidates,{Vector3.new(x*stretch,0,-59.5*stretch),Vector3.new(0,0,1)})
        table.insert(candidates,{Vector3.new(x*stretch,0,59.5*stretch),Vector3.new(0,0,-1)})
    end
    local rng=Random.new()
    for i=#candidates,2,-1 do
        local j=rng:NextInteger(1,i)
        candidates[i],candidates[j]=candidates[j],candidates[i]
    end
    local index=0
    for _,team in ipairs({"Amber","Cyan"}) do
        for stage=1,config.Stages do
            index=index+1
            local spot,normal=candidates[index][1],candidates[index][2]
            local scale=config.Scales[stage]
            local door,text=doorway(folder,"Door",spot,scale,colors[team],normal)
            door:SetAttribute("Team",team)
            door:SetAttribute("Stage",stage)
            text.Text=string.upper(team).." / DOOR "..stage
            local prompt=Instance.new("ProximityPrompt")
            prompt.ActionText,prompt.ObjectText="Enter",team.." door "..stage
            prompt.MaxActivationDistance,prompt.HoldDuration,prompt.RequiresLineOfSight=math.max(3,6*scale),0.3,true
            prompt.Parent=door
            local destination=spot+normal*4+Vector3.new(0,4*config.Scales[stage+1],0)
            prompt.Triggered:Connect(function(player) onDoor(player,team,stage,door,destination) end)
        end
        local x=team=="Amber" and -72 or 72
        local exit=part(folder,"Extraction",Vector3.new(2.5,0.15,2.5),Vector3.new(x,0.1,team=="Amber" and 44 or -44),colors[team])
        exit.Material=Enum.Material.Neon
        exit:SetAttribute("Team",team)
        local prompt=Instance.new("ProximityPrompt")
        prompt.ActionText,prompt.ObjectText="Gather here","Team extraction"
        prompt.MaxActivationDistance,prompt.HoldDuration=4,0.5
        prompt.Parent=exit
        prompt.Triggered:Connect(function(player) onExit(player,team,exit) end)
    end
    -- A public pair is usable at every size and never advances the required sequence.
    local a=Vector3.new(-69*stretch,0,-10*stretch)
    local b=Vector3.new(69*stretch,0,10*stretch)
    for _,pair in ipairs({{a,b},{b,a}}) do
        local door,text=doorway(folder,"TransitDoor",pair[1],1,Color3.fromRGB(97,192,160),Vector3.new(0,0,1))
        text.Text="CROSS-BLOCK TRANSIT"
        local prompt=Instance.new("ProximityPrompt")
        prompt.ActionText,prompt.ObjectText="Cross map","Transit door - any size"
        prompt.MaxActivationDistance,prompt.HoldDuration=7,0.5
        -- Anchor near the ground so smallest avatars can reach it.
        local attachment=Instance.new("Attachment")
        attachment.Position=Vector3.new(0,-2.4,0.3)
        attachment.Parent=door
        prompt.Parent=attachment
        prompt.Triggered:Connect(function(player) onTransit(player,door,pair[2]+Vector3.new(0,0,5)) end)
    end
end
return Arena
