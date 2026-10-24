-- Server-owned preference cache. Inject a DataStore; no networking or engine globals.
local Preferences={}
local function validUser(userId)
 -- Native Studio multiplayer uses negative synthetic UserIds.
 return type(userId)=="number" and userId==userId and userId~=0 and math.abs(userId)<9007199254740992 and userId%1==0
end
local function validated(value,stored)
 if type(value)~="table" or getmetatable(value)~=nil then return nil end
 for key in pairs(value) do
  if key~="mode" and key~="teamSize" and not (stored and key=="version") then return nil end
 end
 if stored and value.version~=1 then return nil end
 if value.mode~="Extraction" or (value.teamSize~=3 and value.teamSize~=4 and value.teamSize~=5) then return nil end
 return {mode="Extraction",teamSize=value.teamSize}
end
local function copy(value) return {mode=value.mode,teamSize=value.teamSize} end
function Preferences.new(store)
 assert(store==nil or (type(store.GetAsync)=="function" and type(store.UpdateAsync)=="function"),"Expected injected preference store or nil")
 local cache={}
 local self={}
 local function entry(userId)
  assert(validUser(userId),"Invalid userId")
  if not cache[userId] then cache[userId]={value={mode="Extraction",teamSize=3},revision=0,dirty=false} end
  return cache[userId]
 end
 function self:get(userId) return copy(entry(userId).value) end
 function self:load(userId)
  local e=entry(userId)
  if e.loading then return copy(e.value),"loading" end
  if e.loaded then return copy(e.value),e.loadStatus end
  e.loading=true
  local revision=e.revision
  local ok,data=pcall(function() return store:GetAsync("u_"..string.format("%.0f",userId)) end)
  local preference=ok and validated(data,true) or nil
  local status=not ok and "loadFailed" or (data==nil and "default" or (preference and "loaded" or "invalidData"))
  if e.revision==revision and not e.dirty and preference then e.value=preference end
  e.loading=false e.loaded=true e.loadStatus=status
  return copy(e.value),status
 end
 function self:set(userId,value)
  assert(validUser(userId),"Invalid userId")
  local preference=validated(value,false)
  if not preference then return nil,"invalidPreferences" end
  local e=entry(userId)
  -- Even choosing current defaults during a pending load is an explicit choice.
  e.revision=e.revision+1
  if e.value.mode~=preference.mode or e.value.teamSize~=preference.teamSize then
   e.value=preference e.dirty=true
  elseif e.loading or not e.loaded or e.loadStatus=="loadFailed" or e.loadStatus=="invalidData" then
   e.dirty=true
  end
  return copy(e.value),"accepted"
 end
 function self:save(userId)
  local e=entry(userId)
  if e.saving then return false,"saving" end
  if not e.dirty then return true,"unchanged" end
  e.saving=true
  local revision=e.revision
  local snapshot=copy(e.value)
  local refused=false
  local ok,result=pcall(function()
   return store:UpdateAsync("u_"..string.format("%.0f",userId),function(previous)
    refused=previous~=nil and validated(previous,true)==nil
    if refused then return nil end -- Preserve unknown/future-version or unrelated data.
    return {version=1,mode=snapshot.mode,teamSize=snapshot.teamSize}
   end)
  end)
  e.saving=false
  local saved=ok and not refused and validated(result,true)
  if not saved or saved.mode~=snapshot.mode or saved.teamSize~=snapshot.teamSize then
   return false,ok and "saveRefused" or "saveFailed"
  end
  if e.revision==revision then e.dirty=false end
  return true,e.dirty and "newerChoicePending" or "saved"
 end
 function self:forget(userId)
  assert(validUser(userId),"Invalid userId")
  local e=cache[userId]
  if e and (e.loading or e.saving or e.dirty) then return false,"pendingPreferences" end
  cache[userId]=nil return true,"forgotten"
 end
 return self
end
return Preferences
