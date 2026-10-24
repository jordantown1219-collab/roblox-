-- Read-only native geometry QA. Lead requires a fresh harness ModuleScript,
-- then calls returned function(cityRoot, decodedRenCenPlan) AFTER integration.
-- Explicit Include root prevents unrelated world/character hits. No Instance edits.
return function(cityRoot,plan)
 assert(typeof(cityRoot)=="Instance","Expected integrated city root")
 assert(type(plan)=="table" and plan.id=="RenCenPromenade_69706033","Unexpected promenade plan")
 local deck=assert(plan.records and plan.records[1],"Missing continuous collision record")
 local cf=CFrame.new(deck.pos[1],deck.pos[2],deck.pos[3],table.unpack(deck.matrix))
 local expectedTop=deck.pos[2]+deck.size[2]/2
 assert(math.abs(expectedTop-.41)<.0001,"Unexpected plan top")
 local workspaceService=game:GetService("Workspace")
 local players=game:GetService("Players")
 local rayParams=RaycastParams.new()
 rayParams.FilterType=Enum.RaycastFilterType.Include
 -- Exclude character descendants even when a caller incorrectly uses Workspace.
 -- Generated detail Parts must be queryable for ray acceptance; transparent
 -- collision decks remain queryable unless integration explicitly changes it.
 local included={}
 local characters={}
 for _,player in ipairs(players:GetPlayers()) do if player.Character then characters[player.Character]=true end end
 local function isCharacter(obj)
  local parent=obj
  while parent do
   if characters[parent] or (parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid")) then return true end
   if parent==cityRoot then break end parent=parent.Parent
  end
  return false
 end
 if cityRoot:IsA("BasePart") and not isCharacter(cityRoot) then table.insert(included,cityRoot) end
 for _,obj in ipairs(cityRoot:GetDescendants()) do
  if obj:IsA("BasePart") and not isCharacter(obj) then table.insert(included,obj) end
 end
 rayParams.FilterDescendantsInstances=included
 rayParams.IgnoreWater=false
 rayParams.RespectCanCollide=true -- Check physical support, not decorative panels.
 local failures,samples={},{}
 local halfWidth,halfLength=deck.size[1]/2,deck.size[3]/2
 local rows=40
 -- 41 center rays at both route endpoints and every paving row joint.
 -- Two side tracks at 21 stations add42 rays; total83 <=100.
 local positions={}
 for row=0,rows do table.insert(positions,{x=0,z=-halfLength+deck.size[3]*row/rows,label="center_joint_"..row}) end
 for row=0,20 do for _,sign in ipairs({-1,1}) do
  table.insert(positions,{x=sign*(halfWidth-.04),z=-halfLength+deck.size[3]*row/20,label="side_"..sign.."_"..row})
 end end
 for _,point in ipairs(positions) do
  local position=cf:PointToWorldSpace(Vector3.new(point.x,0,point.z))
  -- Inset endpoint rays by0.01stud to avoid floating-point boundary ambiguity.
  if math.abs(point.z)>=halfLength-.001 then
   position=cf:PointToWorldSpace(Vector3.new(point.x,0,point.z>0 and halfLength-.01 or -halfLength+.01))
  end
  local ray=workspaceService:Raycast(Vector3.new(position.X,expectedTop+2,position.Z),Vector3.new(0,-4,0),rayParams)
  local reason
  if not ray then reason="no queryable surface"
  elseif math.abs(ray.Position.Y-expectedTop)>.025 then reason="surface height differs from expected .41"
  elseif ray.Normal:Dot(Vector3.new(0,1,0))<.999 then reason="surface normal is not upward"
  elseif not ray.Instance.CanCollide then reason="continuous colliding support missing" end
  local result={id=point.label,worldXZ={position.X,position.Z},hit=ray and ray.Instance:GetFullName() or nil,height=ray and ray.Position.Y or nil,normalY=ray and ray.Normal.Y or nil}
  table.insert(samples,result)
  if reason then result.reason=reason table.insert(failures,result) end
 end
 local endpoints={}
 for _,z in ipairs({-halfLength+.01,halfLength-.01}) do
  local p=cf:PointToWorldSpace(Vector3.new(0,0,z))
  table.insert(endpoints,{p.X,expectedTop,p.Z})
 end
 return {passed=#failures==0,sampleCount=#samples,failures=failures,samples=samples,
         expectedTopStuds=expectedTop,routeSurfaceEndpointsStudsXYZ=endpoints,
         scope="read-only static rays; not avatar, streaming, visual, multiplayer, device or FPS acceptance"}
end
