import json,sys,os,math
from pathlib import Path
sys.path.insert(0,str(Path(os.environ['TEMP'])/'smallsignals-test-deps'))
from shapely.geometry import Polygon,LineString,box,Point
from shapely.ops import split,unary_union,triangulate
from citygeo import *
P=Path(__file__).resolve().parents[1]
raw=json.loads((P/'data/osm_raw.json').read_text(encoding='utf-8'))
a,b=project(BOUNDS[1],BOUNDS[0]);c,d=project(BOUNDS[3],BOUNDS[2]);clip=box(a,d,c,b)
river=json.loads((P/'data/river_raw.json').read_text(encoding='utf-8'))
shore=[]
for m in river['elements'][0]['members']:
 runs=[];run=[]
 for node in m.get('geometry',[]):
  if node is None:
   if len(run)>1:runs.append(run)
   run=[]
  else:run.append(project(node['lat'],node['lon']))
 if len(run)>1:runs.append(run)
 shore+=runs
assert shore,'Missing source river bank'
shoreline=max(shore,key=len)
regions=list(split(clip,LineString(shoreline)).geoms)
assert len(regions)>=2,'Riverbank did not divide bounding rectangle'
water=max(regions,key=lambda g:g.centroid.y)
land=clip.difference(water)
features=[];roadlines=[];building_polys=[];footlines=[]
for e in raw['elements']:
 t=e.get('tags',{});coords=[project(v['lat'],v['lon']) for v in e.get('geometry',[]) if v]
 if len(coords)<2:continue
 if 'building' in t or 'building:part' in t:
  if len(coords)<4 or coords[0]!=coords[-1] or t.get('location')=='underground':continue
  poly=Polygon(coords)
  if not poly.is_valid:poly=poly.buffer(0)
  poly=poly.intersection(clip)
  if poly.is_empty or poly.area<2:continue
  h,source=height_info(t);base=number(t.get('min_height'),0)
  if e['id']==30258238:h,source=218.0,'OSM cylindrical body height; separate source cap reaches 221.5 m (CVU agrees)'
  features.append({'kind':'building','osm':e['id'],'name':t.get('name','Building '+str(e['id'])),'geometry':poly.__geo_interface__,'height':h,'base':min(base,h-1),'heightSource':source,'material':t.get('building:material','concrete'),'tags':{k:v for k,v in t.items() if k in ['height','min_height','building:levels','building:part']}})
  if base<1:building_polys.append(poly)
 elif 'highway' in t:
  if t.get('area')=='yes' or t.get('highway') in ['proposed','construction']:continue
  line=LineString(coords).intersection(clip)
  if line.is_empty:continue
  kind=t['highway'];walk=kind in ['footway','pedestrian','path','steps','cycleway']
  width=number(t.get('width'),0)
  estimated=width==0
  if not width:width=(3 if walk else max(5,number(t.get('lanes'),2)*3.2))
  roadlines.append(line.buffer(width/2))
  if walk and t.get('access') not in ['private','no']:footlines.append(line)
  features.append({'kind':'path' if walk else 'road','osm':e['id'],'name':t.get('name',kind),'geometry':line.__geo_interface__,'width':width,'widthSource':'estimate from lane count/type' if estimated else 'OSM width tag','elevation':number(t.get('layer'),0)*5,'elevationSource':'estimate: layer x 5 m (no surveyed terrain)','steps':kind=='steps','bridge':t.get('bridge')=='yes','tunnel':t.get('tunnel')=='yes'})
 elif t.get('name')=='Hart Plaza' or t.get('leisure')=='park':
  if len(coords)>3 and coords[0]==coords[-1]:
   poly=Polygon(coords).buffer(0).intersection(clip)
   if not poly.is_empty:features.append({'kind':'plaza' if t.get('name')=='Hart Plaza' else 'park','osm':e['id'],'name':t.get('name','Park'),'geometry':poly.__geo_interface__})
# Curated gameplay samples are mapped footpath points with conservative open-ground clearance.
blocks=unary_union(building_polys).buffer(2)
valid=[]
for line in footlines:
 for part in (line.geoms if hasattr(line,'geoms') else [line]):
  for i in range(max(1,int(part.length/12))+1):
   pt=part.interpolate(min(part.length,i*12))
   if land.buffer(-3).contains(pt) and not blocks.contains(pt):valid.append([pt.x,pt.y])
assert len(valid)>20
anchors={}
for name,lat,lon in [('Amber',42.3281,-83.0448),('Cyan',42.3281,-83.0389)]:
 x,z=project(lat,lon)
 pool=sorted(valid,key=lambda v:(v[0]-x)**2+(v[1]-z)**2)
 origin=pool[0];chosen=[]
 for v in pool:
  dist=math.dist(origin,v)
  if 15<dist<140 and all(math.dist(v,w)>15 for w in chosen):chosen.append(v)
  if len(chosen)>=10:break
 assert len(chosen)>=6,(name,len(chosen))
 anchors[name]={'spawn':origin,'sockets':chosen[:8],'exit':chosen[-1],'transit':chosen[-2]}
result={'id':'detroit_riverfront','origin':ORIGIN,'studsPerMeter':STUDS_PER_METER,'boundsWGS84':BOUNDS,'boundsMeters':list(clip.bounds),'groundDatum':'local Y=0 flat estimate, not geodetic elevation','land':land.__geo_interface__,'water':water.__geo_interface__,'shoreline':shoreline,'features':features,'gameplay':anchors,'sourceTimestamp':raw.get('osm3s',{}).get('timestamp_osm_base'),'attribution':'© OpenStreetMap contributors; ODbL 1.0; https://www.openstreetmap.org/copyright'}
(P/'data/detroit_geography.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print('Prepared',len(features),'features;',round(clip.bounds[2]-clip.bounds[0]),'x',round(clip.bounds[3]-clip.bounds[1]),'m; ground/water polygons;',len(valid),'open footpath samples.')
print('Gameplay anchors:',anchors)
