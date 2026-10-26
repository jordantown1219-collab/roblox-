"""Original finishes for the existing west reception room; no shell/door replacement."""
import json,hashlib,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def generate():
 source=json.loads((ROOT/'data/rencen_lobby_plan.json').read_text());floor=next(r for r in source['records']if r['name']=='Lobby_WestReceptionFloor');m=floor['matrix'];c=floor['pos'];records=[]
 def add(name,size,offset,color,material='Metal',**extra):
  x,y,z=offset;records.append(dict(name=name,size=size,pos=[c[0]+m[0]*x+m[2]*z,36+y,c[2]+m[6]*x+m[8]*z],matrix=m,color=color,material=material,collide=False,**extra))
 for side in(-1,1):
  for x in(-12,-6,0,6,12):add('Reception_WoodWallPanel',[5.5,3.1,.12],[x,1.7,side*13.68],[118,96,73],'WoodPlanks')
 for z in(-9,0,9):add('Reception_BackWallPanel',[.12,3.1,8],[ -17.68,1.7,z],[118,96,73],'WoodPlanks')
 for height in(.18,3.45,11.45):
  for side in(-1,1):
   add('Reception_SideWallTrim',[35,.14,.16],[0,height,side*13.55],[161,151,119])
   add('Reception_EntryTrim',[.16,.14,8.5],[17.55,height,side*9.6],[161,151,119])
  add('Reception_BackWallTrim',[.16,.14,27],[ -17.55,height,0],[161,151,119])
 for x in(-9,0,9):
  for z in(-5,5):
   add('Reception_CeilingLightHousing',[5,.18,.7],[x,11.5,z],[88,97,93])
   add('Reception_CeilingLightDiffuser',[4.6,.08,.45],[x,11.36,z],[246,236,211],'SmoothPlastic',light=True)
 add('Reception_CounterFrontPanel',[.12,2.5,13.5],[-7.92,1.5,0],[100,77,55],'WoodPlanks')
 for y in(.4,2.6):add('Reception_CounterBrassBand',[.08,.08,13.2],[-7.82,y,0],[164,152,112])
 for z in(-4,0,4):add('Reception_CounterBrassDivider',[.08,2.2,.08],[-7.82,1.5,z],[164,152,112])
 for z in(-4,4):add('Reception_FloorInlayLong',[18,.012,.12],[3,.018,z],[126,134,130],'Slate')
 for x in(-6,12):add('Reception_FloorInlayEnd',[.12,.012,8],[x,.018,0],[126,134,130],'Slate')
 assert len(records)==50
 center=source['metadata']['center']
 for radius in(24,43):
  for j in range(24):
   a,b=2*math.pi*j/24,2*math.pi*(j+1)/24
   x0,z0=center[0]+radius*math.cos(a),center[2]+radius*math.sin(a)
   x1,z1=center[0]+radius*math.cos(b),center[2]+radius*math.sin(b);length=math.hypot(x1-x0,z1-z0);fx,fz=(x1-x0)/length,(z1-z0)/length
   records.append(dict(name='Circulation_StoneRingInlay',size=[.13,.012,length-.02],pos=[(x0+x1)/2,36.018,(z0+z1)/2],matrix=[fz,0,fx,0,1,0,-fx,0,fz],color=[135,141,133],material='Slate',collide=False))
 destinations=[('RECEPTION',source['metadata']['westRoomCenter']),('WINTERGARDEN',source['metadata']['rampEnd']),('CITY ENTRANCE',source['metadata']['jefferson']['rampEnd'])]
 for i,(text,target)in enumerate(destinations):
  dx,dz=target[0]-center[0],target[2]-center[2];length=math.hypot(dx,dz);fx,fz=dx/length,dz/length;x,z=center[0]+fx*35,center[2]+fz*35;m=[fz,0,fx,0,1,0,-fx,0,fz]
  for label,size,y,color,extra in[('Base',[1.3,.18,1.3],.09,[86,94,89],{}),('Post',[.16,3.6,.16],1.9,[148,153,141],{}),('Board',[7,1.5,.14],3.4,[47,63,62],{'text':text})]:records.append(dict(name=f'CirculationSign_{i}_{label}',size=size,pos=[x,36+y,z],matrix=m,color=color,material='Metal',collide=False,**extra))
 assert len(records)==107

 # Shell bounds; original furniture and the center circulation route remain untouched.
 for r in records:assert max(r['size'])<=40
 return dict(id='RenaissanceReceptionFinish',records=records,roomFloor=floor,classification='Original fictional hotel reception finish; not as-built',sourceHash=hashlib.sha256((ROOT/'data/rencen_lobby_plan.json').read_bytes()).hexdigest())
TAIL="""
local Finish={}
function Finish.finish(model,override)
 local current=override or plan
 local lookup={}for _,r in current.records do lookup[r.name]=r end
 for _,p in model:GetDescendants()do if p:IsA('BasePart')then
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
  local r=lookup[p.Name]
  if r.text then for _,face in{Enum.NormalId.Front,Enum.NormalId.Back}do local gui=Instance.new('SurfaceGui');gui.Name='LobbyWayfinding';gui.Face=face;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=50;gui.Parent=p;local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text=r.text;label.TextScaled=true;label.Font=Enum.Font.GothamMedium;label.TextColor3=Color3.fromRGB(240,237,215);label.Parent=gui end end
  if r.light then local l=Instance.new('SurfaceLight');l.Name='ReceptionLight';l.Face=Enum.NormalId.Bottom;l.Angle=110;l.Range=14;l.Brightness=.35;l.Color=Color3.fromRGB(255,238,211);l.Shadows=false;l.Parent=p end
 end end
end
function Finish.build(root)
 local model,stats=require(script.Parent.CityBlockGenerator).build(root,plan,nil,60)
 Finish.finish(model)
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;model:SetAttribute('ReferenceStatus',plan.classification)
 return model,stats
end
return Finish
"""
if __name__=='__main__':
 p=generate();payload=json.dumps(p,separators=(',',':'),allow_nan=False)
 (ROOT/'data/lobby_interior_finish_plan.json').write_text(payload+'\n')
 (ROOT/'src/LobbyInteriorFinish.lua').write_text('-- Generated by tools/generate_lobby_interior_finish.py\nlocal plan=game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n'+TAIL)
 print(json.dumps({'parts':len(p['records']),'lights':sum(r.get('light',False)for r in p['records'])}))
