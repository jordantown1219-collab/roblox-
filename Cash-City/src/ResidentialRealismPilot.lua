-- Owner-approved visual direction, reused from the one-apartment pilot.
local Pilot={}
function Pilot.modelName(level,unit)
 return level==1 and unit==1 and 'ResidentialTowerA_RealismPilot' or string.format('ResidentialTowerA_Realism_L%02d_U%02d',level,unit)
end
function Pilot.build(root,level,unit)
 level=level or 1;unit=unit or 1
 assert(type(level)=='number' and level%1==0 and level>=1 and level<=39 and type(unit)=='number' and unit%1==0 and unit>=1 and unit<=4,'Invalid apartment target')
 local name=Pilot.modelName(level,unit)
 assert(not root:FindFirstChild(name),'Preserve existing realism finish')
 local floorName=string.format('ResidentialTowerA_Level%02d',level)
 local floor=assert(root:FindFirstChild(floorName))
 local id=string.format('%02d',unit);local prefix='Apartment'..id
 local finishRoot=level==1 and 'ResidentialTowerA_LivingFinish' or floorName..'_LivingFinish'
 local finish=root[finishRoot][prefix..'_LivingBedroomFinish']
 local counter=assert(floor:FindFirstChild(prefix..'_KitchenCounter',true))
 local cf=counter.CFrame*CFrame.new(-11,-3.125,17)
 local top=assert(floor:FindFirstChild(prefix..'_CoffeeTableTop',true))
 assert(top:IsA('Part') and (top.Size-Vector3.new(5,.25,2.7)).Magnitude<.01,'Coffee table changed; review before replacing its shape')
 local model=Instance.new('Model');model.Name=name
 local originals=Instance.new('Folder');originals.Name='OriginalReferences';originals.Parent=model
 local saved={}
 local function preserve(p)
  if saved[p]then return end;saved[p]=true
  local ref=Instance.new('ObjectValue');ref.Name=p.Name;ref.Value=p;ref.Parent=originals
  for _,key in {'Color','Size','CFrame','Transparency','CanCollide','CanQuery','CanTouch','Reflectance'}do p:SetAttribute('RealismPilotOriginal'..key,p[key])end
  p:SetAttribute('RealismPilotOriginalMaterial',p.Material.Name)
  if p:IsA('Part')then p:SetAttribute('RealismPilotOriginalShape',p.Shape.Name)end
 end
 local function part(name,size,pos,color,material,shape,solid)
  local p=Instance.new('Part');p.Name=name;p.Size=Vector3.new(table.unpack(size));p.CFrame=cf*CFrame.new(table.unpack(pos))
  p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.Anchored=true
  p.CanCollide=solid==true;p.CanQuery=solid==true;p.CanTouch=false;p.CastShadow=false
  if shape then p.Shape=shape end;p.Parent=model;return p
 end
 local function cylinder(name,height,diameter,pos,color,material,solid)
  local p=part(name,{height,diameter,diameter},pos,color,material,Enum.PartType.Cylinder,solid)
  p.CFrame=p.CFrame*CFrame.Angles(0,0,math.pi/2);return p
 end
 for _,p in floor:GetDescendants()do
  if p:IsA('BasePart')and p.Name:match('^'..prefix..'_Sofa')then
   preserve(p);p.Color=p:IsA('Seat')and Color3.fromRGB(155,160,149)or Color3.fromRGB(126,137,128);p.Material=Enum.Material.Fabric
  elseif p:IsA('BasePart')and p.Name==prefix..'_CoffeeTableLeg'then
   preserve(p);p.Transparency=1;p.CanCollide=false;p.CanQuery=false
  end
 end
 preserve(top);top.Shape=Enum.PartType.Cylinder;top.Size=Vector3.new(.22,3.8,3.8)
 top.CFrame=cf*CFrame.new(-13,1.5,-4.3)*CFrame.Angles(0,0,math.pi/2)
 top.Material=Enum.Material.Wood;top.Color=Color3.fromRGB(134,104,76)
 for _,x in {-14.1,-11.9}do for _,z in {-5.4,-3.2}do part('CoffeeTableLeg',{.14,1.39,.14},{x,.695,z},Color3.fromRGB(58,65,62),Enum.Material.Metal,nil,true)end end
 for _,x in {-15,-11}do part('SoftBackCushion',{3.6,1.9,.55},{x,1.95,-11.2},Color3.fromRGB(145,153,141),Enum.Material.Fabric,Enum.PartType.Ball)end
 for _,x in {-16.5,-9.5}do for _,z in {-11.1,-8.9}do part('SofaFoot',{.25,.3,.25},{x,.15,z},Color3.fromRGB(66,54,43),Enum.Material.Wood)end end
 for _,p in finish:GetChildren()do
  if p:IsA('Part')and p.Name=='SofaCushion'then preserve(p);p.Shape=Enum.PartType.Ball;p.Color=Color3.fromRGB(188,156,111)
  elseif p:IsA('BasePart')and(p.Name=='DiningTableTop'or p.Name=='DiningChairBack')then preserve(p);p.Material=Enum.Material.Wood;p.Color=Color3.fromRGB(145,115,83)
  elseif p:IsA('BasePart')and p.Name=='LivingRug'then preserve(p);p.Color=Color3.fromRGB(160,150,130)end
 end
 for _,z in {-9.35,-1.65}do part('RugWovenBorder',{9.7,.004,.06},{-13,.0815,z},Color3.fromRGB(119,116,98),Enum.Material.Fabric)end
 for _,x in {-17.85,-8.15}do part('RugWovenBorder',{.06,.004,7.7},{x,.0815,-5.5},Color3.fromRGB(119,116,98),Enum.Material.Fabric)end
 for _,pos in {{6,-4},{10,-4},{8,-5.3},{8,-2.7}}do
  part('LinenPlaceMat',{1.2,.012,1.2},{pos[1],2.927,pos[2]},Color3.fromRGB(186,181,153),Enum.Material.Fabric)
  cylinder('DinnerPlate',.035,.85,{pos[1],2.957,pos[2]},Color3.fromRGB(232,228,212),Enum.Material.SmoothPlastic)
  part('TableSetting',{.045,.015,.6},{pos[1]+.5,2.946,pos[2]},Color3.fromRGB(154,166,161),Enum.Material.Metal)
 end
 for i=1,2 do
  local y=1.66+(i-1)*.16
  part('BookPages',{.85,.11,1.15},{-13.45,y,-4.3},Color3.fromRGB(219,211,189))
  part('OriginalBookCover',{.9,.025,1.2},{-13.45,y+.07,-4.3},i==1 and Color3.fromRGB(97,126,121)or Color3.fromRGB(167,137,92))
 end
 cylinder('ReadingLampBase',.16,1.1,{-19,.08,-8},Color3.fromRGB(67,72,64),Enum.Material.Metal)
 cylinder('ReadingLampStem',4.6,.09,{-19,2.46,-8},Color3.fromRGB(86,89,75),Enum.Material.Metal)
 local shade=cylinder('LinenLampShade',.8,1.6,{-19,5,-8},Color3.fromRGB(235,222,183),Enum.Material.Fabric)
 shade.Transparency=.12
 local light=Instance.new('SurfaceLight');light.Face=Enum.NormalId.Left;light.Range=9;light.Angle=140;light.Brightness=.4;light.Shadows=false;light.Color=Color3.fromRGB(255,225,175);light.Parent=shade
 cylinder('PlantPot',.75,1.2,{-19,.375,-4},Color3.fromRGB(157,139,113),Enum.Material.Concrete)
 cylinder('PlantSoil',.025,1.05,{-19,.765,-4},Color3.fromRGB(67,59,45),Enum.Material.Ground)
 for i=1,5 do
  local angle=2*math.pi*i/5
  local leaf=part('OriginalFoliage',{.45,1.7,.18},{-19+math.cos(angle)*.4,1.4+((i%2)*.35),-4+math.sin(angle)*.4},Color3.fromRGB(82+i*5,112+i*4,75+i*3),Enum.Material.Grass,Enum.PartType.Ball)
  leaf.CFrame=leaf.CFrame*CFrame.Angles(math.sin(angle)*.35,angle,math.cos(angle)*.35)
 end
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;model:SetAttribute('ReviewStatus','APPROVED_STYLE_AWAITING_INDIVIDUAL_QA')
 model.Parent=root;return model
end
function Pilot.applyRange(root,first,last)
 assert(type(first)=='number' and type(last)=='number' and first%1==0 and last%1==0 and first>=1 and last<=39 and last>=first and last-first<=2,'Invalid finish batch')
 local built,retained=0,0
 for level=first,last do for unit=1,4 do
  local current=root:FindFirstChild(Pilot.modelName(level,unit))
  if current then retained=retained+1 else Pilot.build(root,level,unit);built=built+1 end
 end task.wait()end
 return {first=first,last=last,built=built,retained=retained}
end
function Pilot.applyAll(root)
 local results={}
 for first=1,39,3 do table.insert(results,Pilot.applyRange(root,first,math.min(first+2,39)));task.wait()end
 return results
end
return Pilot
