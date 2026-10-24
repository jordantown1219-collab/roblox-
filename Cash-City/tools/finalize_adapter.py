from pathlib import Path
p=Path('src/Arena.lua');s=p.read_text(encoding='utf-8');s=s.replace('if Config.ActiveMap=="MonroeBlock" then return Legacy end','''if Config.ActiveMap=="MonroeBlock" then
 local originalBuild=Legacy.build
 Legacy.build=function()
  local preview=workspace:FindFirstChild("DetroitCityPreview") if preview then preview:Destroy() end
  return originalBuild()
 end
 return Legacy
end''')
s=s.replace(' local shift=Vector3.new(-3800,0,-2800)',''' local shift=Vector3.new(-3800,0,-2800)
 local staging=Instance.new("Model") staging.Name="StagingRoom"
 staging.ModelStreamingMode=Enum.ModelStreamingMode.Persistent staging.Parent=folder''')
s=s.replace('else obj.Position=obj.Position+shift end','else obj.Position=obj.Position+shift obj.Parent=staging end')
p.write_text(s,encoding='utf-8')
f=Path('src/RiverfrontClient.client.lua');s=f.read_text(encoding='utf-8-sig').replace('local Rules=require(config:WaitForChild("InteractionRules"))','if require(config:WaitForChild("Config")).ActiveMap~="DetroitRiverfront" then return end\nlocal Rules=require(config:WaitForChild("InteractionRules"))');f.write_text(s,encoding='utf-8')
f=Path('src/SmallSignalsHUD.lua');s=f.read_text(encoding='utf-8').replace('"MONROE BLOCK • DETROIT"','(config.MapLabel or "MONROE BLOCK • DETROIT")');f.write_text(s,encoding='utf-8')
