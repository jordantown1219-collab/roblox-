-- Additive original kitchen/bathroom detailing; existing fixtures and interactions remain intact.
local Finish={}
function Finish.build(root,level)
 level=level or 1
 assert(type(level)=='number' and level>=1 and level<=39 and level%1==0,'Invalid residential level')
 local floorName='ResidentialTowerA_Level'..string.format('%02d',level)
 local name=level==1 and 'ResidentialTowerA_ApartmentFinish' or floorName..'_ApartmentFinish'
 local floor=assert(root:FindFirstChild(floorName))
 assert(not root:FindFirstChild(name),'Preserve existing finishes')
 local model=Instance.new('Model');model.Name=name
 local steel=Color3.fromRGB(131,145,145)
 local dark=Color3.fromRGB(46,55,55)
 local wood=Color3.fromRGB(152,128,99)
 local function detail(parent,cf,name,size,offset,color,material,trans)
  local p=Instance.new('Part');p.Name=name;p.Size=Vector3.new(table.unpack(size));p.CFrame=cf*CFrame.new(table.unpack(offset))
  p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.Transparency=trans or 0
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Parent=parent;return p
 end
 for index=1,4 do
  local id=string.format('%02d',index)
  local counter=assert(floor:FindFirstChild('Apartment'..id..'_KitchenCounter',true))
  local cf=counter.CFrame*CFrame.new(-11,-3.125,17)
  local unit=Instance.new('Model');unit.Name='Apartment'..id..'_KitchenBathroomFinish';unit.Parent=model
  local function p(name,size,pos,color,material,trans)return detail(unit,cf,name,size,pos,color,material,trans)end
  p('KitchenBacksplash',{10,.9,.055},{11,3.85,-19.46},Color3.fromRGB(190,199,189),Enum.Material.Marble)
  for _,x in {7,9,11,13,15}do
   p('LowerCabinetFront',{1.92,2.55,.045},{x,1.55,-15.475},wood,Enum.Material.WoodPlanks)
   p('LowerHandle',{.65,.065,.09},{x,2.4,-15.41},steel,Enum.Material.Metal)
   p('UpperCabinetFront',{1.92,2.8,.045},{x,6.8,-18.225},wood,Enum.Material.WoodPlanks)
  end
  p('SinkTapStem',{.13,.65,.13},{9,3.62,-17.62},steel,Enum.Material.Metal)
  p('SinkTapSpout',{.13,.13,.65},{9,3.91,-17.36},steel,Enum.Material.Metal)
  p('TapLever',{.4,.07,.07},{9.2,3.63,-17.62},steel,Enum.Material.Metal)
  p('Cooktop',{3.1,.045,2.5},{13.5,3.28,-17},dark,Enum.Material.Metal)
  for _,x in {12.8,14.2}do for _,z in {-17.65,-16.35}do
   local burner=p('Burner',{.035,.7,.7},{x,3.32,z},Color3.fromRGB(14,19,20),Enum.Material.Metal)
   burner.Shape=Enum.PartType.Cylinder;burner.CFrame=burner.CFrame*CFrame.Angles(0,0,math.pi/2)
  end end
  for _,y in {1.8,5.25}do
   p('RefrigeratorDoor',{3.05,3.25,.05},{19,y,-15.425},Color3.fromRGB(179,189,184),Enum.Material.Metal)
   p('RefrigeratorHandle',{.1,1.2,.12},{17.75,y,-15.33},dark,Enum.Material.Metal)
  end
  p('VanityBasinInset',{1.65,.025,1.1},{19,3.035,9.5},Color3.fromRGB(106,125,124),Enum.Material.Metal)
  p('VanityTapStem',{.12,.55,.12},{19,3.25,8.75},steel,Enum.Material.Metal)
  p('VanityTapSpout',{.12,.12,.55},{19,3.5,8.98},steel,Enum.Material.Metal)
  p('MirrorFrame',{3.2,2.5,.08},{19,5.5,8.14},dark,Enum.Material.Metal)
  local mirror=p('MirrorGlass',{2.95,2.25,.035},{19,5.5,8.2},Color3.fromRGB(176,201,203),Enum.Material.Metal)
  mirror.Reflectance=.2
  p('ShowerSideGlass',{.045,6.3,3.8},{20.9,3.35,17},Color3.fromRGB(176,208,204),Enum.Material.Glass,.7)
  p('ShowerBackGlass',{3.8,6.3,.045},{19,3.35,18.9},Color3.fromRGB(176,208,204),Enum.Material.Glass,.7)
  p('ShowerRiser',{.12,4,.12},{20.8,4.1,18.65},steel,Enum.Material.Metal)
  p('ShowerHead',{.6,.1,.6},{20.55,6.15,18.5},steel,Enum.Material.Metal)
  p('ShowerDrain',{.35,.02,.35},{19,.195,17},steel,Enum.Material.Metal)
  p('TowelRail',{.12,.12,2.4},{21.7,3.8,12.5},steel,Enum.Material.Metal)
  p('FoldedTowel',{.16,1.55,1.6},{21.55,3.1,12.5},Color3.fromRGB(204,216,204),Enum.Material.Fabric)
 end
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 model:SetAttribute('Design','Original fictional residential conversion')
 model:SetAttribute('FixtureFunctionality','Visual details only; no appliance-use interactions')
 model.Parent=root;return model
end
return Finish
