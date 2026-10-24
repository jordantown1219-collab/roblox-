"""One-command offline place build. Source data is checked in; network refresh is separate."""
from pathlib import Path
import xml.etree.ElementTree as ET,json,sys,os,math,hashlib,copy
P=Path(__file__).resolve().parent
sys.path.insert(0,str(P/'tools'))
sys.path.insert(0,str(Path(os.environ['TEMP'])/'smallsignals-test-deps'))
from citygeo import STUDS_PER_METER as S
BASE=Path(r'C:\Users\jorda\AppData\Local\SmallSignalsProjects\SmallSignals_v0_8_LobbyToggle\SmallSignals_v0_8_LobbyToggle.rbxlx')
if (P/'data/base_v0_8.rbxlx').exists():BASE=P/'data/base_v0_8.rbxlx'
root=ET.parse(BASE).getroot();counter=0
materials={'Brick':848,'Limestone':820,'Granite':832,'Marble':784,'SmoothPlastic':272,'Concrete':816,'Glass':1568,'Metal':1088,'Asphalt':1376,'WoodPlanks':528,'Grass':1280,'Ground':1360}
civic_plan=json.loads((P/'data/civic_detail_plan.json').read_text(encoding='utf-8'))
civic_finishes={(f['name'],tuple(round(v,3) for v in f['pos'])):f for f in civic_plan['faces']}
from package_renaissance import package as renaissance_package
rencen=renaissance_package()
for guard in rencen['guards']:
 if 'finish' in guard:
  record=guard['record']
  civic_finishes[(record['name'],tuple(round(v,3) for v in record['pos']))]=guard['finish']
def item(parent,cls,name):
 global counter
 counter+=1
 node=ET.SubElement(parent,'Item',{'class':cls,'referent':f'RF09_{counter}'})
 props=ET.SubElement(node,'Properties');ET.SubElement(props,'string',{'name':'Name'}).text=name
 return node
def prop(node,kind,name,value):
 props=node.find('Properties');old=props.find(f"*[@name='{name}']")
 if old is not None:props.remove(old)
 child=ET.SubElement(props,kind,{'name':name});child.text=str(value);return child
def vector(node,name,values):
 x=prop(node,'Vector3',name,'')
 for a,v in zip('XYZ',values):ET.SubElement(x,a).text=str(v)
def frame(node,pos,matrix=None):
 x=prop(node,'CoordinateFrame','CFrame','')
 for a,v in zip('XYZ',pos):ET.SubElement(x,a).text=str(v)
 for index,v in enumerate(matrix or [1,0,0,0,1,0,0,0,1]):ET.SubElement(x,f'R{index//3}{index%3}').text=str(round(v,8))
def color(node,rgb):prop(node,'Color3uint8','Color3uint8',(int(rgb[0])<<16)|(int(rgb[1])<<8)|int(rgb[2]))
def primitive(parent,b):
 finish=civic_finishes.get((b['name'],tuple(round(v,3) for v in b['pos'])))
 node=item(parent,b.get('cls','Part'),b['name'])
 vector(node,'size',b['size']);frame(node,b['pos'],b.get('matrix'))
 color(node,(finish or b)['color'])
 for key,value in [('Anchored',True),('CanCollide',b.get('collide',True)),('CanTouch',b.get('touch',False))]:prop(node,'bool',key,str(value).lower())
 prop(node,'float','Transparency',b.get('trans',0));prop(node,'token','Material',materials[finish['material']] if finish else b.get('materialValue',materials.get(b.get('material','Concrete'),816)))
 if b['name'] in ('SafeLanding','TransitLanding'):prop(node,'float','Transparency',1);prop(node,'bool','CanQuery','false')
 if 'shape' in b:prop(node,'token','shape',b['shape'])
 if b.get('mesh'):
  for key,value in [('MeshId',b['mesh']),('TextureID',b.get('texture',''))]:
   content=prop(node,'Content',key,'');ET.SubElement(content,'url').text=value
  vector(node,'InitialSize',b['size'])
 prop(node,'token','TopSurface',0);prop(node,'token','BottomSurface',0)
 return node
def source(parent,cls,name,code):
 n=item(parent,cls,name);prop(n,'ProtectedString','Source',code)
 if cls=='Script':prop(n,'bool','Disabled','false')
 return n
workspace=next(n for n in root.findall('Item') if n.get('class')=='Workspace')
server=next(n for n in root.findall('Item') if n.get('class')=='ServerScriptService')
rs=next(n for n in root.findall('Item') if n.get('class')=='ReplicatedStorage')
shared=next(n for n in rs.findall('Item') if n.find('Properties').findtext("string[@name='Name']")=='SmallSignals')
sp=next(n for n in root.iter('Item') if n.get('class')=='StarterPlayerScripts')
# Extract all baseline shared source for an independently rebuildable package.
for n in shared.findall('Item'):
 props=n.find('Properties');name=props.findtext("string[@name='Name']");code=props.findtext("ProtectedString[@name='Source']")
 if code is not None and name in ['Config','Rules']:
  target=P/'src'/f'{name}.lua'
  if not target.exists():target.write_text(code,encoding='utf-8')
config=(P/'src/Config.lua').read_text(encoding='utf-8-sig')
if 'ActiveMap' not in config:config=config.replace('return {','return {\n    ActiveMap = "DetroitRiverfront",\n    MapLabel = "DETROIT RIVERFRONT",',1)
(P/'src/Config.lua').write_text(config,encoding='utf-8')
mapping={'Arena':'Arena.lua','SmallSignalsServer':'SmallSignalsServer.server.lua','SmallSignalsClient':'SmallSignalsClient.client.lua','SmallSignalsHUD':'SmallSignalsHUD.lua','SmallSignalsSettings':'SmallSignalsSettings.lua','Config':'Config.lua','Rules':'Rules.lua'}
for n in root.iter('Item'):
 props=n.find('Properties');name=props.findtext("string[@name='Name']") if props is not None else None
 if name in mapping:prop(n,'ProtectedString','Source',(P/'src'/mapping[name]).read_text(encoding='utf-8-sig'))
for name in ['LegacyArena','CityConfig','InteractionRegistry','InteractionWorkshop','InteractionRules','WorldLoading','WeaponVisuals','RiverfrontVehicles','CityDetails','CityBlockGenerator','BuildingTemplates','BuildingInteractions','StorefrontInterior','CivicFacades','CivicFacadeData','HartPathData','RenaissanceDetails','RenaissanceData','Wintergarden','WintergardenData','ArrivalLounge','ArrivalLoungeData']:
 source(server,'ModuleScript',name,(P/'src'/f'{name}.lua').read_text(encoding='utf-8-sig'))
source(shared,'ModuleScript','InteractionRules',(P/'src/InteractionRules.lua').read_text(encoding='utf-8-sig'))
source(sp,'LocalScript','RiverfrontClient',(P/'src/RiverfrontClient.client.lua').read_text(encoding='utf-8-sig'))
source(sp,'LocalScript','VehicleClient',(P/'src/VehicleClient.client.lua').read_text(encoding='utf-8-sig'))
for n in list(workspace):
 if n.tag=='Item' and n.get('class')!='Camera':workspace.remove(n)
prop(workspace,'bool','StreamingEnabled','true')
prop(workspace,'int','StreamingMinRadius',256);prop(workspace,'int','StreamingTargetRadius',768)
# Near-character content streams normally; only tiny collision landing pads stay persistent.
city=item(root,'ServerStorage','ServerStorage')
cityroot=item(city,'Folder','DetroitCityRoot')
# Generated original art descriptors keep meshes/textures reproducible from source.
art=json.loads((P/'data/art_assets.json').read_text(encoding='utf-8'))
for key,parts in art.items():
 model=item(city,'Model',key+'Art')
 for data in parts:
  node=primitive(model,dict(cls='MeshPart',name=data['name'],size=data['size'],pos=data['cf'][:3],matrix=data['cf'][3:],color=[round(c*255) for c in data['color']],material='SmoothPlastic',collide=False))
  for propname,value in [('MeshId',data['mesh']),('TextureID',data['texture'])]:
   content=prop(node,'Content',propname,'');ET.SubElement(content,'url').text=value
  vector(node,'InitialSize',data['size'])

geo=json.loads((P/'data/geometry.json').read_text(encoding='utf-8'))
sectors={}
for b in geo:
 key=b['sector']
 if key not in sectors:
  sectors[key]=item(cityroot,'Model','Sector_'+key)
  prop(sectors[key],'token','ModelStreamingMode',4)
 primitive(sectors[key],b)
G=json.loads((P/'data/detroit_geography.json').read_text(encoding='utf-8'))
for team,data in G['gameplay'].items():
 for index,point in enumerate([data['spawn'],data['exit'],data['transit']]+data['sockets']):
  group=item(cityroot,'Model',f'Landing_{team}_{index}');prop(group,'token','ModelStreamingMode',2)
  primitive(group,dict(name='SafeLanding',size=[12,.5,12],pos=[point[0]*S,-.3,point[1]*S],color=[139,142,131]))
  if index==2:
   # Collision floor at transit destination offset. Separate from all visual streaming.
   primitive(group,dict(name='TransitLanding',size=[22,.5,22],pos=[point[0]*S,-.3,point[1]*S+4],color=[139,142,131]))
preview=copy.deepcopy(cityroot);preview.find('Properties').find("string[@name='Name']").text='DetroitCityPreview'
# Regenerate referents in preview to avoid duplicate identities.
for node in preview.iter('Item'):
 counter+=1;node.set('referent',f'RFPREVIEW_{counter}')
workspace.append(preview)
civic_preview=item(preview,'Folder','CivicFacadeDetails')
marker=item(civic_preview,'StringValue','CashCityReferenceDecorManifest');prop(marker,'string','Value',civic_plan['reference'])
for b in civic_plan['details']:
 node=primitive(civic_preview,b)
 for key in ['CanQuery','CastShadow']:prop(node,'bool',key,'false')
hart_preview=item(preview,'Folder','HartPlazaPavingPreview')
for b in json.loads((P/'data/hart_path_plan.json').read_text())['records']:primitive(hart_preview,b)
# Use the same compact data as runtime. Decor stays static and never owns source shells.
for block in [rencen['towers'],rencen['walk']]:
 group=item(preview,'Model',block['id'])
 # Ownership is encoded via a marker; runtime converts the marker before rebuilding.
 marker=item(group,'StringValue','CashCityGeneratedBlockManifest');prop(marker,'string','Value',block['id'])
 for b in block['records']:
  node=primitive(group,b);prop(node,'bool','CastShadow','false')
  if block['id']==rencen['towers']['id']:prop(node,'bool','CanQuery','false')
from package_wintergarden import package as wintergarden_package
winter=wintergarden_package()
archive=item(preview,'Folder','WintergardenSourceArchive')
marker=item(archive,'StringValue','CashCityWintergardenArchiveManifest');prop(marker,'string','Value','Wintergarden')
for guard in winter['replacements']:
 b=guard['record']; found=None
 for parent in preview.iter('Item'):
  for node in list(parent.findall('Item')):
   props=node.find('Properties')
   if props.findtext("string[@name='Name']")!=b['name']:continue
   cf=props.find("CoordinateFrame[@name='CFrame']")
   if cf is not None and all(abs(float(cf.findtext(axis))-v)<.001 for axis,v in zip('XYZ',b['pos'])):
    found=(parent,node);break
  if found:break
 if not found:raise ValueError('Missing Wintergarden source '+b['name'])
 parent,node=found
 # Archive the original geometry and flags; no geography/source record is deleted.
 state={key:node.find('Properties').findtext("*[@name='"+key+"']") for key in ['CanCollide','CanTouch','CanQuery','CastShadow','Transparency']}
 state.update(index=guard['sourceIndex'])
 saved=item(node,'StringValue','WGOriginalState');prop(saved,'string','Value',json.dumps(state))
 for key in ['CanCollide','CanTouch','CanQuery','CastShadow']:prop(node,'bool',key,'false')
 prop(node,'float','Transparency',1)
 parent.remove(node);archive.append(node)
winter_preview=item(preview,'Model',winter['id'])
marker=item(winter_preview,'StringValue','CashCityGeneratedBlockManifest');prop(marker,'string','Value',winter['id'])
for b in winter['records']:
 node=primitive(winter_preview,b);prop(node,'bool','CastShadow','false')
for index,anchor in enumerate(winter['doorAnchors']):
 # Edit preview leaf; runtime installs the complete authoritative interaction component.
 primitive(winter_preview,dict(name='WintergardenDoorPreview_'+str(index),size=[anchor.get('apertureWidth',anchor['width'])-.6,anchor['height']-.3,.28],pos=anchor['pos'],matrix=anchor['matrix'],color=[126,142,146],material='Metal',collide=True))
lounge_preview=item(winter_preview,'Model','ArrivalLounge')
for b in json.loads((P/'data/arrival_lounge_preview.json').read_text()):
 node=primitive(lounge_preview,b);prop(node,'bool','CastShadow','false')
 if b['cls']=='Seat':prop(node,'bool','Disabled','false')
 if b.get('light'):
  light=item(node,'PointLight','ArrivalLight')
  prop(light,'float','Brightness',b['light']['brightness']);prop(light,'float','Range',b['light']['range']);prop(light,'bool','Shadows','false')
 if b.get('signText'):
  for face in (5,2): # Roblox Front and Back; readable from either approach.
   surface=item(node,'SurfaceGui','AtriumSign_'+str(face));prop(surface,'token','Face',face)
   size=prop(surface,'Vector2','CanvasSize','');ET.SubElement(size,'X').text='600';ET.SubElement(size,'Y').text='240'
   prop(surface,'float','LightInfluence',0)
   label=item(surface,'TextLabel','GenericTitle');prop(label,'string','Text',b['signText']);prop(label,'bool','TextScaled','true');prop(label,'float','BackgroundTransparency',1)
   size=prop(label,'UDim2','Size','')
   for key,value in [('XS',1),('XO',0),('YS',1),('YO',0)]:ET.SubElement(size,key).text=str(value)
   rgb=prop(label,'Color3','TextColor3','')
   for key,value in zip('RGB',[238/255,235/255,214/255]):ET.SubElement(rgb,key).text=str(value)
for entry in json.loads((P/'data/detail_preview.json').read_text(encoding='utf-8')):
 group=item(preview,'Model',entry['name']);prop(group,'token','ModelStreamingMode',1)
 for b in entry['parts']:primitive(group,b)
# Saved camera views the actual geographic district rather than the out-of-map lobby.
camera=next(n for n in workspace.findall('Item') if n.get('class')=='Camera')
# A high oblique view: position (0,2300,2800) looking toward the district center.
back=[0,2300/math.hypot(2300,2800),2800/math.hypot(2300,2800)]
up=[0,back[2],-back[1]]
frame(camera,[0,2300,2800],[1,up[0],back[0],0,up[1],back[1],0,up[2],back[2]])
prop(workspace,'Ref','CurrentCamera',camera.get('referent'))
ET.indent(root)
out=P/'SmallSignals_DetroitRiverfront_v0_14.rbxlx'
ET.ElementTree(root).write(out,encoding='utf-8',xml_declaration=True)
manifest={'place':out.name,'bytes':out.stat().st_size,'baseSHA256':hashlib.sha256(BASE.read_bytes()).hexdigest(),'primitiveCount':len(geo),'sectorCount':len(sectors),'streamingEnabled':True,'runtimeVerified':False,'fpsMeasured':False,'sources':{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in (P/'src').glob('*.lua')}}
(P/'build_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('Built',out.name,f'{out.stat().st_size:,} bytes;',len(geo),'geographic parts;',len(sectors),'sectors. Studio acceptance pending.')

