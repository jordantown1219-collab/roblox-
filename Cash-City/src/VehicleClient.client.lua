local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local remote=game.ReplicatedStorage:WaitForChild("SmallSignals"):WaitForChild("VehicleControl",30)
if not remote then return end
local car,seat,braking=nil,nil,false
local gui=Instance.new("ScreenGui") gui.Name="RiverfrontDriving" gui.ResetOnSpawn=false gui.Parent=player:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel") label.AnchorPoint=Vector2.new(.5,1) label.Position=UDim2.new(.5,0,1,-48) label.Size=UDim2.new(.8,0,0,60)
label.BackgroundColor3=Color3.fromRGB(24,28,30) label.BackgroundTransparency=.1 label.TextColor3=Color3.fromRGB(240,240,228)
label.Font=Enum.Font.GothamMedium label.TextSize=15 label.TextWrapped=true label.Visible=false label.Parent=gui
local actions={Brake=Enum.KeyCode.Space,Lights=Enum.KeyCode.L,Horn=Enum.KeyCode.H,Reset=Enum.KeyCode.R,Exit=Enum.KeyCode.X}
local function bind()
 for name,key in pairs(actions) do
  CAS:BindAction("Vehicle"..name,function(_,state)
   if not car then return Enum.ContextActionResult.Pass end
   if name=="Brake" then braking=state==Enum.UserInputState.Begin
   elseif state==Enum.UserInputState.Begin then remote:FireServer(car,name) end
   return Enum.ContextActionResult.Sink
  end,true,key)
  CAS:SetTitle("Vehicle"..name,name)
 end
end
local function clear()
 for name in pairs(actions) do CAS:UnbindAction("Vehicle"..name) end
 car,seat,braking=nil,nil,false label.Visible=false
end
local function character(char)
 clear()
 local h=char:WaitForChild("Humanoid",10) if not h then return end
 h.Seated:Connect(function(active,newSeat)
  clear()
  if not active or not newSeat or not newSeat:IsA("VehicleSeat") then return end
  local m=newSeat:FindFirstAncestorOfClass("Model")
  if not m or not m:GetAttribute("RiverfrontVehicle") then return end
  car,seat=m,newSeat label.Visible=true bind()
 end)
end
player.CharacterAdded:Connect(character)
if player.Character then task.spawn(character,player.Character) end
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed=elapsed+dt
 if elapsed<.1 or not car or not seat or not seat.Parent then return end
 elapsed=0
 remote:FireServer(car,"Drive",seat.ThrottleFloat,seat.SteerFloat,braking)
 label.Text="RIVERFRONT SUV  •  "..tostring(car:GetAttribute("Speed") or 0).." studs/s\nW/S accelerate/reverse • A/D steer • Space brake • L lights • H horn • R recover • X exit"
end)
