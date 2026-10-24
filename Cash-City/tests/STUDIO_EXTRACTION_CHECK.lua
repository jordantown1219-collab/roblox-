-- Run against the Server datamodel during a solo match after routes spawn.
-- Regresses the v0.9 pad buried under a 0.35-stud footway.
local arena=workspace:WaitForChild("SmallSignalsArena")
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={arena.DetroitCityRoot}
local checked=0
for _,pad in ipairs(arena.RoundInteractions:GetChildren()) do
 if pad.Name=="Extraction" then
  local hit=workspace:Raycast(pad.Position+Vector3.new(0,10,0),Vector3.new(0,-20,0),params)
  assert(hit,"No city surface beneath extraction")
  assert(pad.Position.Y-pad.Size.Y/2>hit.Position.Y,"Extraction is buried beneath city surface")
  assert(pad:FindFirstChildOfClass("ProximityPrompt").Enabled,"Extraction prompt disabled")
  checked=checked+1
 end
end
assert(checked==2,"Expected both team extraction pads")
return "PASS: both extraction pads clear city surfaces"
