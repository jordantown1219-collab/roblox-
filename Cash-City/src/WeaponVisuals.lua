-- Original exterior game models. Combat/ammo remain in SmallSignalsServer.
local TweenService=game:GetService("TweenService")
local Visuals={}
function Visuals.build(tool,name,scale)
 local dark=Color3.fromRGB(29,32,35)
 local metal=Color3.fromRGB(62,66,70)
 local polymer=Color3.fromRGB(37,39,38)
 local handle=Instance.new("Part")
 handle.Name,handle.Size,handle.Transparency="Handle",Vector3.new(.23,.65,.24)*scale,1
 handle.CanCollide,handle.CanTouch,handle.Massless=false,false,true
 handle.Parent=tool
 local function piece(label,size,position,color,rotation,shape)
  local p=Instance.new("Part")
  p.Name,p.Size,p.Color=label,size*scale,color or dark
  p.Material=Enum.Material.Metal
  if shape then p.Shape=shape end
  p.CanCollide,p.CanTouch,p.Massless=false,false,true
  p.CFrame=CFrame.new(position*scale)*(rotation or CFrame.identity)
  p.Parent=tool
  local weld=Instance.new("Weld")
  weld.Name,weld.Part0,weld.Part1,weld.C0=label.."Joint",handle,p,p.CFrame
  weld.Parent=handle
  return p,weld
 end
 if name=="Knife" then
  piece("Rubber grip",Vector3.new(.18,.55,.23),Vector3.new(0,-.1,0),polymer)
  piece("Guard",Vector3.new(.45,.09,.3),Vector3.new(0,.22,0),metal)
  piece("Blade",Vector3.new(.1,1.05,.30),Vector3.new(0,.79,0),Color3.fromRGB(158,163,164))
  piece("Blade point",Vector3.new(.1,.26,.22),Vector3.new(0,1.36,-.04),metal,CFrame.Angles(.15,0,0))
  return
 end
 local smg=name=="SMG"
 local nose=smg and -1.48 or -2.03
 piece("Lower receiver",Vector3.new(.32,.32,.69),Vector3.new(0,.27,-.12),metal)
 piece("Upper receiver",Vector3.new(.31,.27,.91),Vector3.new(0,.56,-.18),metal)
 piece("Pistol grip",Vector3.new(.24,.64,.28),Vector3.new(0,-.15,.07),polymer,CFrame.Angles(math.rad(-17),0,0))
 piece("Trigger guard front",Vector3.new(.12,.27,.08),Vector3.new(0,.02,-.27),dark)
 piece("Trigger guard bottom",Vector3.new(.12,.07,.35),Vector3.new(0,-.10,-.11),dark)
 piece("Trigger",Vector3.new(.07,.18,.07),Vector3.new(0,.05,-.13),metal,CFrame.Angles(.25,0,0))
 local mag,magJoint=piece("Magazine",Vector3.new(.25,smg and .8 or .72,.37),Vector3.new(0,-.12,-.46),dark,CFrame.Angles(math.rad(smg and -3 or -12),0,0))
 magJoint.Name="MagazineJoint"
 piece("Stock tube",Vector3.new(.17,.17,.65),Vector3.new(0,.48,.58),metal)
 piece("Stock cheek",Vector3.new(.31,.25,.58),Vector3.new(0,.43,.86),polymer)
 piece("Shoulder pad",Vector3.new(.35,.66,.14),Vector3.new(0,.25,1.19),polymer,CFrame.Angles(-.07,0,0))
 piece("Stock brace",Vector3.new(.17,.12,.55),Vector3.new(0,.12,.82),polymer,CFrame.Angles(.23,0,0))
 piece("Handguard",Vector3.new(.32,.34,smg and .58 or .91),Vector3.new(0,.43,smg and -.92 or -1.07),dark)
 for _,side in ipairs({-1,1}) do
  for i=1,(smg and 3 or 5) do
   piece("Vent",Vector3.new(.012,.10,.10),Vector3.new(side*.167,.46,-.68-i*.13),Color3.fromRGB(9,11,12))
  end
  piece("Selector",Vector3.new(.03,.055,.15),Vector3.new(side*.17,.34,.15),polymer)
 end
 piece("Top rail",Vector3.new(.22,.055,1.55),Vector3.new(0,.715,-.54),dark)
 for i=1,12 do piece("Rail tooth",Vector3.new(.27,.035,.045),Vector3.new(0,.754,.19-i*.12),metal) end
 piece("Barrel",Vector3.new(smg and .32 or .62,.12,.12),Vector3.new(0,.45,nose+.24),metal,CFrame.Angles(0,math.pi/2,0),Enum.PartType.Cylinder)
 local muzzle=piece("Flash hider",Vector3.new(.20,.19,.19),Vector3.new(0,.45,nose),dark,CFrame.Angles(0,math.pi/2,0),Enum.PartType.Cylinder)
 piece("Front sight",Vector3.new(.08,.18,.09),Vector3.new(0,.64,nose+.18),metal)
 piece("Optic mount",Vector3.new(.22,.08,.32),Vector3.new(0,.80,-.15),metal)
 piece("Red dot housing",Vector3.new(.28,.28,.38),Vector3.new(0,.98,-.15),dark)
 local glass=piece("Optic lens",Vector3.new(.22,.21,.018),Vector3.new(0,.98,-.35),Color3.fromRGB(65,108,103))
 glass.Material,glass.Transparency=Enum.Material.Glass,.25
 piece("Ejection port",Vector3.new(.014,.09,.29),Vector3.new(.164,.55,-.16),Color3.fromRGB(12,13,15))
 local attachment=Instance.new("Attachment")
 attachment.Name,attachment.CFrame="Muzzle",CFrame.new(0,.45*scale,(nose-.12)*scale)
 attachment.Parent=handle
 local flash=Instance.new("PointLight") flash.Name,flash.Enabled,flash.Range,flash.Brightness="MuzzleFlash",false,7*scale,2 flash.Color=Color3.fromRGB(255,202,118) flash.Parent=attachment
 local sound=Instance.new("Sound") sound.Name,sound.SoundId,sound.Volume="Shot","rbxassetid://113879008765178",.45 sound.RollOffMaxDistance=140 sound.Parent=handle
 local reload=Instance.new("Sound") reload.Name,reload.SoundId,reload.Volume="Reload","rbxassetid://18574927786",.35 reload.RollOffMaxDistance=30 reload.Parent=handle
 tool:SetAttribute("VisualModel","Original modern "..name)
 tool:SetAttribute("VisualScale",scale)
end
function Visuals.fire(tool)
 local handle=tool:FindFirstChild("Handle") if not handle then return end
 local sound=handle:FindFirstChild("Shot") if sound then sound:Play() end
 local a=handle:FindFirstChild("Muzzle") local flash=a and a:FindFirstChild("MuzzleFlash")
 if flash then flash.Enabled=true task.delay(.05,function() if flash.Parent then flash.Enabled=false end end) end
end
function Visuals.reload(tool,duration)
 local handle=tool:FindFirstChild("Handle")
 local joint=handle and handle:FindFirstChild("MagazineJoint") if not joint then return end
 local home=joint.C0
 local sound=handle:FindFirstChild("Reload") if sound then sound:Play() end
 local out=TweenService:Create(joint,TweenInfo.new(duration*.3),{C0=home*CFrame.new(0,-.7*(tool:GetAttribute("VisualScale") or 1),0)})
 out:Play()
 task.delay(duration*.6,function()
  if joint.Parent then TweenService:Create(joint,TweenInfo.new(duration*.3),{C0=home}):Play() end
 end)
end
return Visuals
