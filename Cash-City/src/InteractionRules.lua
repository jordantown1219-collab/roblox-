local R={}
function R.finite(value) return type(value)=="number" and value==value and math.abs(value)<1e10 end
function R.request(c)
 return c.valid and c.active and c.alive and c.allowed and c.clear and not c.busy
    and R.finite(c.distance) and c.distance>=0 and c.distance<=c.range
    and R.finite(c.elapsed) and c.elapsed>=c.cooldown
end
function R.range(base,scale)
 if not R.finite(base) or not R.finite(scale) or scale<0.1 or scale>4 then return nil end
 return math.max(3,base*scale)
end
function R.progress(a,b,t) return a+(b-a)*math.max(0,math.min(1,t)) end
return R
