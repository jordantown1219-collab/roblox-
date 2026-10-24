local Legacy=require(script.Parent.LegacyArena)
local Config=require(game:GetService("ReplicatedStorage").SmallSignals.Config)
if Config.ActiveMap=="MonroeBlock" then
 local originalBuild=Legacy.build
 Legacy.build=function()
  local preview=workspace:FindFirstChild("DetroitCityPreview") if preview then preview:Destroy() end
  return originalBuild()
 end
 return Legacy
end
local City=require(script.Parent.CityConfig)
local Registry=require(script.Parent.InteractionRegistry)
local Arena={}
local colors={Amber=Color3.fromRGB(255,181,60),Cyan=Color3.fromRGB(55,211,236)}
local function part(parent,name,size,position,color)
 local p=Instance.new("Part")
 p.Name,p.Size,p.Position,p.Color=name,size,position,color
 p.Anchored,p.Parent=true,parent
 return p
end
function Arena.build()
 local preview=workspace:FindFirstChild("DetroitCityPreview")
 if preview then preview:Destroy() end
 Legacy.build()
 local folder=Legacy.folder
 -- Preserve the original staging room outside the real-world map boundary.
 local shift=Vector3.new(-3800,0,-2800)
 local staging=Instance.new("Model") staging.Name="StagingRoom"
 staging.ModelStreamingMode=Enum.ModelStreamingMode.Persistent staging.Parent=folder
 for _,obj in ipairs(folder:GetChildren()) do
  if obj:IsA("BasePart") then
   if obj.Position.Z<150 then obj:Destroy() else obj.Position=obj.Position+shift obj.Parent=staging end
  end
 end
 Arena.lobby=Legacy.lobby+shift
 Arena.folder,Arena.spawns=folder,City.Spawns
 local city=game:GetService("ServerStorage"):WaitForChild("DetroitCityRoot"):Clone()
 city.Parent=folder
 require(script.Parent.CivicFacades).build(city)
 require(script.Parent.CityBlockGenerator).build(city,require(script.Parent.HartPathData))
 require(script.Parent.RenaissanceDetails).build(city)
 require(script.Parent.Wintergarden).build(city)
 require(script.Parent.RenaissanceLobby).build(city)
 require(script.Parent.RiverAccess).build(city)
 require(script.Parent.InteractionWorkshop).build(folder,Arena.lobby)
 local storage=game:GetService("ServerStorage")
 require(script.Parent.CityDetails).build(folder,storage.SpiritArt)
 require(script.Parent.RiverfrontVehicles).build(folder,storage.SUVArt)
 Arena.records=Registry.start(folder)
 Arena.armorPositions={}
 for _,spots in pairs(City.Sockets) do for _,spot in ipairs(spots) do table.insert(Arena.armorPositions,spot) end end
 folder:SetAttribute("MapId",City.MapId)
 return folder
end
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

function Arena.routes(config,onDoor,onExit,onTransit)
 if Arena.interactions then Arena.interactions:Destroy() end
 local folder=Instance.new("Folder") folder.Name,folder.Parent="RoundInteractions",Arena.folder
 Arena.interactions=folder
 local rng=Random.new()
 for _,team in ipairs({"Amber","Cyan"}) do
  local spots=table.clone(City.Sockets[team])
  for i=#spots,2,-1 do local j=rng:NextInteger(1,i) spots[i],spots[j]=spots[j],spots[i] end
  for stage=1,config.Stages do
   local spot=spots[stage]
   local normal=Vector3.new(0,0,1)
   local door,text=doorway(folder,"Door",spot,config.Scales[stage],colors[team],normal)
   door:SetAttribute("Team",team) door:SetAttribute("Stage",stage)
   text.Text=string.upper(team).." SIGNAL "..stage
   local prompt=Instance.new("ProximityPrompt")
   prompt.ActionText,prompt.ObjectText="Enter signal gate",team.." stage "..stage
   prompt.MaxActivationDistance,prompt.HoldDuration=math.max(3,6*config.Scales[stage]),.3
   prompt.Parent=door
   local destination=spot+Vector3.new(0,4*config.Scales[stage+1],4)
   prompt.Triggered:Connect(function(player) onDoor(player,team,stage,door,destination) end)
  end
  local exit=part(folder,"Extraction",Vector3.new(3,.15,3),City.Exits[team],colors[team])
  -- Source sidewalks can cover the flat datum; keep the pad and LOS prompt above them.
  local groundParams=RaycastParams.new()
  groundParams.FilterType=Enum.RaycastFilterType.Include
  groundParams.FilterDescendantsInstances={Arena.folder.DetroitCityRoot}
  local ground=workspace:Raycast(exit.Position+Vector3.new(0,10,0),Vector3.new(0,-20,0),groundParams)
  if ground then exit.Position=ground.Position+Vector3.new(0,exit.Size.Y/2+.05,0) end
  exit:SetAttribute("Team",team)
  local prompt=Instance.new("ProximityPrompt") prompt.ActionText,prompt.ObjectText="Gather here","Team extraction"
  prompt.MaxActivationDistance,prompt.HoldDuration=4,.5 prompt.Parent=exit
  prompt.Triggered:Connect(function(player) onExit(player,team,exit) end)
 end
 for _,team in ipairs({"Amber","Cyan"}) do
  local source=City.Transit[team]
  local dest=City.Transit[team=="Amber" and "Cyan" or "Amber"]+Vector3.new(0,0,4)
  local door,text=doorway(folder,"TransitDoor",source,1,Color3.fromRGB(97,192,160),Vector3.new(0,0,1))
  text.Text="DISTRICT TRANSIT"
  local control=Instance.new("Attachment") control.Position=Vector3.new(0,-2.4,.3) control.Parent=door
  local prompt=Instance.new("ProximityPrompt") prompt.ActionText,prompt.ObjectText="Cross district","Gameplay transit gate"
  prompt.MaxActivationDistance,prompt.HoldDuration=7,.5 prompt.Parent=control
  prompt.Triggered:Connect(function(player) onTransit(player,door,dest) end)
 end
end
return Arena
