-- Bounded copied-layout batch. Existing floors are never rebuilt or replaced.
local Batch={}
function Batch.build(root,suppliedData)
 local data=suppliedData or require(script.Parent.ResidentialFloorBatchData)
 assert(type(data.first)=='number' and type(data.last)=='number' and data.first%1==0 and data.last%1==0 and data.first>=3 and data.last<=39 and data.last>=data.first and data.last-data.first<=2,'Invalid bounded floor batch')
 assert(#data.connections==data.last-data.first+1,'Unexpected connection count')
 assert(root:FindFirstChild('ResidentialTowerA_Level'..string.format('%02d',data.first-1)),'Previous floor required')
 for level=data.first,data.last do
  local connection=data.connections[level-data.first+1]
  assert(connection.levels[1]==80+12*(level-2) and connection.levels[3]==80+12*(level-1),'Stair levels do not match floor batch')
  assert(not root:FindFirstChild('ResidentialTowerA_Level'..string.format('%02d',level)),'Preserve existing floor')
  assert(not root:FindFirstChild(data.connections[level-data.first+1].id),'Preserve existing stair connection')
 end
 local results={}
 for level=data.first,data.last do
  local floor=require(script.Parent.ResidentialFloorA01).build(root,level)
  require(script.Parent.ResidentialCorridorFinish).build(root,level)
  require(script.Parent.ResidentialApartmentFinish).build(root,level)
  require(script.Parent.ResidentialLivingFinish).build(root,level)
  local plan=data.connections[level-data.first+1]
  local stairs,stats,retained=require(script.Parent.ResidentialAccess).build(root,plan)
  floor:SetAttribute('ConstructionPhase','COPIED_LAYOUT_AWAITING_ACCEPTANCE')
  table.insert(results,{level=level,stairs=stairs.Name,retained=retained})
  task.wait()
 end
 return results
end
return Batch
