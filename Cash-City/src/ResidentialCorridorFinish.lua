-- Original residential conversion; additive finishes preserve doors and walking geometry.
local Finish={}
function Finish.build(root,level)
 level=level or 1
 assert(type(level)=='number' and level>=1 and level<=39 and level%1==0,'Invalid residential level')
 local floorName='ResidentialTowerA_Level'..string.format('%02d',level)
 local name=level==1 and 'ResidentialTowerA_CorridorFinish' or floorName..'_CorridorFinish'
 assert(root:FindFirstChild(floorName),'Residential floor required')
 assert(not root:FindFirstChild(name),'Preserve existing corridor finishes')
 local data=require(script.Parent.ResidentialStairsData)
 local cx,cz=data.center[1],data.center[2]
 local model=Instance.new('Model');model.Name=name
 local function part(name,size,x,y,z,color,material)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.Position=Vector3.new(cx+x,y+12*(level-1),cz+z)
  p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.Anchored=true
  p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Parent=model;return p
 end
 local charcoal=Color3.fromRGB(66,78,80)
 local carpet=Color3.fromRGB(100,111,105)
 -- Separate runs avoid overlaps at the cross and leave the existing lift opening clear.
 local runners=level==1 and {{0,0,96,6.8},{0,24,6.8,40},{0,-30,6.8,28},{0,-6.2,6.8,4.4},{-50.2,-12,2.5,24}} or {{0,0,96,6.8},{0,24,6.8,40},{0,-24,6.8,40},{-50.2,-12,2.5,24}}
 for _,r in runners do
  part('CorridorRunner',Vector3.new(r[3],.025,r[4]),r[1],80.025,r[2],carpet,Enum.Material.Fabric)
 end
 local function text(p,face,value)
  local gui=Instance.new('SurfaceGui');gui.Face=face;gui.CanvasSize=Vector2.new(600,180);gui.Parent=p
  local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
  label.TextColor3=Color3.fromRGB(243,236,217);label.TextScaled=true;label.Font=Enum.Font.GothamMedium;label.Text=value;label.Parent=gui
 end
 for index,loc in {{-26,-1},{-26,1},{26,-1},{26,1}}do
  local x,side=loc[1]+5,loc[2]
  local face=side==1 and Enum.NormalId.Front or Enum.NormalId.Back
  local plaque=part('ApartmentNumber_'..index,Vector3.new(2,.9,.1),x,82.4,side*3.82,charcoal,Enum.Material.Metal)
  text(plaque,face,string.format('%02d-%02d',level,index))
  local lamp=part('CorridorSconce_'..index,Vector3.new(1.2,1.6,.16),x,86,side*3.8,Color3.fromRGB(237,221,188))
  local light=Instance.new('SurfaceLight');light.Face=face;light.Color=lamp.Color;light.Range=12;light.Angle=140
  light.Brightness=.3;light.Shadows=false;light.Parent=lamp
 end
 local sign=part('CorridorDirectory',Vector3.new(6.5,1.1,.18),0,87.6,0,charcoal,Enum.Material.Metal)
 for _,face in {Enum.NormalId.Front,Enum.NormalId.Back}do text(sign,face,level==1 and 'STAIRS: WEST   /   LIFT: SOUTH' or 'LEVEL '..string.format('%02d',level)..' / STAIRS: WEST')end
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 model:SetAttribute('Design','Original fictional residential conversion')
 model.Parent=root;return model
end
return Finish
