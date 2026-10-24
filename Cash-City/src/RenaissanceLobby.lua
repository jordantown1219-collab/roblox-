-- Original estimated interior. Only the guarded podium face is archived; source data is untouched.
local Lobby={}
local busy=setmetatable({},{__mode='k'})
local keys={'CanCollide','CanQuery','CanTouch','CastShadow','Transparency'}
local function frame(r) return CFrame.new(r.pos[1],r.pos[2],r.pos[3],table.unpack(r.matrix)) end
local function shapeMatches(p,r)
 local cf=frame(r)
 return p.Name==r.name and (p.Size-Vector3.new(table.unpack(r.size))).Magnitude<.01
  and (p.Position-cf.Position).Magnitude<.01 and (p.CFrame.RightVector-cf.RightVector).Magnitude<.001
  and (p.CFrame.UpVector-cf.UpVector).Magnitude<.001
end
local function finishMatches(p,r)
 local c=Color3.fromRGB(table.unpack(r.color))
 return p.Material==Enum.Material[r.material] and math.abs(p.Color.R-c.R)<.001 and math.abs(p.Color.G-c.G)<.001 and math.abs(p.Color.B-c.B)<.001
end
local function owned(model,id)
 local marker=model and model:FindFirstChild('CashCityGeneratedBlockManifest')
 return model and (model:GetAttribute('CashCityGeneratedBlock')==true or (marker and marker:IsA('StringValue') and marker.Value==id))
end
function Lobby.build(root,input)
 assert(not busy[root],'Lobby build already active')
 busy[root]=true
 local stage=Instance.new('Folder')
 local ok,result,stats=pcall(function()
  -- Snapshot before the first yielding generator call.
  local http=game:GetService('HttpService')
  local plan=http:JSONDecode(http:JSONEncode(input or require(script.Parent.RenaissanceLobbyData)))
  assert(#plan.sourceReplacements>=1 and #plan.sourceReplacements<=2,'Unexpected podium guard count')
  local rootParent=root.Parent
  local previous=root:FindFirstChild(plan.id)
  assert(not previous or owned(previous,plan.id),'Preserve manual lobby')
  local archive=root:FindFirstChild('RenaissanceLobbySourceArchive')
  local marker=archive and archive:FindFirstChild('CashCityLobbyArchiveManifest')
  assert(not archive or archive:GetAttribute('CashCityLobbyArchive')==true or (marker and marker:IsA('StringValue') and marker.Value==plan.id),'Preserve manual archive')
  local originals={} local indices={}
  for _,guard in ipairs(plan.sourceReplacements) do
   assert((guard.sourceIndex==19478 or guard.sourceIndex==19465) and not indices[guard.sourceIndex],'Unexpected/duplicate podium guard')
   indices[guard.sourceIndex]=true
   local r=guard.record local source
   assert(r.name=='Facade_1307210646','Unexpected source building')
   for _,p in ipairs(root:GetDescendants()) do
    if p:IsA('BasePart') and shapeMatches(p,r) then assert(not source,'Ambiguous podium source') source=p end
   end
   assert(source,'Podium source missing or changed')
   local archived=archive and source:IsDescendantOf(archive)
   if archived and source:GetAttribute('RL_SourceIndex')==nil then
    local saved=assert(source:FindFirstChild('RLOriginalState'),'Missing archived flags')
    local state=http:JSONDecode(saved.Value)
    for _,key in ipairs(keys) do
     local value=state[key]
     if key=='Transparency' then value=tonumber(value) or 0
     elseif value==nil then value=key~='CanTouch' else value=value=='true' end
     source:SetAttribute('RL_Original'..key,value)
    end
    source:SetAttribute('RL_SourceIndex',state.index)
   end
   local finishAllowed=finishMatches(source,r)
   for _,entry in ipairs(require(script.Parent.RenaissanceData).guards) do
    if shapeMatches(source,entry.record) and entry.finish and finishMatches(source,entry.finish) then finishAllowed=true end
   end
   assert(finishAllowed,'Podium finish changed; preserve current work')
   assert((archived and source:GetAttribute('RL_OriginalCanCollide') or source.CanCollide)==r.collide,'Podium collision changed')
   if archived then assert(source:GetAttribute('RL_SourceIndex')==guard.sourceIndex,'Archive identity changed') end
   local before={parent=source.Parent,cf=source.CFrame,size=source.Size,color=source.Color,material=source.Material}
   for _,key in ipairs(keys) do before[key]=source[key] end
   table.insert(originals,{part=source,index=guard.sourceIndex,archived=archived,before=before})
  end
  local model,buildStats=require(script.Parent.CityBlockGenerator).build(stage,plan,nil,80)
  model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  local recordsByName={} for _,record in ipairs(plan.records) do recordsByName[record.name]=record end
  for _,part in ipairs(model:GetDescendants()) do if part:IsA('BasePart') then
   part.CastShadow=false
   local record=recordsByName[part.Name]
   if record and record.seat then
    local seat=Instance.new('Seat') seat.Name=part.Name seat.Size=part.Size seat.CFrame=part.CFrame
    seat.Color=part.Color seat.Material=part.Material seat.Anchored=true seat.CanCollide=true seat.CanTouch=true seat.CastShadow=false
    seat.Disabled=false seat.Parent=part.Parent part:Destroy() part=seat
   end
   if record and record.shape then part.Shape=assert(({[0]=Enum.PartType.Ball,[1]=Enum.PartType.Block,[2]=Enum.PartType.Cylinder})[record.shape],'Unsupported lobby shape') end
   local signText=record and record.signText
   if part.Name=='Lobby_GenericHotelSignBoard' then signText=plan.signAnchors[1].text end
   if signText then
    for _,face in ipairs({Enum.NormalId.Right,Enum.NormalId.Left}) do
     local gui=Instance.new('SurfaceGui') gui.Face=face gui.CanvasSize=Vector2.new(800,240) gui.LightInfluence=0 gui.Parent=part
     local text=Instance.new('TextLabel') text.Size=UDim2.fromScale(1,1) text.BackgroundTransparency=1 text.Text=(face==Enum.NormalId.Right and record.returnText) or signText text.TextScaled=true text.TextColor3=Color3.fromRGB(238,235,214) text.Font=Enum.Font.GothamMedium text.Parent=gui
    end
   end
  end end
  -- Guard all consumed original state after generator yields, before replacing any live work.
  assert(root.Parent==rootParent,'City parent changed during build')
  for _,entry in ipairs(originals) do
   local source,before=entry.part,entry.before
   assert(source.Parent==before.parent and source.CFrame==before.cf and source.Size==before.size and source.Color==before.color and source.Material==before.material,'Podium changed during build')
   for _,key in ipairs(keys) do assert(source[key]==before[key],'Podium flags changed during build') end
  end
  assert(root:FindFirstChild(plan.id)==previous and (not previous or owned(previous,plan.id)),'Lobby destination changed during build')
  assert(root:FindFirstChild('RenaissanceLobbySourceArchive')==archive,'Archive destination changed during build')
  -- Door components share the existing server interaction registry; no per-door scripts.
  for _,anchor in ipairs(plan.doorAnchors or {}) do
   local width,height=anchor.width,anchor.height
   local door=require(script.Parent.BuildingInteractions).door({apertureWidth=width,apertureHeight=height,color=Color3.fromRGB(126,142,146)})
   door.Name='RenaissanceLobbyDoor_'..anchor.name
   local cf=frame(anchor) door:PivotTo(cf)
   door.Control.CFrame=cf*CFrame.new(-width/2+.05,-height/2+1.2,-.65)
   door.Parent=model
  end
  if not archive then archive=Instance.new('Folder') archive.Name='RenaissanceLobbySourceArchive' archive:SetAttribute('CashCityLobbyArchive',true) archive.Parent=root end
  archive:SetAttribute('CashCityLobbyArchive',true)
  for _,entry in ipairs(originals) do
   local source=entry.part
   if not entry.archived then
    for _,key in ipairs(keys) do source:SetAttribute('RL_Original'..key,source[key]) end
    source:SetAttribute('RL_SourceIndex',entry.index) source.Parent=archive
   end
   source.Transparency=1 source.CanCollide=false source.CanQuery=false source.CanTouch=false source.CastShadow=false
  end
  if previous then previous:Destroy() end
  model:SetAttribute('ReferenceStatus','Historical circulation concept; original estimated room heights and dimensions')
  model.Parent=root
  return model,buildStats
 end)
 stage:Destroy() busy[root]=nil
 if not ok then error(result,2) end
 return result,stats
end
return Lobby
