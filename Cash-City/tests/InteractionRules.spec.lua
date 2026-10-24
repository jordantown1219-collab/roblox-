return function(R)
 local n=0
 local function check(v,msg) assert(v,msg) n=n+1 end
 local function ctx() return {alive=true,active=true,allowed=true,distance=3,range=8,busy=false,elapsed=2,cooldown=0.6,clear=true,valid=true} end
 check(R.request(ctx()),"valid request")
 for _,key in ipairs({"alive","active","allowed","clear","valid"}) do local c=ctx() c[key]=false check(not R.request(c),"reject "..key) end
 local c=ctx() c.distance=9 check(not R.request(c),"remote interaction rejected")
 c=ctx() c.distance=0/0 check(not R.request(c),"NaN distance rejected")
 c=ctx() c.distance=math.huge check(not R.request(c),"infinite distance rejected")
 c=ctx() c.busy=true check(not R.request(c),"duplicate during animation rejected")
 c=ctx() c.elapsed=0.1 check(not R.request(c),"cooldown rejected")
 check(R.range(8,0.22)>=3,"tiny prompt usable")
 check(R.range(8,1)==8,"normal prompt range")
 check(R.range(8,0/0)==nil,"invalid character scale")
 check(R.progress(0,1,0)==0 and R.progress(0,1,1)==1,"closed/open endpoints")
 check(R.progress(1,0,1)==0,"close returns exact endpoint")
 check(R.progress(0,1,0.5)==0.5,"midpoint")
 check(R.finite(0) and not R.finite(0/0) and not R.finite(math.huge),"finite inputs")
 print("InteractionRules: "..n.." assertions passed")
 return n
end
