-- Reference-led game interpretations; dimensions/details not independently surveyed.
local Details={}
function Details.build(parent,spiritTemplate)
 local folder=Instance.new("Folder") folder.Name="RiverfrontDetails" folder.Parent=parent
 local bronze=Color3.fromRGB(70,55,39)
 local stone=Color3.fromRGB(173,168,151)
 local function model(name)
  local m=Instance.new("Model") m.Name=name m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  m:SetAttribute("GeometryStatus","Reference-based game interpretation; estimated details") m.Parent=folder return m
 end
 local function part(parent,name,size,cf,color,material,shape)
  local p=Instance.new("Part") p.Name,p.Size,p.CFrame=name,size,cf p.Color=color p.Material=material or Enum.Material.Metal
  p.Anchored,p.CanTouch=true,false if shape then p.Shape=shape end p.Parent=parent return p
 end
 local function rod(parent,name,a,b,radius,color)
  local mid=(a+b)/2 local direction=(b-a).Unit
  local up=math.abs(direction:Dot(Vector3.yAxis))>.95 and Vector3.zAxis or Vector3.yAxis
  local z=direction:Cross(up).Unit local y=z:Cross(direction).Unit
  return part(parent,name,Vector3.new((b-a).Magnitude,radius*2,radius*2),CFrame.fromMatrix(mid,direction,y,z),color,Enum.Material.Metal,Enum.PartType.Cylinder)
 end
 local spirit=model("Spirit of Detroit")
 local statue=spiritTemplate:Clone() statue.Parent=spirit
 local _,size=statue:GetBoundingBox() statue:ScaleTo(statue:GetScale()*28.2/size.Y)
 statue:PivotTo(CFrame.new(-1360.2,18.5,-118.16))
 for _,p in ipairs(statue:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false end end
 part(spirit,"Marble pedestal",Vector3.new(27,4.4,19),CFrame.new(-1360.2,2.2,-118.16),stone,Enum.Material.Marble)
 part(spirit,"Stone backdrop",Vector3.new(42,21,1.2),CFrame.new(-1360.2,10.5,-127.8),Color3.fromRGB(190,185,166),Enum.Material.Limestone)
 -- Joe Louis monument at Jefferson/Woodward. Native sculpture interpretation.
 local fist=model("Monument to Joe Louis") local origin=Vector3.new(-1335.57,0,121.66)
 for _,x in ipairs({-10,10}) do for _,z in ipairs({-9,9}) do
  rod(fist,"Pyramid support",origin+Vector3.new(x,.3,z),origin+Vector3.new(0,23,0),.23,bronze)
 end end
 local function form(name,offset,size,rotation)
  return part(fist,name,size,CFrame.new(origin+offset)*(rotation or CFrame.identity),bronze,Enum.Material.Metal,Enum.PartType.Ball)
 end
 form("Forearm",Vector3.new(0,11,3),Vector3.new(4.5,4.7,15))
 form("Wrist",Vector3.new(0,11,-4.5),Vector3.new(4.7,4.3,5))
 form("Palm",Vector3.new(0,11,-8.2),Vector3.new(6.7,5.3,6))
 for i=1,4 do
  local x=(i-2.5)*1.45
  form("Curled finger",Vector3.new(x,10.4,-10),Vector3.new(1.52,3.7,2.7))
  form("Knuckle",Vector3.new(x,12.5,-9.8),Vector3.new(1.6,1.8,2))
 end
 form("Thumb",Vector3.new(2.1,9.7,-8.2),Vector3.new(2,2.1,5.7),CFrame.Angles(0,-.35,-.25))
 rod(fist,"Suspension",origin+Vector3.new(0,23,0),origin+Vector3.new(0,13.4,0),.06,Color3.fromRGB(52,48,42))
 -- Transcending: two open steel arcs, mapped west of Hart Plaza entrance.
 local arch=model("Transcending - Michigan Labor Legacy Landmark")
 local center=Vector3.new(-1387.3,34.3,485.0)
 local radius=33.4
 local function point(angle)
  return center+Vector3.new(math.cos(angle)*radius,math.sin(angle)*radius,0)
 end
 for _,range in ipairs({{-math.pi/2+.02,math.pi/2-.065},{math.pi/2+.065,math.pi*1.5-.02}}) do
  for i=0,39 do
   local a=range[1]+(range[2]-range[1])*i/40
   local b=range[1]+(range[2]-range[1])*(i+1)/40
   rod(arch,"Brushed steel arc",point(a),point(b),.8,Color3.fromRGB(172,177,176))
  end
 end
 for _,x in ipairs({-2,2}) do part(arch,"Stone foundation",Vector3.new(6,1.4,8),CFrame.new(center.X+x,.7,center.Z),stone,Enum.Material.Granite) end
 -- Finished street furniture, estimated placements outside the signal-gate lane.
 for i=1,8 do
  local x=-1610+i*40 local z=590
  local bench=model("Riverwalk bench "..i)
  for n=1,5 do part(bench,"Seat slat",Vector3.new(6.5,.16,.32),CFrame.new(x,1.65,z+(n-3)*.38),Color3.fromRGB(116,82,52),Enum.Material.WoodPlanks) end
  for n=1,3 do part(bench,"Back slat",Vector3.new(6.5,.32,.18),CFrame.new(x,2.05+n*.4,z+.9),Color3.fromRGB(116,82,52),Enum.Material.WoodPlanks) end
  for _,side in ipairs({-2.5,2.5}) do
   part(bench,"Frame",Vector3.new(.22,1.7,1.9),CFrame.new(x+side,.85,z),Color3.fromRGB(36,42,39))
   part(bench,"Arm rest",Vector3.new(.25,.16,1.9),CFrame.new(x+side,2.3,z),Color3.fromRGB(36,42,39))
  end
 end
 return folder
end
return Details
