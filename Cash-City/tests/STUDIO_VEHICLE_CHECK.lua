-- Run on Server during Play after Arena.build.
local root=workspace:WaitForChild("SmallSignalsArena")
local car=root:WaitForChild("Riverfront SUV")
local motors,steering=0,0
for _,v in ipairs(car:GetDescendants()) do
 if v:IsA("HingeConstraint") then
  assert(v.Attachment0 and v.Attachment1,"Disconnected wheel constraint")
  if v.Name=="WheelMotor" then motors=motors+1 end
  if v.Name=="Steering" then steering=steering+1 end
 elseif v:IsA("BasePart") then assert(not v.Anchored,"Driveable car has anchored part") end
end
assert(motors==4 and steering==2,"Expected four driven wheels and two steering hubs")
assert(car:FindFirstChild("DriverSeat"),"No driver seat")
assert(root:FindFirstChild("Parked SUV - graphite"),"Parked variant missing")
assert(root:FindFirstChild("Parked SUV - riverwalk"),"Second parked variant missing")
return "PASS: complete chassis connections and parked variants"
