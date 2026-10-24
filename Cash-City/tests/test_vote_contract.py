"""Execute existing server matchmaking/vote functions with isolated engine stubs."""
from pathlib import Path
import os
import sys
import unittest

sys.path.insert(0, str(Path(os.environ['TEMP']) / 'smallsignals-test-deps'))
from lupa import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'src/SmallSignalsServer.server.lua').read_text(encoding='utf-8')
FUNCTIONS = SOURCE[SOURCE.index('local function begin(selected, solo)'):SOURCE.index('\nwhile true do')]


class VoteContract(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime()
        self.lua.globals().C = self.lua.execute((ROOT / 'src/Config.lua').read_text(encoding='utf-8-sig'))
        self.lua.execute('''
        roundId=0 members={} votes={} reservations={} queue={} armorPickups={}
        function now() return 100 end
        function broadcast() end
        function clearArmorPickup() error('unexpected pickup') end
        function spawn() end
        function equip() end
        Teams={FindFirstChild=function(_,name) return name end}
        Arena={routes=function() end}
        task={spawn=function() end}
        function player(id,weapon)
            return {UserId=id,GetAttribute=function(_,key) if key=='WeaponChoice' then return weapon or 'Rifle' end end}
        end
        ''' + FUNCTIONS + '''
        beginRound=begin chooseCarriers=startMatch
        ''')

    def test_queue_membership_is_balanced_and_selected_queue_entries_removed(self):
        self.lua.execute('''
        local selected={}
        local waiting=player(999) queue[waiting]=5
        for i=1,10 do selected[i]=player(i) queue[selected[i]]=5 end
        beginRound(selected,false)
        assert(phase=='Vote' and deadline==112 and roundId==1 and not practice)
        local counts={Amber=0,Cyan=0}
        for _,p in ipairs(selected) do
            local m=members[p] counts[m.team]=counts[m.team]+1
            assert(queue[p]==nil and m.stage==0 and not m.carrier and not m.extracted)
        end
        assert(counts.Amber==5 and counts.Cyan==5 and queue[waiting]==5)
        ''')

    def test_no_vote_ties_choose_lowest_user_id_per_team(self):
        self.lua.execute('''
        local a,b,c,d=player(40),player(30),player(20,'SMG'),player(10)
        beginRound({a,b,c,d},false) chooseCarriers()
        assert(phase=='Match' and deadline==580)
        assert(not members[a].carrier and not members[b].carrier)
        assert(members[c].carrier and members[d].carrier)
        assert(members[c].weapon=='SMG' and members[c].ammo==C.Weapons.SMG.Magazine)
        assert(members[d].ammo==C.Weapons.Rifle.Magazine)
        ''')

    def test_only_member_votes_from_same_team_count(self):
        self.lua.execute('''
        local a,b,c,d=player(40),player(30),player(20),player(10)
        beginRound({a,b,c,d},false)
        votes[c]=a -- one valid Amber vote beats zero for lower-ID c
        votes[a]=d -- forged opposite-team vote must not affect Cyan result
        votes[player(1)]=b -- nonmember vote must not count
        chooseCarriers()
        assert(members[a].carrier and not members[c].carrier)
        assert(members[d].carrier and not members[b].carrier)
        ''')


if __name__ == '__main__':
    unittest.main()
