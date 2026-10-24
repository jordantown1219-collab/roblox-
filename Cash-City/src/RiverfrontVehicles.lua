-- Native constraint chassis. Client sends controls; server verifies the seated driver.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Vehicles={}
local cars={}
local function finite(n) return typeof(n)=="number" and n==n and math.abs(n)<=1 end
function Vehicles.build(parent,template)
 local remote=game.ReplicatedStorage.SmallSignals:FindFirstChild("VehicleControl") or Instance.new("RemoteEvent") remote.Name="VehicleControl" remote.Parent=game.ReplicatedStorage.SmallSignals
 local function make(name,position,yaw,driveable)
  local car=Instance.new("Model") car.Name=name car.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  car:SetAttribute("RiverfrontVehicle",true) car:SetAttribute("Driveable",driveable)
  local home=CFrame.new(position)*CFrame.Angles(0,math.rad(yaw),0)
  local function part(label,size,cf,collide)
   local p=Instance.new("Part") p.Name,p.Size,p.CFrame=label,size,home*cf
   p.Transparency,p.Anchored,p.CanCollide=1,not driveable,collide
   p.CanTouch=false p.Parent=car return p
  end
  local chassis=part("Chassis",Vector3.new(5.5,.5,9.8),CFrame.new(0,-1.25,0),true)
  chassis.CustomPhysicalProperties=PhysicalProperties.new(2,.5,.05)
  car.PrimaryPart=chassis
  local function weld(p)
   local w=Instance.new("WeldConstraint") w.Part0,w.Part1,w.Parent=chassis,p,chassis
   p.Massless=true
  end
  local art=template:Clone() art.Name="Bodywork" art.Parent=car
  local wheels={}
  for _,p in ipairs(art:GetDescendants()) do
   if p:IsA("BasePart") then
    local relative=p.CFrame
    p.CFrame=home*relative p.Anchored=not driveable p.CanTouch=false
    if p.Name:find("wheel") then table.insert(wheels,{part=p,cf=relative})
    else p.CanCollide=false weld(p) end
   end
  end
  -- Invisible impact proxies leave the passenger cabin open.
  for _,shape in ipairs({{Vector3.new(6.4,1.1,2.6),CFrame.new(0,-.65,-4.5)},{Vector3.new(6.4,1.1,2.6),CFrame.new(0,-.65,4.5)}}) do weld(part("Impact body",shape[1],shape[2],true)) end
  local motors,steering={},{}
  local function attachment(p,cf,axis)
   local a=Instance.new("Attachment") a.CFrame=cf a.Axis=axis a.Parent=p return a
  end
  for _,wheel in ipairs(wheels) do
   local visual,cf=wheel.part,wheel.cf
   if not driveable then visual.CanCollide=false weld(visual)
   else
    visual.CanCollide=false visual.Massless=true
    local radius=visual.Size.Y/2
    local tire=part("Tire collision",Vector3.new(visual.Size.X,radius*2,radius*2),cf,true)
    tire.Shape=Enum.PartType.Cylinder
    tire.CustomPhysicalProperties=PhysicalProperties.new(.8,1.3,.02)
    local visualWeld=Instance.new("WeldConstraint") visualWeld.Part0,visualWeld.Part1,visualWeld.Parent=tire,visual,tire
    local knuckle=part("Wheel hub",Vector3.new(.3,.3,.3),cf,false) knuckle.Massless=true
    if visual.Name:find("front") then
     local steer=Instance.new("HingeConstraint")
     steer.Name="Steering" steer.Attachment0=attachment(chassis,chassis.CFrame:ToObjectSpace(home*cf),Vector3.yAxis)
     steer.Attachment1=attachment(knuckle,CFrame.identity,Vector3.yAxis)
     steer.ActuatorType=Enum.ActuatorType.Servo steer.ServoMaxTorque=18000 steer.AngularSpeed=7
     steer.LimitsEnabled=true steer.LowerAngle=-32 steer.UpperAngle=32 steer.Parent=chassis
     table.insert(steering,steer)
    else weld(knuckle) end
    local motor=Instance.new("HingeConstraint") motor.Name="WheelMotor"
    motor.Attachment0=attachment(knuckle,CFrame.identity,Vector3.xAxis)
    motor.Attachment1=attachment(tire,CFrame.identity,Vector3.xAxis)
    motor.ActuatorType=Enum.ActuatorType.Motor motor.MotorMaxTorque=9000 motor.MotorMaxAcceleration=35 motor.Parent=knuckle
    table.insert(motors,motor)
    for _,body in ipairs(car:GetChildren()) do if body:IsA("BasePart") and body~=tire then
     local nc=Instance.new("NoCollisionConstraint") nc.Part0,nc.Part1,nc.Parent=tire,body,tire
    end end
   end
  end
  local lights={}
  for _,x in ipairs({-2.55,2.55}) do
   local lamp=part("Headlamp",Vector3.new(.7,.16,.12),CFrame.new(x,-.15,-6.02),false)
   lamp.Transparency=0 lamp.Material=Enum.Material.Neon lamp.Color=Color3.fromRGB(234,242,255) weld(lamp)
   local spot=Instance.new("SpotLight") spot.Face=Enum.NormalId.Front spot.Range=48 spot.Angle=75 spot.Brightness=2 spot.Enabled=false spot.Parent=lamp table.insert(lights,spot)
   local tail=part("Brake lamp",Vector3.new(.7,.18,.12),CFrame.new(x,-.05,6.02),false)
   tail.Transparency=0 tail.Material=Enum.Material.Neon tail.Color=Color3.fromRGB(120,20,16) weld(tail)
   table.insert(lights,tail)
  end
  car:SetAttribute("LightsOn",false)
  if driveable then
   local seat=Instance.new("VehicleSeat") seat.Name="DriverSeat" seat.Size=Vector3.new(1.6,.5,1.7)
   seat.CFrame=home*CFrame.new(-1.3,-.7,-.75) seat.Transparency=1 seat.CanCollide=false seat.CanTouch=false seat.Anchored=false seat.HeadsUpDisplay=false seat.Disabled=false seat.Parent=car weld(seat)
   local control=part("Driver entry",Vector3.new(.2,.2,.2),CFrame.new(-4,-.6,-.7),false) weld(control)
   local prompt=Instance.new("ProximityPrompt") prompt.ActionText,prompt.ObjectText="Drive","Riverfront SUV"
   prompt.MaxActivationDistance=8 prompt.RequiresLineOfSight=false prompt.HoldDuration=.35 prompt.Parent=control
   local engine=Instance.new("Sound") engine.Name="Engine" engine.SoundId="rbxassetid://80317022777602" engine.Volume=.35 engine.Looped=true engine.RollOffMaxDistance=100 engine.Parent=chassis
   local horn=Instance.new("Sound") horn.Name="Horn" horn.SoundId="rbxassetid://127513531122725" horn.Volume=.5 horn.RollOffMaxDistance=120 horn.Parent=chassis
   local r={car=car,seat=seat,chassis=chassis,home=chassis.CFrame,motors=motors,steering=steering,lights=lights,engine=engine,horn=horn,throttle=0,steer=0,brake=true,last=-100,controlAt=0}
   cars[car]=r
   prompt.Triggered:Connect(function(p)
    local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if not h or h.Health<=0 or not root or (root.Position-control.Position).Magnitude>9 or seat.Occupant or p:GetAttribute("Downed") or (p:GetAttribute("Scale") or 1)~=1 then return end
    seat:Sit(h)
   end)
   seat:GetPropertyChangedSignal("Occupant"):Connect(function()
    r.throttle,r.steer,r.brake=0,0,true prompt.Enabled=seat.Occupant==nil
    if seat.Occupant then
     seat.Occupant:UnequipTools()
     local p=Players:GetPlayerFromCharacter(seat.Occupant.Parent)
     pcall(function() chassis:SetNetworkOwner(p) end) engine:Play()
    else
     pcall(function() chassis:SetNetworkOwner(nil) end) engine:Stop()
    end
   end)
  end
  car.Parent=parent
  return car
 end
 make("Riverfront SUV",Vector3.new(-1420,3.8,315),15,true)
 make("Parked SUV - graphite",Vector3.new(-1220,3.7,30),90,false)
 make("Parked SUV - riverwalk",Vector3.new(-900,3.7,480),90,false)
 remote.OnServerEvent:Connect(function(p,car,action,a,b,brake)
  local r=cars[car] local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  if not r or not h or h.Health<=0 or r.seat.Occupant~=h or p:GetAttribute("Downed") or (p:GetAttribute("Scale") or 1)~=1 then return end
  local now=os.clock()
  if action=="Drive" then
   if now-r.last<.04 or not finite(a) or not finite(b) or typeof(brake)~="boolean" then return end
   r.last,r.controlAt=now,now r.throttle,r.steer,r.brake=a,b,brake
  elseif action=="Lights" and now-(r.lightsAt or -100)>.3 then
   r.lightsAt=now car:SetAttribute("LightsOn",not car:GetAttribute("LightsOn"))
  elseif action=="Horn" and now-(r.hornAt or -100)>1 then r.hornAt=now r.horn:Play()
  elseif action=="Exit" then
   h.Sit=false
   task.defer(function() if p.Character and h.Parent and not h.Sit then p.Character:PivotTo(r.chassis.CFrame*CFrame.new(-5,2,0)) end end)
  elseif action=="Reset" and now-(r.resetAt or -100)>3 then
   r.resetAt=now car:PivotTo(r.home+Vector3.new(0,2,0))
   r.chassis.AssemblyLinearVelocity=Vector3.zero r.chassis.AssemblyAngularVelocity=Vector3.zero
  end
 end)
 RunService.Heartbeat:Connect(function()
  for car,r in pairs(cars) do
   if not car.Parent then cars[car]=nil
   else
    if os.clock()-r.controlAt>.5 or not r.seat.Occupant then r.throttle,r.steer,r.brake=0,0,true end
    local occupant=r.seat.Occupant
    if occupant then
     local driver=Players:GetPlayerFromCharacter(occupant.Parent)
     if not driver or occupant.Health<=0 or driver:GetAttribute("Downed") or (driver:GetAttribute("Scale") or 1)~=1 then occupant.Sit=false end
    end
    local speed=r.chassis.AssemblyLinearVelocity.Magnitude
    car:SetAttribute("Speed",math.floor(speed+.5))
    for _,motor in ipairs(r.motors) do motor.AngularVelocity=r.brake and 0 or -r.throttle*23 motor.MotorMaxTorque=r.brake and 18000 or 9000 end
    for _,steer in ipairs(r.steering) do steer.TargetAngle=-r.steer*math.max(12,32-speed*.25) end
    for _,lamp in ipairs(r.lights) do
     if lamp:IsA("SpotLight") then lamp.Enabled=car:GetAttribute("LightsOn")
     else lamp.Color=r.brake and Color3.fromRGB(255,35,20) or Color3.fromRGB(120,20,16) end
    end
    r.engine.PlaybackSpeed=.8+math.min(speed/45,1.2)
    if r.chassis.Position.Y< -50 then
     car:PivotTo(CFrame.new(-1420,6,315)*CFrame.Angles(0,math.rad(15),0)) r.chassis.AssemblyLinearVelocity=Vector3.zero
    end
   end
  end
 end)
 return cars
end
return Vehicles
