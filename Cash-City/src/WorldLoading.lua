-- Server-only destination prefetch. No client-supplied destinations or readiness.
local WorldLoading={}
local pending={}
function WorldLoading.prepare(player,destination,stillValid)
 if pending[player] or not player.Parent then return false end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return false end
 if humanoid.SeatPart then
  humanoid.Sit=false
  task.wait()
  if player.Character~=character or not root.Parent then return false end
 end
 if not workspace.StreamingEnabled then return stillValid() end
 pending[player]=true
 local anchored=root.Anchored
 root.Anchored=true
 player:SetAttribute("RiverfrontLoading",true)
 local started=os.clock()
 local ok,err=pcall(function() player:RequestStreamAroundAsync(destination,4) end)
 -- Restore only this same character; a replacement character owns its own state.
 if root.Parent then root.Anchored=anchored end
 pending[player]=nil
 if player.Parent then
  player:SetAttribute("RiverfrontLoading",false)
  player:SetAttribute("RiverfrontLastPrefetchMs",math.floor((os.clock()-started)*1000))
 end
 if not ok then warn("Riverfront destination prefetch failed",err) return false end
 return player.Parent~=nil and player.Character==character and root.Parent~=nil
  and humanoid.Parent~=nil and humanoid.Health>0 and stillValid()
end
return WorldLoading
