from pathlib import Path
import os
import sys
import unittest

sys.path.insert(0, str(Path(os.environ['TEMP']) / 'smallsignals-test-deps'))
from lupa import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class LoadingRecovery(unittest.TestCase):
    def test_spawn_prefetch_failure_uses_safe_staging_and_finishes_setup(self):
        source = (ROOT / 'src/SmallSignalsServer.server.lua').read_text(encoding='utf-8')
        start = source.index('local spawning = {}')
        end = source.index('local function roster', start)
        lua = LuaRuntime()
        lua.execute('''
        attrs={} calls={} Arena={lobby='safe staging',spawns={Amber='city'}}
        C={SpawnProtection=3,RespawnSeconds=4} roundId=2
        local h={Parent=true,Health=100,Died={Connect=function(_,f) calls.deathHandler=f end}}
        p={Parent=true,Character={PivotTo=function(_,v) calls.destination=v end}}
        function p:SetAttribute(k,v) attrs[k]=v end
        function p:LoadCharacterAsync() calls.loaded=true end
        m={stage=2,team='Amber',checkpoint='checkpoint',armor=50}
        members={[p]=m}
        function humanoid() return h end
        function setArmor(_,v) calls.armor=v end
        function setStage(_,v) calls.stage=v end
        function now() return 100 end
        function equip() calls.equipped=true end
        function warn() end
        CFrame={new=function(v) return v end}
        Instance={new=function(kind) calls.shield=kind return {} end}
        task={delay=function() end}
        WorldLoading={prepare=function() return false end}
        ''' + source[start:end] + '''
        spawn(p)
        assert(calls.destination=='safe staging')
        assert(calls.equipped and calls.shield=='ForceField' and calls.deathHandler)
        assert(attrs.ProtectedUntil==103 and attrs.RiverfrontSpawnRecovery==true)
        assert(members[p]==m and m.stage==2 and m.checkpoint=='checkpoint')
        assert(spawning[p]==nil and calls.stage==2 and calls.armor==0)
        -- Lobby spawns use persistent staging without an unnecessary request.
        members[p]=nil
        WorldLoading.prepare=function() error('lobby must not request') end
        spawn(p)
        assert(calls.destination=='safe staging' and attrs.RiverfrontSpawnRecovery==false)
        ''')


if __name__ == '__main__':
    unittest.main()
