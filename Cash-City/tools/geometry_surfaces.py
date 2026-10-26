"""Horizontal polygon-to-WedgePart conversion shared by new access components."""
import math,shapely
from generate_wintergarden import sub,dot,cross,norm
def horizontal_parts(poly,top,depth,name,color,material):
 records=[]
 for tri in shapely.constrained_delaunay_triangles(poly).geoms:
  a,b,c=[[x,top-depth/2,z]for x,z in list(tri.exterior.coords)[:3]];ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
  if dot(ab,ab)>dot(ac,ac)and dot(ab,ab)>dot(bc,bc):c,a=a,c
  elif dot(ac,ac)>dot(bc,bc):a,b=b,a
  ab,ac,bc=sub(b,a),sub(c,a),sub(c,b);right=norm(cross(ac,ab));back=norm(bc);up=norm(cross(bc,right));width=abs(dot(ab,up))
  for other,v,flip in[(b,ab,1),(c,ac,-1)]:
   length=abs(dot(v,back))
   if min(width,length)<.001:continue
   records.append(dict(name=name,size=[depth,width,length],pos=[(a[i]+other[i])/2 for i in range(3)],matrix=[right[0]*flip,up[0],back[0]*flip,right[1]*flip,up[1],back[1]*flip,right[2]*flip,up[2],back[2]*flip],color=color,material=material,collide=True,cls='WedgePart'))
 return records
