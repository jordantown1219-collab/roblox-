-- Additive landing lights/signs; no changes to the tested stair collision geometry.
local Wayfinding={}
function Wayfinding.build(root)
 assert(not root:FindFirstChild('ResidentialTowerA_StairWayfinding'),'Preserve existing wayfinding')
 assert(root:FindFirstChild('ResidentialTowerA_Level39'),'Complete residential stack required')
 for lower=1,38 do
  local name=lower==1 and 'ResidentialTowerA_UpperStairs' or string.format('ResidentialTowerA_UpperStairs_%02d_%02d',lower,lower+1)
  assert(root:FindFirstChild(name),'Stair connection missing: '..name)
 end
 local center=require(script.Parent.ResidentialFloorBatch09Data).connections[3].center
 local cx,cz=center[1],center[2]
 local model=Instance.new('Model');model.Name='ResidentialTowerA_StairWayfinding'
 local function part(parent,name,size,position,color,material)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.Position=position;p.Color=color;p.Material=material
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Parent=parent;return p
 end
 local function landing(parent,y,z,label)
  local slate=Color3.fromRGB(61,77,79)
  part(parent,'LampHousing',Vector3.new(.16,.6,1.5),Vector3.new(cx-63.03,y+5.3,cz+z),slate,Enum.Material.Metal)
  local lamp=part(parent,'LampDiffuser',Vector3.new(.04,.4,1.2),Vector3.new(cx-62.93,y+5.3,cz+z),Color3.fromRGB(244,227,194),Enum.Material.Neon)
  local light=Instance.new('SurfaceLight');light.Name='LandingLight';light.Face=Enum.NormalId.Right;light.Range=12;light.Angle=140
  light.Brightness=.3;light.Color=Color3.fromRGB(255,235,202);light.Shadows=false;light.Parent=lamp
  local sign=part(parent,'LandingDirectory',Vector3.new(.1,1,2.6),Vector3.new(cx-63.02,y+2.2,cz+z),slate,Enum.Material.Metal)
  local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Right;gui.CanvasSize=Vector2.new(620,220);gui.Parent=sign
  local text=Instance.new('TextLabel');text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.TextColor3=Color3.fromRGB(245,237,215)
  text.TextScaled=true;text.Font=Enum.Font.GothamMedium;text.Text=label;text.Parent=gui
 end
 for lower=1,38 do
  local flight=Instance.new('Model');flight.Name=string.format('Flight_%02d_%02d',lower,lower+1);flight.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  local y=80+12*(lower-1)
  landing(flight,y+6,-8,string.format('%02d TO %02d / STAIRS',lower,lower+1))
  landing(flight,y+12,-24,string.format('LEVEL %02d / CORRIDOR',lower+1))
  flight.Parent=model
 end
 model:SetAttribute('FinishType','Landing lighting and floor wayfinding')
 model.Parent=root;return model
end
return Wayfinding
