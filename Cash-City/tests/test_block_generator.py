"""Actual generator validation via Lua; mocks cover pre-construction paths only."""
from pathlib import Path
import os
import sys
import unittest

sys.path.insert(0, str(Path(os.environ['TEMP']) / 'smallsignals-test-deps'))
from lupa import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class BlockPlanValidation(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime()
        self.lua.execute('''
        task={wait=function() error('unexpected construction/yield in validation test') end}
        function typeof(v) return type(v)=='table' and v.kind or type(v) end
        parent={kind='Instance',FindFirstChild=function() return nil end}
        Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
        CFrame={new=function() return {} end}
        ''')
        self.lua.globals().Generator = self.lua.execute((ROOT / 'src/CityBlockGenerator.lua').read_text())

    def test_invalid_batch_sizes_rejected(self):
        self.lua.execute('''for _,n in ipairs({0,-1,401,1.5,math.huge}) do
        local ok,err=pcall(Generator.build,parent,{id='Test',records={}},nil,n)
        assert(not ok and tostring(err):find('Batch size'),tostring(err)) end''')

    def test_invalid_ids_rejected(self):
        self.lua.execute('''for _,id in ipairs({'','../Landmark','Street A'}) do
        local ok,err=pcall(Generator.build,parent,{id=id,records={}})
        assert(not ok and tostring(err):find('Invalid block id'),tostring(err)) end''')

    def test_manual_content_rejected_without_destroy(self):
        self.lua.execute('''parent.FindFirstChild=function() return {
        GetAttribute=function() return false end,Destroy=function() error('manual content destroyed') end} end
        local ok,err=pcall(Generator.build,parent,{id='Manual',records={}})
        assert(not ok and tostring(err):find('manually built'),tostring(err))''')

    def test_invalid_geometry_releases_lock(self):
        self.lua.execute('''for attempt=1,2 do
        local ok,err=pcall(Generator.build,parent,{id='Retry',records={{pos={0,0,0},size={0,2,2}}}})
        assert(not ok and tostring(err):find('Invalid vector'),tostring(err)) end''')

    def test_sparse_plans_rejected_before_construction(self):
        self.lua.execute('''local record={pos={0,0,0},size={2,2,2}}
        for _,records in ipairs({{[1]=record,[3]=record},{[2]=record},{[1]=record,[2]=record,[4]=record,[100]=record}}) do
            local ok,err=pcall(Generator.build,parent,{id='Sparse',records=records})
            assert(not ok and tostring(err):find('gaps'),tostring(err))
        end''')

    def test_dictionary_and_mixed_keys_rejected_before_construction(self):
        self.lua.execute('''local record={pos={0,0,0},size={2,2,2}}
        for _,records in ipairs({{road=record},{record,extra=record},{[0]=record},{[-1]=record},{[1.5]=record},{['1']=record}}) do
            local ok,err=pcall(Generator.build,parent,{id='Keys',records=records})
            assert(not ok and tostring(err):find('dense ordered'),tostring(err))
        end''')


if __name__ == '__main__':
    unittest.main()
