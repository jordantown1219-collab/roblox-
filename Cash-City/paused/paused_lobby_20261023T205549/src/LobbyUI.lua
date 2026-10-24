-- Original lobby presentation; server snapshots are the only vote/readiness truth.
local LobbyUI={}
local GuiService=game:GetService("GuiService")
local HttpService=game:GetService("HttpService")
local BG=Color3.fromRGB(19,25,30)
local CARD=Color3.fromRGB(34,43,49)
local TEXT=Color3.fromRGB(240,241,231)
local MUTED=Color3.fromRGB(183,194,197)
local ACCENT=Color3.fromRGB(209,171,90)
function LobbyUI.new(player,remote)
 assert(player and remote,"LobbyUI needs player and action remote")
 local self={snapshot=nil,selectedTeam=nil,userChosen=false,defaultsApplied=false,alive=true,visible=true,available=true,signature=nil}
 local connections={}
 local gui=Instance.new("ScreenGui") gui.Name="CashCityLobby" gui.ResetOnSpawn=false
 gui.DisplayOrder=35 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling gui.IgnoreGuiInset=false
 gui.Parent=player:WaitForChild("PlayerGui")
 local function create(class,parent,props)
  local obj=Instance.new(class) for k,v in pairs(props or {}) do obj[k]=v end obj.Parent=parent return obj
 end
 local function round(obj)
  create("UICorner",obj,{CornerRadius=UDim.new(0,8)})
 end
 local function text(parent,value,height,size,color)
  return create("TextLabel",parent,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,height),Font=Enum.Font.Gotham,
   Text=value,TextSize=size or 17,TextColor3=color or TEXT,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left})
 end
 local function button(parent,value,fn,enabled)
  local b=create("TextButton",parent,{Size=UDim2.new(1,0,0,56),Text=value,Font=Enum.Font.GothamMedium,TextSize=17,
   TextColor3=enabled==false and MUTED or TEXT,BackgroundColor3=CARD,AutoButtonColor=enabled~=false,
   TextWrapped=true,Selectable=enabled~=false,Active=enabled~=false})
  round(b) create("UIPadding",b,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})
  if enabled~=false then b.Activated:Connect(fn) end
  return b
 end
 local panel=create("Frame",gui,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(1,-24,1,-24),BackgroundColor3=BG})
 round(panel) create("UISizeConstraint",panel,{MaxSize=Vector2.new(740,740),MinSize=Vector2.new(0,0)})
 local header=create("Frame",panel,{BackgroundTransparency=1,Position=UDim2.fromOffset(16,8),Size=UDim2.new(1,-32,0,64)})
 local title=text(header,"CASH CITY",26,23,ACCENT) title.Size=UDim2.new(1,-64,0,26)
 local countdown=text(header,"Waiting for lobby…",32,15,MUTED) countdown.Position=UDim2.fromOffset(0,27) countdown.Size=UDim2.new(1,-64,0,32)
 local close=button(header,"×",function() self:SetVisible(false) end)
 close.Name="CloseLobby" close.Size=UDim2.fromOffset(52,52) close.Position=UDim2.new(1,-52,0,0)
 local open=button(gui,"Lobby",function() self:SetVisible(true) end)
 open.Name="OpenLobby" open.Size=UDim2.fromOffset(112,52) open.Position=UDim2.new(0,14,1,-66) open.Visible=false
 local scroll=create("ScrollingFrame",panel,{Name="LobbyContent",Position=UDim2.fromOffset(16,80),Size=UDim2.new(1,-32,1,-96),
  BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=6,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
  ScrollingDirection=Enum.ScrollingDirection.Y,Selectable=false})
 create("UIListLayout",scroll,{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
 create("UIPadding",scroll,{PaddingRight=UDim.new(0,12),PaddingBottom=UDim.new(0,16)})
 local focusButtons={}
 local function send(action,payload)
  if self.alive then remote:FireServer(action,payload) end
 end
 local function clock()
  local s=self.snapshot
  if not s then countdown.Text="Connecting to lobby…" return end
  local remaining=type(s.deadline)=="number" and math.max(0,math.ceil(s.deadline-workspace:GetServerTimeNow())) or nil
  countdown.Text=(s.phase=="MapVote" and "Map vote" or "Find your squad")..(remaining and ("  ·  "..remaining.."s") or "")
 end
 local function linkFocus()
  for i,b in ipairs(focusButtons) do
   b.NextSelectionUp=focusButtons[i-1] or close
   b.NextSelectionDown=focusButtons[i+1] or close
  end
  close.NextSelectionDown=focusButtons[1] or close close.NextSelectionUp=focusButtons[#focusButtons] or close
 end
 local function focus(b,key) b:SetAttribute("LobbyFocusKey",key) if b.Selectable then table.insert(focusButtons,b) end return b end
 local function redraw()
  if not self.alive then return end
  local s=self.snapshot or {}
  local oldY=scroll.CanvasPosition.Y
  local selected=GuiService.SelectedObject
  local focusKey=selected and selected:IsDescendantOf(scroll) and selected:GetAttribute("LobbyFocusKey") or nil
  for _,obj in ipairs(scroll:GetChildren()) do if obj:IsA("GuiObject") then obj:Destroy() end end
  focusButtons={}
  local order=0
  local function row(obj) order=order+1 obj.LayoutOrder=order return obj end
  local function label(value,height,size,color) return row(text(scroll,value,height,size,color)) end
  local function action(value,fn,enabled,key) return row(focus(button(scroll,value,fn,enabled),key)) end
  if not self.snapshot then label("Connecting to lobby…",48)
  elseif s.phase=="MapVote" then
   label("CHOOSE THE NEXT MAP",32,20,ACCENT)
   label(s.canVoteMap and "Your confirmed vote is shown below. The server counts every vote." or "A queued squad is choosing its map. Wait for the next queue to join.",56,15,MUTED)
   local maps=s.maps or {}
   if #maps==0 then label("Waiting for available maps…",56) end
   for _,map in ipairs(maps) do
    local mapId=map.id
    local votes=(s.mapVotes or {})[mapId] or 0
    local caption=tostring(map.label or mapId).."  ·  "..tostring(map.size or "Map").."\n"..
     "Recommended team: "..tostring(map.recommendedTeamSize or "—").."  ·  "..tostring(votes).." votes"
    if s.votedMap==mapId then caption=caption.."  ·  Your vote" end
    if not map.available then caption=caption.."  ·  Unavailable" end
    local epoch=s.epoch
    local b=action(caption,function() send("LobbyMapVote",{epoch=epoch,mapId=mapId}) end,map.available==true and s.canVoteMap==true,"map_"..tostring(mapId))
    b.Size=UDim2.new(1,0,0,88)
    if s.votedMap==mapId then b.TextColor3=ACCENT end
   end
  else
   label("PLAY EXTRACTION",32,20,ACCENT)
   label("Choose a team size, then ready up. Match rules stay with the server.",48,15,MUTED)
   label("GAME MODES",24,14,MUTED)
   for _,mode in ipairs(s.modes or {{id="Extraction",label="Extraction",available=true}}) do
    -- Only Extraction is implemented, even if an invalid snapshot advertises another mode.
    local available=mode.id=="Extraction" and mode.available==true
    local b=action(tostring(mode.label or mode.id)..(available and "  ·  Available" or "  ·  Locked: gameplay not ready"),function() end,false,"mode_"..tostring(mode.id))
    b.Size=UDim2.new(1,0,0,64)
   end
   label("PLAYERS PER TEAM",24,14,MUTED)
   for _,n in ipairs({3,4,5}) do
    local count=(s.queues or {})[n] or (s.queues or {})[tostring(n)] or 0
    local chosen=self.selectedTeam==n
    local b=action(tostring(n).." per team  ·  "..tostring(count).." joined"..(chosen and "  ·  Selected" or ""),function()
     self.selectedTeam=n self.userChosen=true redraw()
    end,not s.ready,"team_"..n)
    if chosen then b.TextColor3=ACCENT end
   end
   if s.ready then
    label("READY  ·  "..tostring(s.teamSize or self.selectedTeam).." per team",32,18,ACCENT)
    action("Leave queue",function() send("LobbyLeave",{}) end,true,"leave")
   else
    action("Ready up",function() send("LobbyJoin",{mode="Extraction",teamSize=self.selectedTeam or 3}) end,true,"ready")
   end
   label("After 90 seconds, queued players can vote to start a smaller match.",52,15,MUTED)
   local votes=tonumber(s.startVotes) or 0
   local needed=tonumber(s.startNeeded) or 0
   local epoch=s.epoch
   action("Start smaller match  ·  "..votes.." / "..needed.." votes",function()
    send("LobbyStartVote",{epoch=epoch})
   end,s.canStartSmall==true,"start_small")
   if not s.canStartSmall then label("Available when the server unlocks the smaller-match vote.",44,14,MUTED) end
   if game:GetService("RunService"):IsStudio() then
    action("Solo practice  ·  Studio only",function() send("Practice") end,true,"practice")
   end
  end
  linkFocus() clock()
  scroll.CanvasPosition=Vector2.new(0,oldY)
  if focusKey then for _,b in ipairs(focusButtons) do if b:GetAttribute("LobbyFocusKey")==focusKey then GuiService.SelectedObject=b break end end end
  if self.available and self.visible and (GuiService:IsTenFootInterface() or game:GetService("UserInputService").GamepadEnabled) then
   local current=GuiService.SelectedObject
   -- A redraw can destroy the selected widget; repair focus only when lost.
   if not current or not current.Parent then GuiService.SelectedObject=focusButtons[1] or close end
  end
 end
 function self:Update(snapshot)
  if not self.alive or type(snapshot)~="table" then return end
  self.snapshot=snapshot
  if not self.userChosen and not self.defaultsApplied and snapshot.defaults then
   local n=(snapshot.ready and snapshot.teamSize) or snapshot.defaults.teamSize or 3
   self.selectedTeam=(n==3 or n==4 or n==5) and n or 3
   self.defaultsApplied=true
  end
  if not self.selectedTeam then self.selectedTeam=3 end
  -- deadline changes need only countdown refresh. Content changes rebuild bounded cards.
  local relevant={} for k,v in pairs(snapshot) do if k~="deadline" then relevant[k]=v end end
  local ok,signature=pcall(HttpService.JSONEncode,HttpService,relevant)
  if not ok or signature~=self.signature then self.signature=ok and signature or nil redraw() else clock() end
 end
 function self:SetVisible(visible)
  if not self.alive then return end
  visible=visible==true
  if self.visible==visible then return end
  self.visible=visible panel.Visible=self.visible open.Visible=not self.visible
  if not self.available then return end
  local selected=GuiService.SelectedObject
  if self.visible then
   if GuiService:IsTenFootInterface() or game:GetService("UserInputService").GamepadEnabled then GuiService.SelectedObject=focusButtons[1] or close end
  elseif selected and selected:IsDescendantOf(panel) then GuiService.SelectedObject=open end
 end
 function self:SetAvailable(available)
  if not self.alive then return end
  available=available==true
  if self.available==available then return end
  self.available=available gui.Enabled=available
  local selected=GuiService.SelectedObject
  if not available then
   if selected and selected:IsDescendantOf(gui) then GuiService.SelectedObject=nil end
  elseif GuiService:IsTenFootInterface() or game:GetService("UserInputService").GamepadEnabled then
   GuiService.SelectedObject=self.visible and (focusButtons[1] or close) or open
  end
 end
 function self:Destroy()
  if not self.alive then return end self.alive=false
  if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then GuiService.SelectedObject=nil end
  for _,connection in ipairs(connections) do connection:Disconnect() end
  if self.timer then pcall(task.cancel,self.timer) end
  gui:Destroy()
 end
 redraw()
 self:SetVisible(true) -- Initial gamepad focus after parent/controls exist.
 self.timer=task.spawn(function() while self.alive do task.wait(.5) if self.alive then clock() end end end)
 return self
end
return LobbyUI
