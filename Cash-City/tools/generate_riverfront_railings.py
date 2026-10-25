"""Original open railing over six guarded existing shoreline safety segments."""
import hashlib,json,math
from pathlib import Path
from generate_river_access import Point,shape
ROOT=Path(__file__).resolve().parents[1]
SOURCE_INDICES=tuple(range(11337,11343))

def generate(root=ROOT):
    paths=[root/'data/geometry.json',root/'data/detroit_geography.json']
    geometry,geography=[json.loads(p.read_text()) for p in paths]
    records=[];guards=[];posts=[];total=0
    for index in SOURCE_INDICES:
        r=geometry[index];assert r['name']=='EstimatedRiverSafetyRail' and r['collide'] and r['size'][1]==4
        assert -1850<r['pos'][0]<750 and -650<r['pos'][2]<1250
        guards.append(dict(sourceIndex=index,record=r));m=r['matrix'];length=r['size'][2];total+=length
        def world(x,y,z):return [r['pos'][i]+m[i*3]*x+m[i*3+1]*y+m[i*3+2]*z for i in range(3)]
        post_matrix=[m[1],-m[0],m[2],m[4],-m[3],m[5],m[7],-m[6],m[8]]
        tube_matrix=[m[2],m[1],-m[0],m[5],m[4],-m[3],m[8],m[7],-m[6]]
        def add(name,size,pos,matrix):records.append(dict(name=name,size=size,pos=pos,matrix=matrix,material='Metal',color=[80,88,86],shape='Cylinder',collide=False))
        count=math.ceil(length/8)
        for j in range(count+1):
            pos=world(0,-.15,-length/2+length*j/count)
            if any(math.dist(pos,old)<.05 for old in posts):continue
            posts.append(pos);add('RiverRail_Post_'+str(index)+'_'+str(j),[4.3,.18,.18],pos,post_matrix)
        for j,(y,diameter) in enumerate(((-1.2,.12),(0,.12),(1.91,.18))):
            add('RiverRail_Tube_'+str(index)+'_'+str(j),[length,diameter,diameter],world(0,y,0),tube_matrix)
    assert len(records)<=160 and len(guards)==6
    for r in records:
        assert all(math.isfinite(v) and 0<v<=2048 for v in r['size'])
        assert r['pos'][1]+r['size'][0]/2<=4.001 if r['name'].startswith('RiverRail_Post') else True
    mid=geometry[11340];m=mid['matrix'];scale=geography['studsPerMeter'];land=shape(geography['land'])
    outside=-1 if land.covers(Point((mid['pos'][0]+m[0]*5)/scale,(mid['pos'][2]+m[6]*5)/scale)) else 1
    camera=dict(eye=[mid['pos'][0]+m[0]*35*outside,12,mid['pos'][2]+m[6]*35*outside],target=[mid['pos'][0],2,mid['pos'][2]])
    return dict(id='Map1RiverWalkRailings',records=records,guards=guards,postCount=len(posts),lengthMeters=total/scale,camera=camera,classification='Existing shoreline alignment and height; original open-rail interpretation, not surveyed',sourceHashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in paths})

TAIL='''
local Railings={}
local function frame(r)return CFrame.new(r.pos[1],r.pos[2],r.pos[3],table.unpack(r.matrix))end
function Railings.build(root)
 local candidates={}for i,p in ipairs(root:GetDescendants()) do
  if p:IsA('BasePart') and p.Name=='EstimatedRiverSafetyRail' then table.insert(candidates,p) end
  if i%1000==0 then task.wait() end
 end
 local originals={}
 for _,g in ipairs(plan.guards) do local r=g.record;local cf=frame(r);local found
  for _,p in ipairs(candidates) do if (p.Position-cf.Position).Magnitude<.01 and (p.Size-Vector3.new(table.unpack(r.size))).Magnitude<.01 and (p.CFrame.RightVector-cf.RightVector).Magnitude<.001 and (p.CFrame.UpVector-cf.UpVector).Magnitude<.001 then assert(not found,'Ambiguous safety rail');found=p end end
  assert(found and found.CanCollide==r.collide,'Preserve changed safety rail')
  local c=Color3.fromRGB(table.unpack(r.color));local color=found.Color
  assert(found.Material==Enum.Material[r.material] and math.abs(color.R-c.R)+math.abs(color.G-c.G)+math.abs(color.B-c.B)<.005,'Preserve custom rail finish')
  assert(math.abs(found.Transparency-(r.trans or 0))<.001 or (found:GetAttribute('RiverRailOriginalTransparency')~=nil and found.Transparency==1),'Preserve custom rail transparency')
  table.insert(originals,{p=found,cf=found.CFrame,size=found.Size,collision=found.CanCollide,query=found.CanQuery,touch=found.CanTouch,anchored=found.Anchored})
 end
 local model,stats=require(script.Parent.CityBlockGenerator).build(root,plan,nil,80)
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then p.Shape=Enum.PartType.Cylinder;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false end end
 for _,r in ipairs(originals) do local p=r.p
  assert(p:IsDescendantOf(root) and p.CFrame==r.cf and p.Size==r.size and p.CanCollide==r.collision and p.CanQuery==r.query and p.CanTouch==r.touch and p.Anchored==r.anchored,'Safety geometry changed during build')
  if p:GetAttribute('RiverRailOriginalTransparency')==nil then p:SetAttribute('RiverRailOriginalTransparency',p.Transparency);p:SetAttribute('RiverRailOriginalCastShadow',p.CastShadow) end
  p.Transparency=1;p.CastShadow=false
 end
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;model:SetAttribute('ReferenceStatus',plan.classification)
 return model,stats,#originals
end
return Railings
'''
if __name__=='__main__':
    p=generate();payload=json.dumps(p,separators=(',',':'),allow_nan=False)
    (ROOT/'data/riverfront_railings_plan.json').write_text(payload+'\n',encoding='utf-8')
    (ROOT/'src/RiverfrontRailings.lua').write_text('-- Generated by tools/generate_riverfront_railings.py\nlocal plan=game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n'+TAIL,encoding='utf-8')
    print(json.dumps({'parts':len(p['records']),'posts':p['postCount'],'sourceRails':len(p['guards']),'meters':p['lengthMeters']}))
