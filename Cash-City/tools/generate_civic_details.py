"""Reference-led CAYMC facade rhythm on preserved OSM shells; bay sizes are estimates."""
from pathlib import Path
import json, math

ROOT=Path(__file__).resolve().parents[1]
REFERENCE='https://www.michiganmodern.org/modern-buildings/city-county-building-coleman-a-young-municipal-center/'

def make_plan(source):
    plan={'version':1,'reference':REFERENCE,'status':'Source footprints/heights retained; architectural bay spacing is an estimate','faces':[],'details':[]}
    for building in source['buildings']:
        osm=building['osm']; floors={69000343:20,320396455:14}[osm]
        for face in building['faces']:
            r=face['record']; n=face['outwardNormalXYZ']; length=r['size'][2]
            base=r['pos'][1]-r['size'][1]/2; height=r['size'][1]; story=height/floors
            finish='west_blank_marble' if n[0]<-.7 else 'east_brick' if n[0]>.7 else 'window_elevation'
            plan['faces'].append({'name':r['name'],'pos':r['pos'],'size':r['size'],'matrix':r['matrix'],'osm':osm,'finish':finish,'color':[130,83,64] if finish=='east_brick' else [208,205,193],'material':'Brick' if finish=='east_brick' else 'Marble'})
            if finish=='west_blank_marble':continue
            def add(name,along,y,width,tall,depth,color,material,offset):
                m=r['matrix']
                pos=[r['pos'][0]+m[2]*along+n[0]*offset,y,r['pos'][2]+m[8]*along+n[2]*offset]
                plan['details'].append({'name':name,'size':[depth,tall,width],'pos':pos,'matrix':m,'color':color,'material':material,'osm':osm,'collide':False})
            for floor in range(floors):
                y=base+(floor+.53)*story
                if finish=='east_brick':
                    # Two offset ribbon groups described by the civic architectural reference.
                    for along,width in [(-length*.28,length*.31),(length*.20,length*.38)]:
                        add('Civic_EastRibbon',along,y,width,story*.48,.16,[47,63,68],'Glass',.49)
                else:
                    add('Civic_CourtsWindow' if osm==69000343 else 'Civic_AdminRibbon',0,y,length-.8,story*.52,.16,[45,65,74],'Glass',.49)
            if finish=='window_elevation':
                bays=max(2,round(length/(8 if osm==69000343 else 6.5)))
                for column in range(1,bays):
                    width=1.2 if osm==69000343 else (.45 if column%4==0 else .16)
                    add('Civic_VerticalMarblePier' if osm==69000343 else 'Civic_RibbonMullion',-length/2+length*column/bays,base+height/2,width,height,.22,[210,207,196] if osm==69000343 else [169,170,164],'Marble' if osm==69000343 else 'Metal',.68)
    assert len(plan['details'])<=450,'Reference detail budget exceeded'
    return plan

def main():
    source=json.loads((ROOT/'data/civic_facades.json').read_text())
    plan=make_plan(source)
    payload=json.dumps(plan,separators=(',',':'),allow_nan=False)
    (ROOT/'data/civic_detail_plan.json').write_text(payload,encoding='utf-8')
    (ROOT/'src/CivicFacadeData.lua').write_text('-- Generated from preserved source shells; see tools/generate_civic_details.py\nreturn game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n',encoding='utf-8')
    print(f"Civic details: {len(plan['faces'])} source faces, {len(plan['details'])} noncolliding accents")

if __name__=='__main__':main()
