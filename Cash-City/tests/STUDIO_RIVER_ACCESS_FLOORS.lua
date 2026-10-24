-- Read-only engine collision checks. Run with fresh module after source integration.
return function(city, data)
 local ray=RaycastParams.new()
 ray.FilterType=Enum.RaycastFilterType.Include
 ray.FilterDescendantsInstances={city}
 ray.RespectCanCollide=true
 local failures={} local checks=0 local headroomChecks=0
 local function probe(p, expected, tolerance, label)
  checks+=1
  local hit=workspace:Raycast(Vector3.new(p[1],expected+2,p[3]),Vector3.new(0,-4,0),ray)
  if not hit or math.abs(hit.Position.Y-expected)>tolerance then
   table.insert(failures,{label=label,expected=expected,actual=hit and hit.Position.Y,part=hit and hit.Instance:GetFullName(),pos=p})
  end
  if hit then
   headroomChecks+=1
   local obstacle=workspace:Raycast(hit.Position+Vector3.new(0,.3,0),Vector3.new(0,7.7,0),ray)
   if obstacle then table.insert(failures,{label=label..' headroom',part=obstacle.Instance:GetFullName(),pos=p}) end
  end
 end
 for _,key in ipairs({'routeRamp','routeStairs'}) do
  local route=data[key]
  for index,sample in ipairs(route) do
   probe(sample.pos,sample.floorY,.08,key..' waypoint '..index)
   if index>1 then
    local previous=route[index-1]
    local a,b=Vector3.new(table.unpack(previous.pos)),Vector3.new(table.unpack(sample.pos))
    local count=math.ceil((b-a).Magnitude/.5)
    for j=1,count-1 do
     local t=j/count local p=a:Lerp(b,t)
     -- A stair has discontinuous treads; .23 tolerates one .2 riser, not a .6 gap.
     probe({p.X,p.Y,p.Z},p.Y,key=='routeStairs' and .23 or .08,key..' leg '..index..' sample '..j)
     local delta=b-a local horizontal=Vector3.new(delta.X,0,delta.Z)
     if horizontal.Magnitude>.01 then
      local side=Vector3.new(horizontal.Z,0,-horizontal.X).Unit*2.5
      for _,sign in ipairs({-1,1}) do
       local q=p+side*sign
       probe({q.X,q.Y,q.Z},p.Y,.25,key..' width '..index..' sample '..j..' side '..sign)
      end
     end
    end
   end
  end
 end
 return {passed=#failures==0,checks=checks,headroomChecks=headroomChecks,failures=failures}
end
