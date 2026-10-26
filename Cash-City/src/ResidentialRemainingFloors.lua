-- Reuses validated floor and stair templates; existing floors are never rebuilt.
local Remaining={}
local Http=game:GetService('HttpService')
local template=require(script.Parent.ResidentialFloorBatch09Data).connections[3]
assert(template.levels[1]==188 and template.levels[3]==200,'Unexpected stair template')
function Remaining.planForLevel(level)
 assert(type(level)=='number' and level%1==0 and level>=12 and level<=39,'Invalid remaining level')
 local lower=level-1
 local plan=Http:JSONDecode(Http:JSONEncode(template))
 local dy=12*(lower-10)
 plan.id=string.format('ResidentialTowerA_UpperStairs_%02d_%02d',lower,level)
 for _,r in plan.records do
  r.name=r.name:gsub('^ResidentialUpperStairs_L10_',string.format('ResidentialUpperStairs_L%02d_',lower))
  r.pos[2]=r.pos[2]+dy
 end
 local roof=0
 for _,guard in plan.guards do
  local r=guard.record;r.pos[2]=r.pos[2]+dy
  if r.label=='ShaftRoof' then
   r.name=r.name:gsub('^ResidentialUpperStairs_L09_',string.format('ResidentialUpperStairs_L%02d_',lower-1))
   roof=roof+1
  end
 end
 assert(roof==1,'Previous stair roof guard missing')
 for i,y in plan.levels do plan.levels[i]=y+dy end
 return plan
end
function Remaining.buildBatch(root,first,last)
 assert(type(first)=='number' and type(last)=='number' and first%1==0 and last%1==0 and first>=12 and last<=39 and last>=first and last-first<=2,'Invalid remaining batch')
 local data={first=first,last=last,connections={}}
 for level=first,last do table.insert(data.connections,Remaining.planForLevel(level))end
 return require(script.Parent.ResidentialFloorBatch).build(root,data)
end
function Remaining.build(root,last)
 last=last or 39
 assert(type(last)=='number' and last%1==0 and last>=12 and last<=39,'Invalid final residential level')
 local results={}
 for first=12,last,3 do
  table.insert(results,Remaining.buildBatch(root,first,math.min(first+2,last)))
  task.wait()
 end
 return results
end
return Remaining
