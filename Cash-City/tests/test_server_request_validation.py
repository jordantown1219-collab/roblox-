"""Actual Action callback/guards, isolated from networking and engine raycasts."""
from pathlib import Path
import os
import sys
import unittest

sys.path.insert(0, str(Path(os.environ['TEMP']) / 'smallsignals-test-deps'))
from lupa import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'src/SmallSignalsServer.server.lua').read_text(encoding='utf-8')
GUARDS = SOURCE[SOURCE.index('local function active(p)'):SOURCE.index('local function setArmor')]
CALLBACK = SOURCE[SOURCE.index('local function vectorFinite(v)'):SOURCE.index('local function addPlayer(p)')]


def harness():
    lua = LuaRuntime()
    lua.globals().C = lua.execute((ROOT / 'src/Config.lua').read_text())
    lua.execute('''
    local vectorMT={}
    function vector(x,y,z) return setmetatable({X=x,Y=y,Z=z,_vector=true},vectorMT) end
    vectorMT.__sub=function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
    vectorMT.__mul=function(a,b) return vector(a.X*b,a.Y*b,a.Z*b) end
    vectorMT.__index=function(v,k)
        local n=math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)
        if k=='Magnitude' then return n end
        if k=='Unit' then return vector(v.X/n,v.Y/n,v.Z/n) end
    end
    function typeof(v) return type(v)=='table' and v._vector and 'Vector3' or type(v) end
    table.find=function(t,v) for i,x in ipairs(t) do if x==v then return i end end end
    phase='Match' time=100 calls=0 lastAction={} queue={} votes={}
    local attributes={}
    h={Health=100}
    tool={Name='Rifle'} head={Position=vector(0,0,0)}
    p={Character={FindFirstChildOfClass=function() return tool end,
       FindFirstChild=function(_,name) if name=='Head' then return head else return tool end end}}
    function p:GetAttribute(k) return attributes[k] end
    function p:SetAttribute(k,v) attributes[k]=v end
    m={stage=0,team='Amber',weapon='Rifle',carrier=true,ammo=20}
    members={[p]=m}
    function humanoid() return h end
    function now() return time end
    function root() return nil end
    WeaponVisuals={fire=function() end,reload=function() end}
    RaycastParams={new=function() return {} end}
    Enum={RaycastFilterType={Exclude='Exclude'}}
    workspace={Raycast=function(_,origin,direction) calls=calls+1 lastRange=direction.Magnitude return nil end}
    RunService={IsStudio=function() return false end}
    remote={OnServerEvent={Connect=function(_,fn) request=fn end}}
    ''' + GUARDS + CALLBACK)
    return lua


class ServerRequestValidation(unittest.TestCase):
    def test_unknown_actions_cannot_grow_throttle_state(self):
        harness().execute('''
        for i=1,1000 do request(p,'Unsupported_'..i,vector(100,0,0)) end
        assert(lastAction[p]==nil,'Unsupported actions allocated throttle entries')
        assert(calls==0 and m.ammo==20)
        request(p,'Attack',vector(100,0,0))
        assert(calls==1 and m.ammo==19 and lastAction[p].Attack==100)
        local count=0 for _ in pairs(lastAction[p]) do count=count+1 end
        assert(count==1,'Unexpected throttle keys retained')
        ''')

    def test_lobby_ready_and_unready_still_work(self):
        harness().execute('''
        phase='Lobby' request(p,'Ready',3) assert(queue[p]==3)
        time=101 request(p,'Unready') assert(queue[p]==nil)
        ''')

    def test_nonfinite_wrong_type_and_oversized_targets_never_fire(self):
        harness().execute('''
        local invalid={false,'target',{},vector(0/0,0,0),vector(math.huge,0,0),
            vector(0,-math.huge,0),vector(0,0,1000000),vector(-1000000,0,0)}
        for _,target in ipairs(invalid) do
            request(p,'Attack',target) time=time+1
            assert(calls==0 and m.ammo==20 and m.lastShot==nil)
        end
        request(p,{},vector(100,0,0)) assert(lastAction[p]['Attack']~=nil and calls==0)
        ''')

    def test_phase_membership_alive_and_loading_guards(self):
        for condition in ("phase='Lobby'", "members[p]=nil", "h.Health=0",
                          "p:SetAttribute('Downed',true)", "p:SetAttribute('RiverfrontLoading',true)"):
            with self.subTest(condition=condition):
                harness().execute(condition + " request(p,'Attack',vector(100,0,0)) assert(calls==0 and m.ammo==20)")

    def test_equipment_ammo_reload_and_zero_aim_guards(self):
        for condition in ("tool=nil", "m.carrier=false", "tool.Name='SMG'",
                          "m.ammo=0", "m.reloadAt=105", "head=nil"):
            with self.subTest(condition=condition):
                harness().execute(condition + " request(p,'Attack',vector(100,0,0)) assert(calls==0 and m.lastShot==nil)")
        harness().execute("request(p,'Attack',vector(0,0,0)) assert(calls==0 and m.ammo==20)")

    def test_server_weapon_cooldown_and_range_override_client_distance(self):
        harness().execute('''
        request(p,'Attack',vector(999999,0,0))
        assert(calls==1 and m.ammo==19 and lastRange==C.Weapons.Rifle.Range)
        time=100.01 request(p,'Attack',vector(100,0,0)) assert(calls==1)
        time=100.1 request(p,'Attack',vector(100,0,0)) assert(calls==1)
        time=100.25 request(p,'Attack',vector(100,0,0)) assert(calls==2 and m.ammo==18)
        ''')

    def test_noncarrier_melee_uses_stage_reach_without_ammo(self):
        harness().execute('''
        m.carrier=false m.stage=3 tool.Name='Knife'
        request(p,'Attack',vector(500,0,0))
        assert(calls==1 and math.abs(lastRange-C.Weapons.Knife.Range*C.Scales[4])<1e-9)
        assert(m.ammo==20)
        ''')


if __name__ == '__main__':
    unittest.main()
