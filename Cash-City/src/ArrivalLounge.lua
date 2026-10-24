-- Original furnishings; native Seats function without per-chair scripts.
local Lounge={}
function Lounge.build(garden,data)
 data=data or require(script.Parent.ArrivalLoungeData)
 local old=garden:FindFirstChild("ArrivalLounge")
 assert(not old or old:GetAttribute("CashCityArrivalLounge")==true,"Preserve manual arrival lounge")
 local model=Instance.new("Model") model.Name="ArrivalLounge" model:SetAttribute("CashCityArrivalLounge",true)
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local function part(class,name,size,cf,color)
  local p=Instance.new(class) p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=Enum.Material.Metal
  p.Anchored=true p.CanCollide=true p.CanTouch=class=="Seat" p.CastShadow=false p.Parent=model return p
 end
 local ok,err=pcall(function()
  for i,a in ipairs(data.seats) do
   local cf=CFrame.new(a.pos[1],a.pos[2],a.pos[3],table.unpack(a.matrix))
   part("Part","LoungeLowPlinth",Vector3.new(6,.3,4),cf*CFrame.new(0,.15,0),Color3.fromRGB(171,173,168))
   for _,x in ipairs({-1.5,1.5}) do
    local seat=part("Seat","ArrivalSeat",Vector3.new(2.8,.3,2.6),cf*CFrame.new(x,1.4,0),Color3.fromRGB(88,104,105))
    seat.Disabled=false
   end
   local back=part("Part","BenchBack",Vector3.new(6,2,.25),cf*CFrame.new(0,2.25,1.35),Color3.fromRGB(112,87,61))
   back.Material=Enum.Material.WoodPlanks
   local planter=part("Part","LoungePlanter",Vector3.new(1.8,1.4,1.8),cf*CFrame.new(-4.5,.7,0),Color3.fromRGB(177,175,164))
   planter.Material=Enum.Material.Concrete
   local soil=part("Part","PlanterSoil",Vector3.new(1.5,.12,1.5),cf*CFrame.new(-4.5,1.43,0),Color3.fromRGB(65,57,42))
   soil.Material=Enum.Material.Ground soil.CanCollide=false
   for _,leaf in ipairs({{-.45,2.05,0,.4},{.4,2.3,.25,-.35},{0,2.6,-.3,.15}}) do
    local foliage=part("Part","OriginalIndoorFoliage",Vector3.new(.7,1.8,.65),cf*CFrame.new(-4.5+leaf[1],leaf[2],leaf[3])*CFrame.Angles(0,0,leaf[4]),Color3.fromRGB(69,100,62))
    foliage.Material=Enum.Material.Grass foliage.CanCollide=false foliage.CanQuery=false
   end
   local lamp=part("Part","ArrivalLight",Vector3.new(.45,4,.45),cf*CFrame.new(4.5,2,0),Color3.fromRGB(190,196,193))
   lamp.CanCollide=false
   local cap=part("Part","ArrivalLightDiffuser",Vector3.new(.8,.3,.8),cf*CFrame.new(4.5,4.05,0),Color3.fromRGB(242,232,207))
   cap.Material=Enum.Material.SmoothPlastic cap.CanCollide=false
   local light=Instance.new("PointLight") light.Color=Color3.fromRGB(255,235,200) light.Brightness=.6 light.Range=14 light.Shadows=false light.Parent=lamp
  end
  local a=data.seats[1] local cf=CFrame.new(a.pos[1],a.pos[2],a.pos[3],table.unpack(a.matrix))
  local sign=part("Part","GenericAtriumSign",Vector3.new(6,2.4,.15),cf*CFrame.new(0,4.2,1.5),Color3.fromRGB(31,42,45))
  sign.CanCollide=false
  for _,face in ipairs({Enum.NormalId.Front,Enum.NormalId.Back}) do
  local surface=Instance.new("SurfaceGui") surface.Face=face surface.CanvasSize=Vector2.new(600,240) surface.LightInfluence=0 surface.Parent=sign
  local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1 label.Text=data.sign label.TextColor3=Color3.fromRGB(238,235,214) label.TextScaled=true label.Font=Enum.Font.GothamMedium label.Parent=surface
  end
 end)
 if not ok then model:Destroy() error(err) end
 if old then old:Destroy() end model.Parent=garden
 return model
end
return Lounge
