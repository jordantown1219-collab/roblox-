"""Injected-store actual-module tests; no live DataStore or engine claims."""
from pathlib import Path
import os
import sys
import unittest

sys.path.insert(0, str(Path(os.environ['TEMP']) / 'smallsignals-test-deps'))
from lupa import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]


class LobbyPreferences(unittest.TestCase):
    def setUp(self):
        self.lua=LuaRuntime()
        self.lua.globals().Module=self.lua.execute((ROOT/'src/LobbyPreferences.lua').read_text())
        self.lua.execute('''
        reads=0 writes=0 data=nil
        store={GetAsync=function(_,key) assert(key=='u_42') reads=reads+1 return data end,
         UpdateAsync=function(_,key,fn) assert(key=='u_42') writes=writes+1 data=fn(data) return data end}
        prefs=Module.new(store)
        ''')

    def test_default_cache_has_no_write_and_output_is_copied(self):
        self.lua.execute('''
        local p,s=prefs:load(42) assert(s=='default' and p.mode=='Extraction' and p.teamSize==3)
        p.teamSize=5 assert(prefs:get(42).teamSize==3)
        prefs:load(42) assert(reads==1)
        local ok,status=prefs:save(42) assert(ok and status=='unchanged' and writes==0)
        assert(prefs:forget(42))
        ''')

    def test_valid_load_set_save_and_no_repeated_unchanged_writes(self):
        self.lua.execute('''
        data={version=1,mode='Extraction',teamSize=5}
        assert(prefs:load(42).teamSize==5)
        local input={mode='Extraction',teamSize=4} assert(prefs:set(42,input)) input.teamSize=3
        assert(prefs:get(42).teamSize==4 and writes==0)
        assert(prefs:save(42) and data.teamSize==4 and data.version==1)
        prefs:set(42,{mode='Extraction',teamSize=4}) prefs:save(42) assert(writes==1)
        assert(prefs:forget(42))
        ''')

    def test_invalid_entire_payload_rejected_without_mutation(self):
        self.lua.execute('''
        local values={{mode='Deathmatch',teamSize=3},{mode='Extraction',teamSize=6},
          {mode='Extraction',teamSize=3,admin=true},{mode='Extraction',teamSize={3}},
          {mode='Extraction'},{teamSize=3},setmetatable({mode='Extraction',teamSize=3},{})}
        for _,v in ipairs(values) do assert(not prefs:set(42,v)) end
        assert(not prefs:set(42,'bad')) assert(not prefs:set(42,nil))
        assert(prefs:get(42).teamSize==3 and writes==0)
        for _,id in ipairs({0,-1.5,1.5,math.huge,0/0,'42'}) do
          assert(not pcall(function() prefs:get(id) end))
        end
        ''')

    def test_late_load_never_overwrites_explicit_choice(self):
        self.lua.execute('''
        store.GetAsync=function() reads=reads+1 return coroutine.yield('loading') end
        local c=coroutine.create(function() prefs:load(42) end)
        assert(coroutine.resume(c))
        local value,status=prefs:load(42) assert(status=='loading' and reads==1)
        prefs:set(42,{mode='Extraction',teamSize=3})
        assert(coroutine.resume(c,{version=1,mode='Extraction',teamSize=5}))
        assert(prefs:get(42).teamSize==3)
        assert(prefs:save(42) and data.teamSize==3)
        ''')

    def test_save_failure_keeps_dirty_choice_for_explicit_retry(self):
        self.lua.execute('''
        prefs:set(42,{mode='Extraction',teamSize=5})
        local working=store.UpdateAsync
        store.UpdateAsync=function() writes=writes+1 error('unavailable') end
        local ok,status=prefs:save(42) assert(not ok and status=='saveFailed')
        assert(not prefs:forget(42) and prefs:get(42).teamSize==5 and writes==1)
        store.UpdateAsync=working assert(prefs:save(42) and writes==2 and data.teamSize==5)
        assert(prefs:forget(42))
        ''')

    def test_wrong_version_and_unrelated_stored_keys_are_preserved(self):
        self.lua.execute('''
        for _,bad in ipairs({{version=2,mode='Extraction',teamSize=5},
            {version=1,mode='Extraction',teamSize=5,coins=900}}) do
          prefs=Module.new(store) data=bad
          local v,s=prefs:load(42) assert(s=='invalidData' and v.teamSize==3)
          prefs:set(42,{mode='Extraction',teamSize=4})
          local before=data
          store.UpdateAsync=function(_,key,fn) writes=writes+1 local result=fn(data) if result then data=result end return result end
          local ok,status=prefs:save(42) assert(not ok and status=='saveRefused' and data==before)
          assert(not prefs:forget(42))
        end
        ''')

    def test_new_choice_during_save_survives_and_concurrent_save_is_guarded(self):
        self.lua.execute('''
        prefs:set(42,{mode='Extraction',teamSize=4})
        store.UpdateAsync=function(_,key,fn) writes=writes+1 local value=fn(nil) coroutine.yield() return value end
        local c=coroutine.create(function() assert(prefs:save(42)) end)
        assert(coroutine.resume(c))
        local ok,status=prefs:save(42) assert(not ok and status=='saving' and writes==1)
        prefs:set(42,{mode='Extraction',teamSize=5}) assert(coroutine.resume(c))
        assert(prefs:get(42).teamSize==5 and not prefs:forget(42))
        store.UpdateAsync=function(_,key,fn) writes=writes+1 data=fn(nil) return data end
        assert(prefs:save(42) and data.teamSize==5 and writes==2)
        ''')

    def test_unavailable_store_does_not_crash_or_discard_choice(self):
        self.lua.execute('''
        prefs=Module.new(nil)
        local v,s=prefs:load(42) assert(s=='loadFailed' and v.teamSize==3)
        prefs:set(42,{mode='Extraction',teamSize=5})
        local ok,status=prefs:save(42) assert(not ok and status=='saveFailed')
        assert(prefs:get(42).teamSize==5 and not prefs:forget(42))
        ''')

    def test_explicit_default_after_load_failure_can_replace_valid_old_preference(self):
        self.lua.execute('''
        data={version=1,mode='Extraction',teamSize=5}
        store.GetAsync=function() error('temporary read failure') end
        prefs:load(42)
        prefs:set(42,{mode='Extraction',teamSize=3})
        assert(prefs:save(42) and writes==1 and data.teamSize==3)
        ''')

    def test_negative_studio_user_ids_are_safe_and_isolated(self):
        self.lua.execute('''
        local keys={}
        local studioStore={GetAsync=function(_,key) keys[#keys+1]=key return nil end,
          UpdateAsync=function(_,key,fn) keys[#keys+1]=key return fn(nil) end}
        local studio=Module.new(studioStore)
        assert(studio:get(-1).teamSize==3)
        assert(studio:load(-1).teamSize==3)
        studio:set(-1,{mode='Extraction',teamSize=5}) assert(studio:save(-1))
        assert(keys[1]=='u_-1' and keys[2]=='u_-1')
        assert(studio:get(-2).teamSize==3 and studio:get(-1).teamSize==5)
        ''')


if __name__=='__main__': unittest.main()
