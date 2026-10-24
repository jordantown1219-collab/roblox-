"""Current balance contracts, not multiplayer/physics acceptance."""
from pathlib import Path
import os
import sys
import unittest

sys.path.insert(0, str(Path(os.environ['TEMP']) / 'smallsignals-test-deps'))
from lupa import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class TeamRules(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.globals().R = self.lua.execute((ROOT / 'src/Rules.lua').read_text(encoding='utf-8-sig'))
        self.lua.globals().C = self.lua.execute((ROOT / 'src/Config.lua').read_text(encoding='utf-8-sig'))

    def test_stage_tuning_and_all_weapon_damage(self):
        self.lua.execute('''
        assert(C.Stages==3 and #C.Scales==4)
        local scales={1,.65,.40,.22}
        local health={100,80,60,40}
        local strength={1,.8,.6,.4}
        local armor={60,48,36,24}
        local expected={Rifle={28,22,17,11},SMG={16,13,10,6},Knife={40,32,24,16}}
        for i=1,4 do
            assert(C.Scales[i]==scales[i] and C.Health[i]==health[i])
            assert(C.Strength[i]==strength[i] and C.Armor[i]==armor[i])
            for name,w in pairs(C.Weapons) do assert(R.damage(w.Damage,C.Strength[i])==expected[name][i]) end
        end
        -- Strength is deliberately not the avatar scale in the current balance.
        assert(C.Strength[4]~=C.Scales[4])
        ''')

    def test_launch_map_mode_and_minimum_team_size(self):
        self.lua.execute('''
        assert(C.ActiveMap=='DetroitRiverfront' and C.GameMode=='Extraction')
        assert(#C.TeamSizes==3 and C.TeamSizes[1]==3 and C.TeamSizes[2]==4 and C.TeamSizes[3]==5)
        ''')

    def test_gate_sequence_and_team_phase_guards(self):
        self.lua.execute('''
        for stage=0,C.Stages-1 do
            for door=1,C.Stages do
                assert(R.canEnter(stage,door,'Amber','Amber',false,'Match')==(door==stage+1))
                assert(not R.canEnter(stage,door,'Amber','Cyan',false,'Match'))
                assert(not R.canEnter(stage,door,'Amber','Amber',true,'Match'))
                for _,phase in ipairs({'Lobby','Vote','Results'}) do
                    assert(not R.canEnter(stage,door,'Amber','Amber',false,phase))
                end
            end
        end
        ''')

    def test_every_required_teammate_must_finish(self):
        self.lua.execute('''
        local function done() return {required=true,connected=true,stage=C.Stages,extracted=true,downed=false} end
        assert(not R.allFinished({},C.Stages))
        for _,size in ipairs(C.TeamSizes) do
            local roster={} for i=1,size do roster[i]=done() end
            assert(R.allFinished(roster,C.Stages))
            for i=1,size do
                for _,field in ipairs({'connected','extracted'}) do
                    roster[i][field]=false assert(not R.allFinished(roster,C.Stages)) roster[i]=done()
                end
                roster[i].downed=true assert(not R.allFinished(roster,C.Stages)) roster[i]=done()
                for stage=0,C.Stages-1 do
                    roster[i].stage=stage assert(not R.allFinished(roster,C.Stages))
                end
                roster[i]=done()
            end
        end
        ''')

    def test_disconnect_grace_blocks_until_member_no_longer_required(self):
        self.lua.execute('''
        local roster={{required=true,connected=true,stage=3,extracted=true},
                      {required=true,connected=false}}
        assert(not R.allFinished(roster,C.Stages))
        roster[2].required=false assert(R.allFinished(roster,C.Stages))
        roster[1].required=false assert(not R.allFinished(roster,C.Stages))
        assert(C.RejoinWindow==45)
        ''')

    def test_damage_conservation_through_stage_armor(self):
        self.lua.execute('''
        for i=1,4 do
            for _,w in pairs(C.Weapons) do
                local amount=R.damage(w.Damage,C.Strength[i])
                for _,armor in ipairs({0,5,C.Armor[i]}) do
                    local remaining,hp=R.absorbDamage(armor,amount)
                    assert(remaining>=0 and hp>=0)
                    assert((armor-remaining)+hp==amount)
                end
            end
        end
        ''')

    def test_armor_assignment_and_size_are_independent_of_team_completion(self):
        self.lua.execute('''
        for stage=0,C.Stages do
            assert(R.canTakeArmor(1,'Amber',stage,1,'Amber',stage,true))
            assert(not R.canTakeArmor(2,'Amber',stage,1,'Amber',stage,true))
            assert(R.canTakeArmor(3,'Cyan',stage,1,'Amber',stage,true))
            assert(not R.canTakeArmor(3,'Cyan',(stage+1)%4,1,'Amber',stage,true))
            assert(not R.canTakeArmor(1,'Amber',stage,1,'Amber',stage,false))
        end
        ''')


if __name__ == '__main__':
    unittest.main()
