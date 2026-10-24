import urllib.request,json,pathlib,zipfile,hashlib
p=pathlib.Path('tools/rojo');p.mkdir(exist_ok=True)
request=urllib.request.Request('https://api.github.com/repos/rojo-rbx/rojo/releases/latest',headers={'User-Agent':'SmallSignals-Studio-Setup'})
release=json.load(urllib.request.urlopen(request,timeout=25))
assets=release['assets'];asset=next(a for a in assets if 'windows' in a['name'].lower() and 'x86_64' in a['name'].lower() and a['name'].endswith('.zip'))
print('Official release',release['tag_name'],asset['name'],'digest',asset.get('digest'),flush=True)
data=urllib.request.urlopen(asset['browser_download_url'],timeout=60).read()
sha=hashlib.sha256(data).hexdigest()
if asset.get('digest'):assert asset['digest']=='sha256:'+sha,'Release hash mismatch'
(p/'release.zip').write_bytes(data)
with zipfile.ZipFile(p/'release.zip') as z:
 for f in z.infolist():
  if pathlib.PurePosixPath(f.filename).name=='rojo.exe':(p/'rojo.exe').write_bytes(z.read(f))
assert (p/'rojo.exe').exists()
metadata={'tag':release['tag_name'],'url':asset['browser_download_url'],'archiveSHA256':sha,'githubDigest':asset.get('digest'),'hashVerified':bool(asset.get('digest'))}
(p/'release.json').write_text(json.dumps(metadata,indent=2))
print('Downloaded Rojo to project tools folder. Hash:',sha,flush=True)
