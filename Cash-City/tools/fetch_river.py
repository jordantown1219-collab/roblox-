import urllib.request,urllib.parse,json,pathlib
p=pathlib.Path('data')
q='[out:json][timeout:40];relation(5678328);out body geom(42.324,-83.050,42.336,-83.029);'
url='https://overpass-api.de/api/interpreter?'+urllib.parse.urlencode({'data':q})
b=urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'SmallSignals-Geographic-Blockout/0.9'}),timeout=55).read()
(p/'river_raw.json').write_bytes(b);d=json.loads(b);print('River member data:',len(b),'bytes;',len(d['elements'][0].get('members',[])),'members')
