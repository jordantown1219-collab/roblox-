import sys,os,json,math
from pathlib import Path
sys.path.insert(0,str(Path(os.environ['TEMP'])/'smallsignals-test-deps'))
import shapely
from shapely.geometry import shape,box,LineString,Point
from shapely.ops import triangulate
from citygeo import *
P=Path(__file__).resolve().parents[1]
G=json.loads((P/'data/detroit_geography.json').read_text(encoding='utf-8'))
S=STUDS_PER_METER
parts=[]
def add(name,size,pos,color,material='Concrete',yaw=0,collide=True,trans=0,sector=None,cls='Part',matrix=None,**meta):
 assert min(size)>0 and max(size)<=2048,(name,size)
 if matrix is None:
  co,si=math.cos(yaw),math.sin(yaw);matrix=[co,0,si,0,1,0,-si,0,co]
 item=dict(name=name,size=size,pos=pos,color=color,material=material,collide=collide,trans=trans,matrix=matrix,cls=cls,sector=sector or sector_key(pos[0]/S,pos[2]/S),meta=meta)
 parts.append(item);return item

def sub(a,b):return [a[i]-b[i] for i in range(3)]
def dot(a,b):return sum(a[i]*b[i] for i in range(3))
def cross(a,b):return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
def norm(v):
 l=math.sqrt(dot(v,v));return [x/l for x in v]
def triangle(name,points,y,depth,color,material,sector,collide=True,trans=0):
 a,b,c=[[x*S,y,z*S] for x,z in points]
 ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
 right_corner=None
 for i,v in enumerate((a,b,c)):
  u,w=[point for j,point in enumerate((a,b,c)) if j!=i]
  vu,vw=sub(u,v),sub(w,v)
  if abs(dot(vu,vw))<=1e-8*math.sqrt(dot(vu,vu)*dot(vw,vw)):
   right_corner=(u,v,w);break
 if right_corner is not None:a,b,c=right_corner
 elif dot(ab,ab)>dot(ac,ac) and dot(ab,ab)>dot(bc,bc):c,a=a,c
 elif dot(ac,ac)>dot(bc,bc) and dot(ac,ac)>dot(ab,ab):a,b=b,a
 ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
 if dot(cross(ac,ab),cross(ac,ab))<1e-8:return
 right=norm(cross(ac,ab));back=norm(bc);up=norm(cross(bc,right))
 width=abs(dot(ab,up))
 for one,other,flip in [(b,ab,1),(c,ac,-1)]:
  length=abs(dot(other,back))
  if min(width,length)<.01:continue
  mat=[right[0]*flip,up[0],back[0]*flip,right[1]*flip,up[1],back[1]*flip,right[2]*flip,up[2],back[2]*flip]
  add(name,[depth,width,length],[(a[i]+one[i])/2 for i in range(3)],color,material,collide=collide,trans=trans,sector=sector,cls='WedgePart',matrix=mat)

def polys(g):return list(g.geoms) if hasattr(g,'geoms') and g.geom_type!='Polygon' else [g]
def surface_piece(name,poly,y,depth,color,material,sector,collide,trans):
 if poly.is_empty:return
 poly=poly.simplify(1e-8,preserve_topology=True)
 rect=poly.minimum_rotated_rectangle
 if poly.geom_type=='Polygon' and rect.geom_type=='Polygon' and poly.symmetric_difference(rect).area<1e-7:
  a,b,c=list(rect.exterior.coords)[:3]
  length,width=math.dist(a,b)*S,math.dist(b,c)*S
  if min(length,width)>.01:
   add(name,[width,depth,length],[rect.centroid.x*S,y,rect.centroid.y*S],color,material,math.atan2(b[0]-a[0],b[1]-a[1]),collide,trans,sector)
  return
 for tri in shapely.constrained_delaunay_triangles(poly).geoms:
  triangle(name,list(tri.exterior.coords)[:3],y,depth,color,material,sector,collide,trans)
def surface(name,poly,y,depth,color,material='Concrete',collide=True,trans=0):
 if poly.is_empty:return
 for subpoly in polys(poly):
  if subpoly.geom_type!='Polygon':continue
  bounds=subpoly.bounds
  for ix in range(math.floor(bounds[0]/256),math.floor(bounds[2]/256)+1):
   for iz in range(math.floor(bounds[1]/256),math.floor(bounds[3]/256)+1):
    piece=subpoly.intersection(box(ix*256,iz*256,(ix+1)*256,(iz+1)*256))
    for poly2 in polys(piece):
     if poly2.is_empty or poly2.geom_type!='Polygon' or poly2.area<.01:continue
     sector=f'{ix}_{iz}'
     surface_piece(name,poly2,y,depth,color,material,sector,collide,trans)

from surfaces import build_surface_layers
for layer in build_surface_layers(G):
 depth=3 if layer['name']=='SourceLand' else .14
 surface(layer['name'],layer['geometry'],layer['top']-depth/2,depth,layer['color'],layer['material'],layer['name']!='DetroitRiver',.12 if layer['name']=='DetroitRiver' else 0)
# Follows source bank. Safety railing is a gameplay estimate, not a surveyed historic fixture.
line=LineString(G['shoreline']).intersection(box(*G['boundsMeters']))
for geom in polys(line):
 if geom.geom_type!='LineString':continue
 coords=list(geom.coords)
 for a,b in zip(coords,coords[1:]):
  length=math.dist(a,b)*S
  if length<.1:continue
  mid=[(a[0]+b[0])/2*S,2,(a[1]+b[1])/2*S]
  add('EstimatedRiverSafetyRail',[.45,4,length],mid,[80,88,86],'Metal',math.atan2(b[0]-a[0],b[1]-a[1]))
# Transport surfaces are unioned/clipped above, including intersections and land seams.
# Footprints are polygon wall shells rather than axis-aligned substitute boxes.
for f in G['features']:
 if f['kind']!='building':continue
 poly=shape(f['geometry']);h=f['height']*S;base=f['base']*S
 glass=f['material']=='glass' or f['osm'] in [419447171,419447172,419447173,419447174,30258238]
 color=[65,83,88] if glass else [143,141,130]
 for polygon in polys(poly):
  if polygon.geom_type!='Polygon':continue
  coords=list(polygon.simplify(.35,preserve_topology=True).exterior.coords)
  for a,b in zip(coords,coords[1:]):
   length=math.dist(a,b)*S
   if length<.1:continue
   add('Facade_'+str(f['osm']),[.7,h-base,length+.1],[(a[0]+b[0])/2*S,(h+base)/2,(a[1]+b[1])/2*S],color,'Glass' if glass else 'Concrete',math.atan2(b[0]-a[0],b[1]-a[1]),True,0,osm=f['osm'],heightSource=f['heightSource'])
   # Slim repeated facade mullions: native reusable geometry, no copied texture.
   if glass and length>5:
    for t in [0.25,0.75]:
     add('FacadeMullion',[.9,h-base,.7],[(a[0]+(b[0]-a[0])*t)*S,(h+base)/2,(a[1]+(b[1]-a[1])*t)*S],[116,126,128],'Metal',collide=False)
  surface('Roof_'+str(f['osm']),polygon.simplify(.35,preserve_topology=True),h,.5,[94,101,100],'Concrete')
# Bounded street-level refinement near Hart Plaza. Estimated bay rhythm, not surveyed details.
# Keep accents in source sectors; no whole-district atomic model or extra collision walls.
refined=0
for wall in list(parts):
 if not wall['name'].startswith('Facade_'):continue
 x,y,z=wall['pos']; width,height,length=wall['size']
 if math.hypot(x+1360,z+118)>550 or length<35 or y-height/2>1:continue
 if refined>=10:break
 refined+=1
 glass=wall['material']=='Glass'
 wall['color']=[67,86,91] if glass else [166,162,149]
 wall['material']='Glass' if glass else 'Limestone'
 # Both faces of the source wall receive raised detailing; each is separated from the wall plane.
 m=wall['matrix']; nx,nz=m[0],m[6]; zx,zz=m[2],m[8]
 for side in [-1,1]:
  for elevation in [1.1,13.5]:
   add('Polish_StoneCourse',[.18,.55,length],[x+nx*side*.49,elevation,z+nz*side*.49],[115,117,110],'Concrete',matrix=m,collide=False,sector=wall['sector'])
  bays=min(4,max(2,int(length/24)))
  for bay in range(bays):
   along=(bay-(bays-1)/2)*length/bays
   add('Polish_GroundGlazing',[.14,8.5,length/bays-3],[x+zx*along+nx*side*.48,7.3,z+zz*along+nz*side*.48],[52,71,77],'Glass',matrix=m,collide=False,sector=wall['sector'])

# Conservative visual-only high rises: all source positions retained, interiors are not advertised.
(P/'data/geometry.json').write_text(json.dumps(parts,separators=(',',':')),encoding='utf-8')
print('Generated',len(parts),'native primitives;',len(set(b['sector'] for b in parts)),'geographic sectors;',max(max(b['size']) for b in parts),'largest part dimension.')
