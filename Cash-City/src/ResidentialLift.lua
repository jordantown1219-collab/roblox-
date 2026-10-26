-- Server-owned construction lift; no client positions or passenger lists are accepted.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local TweenService=game:GetService('TweenService')
local Rules=require(script.Parent.InteractionRules)
local Lift={}
local services=setmetatable({},{__mode='k'})
function Lift.build(root,config)
 assert(RunService:IsServer() or RunService:IsStudio())
 assert(not root:FindFirstChild('ResidentialTowerA_Lift'),'Preserve existing lift')
 local cx,cz=config.liftCenter[1],config.liftCenter[2]
 local stops=config.stops
 assert(#stops==2 and Rules.finite(stops[1]) and Rules.finite(stops[2]) and stops[2]>stops[1])
 local model=Instance.new('Model');model.Name='ResidentialTowerA_Lift';model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 model:SetAttribute('StudioOnly',true);model:SetAttribute('AccessEnabled',RunService:IsStudio())
 local car=Instance.new('Model');car.Name='Car';car.Parent=model
 local function part(parent,name,size,cf,color,collide)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color or Color3.fromRGB(144,151,140);p.Material=Enum.Material.Metal
  p.Anchored=true;p.CanCollide=collide~=false;p.CanQuery=collide~=false;p.CanTouch=false;p.CastShadow=false;p.Parent=parent;return p
 end
 local base=CFrame.new(cx,stops[1],cz)
 local floor=part(car,'CarFloor',Vector3.new(6.6,.25,6.6),base*CFrame.new(0,-.125,0),Color3.fromRGB(173,168,149))
 floor.PivotOffset=CFrame.new(0,.125,0);car.PrimaryPart=floor
 for _,side in ipairs({-1,1})do part(car,'CarSide',Vector3.new(.16,8.5,6.6),base*CFrame.new(side*3.22,4.25,0))end
 part(car,'CarRoof',Vector3.new(6.6,.18,6.6),base*CFrame.new(0,8.59,0))
 local lamp=part(car,'CarLight',Vector3.new(3,.06,.6),base*CFrame.new(0,8.46,0),Color3.fromRGB(244,235,211),false)
 local light=Instance.new('SurfaceLight');light.Face=Enum.NormalId.Bottom;light.Brightness=.4;light.Range=12;light.Shadows=false;light.Parent=lamp
 local carBack=part(car,'CarBackShutter',Vector3.new(6.3,8.5,.12),base*CFrame.new(0,4.25,-3.3))
 local carFront=part(car,'CarFrontShutter',Vector3.new(6.3,8.5,.12),base*CFrame.new(0,4.25,3.3))
 local gates={}
 gates[1]=part(model,'LobbyLandingGate',Vector3.new(6.4,8.5,.12),CFrame.new(cx,stops[1]+4.25,cz-3.4))
 gates[2]=part(model,'ResidentialLandingGate',Vector3.new(6.4,8.5,.12),CFrame.new(cx,stops[2]+4.25,cz+3.4))
 local controls,prompts={},{}
 local function button(parent,name,cf,text)
  local host=part(parent,name,Vector3.new(.35,.5,.1),cf,Color3.fromRGB(48,66,65),false)
  local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Call';prompt.ObjectText=text;prompt.HoldDuration=.2
  prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX;prompt.MaxActivationDistance=8;prompt.RequiresLineOfSight=true;prompt.Parent=host
  controls[host]=true;prompts[host]=prompt;return host
 end
 local lower=button(model,'LobbyCallButton',CFrame.new(cx+2.2,stops[1]+1.2,cz-4.8),'Residential lift')
 local upper=button(model,'ResidentialCallButton',CFrame.new(cx+2.2,stops[2]+1.2,cz+4.8),'Lobby lift')
 local inside=button(car,'CarButton',base*CFrame.new(-2.7,1.2,0),'Lobby / apartments')
 prompts[inside].ActionText='Ride'
 local value=Instance.new('CFrameValue');value.Name='CarMotion';value.Value=car:GetPivot();value.Parent=model
 local current,busy,destroyed=1,false,false
 local activeTween,held=nil,{}
 local last=setmetatable({},{__mode='k'})
 local connections={}
 local function release()
  for _,s in ipairs(held)do
   if s.weld then s.weld:Destroy();s.weld=nil end
   if s.h.Parent then s.h.PlatformStand=s.platform;s.h.AutoRotate=s.rotate end
   if s.root.Parent then s.root.AssemblyLinearVelocity=Vector3.zero;s.root.AssemblyAngularVelocity=Vector3.zero end
  end
  held={}
 end
 local function shutter(p,opened,animate)
  local y=p.Parent==car and car:GetPivot().Position.Y or (p==gates[1] and stops[1] or stops[2])
  local height=opened and .05 or 8.5
  local target={Size=Vector3.new(p.Size.X,height,p.Size.Z),CFrame=CFrame.new(p.Position.X,y+8.5-height/2,p.Position.Z)}
  p.CanCollide=false
  if animate then local t=TweenService:Create(p,TweenInfo.new(.35),target);t:Play();t.Completed:Wait()else p.Size=target.Size;p.CFrame=target.CFrame end
  if p.Parent then p.CanCollide=not opened end
 end
 local function closeAll()
  for _,g in ipairs({gates[1],gates[2],carBack,carFront})do shutter(g,false,false)end
 end
 local function dock()
  closeAll();shutter(gates[current],true,false);shutter(current==1 and carBack or carFront,true,false)
 end
 local function rootOf(p)
  local c=p and p.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local r=c and c:FindFirstChild('HumanoidRootPart')
  return c,h,r
 end
 local function isInside(r)
  if not r then return false end
  local p=car:GetPivot():PointToObjectSpace(r.Position)
  local hx=(6.6-r.Size.X)/2-.2;local hz=(6.6-r.Size.Z)/2-.2
  return math.abs(p.X)<=hx and math.abs(p.Z)<=hz and p.Y>.1 and p.Y<7.8
 end
 local function doorwayBlocked()
  local z=cz+(current==1 and -3.4 or 3.4);local y=stops[current]
  for _,p in ipairs(Players:GetPlayers())do local _,h,r=rootOf(p)
   if h and h.Health>0 and r and math.abs(r.Position.X-cx)<3.4 and math.abs(r.Position.Z-z)<1.2 and r.Position.Y>y and r.Position.Y<y+8.5 then return true end
  end
  return false
 end
 local function validate(p,target,host)
  if typeof(p)~='Instance' or not p:IsA('Player') or p.Parent~=Players then return false,'Invalid player' end
  if target~=1 and target~=2 then return false,'Invalid stop' end
  if not controls[host] or not host:IsDescendantOf(model) then return false,'Invalid control' end
  if destroyed or not model.Parent or not model:GetAttribute('AccessEnabled') then return false,'Lift closed for construction' end
  if busy then return false,'Lift moving' end
  local c,h,r=rootOf(p)
  if not h or h.Health<=0 or not r or p:GetAttribute('Downed') then return false,'Unavailable character' end
  local distance=(r.Position-host.Position).Magnitude
  if not Rules.finite(distance) or distance>8 then return false,'Too far from lift control' end
  local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={c}
  if workspace:Raycast(r.Position,host.Position-r.Position,ray)then return false,'Lift control is obstructed' end
  if os.clock()-(last[p]or -100)<.65 then return false,'Please wait' end
  if host==inside and not isInside(r)then return false,'Step inside the lift' end
  return true
 end
 local function request(p,target,host)
  host=host or inside
  local allowed,reason=validate(p,target,host)
  if not allowed then return false,reason end
  if doorwayBlocked()then return false,'Stand clear of the lift entrance' end
  last[p]=os.clock()
  if target==current then dock();return true,'Already at landing' end
  busy=true;model:SetAttribute('Busy',true)
  closeAll()
  if doorwayBlocked()then busy=false;model:SetAttribute('Busy',false);dock();return false,'Stand clear of the lift entrance' end
  local ok,err=xpcall(function()
   for _,passenger in ipairs(Players:GetPlayers())do local _,h,r=rootOf(passenger)
    if h and h.Health>0 and isInside(r)then
     local s={h=h,root=r,platform=h.PlatformStand,rotate=h.AutoRotate}
     h.Sit=false;h.PlatformStand=true;h.AutoRotate=false
     local weld=Instance.new('WeldConstraint');weld.Name='ResidentialLiftPassenger';weld.Part0=floor;weld.Part1=r;weld.Parent=r;s.weld=weld;table.insert(held,s)
    end
   end
   value.Value=car:GetPivot()
   activeTween=TweenService:Create(value,TweenInfo.new(math.abs(stops[target]-stops[current])/8,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value=CFrame.new(cx,stops[target],cz)})
   activeTween:Play();local status=activeTween.Completed:Wait();assert(status==Enum.PlaybackState.Completed and not destroyed,'Lift movement interrupted')
   current=target;model:SetAttribute('CurrentStop',current);model:SetAttribute('CarFloorY',stops[current])
  end,debug.traceback)
  if not ok and not destroyed then value.Value=CFrame.new(cx,stops[current],cz);car:PivotTo(value.Value);model:SetAttribute('LastFailure','Lift movement interrupted')end
  release();activeTween=nil;busy=false
  if not destroyed then model:SetAttribute('Busy',false);dock()end
  if not ok then return false,tostring(err)end
  return true,'Arrived'
 end
 table.insert(connections,value:GetPropertyChangedSignal('Value'):Connect(function()if not destroyed then car:PivotTo(value.Value)end end))
 for host,prompt in pairs(prompts)do
  prompt.Enabled=model:GetAttribute('AccessEnabled')
  table.insert(connections,prompt.Triggered:Connect(function(p)
   local target=host==lower and 1 or host==upper and 2 or (current==1 and 2 or 1)
   local ok,reason=request(p,target,host);if not ok and model.Parent then model:SetAttribute('LastFailure',reason)end
  end))
 end
 table.insert(connections,model:GetAttributeChangedSignal('AccessEnabled'):Connect(function()for _,prompt in pairs(prompts)do prompt.Enabled=model:GetAttribute('AccessEnabled')==true end end))
 model.Destroying:Connect(function()
  if services[root]and services[root].model==model then services[root]=nil end
  destroyed=true;if activeTween then activeTween:Cancel()end;release();for _,c in ipairs(connections)do c:Disconnect()end
 end)
 model:SetAttribute('CurrentStop',1);model:SetAttribute('Busy',false);model:SetAttribute('CarFloorY',stops[1])
 dock();model.Parent=root
 local api={model=model,car=car,requestRide=request,canRequest=function(p,target)return validate(p,target,inside)end,controls={lower=lower,upper=upper,inside=inside},Destroy=function()model:Destroy()end}
 services[root]=api;return api
end
function Lift.get(root)return services[root]end
return Lift
