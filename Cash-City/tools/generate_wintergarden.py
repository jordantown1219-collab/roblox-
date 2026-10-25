"""Original source-guarded river-entry glass barrel; no source geometry mutations."""
import hashlib
import json
import math
import os
from pathlib import Path
import sys
sys.path.insert(0, str(Path(os.environ.get("TEMP", "")) / "smallsignals-test-deps"))
import shapely
from shapely.geometry import Polygon, LineString, Point, box, shape
from shapely import affinity

ROOT=Path(__file__).resolve().parents[1]
OSM=419447156
FLOOR=.35

def sub(a,b): return [a[i]-b[i] for i in range(3)]
def dot(a,b): return sum(a[i]*b[i] for i in range(3))
def cross(a,b): return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
def norm(v):
    length=math.sqrt(dot(v,v)); return [n/length for n in v]

def generate(root=ROOT):
    geo_path=root/'data/detroit_geography.json'; geometry_path=root/'data/geometry.json'
    geography=json.loads(geo_path.read_text()); source=json.loads(geometry_path.read_text())
    feature=next(f for f in geography['features'] if f['osm']==OSM)
    scale=geography['studsPerMeter']
    original=affinity.scale(shape(feature['geometry']),xfact=scale,yfact=scale,origin=(0,0))
    # Keep the full original source outline; inset leaves wall/roof thickness inside it.
    footprint=original.buffer(-.25,join_style=2)
    ux,uz=norm([.8708,0,-.4917])[::2]
    vx,vz=uz,-ux
    center=footprint.centroid
    def local(point):
        x,z=point[0]-center.x,point[1]-center.y
        return x*ux+z*uz,x*vx+z*vz
    def world(u,v,y): return [center.x+ux*u+vx*v,y,center.y+uz*u+vz*v]
    local_poly=Polygon([local(p) for p in footprint.exterior.coords])
    umin,vmin,umax,vmax=local_poly.bounds
    breaks=[umin+(umax-umin)*i/8 for i in range(9)]
    spring=15*scale; peak=29.7*scale
    heights=[spring+(peak-spring)*math.sqrt(max(0,1-((2*u-umin-umax)/(umax-umin))**2)) for u in breaks]
    def roof_y(u):
        for i in range(8):
            if u<=breaks[i+1]+1e-7:
                t=(u-breaks[i])/(breaks[i+1]-breaks[i]); return heights[i]*(1-t)+heights[i+1]*t
        return heights[-1]
    records=[]
    def add(name,size,pos,matrix,color,material,collide=True,trans=0,cls='Part'):
        if min(size)<.001: return
        records.append({'name':name,'size':size,'pos':pos,'matrix':matrix,'color':color,'material':material,
                        'collide':collide,'trans':trans,'cls':cls,'meta':{'owner':'Wintergarden','osm':OSM,'dimensions':'original gameplay estimate'}})
    def triangle(name,a,b,c,depth,color,material,trans=0):
        ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
        if dot(ab,ab)>dot(ac,ac) and dot(ab,ab)>dot(bc,bc): c,a=a,c
        elif dot(ac,ac)>dot(bc,bc) and dot(ac,ac)>dot(ab,ab): a,b=b,a
        ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
        if dot(cross(ac,ab),cross(ac,ab))<1e-8:return
        right=norm(cross(ac,ab)); back=norm(bc); up=norm(cross(bc,right)); width=abs(dot(ab,up))
        for other,vector,flip in [(b,ab,1),(c,ac,-1)]:
            length=abs(dot(vector,back))
            if min(width,length)<.001:continue
            matrix=[right[0]*flip,up[0],back[0]*flip,right[1]*flip,up[1],back[1]*flip,right[2]*flip,up[2],back[2]*flip]
            add(name,[depth,width,length],[(a[i]+other[i])/2 for i in range(3)],matrix,color,material,True,trans,'WedgePart')
            records[-1]['meta']['surfaceTriangleVertices']=[a,b,c]
    def sheet(name,poly,height,depth,color,material,trans=0):
        if poly.is_empty or poly.geom_type!='Polygon':return
        for tri in shapely.constrained_delaunay_triangles(poly).geoms:
            pts=[world(u,v,height(u)) for u,v in list(tri.exterior.coords)[:3]]
            triangle(name,*pts,depth,color,material,trans)
    # Thin triangulated surfaces follow the actual nonrectangular footprint.
    for i in range(8):
        piece=local_poly.intersection(box(breaks[i],vmin-1,breaks[i+1],vmax+1))
        sheet('Wintergarden_CurvedGlassRoof',piece,roof_y,.16,[141,185,172],'Glass',.38)
    sheet('Wintergarden_Floor',local_poly,lambda u:FLOOR-.15,.3,[184,183,174],'Limestone')
    # Find the broad real source river face for a single functional entrance aperture.
    target=next(r for r in source if r['name']==f'Facade_{OSM}' and r['size'][2]>70 and r['pos'][2]>280)
    ring=list(footprint.exterior.coords)
    edges=list(zip(ring,ring[1:]))
    target_point=Point(target['pos'][0],target['pos'][2])
    entry_index=min(range(len(edges)),key=lambda i:LineString(edges[i]).distance(target_point))
    # Source-aligned rear portal to the estimated public-lobby connector.
    rear_source=source[19478]
    assert rear_source['name']=='Facade_1307210646', 'Rear source identity changed'
    rear_center=Point(rear_source['pos'][0],rear_source['pos'][2])
    rear_index=min(range(len(edges)),key=lambda i:LineString(edges[i]).distance(rear_center))
    assert rear_index!=entry_index
    door=None
    rear_portal=None
    for edge_index,(a,b) in enumerate(edges):
        dx,dz=b[0]-a[0],b[1]-a[1]; length=math.hypot(dx,dz); tx,tz=dx/length,dz/length
        # Right handed frame: local X outward normal, local Z along edge.
        nx,nz=tz,-tx
        midpoint=((a[0]+b[0])/2,(a[1]+b[1])/2)
        if nx*(midpoint[0]-center.x)+nz*(midpoint[1]-center.y)<0:nx,nz=-nx,-nz
        # Choose tangent sign to make columns(normal,up,tangent) right handed.
        tx,tz=-nz,nx
        matrix=[nx,0,tx,0,1,0,nz,0,tz]
        cuts=[0,1]
        ua,ub=local(a)[0],local(b)[0]
        if abs(ub-ua)>1e-8:
            cuts += [(u-ua)/(ub-ua) for u in breaks[1:-1] if 0<(u-ua)/(ub-ua)<1]
        if edge_index==entry_index:
            cuts += [.5-4/length,.5+4/length]
            # Components.door local -Z faces outward; local X follows facade tangent.
            door_matrix=[-nz,0,-nx,0,1,0,nx,0,-nz]
            door={'name':'Wintergarden river entrance','pos':[midpoint[0],FLOOR+5,midpoint[1]],'matrix':door_matrix,
                  'width':8,'apertureWidth':8,'height':10,
                  'approachPoints':[[midpoint[0]+nx*5,FLOOR,midpoint[1]+nz*5],[midpoint[0]-nx*8,FLOOR,midpoint[1]-nz*8]],
                  'outwardNormal':[nx,0,nz]}
        rear_interval=None
        if edge_index==rear_index:
            mid=((rear_center.x-a[0])*dx+(rear_center.y-a[1])*dz)/(length*length)
            rear_interval=(mid-4/length,mid+4/length)
            assert 0<rear_interval[0]<rear_interval[1]<1
            cuts+=list(rear_interval)
            rear_portal={'pos':[a[0]+dx*mid,FLOOR+5,a[1]+dz*mid],
                         'matrix':[-nz,0,-nx,0,1,0,nx,0,-nz],
                         'width':8,'height':10,'outwardNormal':[nx,0,nz]}
        cuts=sorted(set(cuts))
        for t0,t1 in zip(cuts,cuts[1:]):
            p=(a[0]+dx*t0,a[1]+dz*t0); q=(a[0]+dx*t1,a[1]+dz*t1)
            yp,yq=roof_y(local(p)[0]),roof_y(local(q)[0]); low=min(yp,yq)
            bottom=FLOOR
            if edge_index==entry_index and abs((t0+t1)/2-.5)<4/length-1e-7:bottom=FLOOR+10
            if rear_interval and rear_interval[0]<(t0+t1)/2<rear_interval[1]:bottom=FLOOR+10
            segment=math.dist(p,q)
            add('Wintergarden_GlassWall',[.22,low-bottom,segment],[(p[0]+q[0])/2,(bottom+low)/2,(p[1]+q[1])/2],matrix,[141,185,172],'Glass',True,.38)
            if abs(yp-yq)>.001:
                triangle('Wintergarden_WallArchFill',[p[0],yp,p[1]],[q[0],yq,q[1]],
                         [p[0],low,p[1]] if yp>yq else [q[0],low,q[1]],.22,[141,185,172],'Glass',.38)
    assert door, 'No source-derived entry face'
    # Guard roof, source glass walls and their exactly associated generated mullions.
    indices={i for i,r in enumerate(source) if r['name'] in (f'Facade_{OSM}',f'Roof_{OSM}')}
    for i,r in enumerate(source):
        if r['name']!=f'Facade_{OSM}':continue
        for j in (i+1,i+2):
            candidate=source[j]
            quarter=(r['size'][2]-.1)/4
            distances=[math.dist(candidate['pos'],[r['pos'][0]+r['matrix'][2]*quarter*sign,r['pos'][1],r['pos'][2]+r['matrix'][8]*quarter*sign]) for sign in (-1,1)]
            assert candidate['name']=='FacadeMullion' and candidate['size']==[.9,r['size'][1],.7] and min(distances)<1e-6, 'Mullion association changed'
            indices.add(j)
    replacements=[{'sourceIndex':i,'record':source[i]} for i in sorted(indices)]
    inside=door['approachPoints'][1]
    samples=[{'pos':[inside[0]-door['outwardNormal'][0]*distance,FLOOR,inside[2]-door['outwardNormal'][2]*distance],
              'floorY':FLOOR,'width':4.6,'clearHeight':10} for distance in (0,6,12)]
    def decorative_rod(name,a,b,color,width=.42):
        direction=norm(sub(b,a)); right=norm(cross([0,1,0],direction)); up=cross(direction,right)
        matrix=[right[0],up[0],direction[0],right[1],up[1],direction[1],right[2],up[2],direction[2]]
        add(name,[width,width,math.dist(a,b)],[(a[i]+b[i])/2 for i in range(3)],matrix,color,'Metal',False)
    # Original pale-yellow roof ribs below the glass surface; spacing is not surveyed.
    decorative_footprint=local_poly.buffer(-1)
    for fraction in (.25,.5,.75,.875):
        v=vmin+(vmax-vmin)*fraction
        cut=decorative_footprint.intersection(LineString([(umin-1,v),(umax+1,v)]))
        if cut.geom_type!='LineString':continue
        left,right=sorted([cut.coords[0][0],cut.coords[-1][0]])
        cuts=[left]+[u for u in breaks[1:-1] if left<u<right]+[right]
        for a,b in zip(cuts,cuts[1:]):
            decorative_rod('Wintergarden_DecorativePaleYellowRoofRib',world(a,v,roof_y(a)-.8),world(b,v,roof_y(b)-.8),[218,202,132])
    u=(umin+umax)/2
    spine=decorative_footprint.intersection(LineString([(u,vmin-1),(u,vmax+1)]))
    if spine.geom_type=='LineString':
        a,b=spine.coords[0],spine.coords[-1]
        decorative_rod('Wintergarden_DecorativeSilverInlandSpine',world(a[0],a[1],roof_y(u)-.8),world(b[0],b[1],roof_y(u)-.8),[211,217,213],.4)
    # Slender glazing bars follow the existing eight roof facets, below the glass.
    # Reuse the clipped footprint and profile; never replace walls or entry assemblies.
    for u in breaks[1:-1]:
        cut=decorative_footprint.intersection(LineString([(u,vmin-1),(u,vmax+1)]))
        if cut.geom_type!='LineString':continue
        a,b=cut.coords[0],cut.coords[-1]
        decorative_rod('Wintergarden_DecorativeRoofGlazingBar',world(a[0],a[1],roof_y(u)-.3),world(b[0],b[1],roof_y(u)-.3),[185,195,191],.24)
    # Two explicitly decorative planters, outside entrance and all standing-room probes.
    route=LineString([(p['pos'][0],p['pos'][2]) for p in samples]+[(door['pos'][0],door['pos'][2])])
    planter_count=0
    for fraction in (.25,.75):
        point=world(umin+(umax-umin)*fraction,(vmin+vmax)/2,FLOOR)
        probe=Point(point[0],point[2])
        if not footprint.covers(probe.buffer(4)) or probe.distance(route)<9:continue
        identity=[1,0,0,0,1,0,0,0,1]
        add('Wintergarden_DecorativePlanterBase',[4,2,4],[point[0],FLOOR+1,point[2]],identity,[179,178,165],'Limestone',False)
        add('Wintergarden_DecorativePlanterGreenery',[3.3,1.2,3.3],[point[0],FLOOR+2.6,point[2]],identity,[78,106,69],'Grass',False)
        planter_count+=1
    assert len(records)<=200, f'Primitive budget exceeded {len(records)}; leave room for door parts'
    return {'id':'Wintergarden','records':records,'replacements':replacements,'doorAnchors':[door],'routeSamples':samples,
            'metadata':{'sourceOsm':OSM,'sourceHashes':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (geo_path,geometry_path)},
                        'sourceFootprintStuds':{'type':'Polygon','coordinates':[list(map(list,original.exterior.coords))]},
                        'roofFootprintStuds':{'type':'Polygon','coordinates':[list(map(list,footprint.exterior.coords))]},
                        'axisAcrossRiverXZ':[ux,uz],'axisInlandXZ':[vx,vz], 'sourceTopStuds':30*scale,
                        'profileSpringlineStuds':spring,'profilePeakStuds':peak,'profileClassification':'Unsurveyed original gameplay estimate; reference-informed orientation/material only',
                        'rearLobbyPortal':rear_portal,'roofSlices':8,'floorTopStuds':FLOOR,'glassTint':'Original muted green; no copied texture','decorativePlanters':planter_count,
                        'identity':'Anonymous source glass part, Wintergarden candidate by map/reference correlation',
                        'limitations':['Functional door components and registry are Lead integration tasks.','Exclude previous atrium facade-grid accents on replaced source faces.','No tower/podium/stair replacement, authentic interior or measured roof-section claim.','Native collision/walking/size/device/multiplayer/FPS and visual acceptance pending.']}}

if __name__=='__main__':
    plan=generate()
    (ROOT/'data/wintergarden_plan.json').write_text(json.dumps(plan,sort_keys=True,separators=(',',':'),allow_nan=False)+'\n',encoding='utf-8')
    print(json.dumps({'parts':len(plan['records']),'replacements':len(plan['replacements']),'axis':plan['metadata']['axisAcrossRiverXZ']}))
