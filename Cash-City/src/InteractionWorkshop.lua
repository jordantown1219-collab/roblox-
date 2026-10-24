-- A labeled original workshop in the staging room, not a reconstruction of any Detroit interior.
local CollectionService=game:GetService("CollectionService")
local Workshop={}
function Workshop.build(parent,origin)
 local function part(parent,name,size,position,color,collide)
  local p=Instance.new("Part") p.Name,p.Size,p.Position=name,size,position
  p.Anchored,p.CanCollide,p.Color,p.Parent=true,collide~=false,color or Color3.fromRGB(95,111,77),parent
  return p
 end
 local function assembly(name,center,size,pivot,axis,travel,motion,color)
  local model=Instance.new("Model") model.Name=name model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic model.Parent=parent
  local moving=Instance.new("Model") moving.Name,moving.Parent="Moving",model
  local leaf=part(moving,"Leaf",size,center,color)
  moving.PrimaryPart=leaf
  local hinge=part(model,"MotionPivot",Vector3.new(.1,.1,.1),pivot,nil,false) hinge.Transparency=1
  local control=part(model,"Control",Vector3.new(.25,.25,.25),center+Vector3.new(-size.X/2-3,origin.Y-3-center.Y,4),nil,false)
  control.Transparency=1 control.CanQuery=false hinge.CanQuery=false
  local prompt=Instance.new("ProximityPrompt") prompt.ActionText,prompt.ObjectText="Open",name
  prompt.MaxActivationDistance,prompt.HoldDuration,prompt.RequiresLineOfSight=9,.25,true prompt.Parent=control
  model:SetAttribute("Motion",motion) model:SetAttribute("Axis",axis) model:SetAttribute("Travel",travel)
  model:SetAttribute("Duration",.8) model:SetAttribute("Range",9) model:SetAttribute("LobbyInteraction",true)
  model:SetAttribute("GeometryStatus","Original workshop geometry; motion pivots specified in local assembly")
  CollectionService:AddTag(model,"SSInteractable")
  return model,leaf
 end
 local base=origin-Vector3.new(0,4,0)
 local center=base+Vector3.new(-18,5,-12)
 local door=assembly("Workshop hinged door",center,Vector3.new(6,10,.4),center-Vector3.new(3,0,0),"Y",95,"Hinge",Color3.fromRGB(130,98,64))
 part(door,"LeftFrame",Vector3.new(.5,10.5,.8),center-Vector3.new(3.65,-.25,0))
 part(door,"RightFrame",Vector3.new(.5,10.5,.8),center+Vector3.new(3.4,.25,0))
 part(door,"Header",Vector3.new(7.3,.5,.8),center+Vector3.new(0,5.5,0))
 local wincenter=base+Vector3.new(14,5,-12)
 local window,pane=assembly("Workshop sliding window",wincenter,Vector3.new(5,3,.3),wincenter,"X",5.4,"Slide",Color3.fromRGB(101,170,191))
 pane.Material,pane.Transparency=Enum.Material.Glass,.35
 part(window,"FixedGlass",Vector3.new(5,3,.3),wincenter+Vector3.new(5.5,0,.5),Color3.fromRGB(101,170,191))
 for _,y in ipairs({-1.9,1.9}) do part(window,"WindowRail",Vector3.new(11.4,.4,.8),wincenter+Vector3.new(2.75,y,0)) end
 local drawercenter=base+Vector3.new(20,1.2,13)
 local drawer=assembly("Workshop drawer",drawercenter,Vector3.new(5,1.5,3),drawercenter,"Z",-3.2,"Slide",Color3.fromRGB(137,115,79))
 for _,x in ipairs({-3,3}) do part(drawer,"CabinetSide",Vector3.new(.5,4.5,4),drawercenter+Vector3.new(x,1.4,.5)) end
 part(drawer,"CabinetTop",Vector3.new(6.5,.4,4),drawercenter+Vector3.new(0,3.8,.5))
 local carbase=base+Vector3.new(-16,0,13)
 local car=Instance.new("Model") car.Name,car.ModelStreamingMode,car.Parent="Original parked workshop vehicle",Enum.ModelStreamingMode.Atomic,parent
 part(car,"Chassis",Vector3.new(10,1.4,18),carbase+Vector3.new(0,.8,0),Color3.fromRGB(55,69,78))
 for _,z in ipairs({-6,6}) do part(car,"BodyEnd",Vector3.new(10,3,5.5),carbase+Vector3.new(0,2.5,z),Color3.fromRGB(55,69,78)) end
 part(car,"Roof",Vector3.new(10,.4,7),carbase+Vector3.new(0,5.4,0))
 local doorcenter=carbase+Vector3.new(-5,3.5,0)
 local cardoor=assembly("Parked vehicle driver door",doorcenter,Vector3.new(.3,3,5),doorcenter-Vector3.new(0,0,2.5),"Y",-70,"Hinge",Color3.fromRGB(55,69,78))
 cardoor.Parent=car
 local seat=Instance.new("Seat") seat.Name,seat.Anchored,seat.Size,seat.Position="DriverSeat",true,Vector3.new(2,1,2),carbase+Vector3.new(-2,2,0) seat.Parent=car
 local placard=part(parent,"WorkshopNotice",Vector3.new(18,3,.3),base+Vector3.new(0,10,20),Color3.fromRGB(40,55,34),false)
 local gui=Instance.new("SurfaceGui") gui.Face,gui.CanvasSize=Enum.NormalId.Front,Vector2.new(720,120) gui.Parent=placard
 local text=Instance.new("TextLabel") text.Size,text.BackgroundTransparency=UDim2.fromScale(1,1),1
 text.Text,text.TextColor3,text.Font,text.TextSize="INTERACTION WORKSHOP / ORIGINAL TEST FIXTURES",Color3.fromRGB(245,220,151),Enum.Font.GothamBold,24 text.Parent=gui
end
return Workshop
