-- Source-preserving original plaza connection. Existing registry/gameplay are unchanged.
local Access={}
function Access.build(root,plan)
 plan=plan or require(script.Parent.RiverAccessData)
 assert(plan.id=='RenCenRiverAccess','Unexpected access block')
 local old=root:FindFirstChild(plan.id)
 if old and old:GetAttribute('CashCityGeneratedBlock')~=true then
  local marker=old:FindFirstChild('CashCityGeneratedBlockManifest')
  assert(marker and marker:IsA('StringValue') and marker.Value==plan.id,'Preserve manual river access')
  old:SetAttribute('CashCityGeneratedBlock',true)
 end
 local model,stats=require(script.Parent.CityBlockGenerator).build(root,plan,nil,80)
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 model:SetAttribute('ReferenceStatus','Original grade-preserving plaza design; not surveyed historic stairs')
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then p.CastShadow=false end end
 return model,stats
end
return Access
