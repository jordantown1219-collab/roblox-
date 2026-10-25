-- Original daylight/water finish. No geometry, physics, weather loop or camera changes.
local Appearance={}
local Lighting=game:GetService("Lighting")
local function ownedEffect(class,name)
 local effect=Lighting:FindFirstChild(name)
 assert(not effect or (effect:IsA(class) and effect:GetAttribute("CashCityOwned")==true),"Preserve custom lighting effect")
 if not effect then
  effect=Instance.new(class);effect.Name=name;effect:SetAttribute("CashCityOwned",true);effect.Parent=Lighting
 end
 return effect
end
local function sameColor(a,b)
 return math.abs(a.R-b.R)<.001 and math.abs(a.G-b.G)<.001 and math.abs(a.B-b.B)<.001
end
function Appearance.apply(city)
 assert(typeof(city)=="Instance","Expected existing Detroit city")
 Lighting.ClockTime=14
 Lighting.Brightness=2.3
 Lighting.Ambient=Color3.fromRGB(77,84,94)
 Lighting.OutdoorAmbient=Color3.fromRGB(111,119,128)
 Lighting.ExposureCompensation=.05
 Lighting.EnvironmentDiffuseScale=.45
 Lighting.EnvironmentSpecularScale=.65
 Lighting.ShadowSoftness=.35
 local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere")
 local atmospherePreserved=atmosphere and atmosphere.Name~="CashCityRiverfrontAtmosphere" or false
 if not atmospherePreserved then
  atmosphere=ownedEffect("Atmosphere","CashCityRiverfrontAtmosphere")
  atmosphere.Color=Color3.fromRGB(204,216,225);atmosphere.Decay=Color3.fromRGB(150,166,177)
  atmosphere.Density=.16;atmosphere.Offset=.08;atmosphere.Haze=.8;atmosphere.Glare=0
 end
 local grade=ownedEffect("ColorCorrectionEffect","CashCityRiverfrontGrade")
 grade.Brightness=0;grade.Contrast=.04;grade.Saturation=-.05;grade.TintColor=Color3.fromRGB(255,250,242);grade.Enabled=true
 local changed,skipped=0,0
 for index,p in ipairs(city:GetDescendants()) do
  if p:IsA("BasePart") and p.Name=="DetroitRiver" then
   if p:GetAttribute("CashCityRiverFinish")==true or (p.Material==Enum.Material.Glass and sameColor(p.Color,Color3.fromRGB(39,88,100))) then
    if p:GetAttribute("CashCityRiverPreviousColor")==nil then
     p:SetAttribute("CashCityRiverPreviousColor",p.Color)
     p:SetAttribute("CashCityRiverPreviousTransparency",p.Transparency)
     p:SetAttribute("CashCityRiverPreviousReflectance",p.Reflectance)
    end
    p.Color=Color3.fromRGB(43,80,84);p.Transparency=.1;p.Reflectance=.06
    p:SetAttribute("CashCityRiverFinish",true);changed=changed+1
   else skipped=skipped+1 end
  end
  if index%1000==0 then task.wait() end
 end
 return {riverParts=changed,customRiverPartsPreserved=skipped,customAtmospherePreserved=atmospherePreserved}
end
return Appearance
