-- Run on Edit or Server. Checks actual Roblox instances, then removes fixtures.
local visuals=require(game.ServerScriptService.WeaponVisuals)
local checked=0
for _,name in ipairs({"Rifle","SMG","Knife"}) do
 for _,scale in ipairs({1,.65,.4,.22}) do
  local tool=Instance.new("Tool") visuals.build(tool,name,scale)
  local handle=tool:FindFirstChild("Handle") assert(handle,"Missing tool grip")
  for _,p in ipairs(tool:GetChildren()) do
   if p:IsA("BasePart") then
    assert(not p.CanCollide and p.Massless,"Weapon can obstruct player collision")
    if p~=handle then
     local joined=false
     for _,w in ipairs(handle:GetChildren()) do if w:IsA("Weld") and w.Part0==handle and w.Part1==p then joined=true break end end
     assert(joined,"Detached weapon part: "..p.Name)
    end
   end
  end
  if name~="Knife" then
   local muzzle=handle:FindFirstChild("Muzzle") assert(muzzle,"Missing muzzle")
   assert(muzzle.Position.Z<tool["Flash hider"].Position.Z,"Muzzle sits inside barrel")
   assert(handle:FindFirstChild("MagazineJoint"),"Magazine cannot reload")
  end
  tool:Destroy() checked=checked+1
 end
end
return "PASS: "..checked.." weapon/scale assemblies"
