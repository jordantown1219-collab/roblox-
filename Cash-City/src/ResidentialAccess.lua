-- Lead-owned guarded access installation. No source parts are deleted.
local Access={}
local function frame(r)return CFrame.new(r.pos[1],r.pos[2],r.pos[3],table.unpack(r.matrix))end
function Access.build(root,plan)
 plan=plan or require(script.Parent.ResidentialAccessData)
 assert(not root:FindFirstChild(plan.id),'Preserve existing access build')
 local byName={}for i,p in root:GetDescendants()do if p:IsA('BasePart')then byName[p.Name]=byName[p.Name]or{};table.insert(byName[p.Name],p)end;if i%1000==0 then task.wait()end end
 local originals={}
 for _,g in plan.guards do local r=g.record;local cf=frame(r);local found
  for _,p in byName[r.name]or{}do if(p.Position-cf.Position).Magnitude<.002 and(p.Size-Vector3.new(table.unpack(r.size))).Magnitude<.002 and(p.CFrame.RightVector-cf.RightVector).Magnitude<.001 and(p.CFrame.UpVector-cf.UpVector).Magnitude<.001 then assert(not found,'Ambiguous access source');found=p end end
  assert(found,'Access source missing or modified: '..r.name)
  table.insert(originals,{p=found,parent=found.Parent,cf=found.CFrame,size=found.Size,color=found.Color,material=found.Material,trans=found.Transparency,reflectance=found.Reflectance,collide=found.CanCollide,query=found.CanQuery,touch=found.CanTouch,shadow=found.CastShadow})
 end
 local model,stats=require(script.Parent.CityBlockGenerator).build(root,plan,nil,80)
 local lookup={}for _,r in plan.records do lookup[r.name]=r end
 for _,p in model:GetDescendants()do if p:IsA('BasePart')then local r=lookup[p.Name];if r.guard~=nil then local s=originals[r.guard+1];p.Color=s.color;p.Material=s.material;p.Transparency=s.trans;p.Reflectance=s.reflectance;p.CanCollide=s.collide;p.CanQuery=s.query;p.CanTouch=s.touch;p.CastShadow=s.shadow else p.Anchored=true;p.CanTouch=false;p.CastShadow=false end end end
 for _,s in originals do assert(s.p.Parent==s.parent and s.p.CFrame==s.cf and s.p.Size==s.size,'Access source changed during build')end
 for _,s in originals do local p=s.p;for _,key in{'Transparency','CanCollide','CanQuery','CanTouch','CastShadow'}do p:SetAttribute('ResidentialAccessOriginal'..key,p[key])end;p.Transparency=1;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false end
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;model:SetAttribute('ConstructionPhase','ACCESS_UNDER_TEST');return model,stats,#originals
end
return Access
