-- Studio Server only. A fresh, scriptless rig per case prevents SeatWeld scaling of furniture.
-- Prepare CashCitySeatRigTemplate in ServerStorage from a healthy unseated avatar clone.
-- No live player is resized or repositioned. Not a device/multiplayer test.
assert(game:GetService('RunService'):IsStudio(),'Studio only')
local template=assert(game.ServerStorage:FindFirstChild('CashCitySeatRigTemplate'))
local lounge=workspace.SmallSignalsArena.DetroitCityRoot.Wintergarden.ArrivalLounge
local seats={} for _,v in lounge:GetChildren() do if v:IsA('Seat') then table.insert(seats,v) end end
local scale=.22 -- Run separately at 1, .65, .4, .22.
local results={}
for _,seat in ipairs(seats) do
 assert(not seat.Occupant,'Preserve occupied seat')
 local cf,size=seat.CFrame,seat.Size
 local rig=template:Clone() local h=rig:FindFirstChildOfClass('Humanoid')
 local ok,err=xpcall(function()
  rig:ScaleTo(scale) rig:PivotTo(cf*CFrame.new(0,3*scale,-4)) rig.Parent=workspace
  rig.HumanoidRootPart:SetNetworkOwner(nil)
  task.wait(.4) h:MoveTo(seat.Position) h.Jump=true
  local deadline=os.clock()+3
  repeat task.wait(.1) until seat.Occupant==h or os.clock()>deadline
  table.insert(results,{seat=tostring(cf.Position),scale=scale,seated=seat.Occupant==h,health=h.Health})
 end,debug.traceback)
 rig:Destroy() task.wait(.1)
 assert(seat.CFrame==cf and seat.Size==size,'Seat geometry changed')
 assert(ok,err)
end
return results
