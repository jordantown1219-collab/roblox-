"""Small reference-led paving trial on a validated existing Hart Plaza path."""
from pathlib import Path
import json,math
ROOT=Path(__file__).resolve().parents[1]

def make_plan(site):
 s=site['firstMapSlice']; a,b=s['anchorsStudsXYZ']; scale=site['studsPerMeter']
 dx,dz=b[0]-a[0],b[2]-a[2];length=math.hypot(dx,dz)
 forward=(dx/length,dz/length);right=(forward[1],-forward[0]);width=2*scale
 mid=((a[0]+b[0])/2,(a[2]+b[2])/2)
 matrix=[right[0],0,forward[0],0,1,0,right[1],0,forward[1]]
 def position(x,z,y):return [mid[0]+right[0]*x+forward[0]*z,y,mid[1]+right[1]*x+forward[1]*z]
 top=s['currentRenderedPathTopStuds']+.06
 records=[{'name':'ContinuousPathCollision','size':[width,.08,length],'pos':position(0,0,top-.04),'matrix':matrix,'color':[157,142,130],'material':'Concrete','collide':True,'trans':1}]
 for row in range(8):
  for col in range(4):
   tone=(row+col)%3-1
   records.append({'name':'HartGranitePanel','size':[width/4-.025,.03,length/8-.025],'pos':position((col-1.5)*width/4,(row-3.5)*length/8,top-.015),'matrix':matrix,'color':[157+tone*3,142+tone*3,130+tone*3],'material':'Granite','collide':False})
 return {'id':'HartPlazaPath_106403203','records':records,'sourceOSM':106403203,'referenceStatus':'Granite material study on mapped path; panel layout is an original approximation, not surveyed paving','heightChangeStuds':.06,'reference':'https://detroitmi.gov/sites/detroitmi.localhost/files/2018-08/2018%2007%2031%20Hart%20Plaza%20Draft%20NR%20Nomination%20Form%20FINAL%20w%20maps.pdf'}

def main():
 p=make_plan(json.loads((ROOT/'data/playable_block.json').read_text()))
 payload=json.dumps(p,separators=(',',':'),allow_nan=False)
 (ROOT/'data/hart_path_plan.json').write_text(payload)
 (ROOT/'src/HartPathData.lua').write_text('-- Source path retained; see tools/generate_hart_path.py\nreturn game:GetService("HttpService"):JSONDecode([=['+payload+']=])\n')
 print('Hart path:',len(p['records']),'records; original grade retained within .06stud paving thickness')

if __name__=='__main__':main()
