-- Reusable geometry only; InteractionRegistry owns validation and motion.
local Components={}
local function dimension(value,default,low,high,label)
 value=value==nil and default or value
 assert(type(value)=="number" and value==value and value>=low and value<=high,"Invalid "..label)
 return value
end
function Components.door(config)
 config=config or {} assert(type(config)=="table","Expected door config")
 local width=dimension(config.apertureWidth,6,5,8,"aperture width")
 local height=dimension(config.apertureHeight,9,8,11,"aperture height")
 local travel=dimension(config.travel,90,75,90,"door travel")
 local duration=dimension(config.duration,.8,.25,2,"duration")
 local color=config.color or Color3.fromRGB(92,109,108)
 assert(typeof(color)=="Color3","Expected Color3")
 local model=Instance.new("Model") model.Name="Original hinged entrance"
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic model.WorldPivot=CFrame.new()
 local function part(parent,name,size,pos,collide)
  local p=Instance.new("Part") p.Name=name p.Size=size p.Position=pos
  p.Anchored=true p.CanCollide=collide p.CanTouch=false p.Color=color
  p.Material=Enum.Material.Metal p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
  p.Parent=parent return p
 end
 local moving=Instance.new("Model") moving.Name="Moving" moving.Parent=model
 local leafWidth=width-.6
 local leaf=part(moving,"Leaf",Vector3.new(leafWidth,height-.3,.28),Vector3.new(0,0,0),true)
 moving.PrimaryPart=leaf
 local handle=part(moving,"Handle",Vector3.new(.14,.65,.14),Vector3.new(leafWidth/2-.45,0,-.24),false)
 handle.Material=Enum.Material.SmoothPlastic handle.Color=Color3.fromRGB(180,183,180)
 local hinge=part(model,"MotionPivot",Vector3.new(.05,.05,.05),Vector3.new(-leafWidth/2,0,0),false)
 hinge.Transparency=1 hinge.CanQuery=false
 -- Just left of the complete sweep, within the jamb gap: ray visible through aperture from either side.
 local control=part(model,"Control",Vector3.new(.05,.05,.05),Vector3.new(-width/2+.05,-.6,-.65),false)
 control.Transparency=1 control.CanQuery=false
 local prompt=Instance.new("ProximityPrompt") prompt.ActionText="Open" prompt.ObjectText="Entrance door"
 prompt.MaxActivationDistance=9 prompt.HoldDuration=.2 prompt.RequiresLineOfSight=true
 prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.GamepadKeyCode=Enum.KeyCode.ButtonX prompt.Parent=control
 model:SetAttribute("Motion","Hinge") model:SetAttribute("Axis","Y") model:SetAttribute("Travel",travel)
 model:SetAttribute("Duration",duration) model:SetAttribute("Range",9)
 model:SetAttribute("ApertureWidth",width) model:SetAttribute("ApertureHeight",height)
 model:SetAttribute("IntegrationStatus","GeometryOnlyAwaitingRegistryAndMultiplayerTest")
 -- Leave LobbyInteraction unset: existing match/team validation remains authoritative.
 game:GetService("CollectionService"):AddTag(model,"SSInteractable")
 return model
end
-- Original two-track training sash; never replaces fixed commercial glazing.
function Components.slidingWindow(config)
 config=config or {} assert(type(config)=="table","Expected window config")
 local width=dimension(config.width,8,6,12,"window width")
 local height=dimension(config.height,5,4,8,"window height")
 local duration=dimension(config.duration,.8,.25,2,"duration")
 local model=Instance.new("Model") model.Name="Original training sliding window"
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic model.WorldPivot=CFrame.new()
 local function part(parent,name,size,pos,collide,glass)
  local p=Instance.new("Part") p.Name=name p.Size=size p.Position=pos
  p.Anchored=true p.CanTouch=false p.CanCollide=collide
  p.Material=glass and Enum.Material.Glass or Enum.Material.Metal
  p.Color=glass and Color3.fromRGB(151,187,196) or Color3.fromRGB(65,68,67)
  p.Transparency=glass and .35 or 0
  p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
  p.Parent=parent return p
 end
 local travel=width/2-.3
 for _,sign in ipairs({-1,1}) do
  part(model,"SideFrame",Vector3.new(.2,height,.8),Vector3.new(sign*(width/2-.1),0,0),true)
  part(model,"Rail",Vector3.new(width-.4,.2,.8),Vector3.new(0,sign*(height/2-.1),0),true)
 end
 -- Parallel tracks separated in Z prevent the moving sash crossing the fixed pane.
 part(model,"FixedPane",Vector3.new(travel,height-.6,.12),Vector3.new(travel/2,0,.18),true,true)
 local moving=Instance.new("Model") moving.Name="Moving" moving.Parent=model
 local sash=part(moving,"Sash",Vector3.new(travel,height-.6,.12),Vector3.new(-travel/2,0,-.18),true,true)
 moving.PrimaryPart=sash
 local pivot=part(model,"MotionPivot",Vector3.new(.05,.05,.05),Vector3.new(0,0,0),false)
 pivot.Transparency=1 pivot.CanQuery=false
 local control=part(model,"Control",Vector3.new(.05,.05,.05),Vector3.new(-width/2+.1,0,-.65),false)
 control.Transparency=1 control.CanQuery=false
 local prompt=Instance.new("ProximityPrompt") prompt.ActionText="Open" prompt.ObjectText="Training sliding window"
 prompt.MaxActivationDistance=9 prompt.HoldDuration=.2 prompt.RequiresLineOfSight=true
 prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.GamepadKeyCode=Enum.KeyCode.ButtonX prompt.Parent=control
 model:SetAttribute("Motion","Slide") model:SetAttribute("Axis","X") model:SetAttribute("Travel",travel)
 model:SetAttribute("Duration",duration) model:SetAttribute("Range",9)
 model:SetAttribute("FrameWidth",width) model:SetAttribute("FrameHeight",height)
 model:SetAttribute("IntegrationStatus","TrainingGeometryAwaitingNativeAcceptance")
 game:GetService("CollectionService"):AddTag(model,"SSInteractable")
 return model
end
return Components
