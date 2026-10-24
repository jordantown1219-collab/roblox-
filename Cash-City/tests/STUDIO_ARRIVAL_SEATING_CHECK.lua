-- Run on Server in solo Studio Practice with a healthy character. Never install as production script.
-- Exercises built-in seat touching via Humanoid approach+jump; no Seat:Sit shortcut.
local RunService=game:GetService('RunService')
assert(RunService:IsStudio() and RunService:IsServer(),'Studio Server only')
local player=assert(game.Players:GetPlayers()[1],'Player required')
local character=assert(player.Character,'Character required')
local humanoid=assert(character:FindFirstChildOfClass('Humanoid'))
assert(humanoid.Health>0 and not humanoid.Sit,'Healthy standing character required')
local root=character:WaitForChild('HumanoidRootPart')
local lounge=workspace.SmallSignalsArena.DetroitCityRoot.Wintergarden.ArrivalLounge
local original,scale=character:GetPivot(),character:GetScale()
local owner,automatic=root:GetNetworkOwner(),root:GetNetworkOwnershipAuto()
local results={}
local seatIndex=0
local requestedSeatIndex=1 -- Run one seat per fresh Practice session; 1 through 4.
local function detach()
 humanoid.Sit=false humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
 local deadline=os.clock()+4
 repeat task.wait(.1) until humanoid.SeatPart==nil and not lounge:FindFirstChild('SeatWeld',true) or os.clock()>deadline
 assert(humanoid.SeatPart==nil and not lounge:FindFirstChild('SeatWeld',true),'Seat weld still attached; never scale welded furniture')
end
local ok,err=xpcall(function()
 root:SetNetworkOwner(nil) -- Avoid a client controller overwriting server MoveTo during the fixture.
 for _,seat in ipairs(lounge:GetChildren()) do if seat:IsA('Seat') then
  seatIndex+=1
  if seatIndex==requestedSeatIndex then
  assert(not seat.Occupant,'Seat occupied; preserve other players')
  for _,size in ipairs({1,.65,.4,.22}) do
   detach() task.wait(3.1)
   local seatFrame,seatSize=seat.CFrame,seat.Size
   character:ScaleTo(size)
   assert(seat.CFrame==seatFrame and seat.Size==seatSize,'Fixture changed seat')
   character:PivotTo(seat.CFrame*CFrame.new(0,3*size,-4))
   task.wait(.4)
   humanoid:MoveTo(seat.Position) humanoid.Jump=true
   local deadline=os.clock()+4
   repeat task.wait(.1) until seat.Occupant==humanoid or os.clock()>deadline
   table.insert(results,{seat=tostring(seat.Position),scale=size,seated=seat.Occupant==humanoid,health=humanoid.Health})
   detach()
  end
  end
 end end
end,debug.traceback)
if character.Parent==workspace and root:IsDescendantOf(workspace) then
 local restored,restoreError=pcall(function()
  detach() character:ScaleTo(scale) character:PivotTo(original)
  if automatic then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(owner) end
 end)
 if not restored then ok=false err=tostring(err or '')..' Cleanup: '..tostring(restoreError) end
else
 ok=false err=tostring(err or '')..' Character replaced during fixture; Play reset required'
end
assert(ok,err)
return results
