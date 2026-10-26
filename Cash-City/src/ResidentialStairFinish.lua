-- Original fictional residential conversion: finishes outside the tested stair route.
local Finish={}
function Finish.build(root)
 assert(root:FindFirstChild('ResidentialTowerA_Stairs'),'Build stairs before finishes')
 assert(not root:FindFirstChild('ResidentialTowerA_StairFinish'),'Preserve existing finishes')
 local plan=require(script.Parent.ResidentialStairsData)
 local cx,cz=plan.center[1],plan.center[2]
 local model=Instance.new('Model');model.Name='ResidentialTowerA_StairFinish'
 local function part(name,size,pos,material,color,trans,collide)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.Position=pos
  p.Material=material;p.Color=color;p.Transparency=trans or 0
  p.Anchored=true;p.CanCollide=collide==true;p.CanQuery=collide==true;p.CanTouch=false;p.CastShadow=false;p.Parent=model
  return p
 end
 local metal=Color3.fromRGB(65,76,79)
 local glass=Color3.fromRGB(159,191,190)
 -- Walls sit outside the tested lanes and landings. East side retains both entries.
 for i=0,4 do
  local y=36+(i+.5)*10.6
  part('WestGlass',Vector3.new(.16,10.4,30.4),Vector3.new(cx-63.22,y,cz-11),Enum.Material.Glass,glass,.55,true)
  for _,z in {-26.22,4.22}do
   part('EndGlass',Vector3.new(11.4,10.4,.16),Vector3.new(cx-57.5,y,cz+z),Enum.Material.Glass,glass,.55,true)
  end
  part('WestTransom',Vector3.new(.22,.12,30.5),Vector3.new(cx-63.22,36+i*10.6,cz-11),Enum.Material.Metal,metal)
 end
 for _,x in {-63.22,-51.78}do for _,z in {-26.22,4.22}do
  part('CornerMullion',Vector3.new(.18,53,.18),Vector3.new(cx+x,62.5,cz+z),Enum.Material.Metal,metal)
 end end
 part('EastMiddleGlass',Vector3.new(.16,35.5,30.4),Vector3.new(cx-51.78,62.25,cz-11),Enum.Material.Glass,glass,.55,true)
 part('EastLowerGlass',Vector3.new(.16,8.5,26),Vector3.new(cx-51.78,40.25,cz-9),Enum.Material.Glass,glass,.55,true)
 part('EastHeader',Vector3.new(.16,.5,30.4),Vector3.new(cx-51.78,88.75,cz-11),Enum.Material.Metal,metal,0,true)
 part('StairRoof',Vector3.new(11.6,.18,30.6),Vector3.new(cx-57.5,89.1,cz-11),Enum.Material.Metal,metal,0,true)
 for index,y in {36,47,58,69,80}do
  local z=cz+((index%2==1)and -24 or 2)
  local lamp=part('LandingLight',Vector3.new(.16,.3,2),Vector3.new(cx-62.98,y+5.4,z),Enum.Material.Neon,Color3.fromRGB(245,224,185))
  local light=Instance.new('SurfaceLight');light.Face=Enum.NormalId.Right;light.Range=14;light.Angle=140;light.Brightness=.5;light.Shadows=false;light.Color=lamp.Color;light.Parent=lamp
  local sign=part('LevelSign',Vector3.new(.12,1.1,2.4),Vector3.new(cx-62.98,y+2.4,z),Enum.Material.Metal,metal)
  local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Right;gui.CanvasSize=Vector2.new(480,220);gui.Parent=sign
  local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.TextColor3=Color3.fromRGB(240,236,217);label.TextScaled=true;label.Font=Enum.Font.GothamMedium
  label.Text=index==1 and 'LOBBY  /  DOWN' or (index==5 and 'RESIDENCES  /  LEVEL 01' or 'STAIRS  /  CONTINUE');label.Parent=gui
 end
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 model:SetAttribute('Design','Original fictional residential conversion')
 model.Parent=root
 return model
end
return Finish
