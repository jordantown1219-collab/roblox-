-- Original furniture pass, built separately from preserved apartment shells.
local Finish={}
function Finish.build(root,level)
 level=level or 1
 assert(type(level)=='number' and level>=1 and level<=39 and level%1==0,'Invalid residential level')
 local floorName='ResidentialTowerA_Level'..string.format('%02d',level)
 local name=level==1 and 'ResidentialTowerA_LivingFinish' or floorName..'_LivingFinish'
 local floor=assert(root:FindFirstChild(floorName))
 assert(not root:FindFirstChild(name),'Preserve existing furnishing pass')
 local model=Instance.new('Model');model.Name=name
 local timber=Color3.fromRGB(144,117,87)
 local metal=Color3.fromRGB(64,76,77)
 for index=1,4 do
  local id=string.format('%02d',index)
  local counter=assert(floor:FindFirstChild('Apartment'..id..'_KitchenCounter',true))
  local cf=counter.CFrame*CFrame.new(-11,-3.125,17)
  local unit=Instance.new('Model');unit.Name='Apartment'..id..'_LivingBedroomFinish';unit.Parent=model
  local function p(name,size,pos,color,material,solid,class)
   local part=Instance.new(class or 'Part');part.Name=name;part.Size=Vector3.new(table.unpack(size));part.CFrame=cf*CFrame.new(table.unpack(pos))
   part.Color=color;part.Material=material or Enum.Material.SmoothPlastic;part.Anchored=true
   part.CanCollide=solid==true;part.CanQuery=solid==true;part.CanTouch=class=='Seat';part.CastShadow=false;part.Parent=unit;return part
  end
  p('LivingRug',{10,.025,8},{-13,.065,-5.5},Color3.fromRGB(165,160,140),Enum.Material.Fabric)
  p('BedroomRug',{8,.025,9},{-13,.065,11},Color3.fromRGB(127,143,137),Enum.Material.Fabric)
  for _,x in {-15.5,-10.5}do p('SofaCushion',{1.5,1.2,.45},{x,2,-10.9},Color3.fromRGB(195,172,123),Enum.Material.Fabric)end
  p('DiningTableTop',{6,.22,4},{8,2.8,-4},timber,Enum.Material.WoodPlanks,true)
  p('DiningTablePedestal',{1.2,2.69,1.2},{8,1.345,-4},metal,Enum.Material.Metal,true)
  for _,chair in {{3,-4,-math.pi/2},{13,-4,math.pi/2},{8,-8,math.pi},{8,-.9,0}}do
   local x,z,yaw=chair[1],chair[2],chair[3]
   local seat=p('DiningSeat',{2.4,.35,2.2},{x,1.55,z},Color3.fromRGB(128,148,139),Enum.Material.Fabric,true,'Seat')
   seat.CFrame=seat.CFrame*CFrame.Angles(0,yaw,0)
   local back=p('DiningChairBack',{2.4,1.9,.16},{x,2.3,z},timber,Enum.Material.WoodPlanks,true)
   back.CFrame=seat.CFrame*CFrame.new(0,.75,1.05)
   p('DiningChairBase',{.9,1.375,.9},{x,.6875,z},metal,Enum.Material.Metal,true)
  end
  for _,loc in {{-19,14},{-9,17.5}}do
   local x,z=loc[1],loc[2]
   p('BedsideLampBase',{.7,.09,.7},{x,2.345,z},metal,Enum.Material.Metal)
   p('BedsideLampStem',{.1,.8,.1},{x,2.78,z},metal,Enum.Material.Metal)
   local shade=p('BedsideLampShade',{1.15,.7,1.15},{x,3.5,z},Color3.fromRGB(226,217,185),Enum.Material.Fabric)
   local light=Instance.new('SurfaceLight');light.Face=Enum.NormalId.Top;light.Range=7;light.Angle=120;light.Brightness=.2
   light.Color=Color3.fromRGB(255,231,191);light.Shadows=false;light.Parent=shade
  end
  p('AbstractArtFrame',{.08,3.4,5.4},{-21.78,6.3,-8},metal,Enum.Material.Metal)
  for i,color in {Color3.fromRGB(99,137,137),Color3.fromRGB(192,164,113),Color3.fromRGB(193,202,182)}do
   p('OriginalAbstractPanel',{.03,3.1,1.65},{-21.72,6.3,-11.3+i*1.65},color)
  end
 end
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 model:SetAttribute('Design','Original fictional residential conversion')
 model.Parent=root;return model
end
return Finish
