from pathlib import Path
import xml.etree.ElementTree as ET,json,copy
P=Path(__file__).resolve().parents[1]
root=ET.parse(P/'SmallSignals_DetroitRiverfront_v0_14.rbxlx').getroot()
(P/'assets').mkdir(exist_ok=True)
for name in ['DetroitCityRoot','DetroitCityPreview','SUVArt','SpiritArt']:
 original=next(n for n in root.iter('Item') if n.find('Properties').findtext("string[@name='Name']")==name)
 model=ET.Element('roblox',{'version':'4'});model.append(copy.deepcopy(original))
 ET.ElementTree(model).write(P/'assets'/f'{name}.rbxmx',encoding='utf-8',xml_declaration=True)
def folder(cls='Folder',**children):return {'$className':cls,'$ignoreUnknownInstances':True,**children}
def src(file):return {'$path':'src/'+file,'$ignoreUnknownInstances':True}
shared=folder(Config=src('Config.lua'),Rules=src('Rules.lua'),InteractionRules=src('InteractionRules.lua'),Action={'$className':'RemoteEvent'},State={'$className':'RemoteEvent'})
server=folder('ServerScriptService',**{name:src(file) for name,file in {'Wintergarden':'Wintergarden.lua','WintergardenData':'WintergardenData.lua','RenaissanceDetails':'RenaissanceDetails.lua','RenaissanceData':'RenaissanceData.lua','HartPathData':'HartPathData.lua','CivicFacadeData':'CivicFacadeData.lua','CivicFacades':'CivicFacades.lua','StorefrontInterior':'StorefrontInterior.lua','BuildingInteractions':'BuildingInteractions.lua','BuildingTemplates':'BuildingTemplates.lua','CityBlockGenerator':'CityBlockGenerator.lua','WorldLoading':'WorldLoading.lua','WeaponVisuals':'WeaponVisuals.lua','RiverfrontVehicles':'RiverfrontVehicles.lua','CityDetails':'CityDetails.lua','Arena':'Arena.lua','LegacyArena':'LegacyArena.lua','CityConfig':'CityConfig.lua','InteractionRegistry':'InteractionRegistry.lua','InteractionWorkshop':'InteractionWorkshop.lua','InteractionRules':'InteractionRules.lua','SmallSignalsServer':'SmallSignalsServer.server.lua'}.items()})
client=folder('StarterPlayerScripts',**{name:src(file) for name,file in {'VehicleClient':'VehicleClient.client.lua','SmallSignalsClient':'SmallSignalsClient.client.lua','SmallSignalsHUD':'SmallSignalsHUD.lua','SmallSignalsSettings':'SmallSignalsSettings.lua','RiverfrontClient':'RiverfrontClient.client.lua'}.items()})
tree=folder('DataModel',ReplicatedStorage=folder('ReplicatedStorage',SmallSignals=shared),ServerScriptService=server,StarterPlayer=folder('StarterPlayer',StarterPlayerScripts=client))
# Code-only sync leaves Studio scenery alone. Open the generated place first.
project={'name':'SmallSignals Detroit - Code Sync','servePort':34872,'tree':tree}
(P/'scripts.project.json').write_text(json.dumps(project,indent=2),encoding='utf-8')
full=copy.deepcopy(project);full['name']='SmallSignals Detroit - Source And Geometry'
full['tree']['ServerStorage']=folder('ServerStorage',DetroitCityRoot={'$path':'assets/DetroitCityRoot.rbxmx','$ignoreUnknownInstances':True},SUVArt={'$path':'assets/SUVArt.rbxmx','$ignoreUnknownInstances':True},SpiritArt={'$path':'assets/SpiritArt.rbxmx','$ignoreUnknownInstances':True})
full['tree']['Workspace']=folder('Workspace',DetroitCityPreview={'$path':'assets/DetroitCityPreview.rbxmx','$ignoreUnknownInstances':True})
(P/'full.project.json').write_text(json.dumps(full,indent=2),encoding='utf-8')
print('Exported model assets and code-only/full Rojo projects. Unknown Studio instances are preserved.')


