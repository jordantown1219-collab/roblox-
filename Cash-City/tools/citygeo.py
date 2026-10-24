import math,re
ORIGIN=(42.329,-83.040)
STUDS_PER_METER=1/0.28
R=6378137.0
BOUNDS=(-83.0485,42.326,-83.031,42.3345)
def project(lat,lon):
 return math.radians(lon-ORIGIN[1])*R*math.cos(math.radians(ORIGIN[0])), -math.radians(lat-ORIGIN[0])*R
def inverse(x,z):
 return ORIGIN[0]-math.degrees(z/R),ORIGIN[1]+math.degrees(x/(R*math.cos(math.radians(ORIGIN[0]))))
def sector_key(x,z):return f'{math.floor(x/256)}_{math.floor(z/256)}'
def number(value,default=0):
 try:return float(re.match(r'[-+]?\d+(?:\.\d+)?',str(value)).group())
 except (ValueError,AttributeError):return default

def height_info(tags):
 name=tags.get('name','')
 if re.search(r'Renaissance Center Tower [1-4]00$',name):return 155.0,'CVU architectural height; OSM surrounding detailed parts may differ by datum'
 if re.search(r'Renaissance Center Tower [56]00$',name):return 103.0,'CVU architectural height; OSM part tags differ'
 if tags.get('height'):
  return number(tags['height'],12),'OSM height tag (not independently surveyed)'
 if tags.get('building:levels'):return number(tags['building:levels'],4)*3.3,'estimate: levels times 3.3 m'
 return 12.0,'estimate: unmeasured massing default 12 m'
