import urllib.request,urllib.parse,json,pathlib,time
p=pathlib.Path(__file__).resolve().parents[1]/'data'
q='[out:json][timeout:45];(way["highway"](42.325,-83.049,42.335,-83.030);way["building"](42.325,-83.049,42.335,-83.030);way["building:part"](42.325,-83.049,42.335,-83.030);way["natural"="water"](42.325,-83.049,42.335,-83.030);relation["natural"="water"](42.325,-83.049,42.335,-83.030);way["leisure"="park"](42.325,-83.049,42.335,-83.030);way["place"="square"](42.325,-83.049,42.335,-83.030););out tags geom;'
for endpoint in ['https://overpass-api.de/api/interpreter','https://overpass.kumi.systems/api/interpreter']:
 try:
  req=urllib.request.Request(endpoint,data=urllib.parse.urlencode({'data':q}).encode(),headers={'User-Agent':'SmallSignalsDetroitPrototype/0.9 (geographic blockout; OSM attribution included)'})
  data=urllib.request.urlopen(req,timeout=60).read()
  obj=json.loads(data);assert 'elements' in obj
  (p/'osm_raw.json').write_bytes(data)
  (p/'osm_request.txt').write_text(q,encoding='utf-8')
  print('Downloaded',len(obj['elements']),'OSM features;',len(data),'bytes',flush=True)
  print([(e['id'],e.get('tags',{}).get('name'),e.get('tags',{}).get('height'),e.get('tags',{}).get('building')) for e in obj['elements'] if 'Renaissance' in e.get('tags',{}).get('name','') or 'Hart Plaza' in e.get('tags',{}).get('name','')],flush=True)
  break
 except Exception as e: print(endpoint,type(e).__name__,str(e)[:150],flush=True)
else:raise SystemExit('Geodata download failed')
