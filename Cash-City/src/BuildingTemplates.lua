-- Original, unbranded single-story shell factory. No automatic Workspace insertion.
local Templates={}
local function number(value,default,minimum,maximum,label)
 value=value==nil and default or value
 assert(type(value)=="number" and value==value and value>=minimum and value<=maximum,"Invalid "..label)
 return value
end
function Templates.storefront(config,doorTemplate,windowTemplate)
 config=config or {} assert(type(config)=="table","Expected building config")
 local width=number(config.width,32,24,80,"width")
 local depth=number(config.depth,28,16,80,"depth")
 local height=number(config.height,14,12,24,"height")
 local wall=number(config.wallThickness,.6,.3,1,"wall thickness")
 local doorWidth=number(config.doorWidth,6,5,8,"door width")
 local doorHeight=number(config.doorHeight,9,8,11,"door height")
 assert(doorHeight<height-1,"Door needs a structural header")
 assert(config.stories==nil or config.stories==1,"Only single-story storefront is supported")
 local material=Enum.Material[config.material or "Brick"]
 assert(material,"Unknown wall material")
 local color=config.color or Color3.fromRGB(151,111,85)
 assert(typeof(color)=="Color3","Expected Color3 wall color")
 local cf=config.cframe or CFrame.new()
 assert(typeof(cf)=="CFrame","Expected building CFrame")
 for _,v in ipairs({cf:GetComponents()}) do assert(v==v and math.abs(v)<math.huge,"Invalid building CFrame") end
 if doorTemplate then
  assert(typeof(doorTemplate)=="Instance" and doorTemplate:IsA("Model") and doorTemplate.Archivable,"Invalid door component")
  local moving=doorTemplate:FindFirstChild("Moving")
  local pivot=doorTemplate:FindFirstChild("MotionPivot")
  local control=doorTemplate:FindFirstChild("Control")
  assert(moving and moving:IsA("Model") and pivot and pivot:IsA("BasePart") and control and control:IsA("BasePart") and control:FindFirstChildOfClass("ProximityPrompt"),"Door must use InteractionRegistry contract")
  local motion,axis,travel=doorTemplate:GetAttribute("Motion"),doorTemplate:GetAttribute("Axis"),doorTemplate:GetAttribute("Travel")
  assert((motion=="Hinge" or motion=="Slide") and (axis=="X" or axis=="Y" or axis=="Z") and type(travel)=="number" and travel==travel and math.abs(travel)<math.huge,"Invalid door motion")
  local _,bounds=moving:GetBoundingBox()
  assert(bounds.X<=doorWidth and bounds.Y<=doorHeight,"Door panel exceeds aperture")
 end
 local windowWidth=width/2-doorWidth/2-3
 local bottom,top=3.5,math.min(10,height-2)
 local frameWidth,frameHeight
 if windowTemplate then
  assert(typeof(windowTemplate)=="Instance" and windowTemplate:IsA("Model") and windowTemplate.Archivable,"Invalid window component")
  frameWidth=number(windowTemplate:GetAttribute("FrameWidth"),nil,6,12,"window frame width")
  frameHeight=number(windowTemplate:GetAttribute("FrameHeight"),nil,4,8,"window frame height")
  assert(frameWidth<=windowWidth and frameHeight<=top-bottom,"Window component does not fit storefront aperture")
  local moving=windowTemplate:FindFirstChild("Moving")
  local pivot=windowTemplate:FindFirstChild("MotionPivot")
  local control=windowTemplate:FindFirstChild("Control")
  local travel=windowTemplate:GetAttribute("Travel")
  assert(moving and moving:IsA("Model") and pivot and pivot:IsA("BasePart") and control and control:IsA("BasePart") and control:FindFirstChildOfClass("ProximityPrompt"),"Window must use InteractionRegistry contract")
  assert(windowTemplate:GetAttribute("Motion")=="Slide" and windowTemplate:GetAttribute("Axis")=="X" and type(travel)=="number" and travel==travel and math.abs(travel-(frameWidth/2-.3))<.0001,"Invalid window motion")
  local origin=windowTemplate:GetPivot()
  local motionFrame=origin:ToObjectSpace(moving:GetPivot())
  assert((motionFrame.RightVector-Vector3.new(1,0,0)).Magnitude<.0001 and (motionFrame.UpVector-Vector3.new(0,1,0)).Magnitude<.0001,"Window slide axes must align with component")
  for _,obj in ipairs(windowTemplate:GetDescendants()) do
   assert(obj.Archivable and not obj:IsA("LuaSourceContainer"),"Window descendants must clone completely without scripts")
   if obj:IsA("BasePart") then
    assert(obj.Anchored,"Window component must be anchored")
    local localFrame=origin:ToObjectSpace(obj.CFrame)
    for _,alpha in ipairs({0,1}) do
     local shifted=localFrame
     if obj:IsDescendantOf(moving) then shifted=CFrame.new(travel*alpha,0,0)*localFrame end
     for _,x in ipairs({-.5,.5}) do for _,y in ipairs({-.5,.5}) do for _,z in ipairs({-.5,.5}) do
      local corner=shifted*Vector3.new(obj.Size.X*x,obj.Size.Y*y,obj.Size.Z*z)
      assert(math.abs(corner.X)<=frameWidth/2+.0001 and math.abs(corner.Y)<=frameHeight/2+.0001 and math.abs(corner.Z)<=1,"Window geometry/sweep exceeds frame")
     end end end
    end
   end
  end
 end
 local model=Instance.new("Model") model.Name="OriginalStorefront"
 model.WorldPivot=cf
 model:SetAttribute("BuildingTemplateVersion",1)
 model:SetAttribute("DoorIntegration",doorTemplate and "ComponentProvidedAwaitingRegistry" or "OpenApertureNoDoor")
 model:SetAttribute("AccessibleShell",true)
 if windowTemplate then model:SetAttribute("WindowIntegration","ComponentsProvidedAwaitingRegistry") end
 local function part(name,size,pos,mat,col,collide,trans)
  local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf*CFrame.new(pos)
  p.Anchored=true p.CanTouch=false p.CanCollide=collide~=false
  p.Material=mat or material p.Color=col or color p.Transparency=trans or 0
  p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=model
  return p
 end
 local function panel(name,x1,x2,y1,y2,z)
  part(name,Vector3.new(x2-x1,y2-y1,wall),Vector3.new((x1+x2)/2,(y1+y2)/2,z))
 end
 part("Floor",Vector3.new(width,1,depth),Vector3.new(0,-.5,0),Enum.Material.Concrete,Color3.fromRGB(153,151,143))
 part("Roof",Vector3.new(width+1,1,depth+1),Vector3.new(0,height+.5,0),Enum.Material.Concrete,Color3.fromRGB(105,106,105))
 part("RearWall",Vector3.new(width,height,wall),Vector3.new(0,height/2,depth/2))
 for _,sign in ipairs({-1,1}) do
  part("SideWall",Vector3.new(wall,height,depth),Vector3.new(sign*width/2,height/2,0))
 end
 local front=-depth/2
 local edge=width/2
 local doorEdge=doorWidth/2
 panel("DoorHeader",-doorEdge,doorEdge,doorHeight,height,front)
 for _,sign in ipairs({-1,1}) do
  local inner=doorEdge+1.5 local outer=inner+windowWidth
  local x1,x2=sign==1 and inner or -outer,sign==1 and outer or -inner
  local pier1,pier2=sign==1 and doorEdge or -inner,sign==1 and inner or -doorEdge
  panel("DoorPier",pier1,pier2,0,height,front)
  local end1,end2=sign==1 and outer or -edge,sign==1 and edge or -outer
  panel("CornerPier",end1,end2,0,height,front)
  panel("WindowSillWall",x1,x2,0,bottom,front)
  panel("WindowHeader",x1,x2,top,height,front)
  if windowTemplate then
   local center=(x1+x2)/2 local middle=(bottom+top)/2
   local left,right=center-frameWidth/2,center+frameWidth/2
   local lower,upper=middle-frameHeight/2,middle+frameHeight/2
   if left>x1 then panel("WindowInfill",x1,left,bottom,top,front) end
   if right<x2 then panel("WindowInfill",right,x2,bottom,top,front) end
   if lower>bottom then panel("WindowInfill",left,right,bottom,lower,front) end
   if upper<top then panel("WindowInfill",left,right,upper,top,front) end
   local window=windowTemplate:Clone() window.Name=sign==1 and "RightSlidingWindow" or "LeftSlidingWindow"
   window:PivotTo(cf*CFrame.new(center,middle,front)) window.Parent=model
   game:GetService("CollectionService"):AddTag(window,"SSInteractable")
  else
   part("WindowPane",Vector3.new(x2-x1,top-bottom,.15),Vector3.new((x1+x2)/2,(top+bottom)/2,front),Enum.Material.Glass,Color3.fromRGB(151,187,196),true,.45)
   part("WindowTrim",Vector3.new(x2-x1+.2,.18,wall+.15),Vector3.new((x1+x2)/2,bottom,front),Enum.Material.Metal,Color3.fromRGB(65,68,67),false)
  end
 end
 if doorTemplate then
  local door=doorTemplate:Clone() door.Name="EntranceDoor"
  door:PivotTo(cf*CFrame.new(0,doorHeight/2,front)) door.Parent=model
  game:GetService("CollectionService"):AddTag(door,"SSInteractable")
 end
 return model
end
return Templates
