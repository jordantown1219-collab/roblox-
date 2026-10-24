-- Per-client measurements, not an FPS guarantee. Sample locally through Player attributes.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Stats=game:GetService("Stats")
local CollectionService=game:GetService("CollectionService")
local player=Players.LocalPlayer
-- ReplicatedStorage is not spatially streamed, but a missing package must not
-- leave this optional helper waiting forever after an incomplete install.
local config=game.ReplicatedStorage:WaitForChild("SmallSignals",15)
if not config then warn("Riverfront client: SmallSignals package did not arrive") return end
local configModule=config:WaitForChild("Config",15)
local rulesModule=config:WaitForChild("InteractionRules",15)
if not configModule or not rulesModule then warn("Riverfront client: required modules did not arrive") return end
if require(configModule).ActiveMap~="DetroitRiverfront" then return end
local Rules=require(rulesModule)
local watched={}
local function applyPrompt(model,prompt)
 if not model.Parent or not prompt.Parent or not prompt:IsA("ProximityPrompt") then return end
 local range=Rules.range(model:GetAttribute("Range") or 9,player:GetAttribute("Scale") or 1)
 prompt.MaxActivationDistance=range or 3
end
local function promptRange(model)
 if not model.Parent then return end
 for _,desc in ipairs(model:GetDescendants()) do applyPrompt(model,desc) end
end
local function forget(model)
 local connections=watched[model]
 if not connections then return end
 for _,connection in ipairs(connections) do connection:Disconnect() end
 watched[model]=nil
end
local function watch(model)
 if watched[model] or not model.Parent then return end
 -- Tags may replicate before a nonatomic model's prompts. Listen for later
 -- descendants and reconnect when the tagged instance streams back in.
 watched[model]={
  model.DescendantAdded:Connect(function(desc) applyPrompt(model,desc) end),
  model:GetAttributeChangedSignal("Range"):Connect(function() promptRange(model) end),
 }
 promptRange(model)
end
local function updateRanges()
 for model in pairs(watched) do promptRange(model) end
end
player:GetAttributeChangedSignal("Scale"):Connect(updateRanges)
CollectionService:GetInstanceAddedSignal("SSInteractable"):Connect(watch)
CollectionService:GetInstanceRemovedSignal("SSInteractable"):Connect(forget)
for _,model in ipairs(CollectionService:GetTagged("SSInteractable")) do watch(model) end
local elapsed,frames,worst=0,0,0
RunService.RenderStepped:Connect(function(dt)
 elapsed=elapsed+dt frames=frames+1 worst=math.max(worst,dt)
 if elapsed>=5 then
  player:SetAttribute("RiverfrontSampleFPS",math.floor(frames/elapsed+.5))
  player:SetAttribute("RiverfrontWorstFrameMs",math.floor(worst*10000)/10)
  player:SetAttribute("RiverfrontClientMemoryMb",math.floor(Stats:GetTotalMemoryUsageMb()))
  elapsed,frames,worst=0,0,0
 end
end)
-- Credit stays available even if custom game menus are closed.
local playerGui=player:WaitForChild("PlayerGui",15)
if not playerGui then warn("Riverfront client: PlayerGui did not arrive") return end
local gui=Instance.new("ScreenGui") gui.Name,gui.ResetOnSpawn="RiverfrontCredits",false gui.Parent=playerGui
local credit=Instance.new("TextLabel") credit.Name,credit.AnchorPoint="Attribution",Vector2.new(.5,1)
credit.Position,credit.Size=UDim2.new(.5,0,1,-4),UDim2.new(.7,0,0,20)
credit.BackgroundTransparency,credit.TextSize,credit.Font=.25,10,Enum.Font.Gotham
credit.BackgroundColor3,credit.TextColor3=Color3.fromRGB(20,28,23),Color3.fromRGB(232,238,219)
credit.Text="Map data © OpenStreetMap contributors • ODbL • openstreetmap.org/copyright"
credit.TextWrapped,credit.Parent=true,gui

local loading=Instance.new("TextLabel")
loading.Name="DestinationLoading"
loading.AnchorPoint=Vector2.new(.5,0)
loading.Position,loading.Size=UDim2.new(.5,0,0,18),UDim2.fromOffset(270,36)
loading.BackgroundColor3,loading.TextColor3=Color3.fromRGB(20,28,23),Color3.fromRGB(242,244,238)
loading.BackgroundTransparency,loading.TextSize,loading.Font=.1,16,Enum.Font.GothamMedium
loading.Text="Loading destination…"
loading.Parent=gui
local function refreshLoading() loading.Visible=player:GetAttribute("RiverfrontLoading")==true end
player:GetAttributeChangedSignal("RiverfrontLoading"):Connect(refreshLoading)
refreshLoading()
