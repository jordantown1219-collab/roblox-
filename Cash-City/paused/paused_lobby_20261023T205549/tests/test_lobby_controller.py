from pathlib import Path
import os
import sys
import unittest

sys.path.insert(0, str(Path(os.environ['TEMP']) / 'smallsignals-test-deps'))
from lupa import LuaRuntime
ROOT = Path(__file__).resolve().parents[1]


class LobbyControllerTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.globals().Controller = self.lua.execute((ROOT / 'src/LobbyController.lua').read_text())
        self.lua.execute('''
        config={teamSizes={3,4,5},waitSeconds=90,voteSeconds=12,
         maps={{id='Detroit',label='Detroit',size='Large',recommendedTeamSize=3,available=true},
               {id='Alpha',label='Alpha',size='Small',recommendedTeamSize=3,available=true},
               {id='Future',label='Future',size='Large',available=false}},
         modes={{id='Extraction',label='Extraction',available=true},{id='Future',available=false}}}
        c=Controller.new(config)
        function join(id,size,time) assert(c:join(id,'Extraction',size or 3,time or 0)) end
        ''')

    def test_full_rosters_sorted_and_selection_exactly_once(self):
        self.lua.execute('''
        for _,size in ipairs({3,4,5}) do
         c=Controller.new(config)
         for i=size*2+1,1,-1 do join(i,size,0) end
         assert(c:tick(0)==nil)
         local s=c:snapshot(1,0) assert(s.phase=='MapVote' and s.deadline==12)
         assert(not c:voteMap(size*2+1,'Detroit',s.epoch,0))
         assert(c:voteMap(1,'Detroit',s.epoch,0))
         assert(c:tick(11.999)==nil)
         local pick=c:tick(12) assert(#pick.players==size*2 and pick.teamSize==size and pick.requestedTeamSize==size)
         for i,id in ipairs(pick.players) do assert(id==i) end
         assert(pick.mode=='Extraction' and pick.mapId=='Detroit')
         assert(c:tick(12)==nil and c:snapshot(size*2+1,12).ready)
         assert(not c:snapshot(1,12).ready)
        end
        ''')

    def test_wait_boundary_strict_majority_and_unpaired_highest_remains(self):
        self.lua.execute('''
        for i=1,5 do join(i) end
        local epoch=c:snapshot(1,0).epoch
        assert(not c:voteStart(1,epoch,89.999))
        assert(c:voteStart(1,epoch,90)) assert(c:voteStart(2,epoch,90))
        assert(c:tick(90)==nil and c:snapshot(1,90).phase=='Queue')
        assert(c:voteStart(3,epoch,90)) assert(c:tick(90)==nil)
        local s=c:snapshot(1,90) assert(s.phase=='MapVote')
        assert(not c:voteMap(5,'Alpha',s.epoch,90))
        local result=c:tick(102) assert(result.teamSize==2 and result.requestedTeamSize==3)
        assert(#result.players==4 and c:snapshot(5,102).ready)
        ''')

    def test_replacement_stale_nonmembers_unavailable_and_deterministic_tie(self):
        self.lua.execute('''
        for i=1,6 do join(i) end
        local queueEpoch=c:snapshot(1,0).epoch c:tick(0)
        local e=c:snapshot(1,0).epoch assert(e~=queueEpoch)
        assert(not c:voteMap(1,'Detroit',queueEpoch,0))
        assert(not c:voteMap(99,'Detroit',e,0))
        assert(not c:voteMap(1,'Future',e,0))
        assert(c:voteMap(1,'Detroit',e,0)) assert(c:voteMap(1,'Alpha',e,0))
        assert(c:snapshot(1,0).mapVotes.Detroit==0 and c:snapshot(1,0).mapVotes.Alpha==1)
        assert(c:voteMap(2,'Detroit',e,0))
        assert(c:tick(12).mapId=='Alpha')
        assert(not c:voteMap(1,'Alpha',e,12))
        ''')

    def test_leave_rebalances_reserved_and_cancels_insufficient_vote(self):
        self.lua.execute('''
        for i=1,6 do join(i) end c:tick(0)
        local e=c:snapshot(1,0).epoch assert(c:voteMap(6,'Detroit',e,0))
        c:leave(1)
        assert(c:snapshot(6,0).ready and not c:voteMap(6,'Detroit',e,0))
        assert(c:snapshot(2,0).mapVotes.Detroit==0)
        local p=c:tick(12) assert(#p.players==4 and p.players[1]==2 and p.players[4]==5)
        c=Controller.new(config) join(1) join(2)
        local q=c:snapshot(1,90).epoch assert(c:voteStart(1,q,90) and c:voteStart(2,q,90))
        c:tick(90) local old=c:snapshot(1,90).epoch c:leave(1)
        assert(c:snapshot(2,90).phase=='Queue' and c:snapshot(2,90).ready)
        assert(c:snapshot(2,90).epoch~=old and not c:voteMap(2,'Alpha',old,90))
        ''')

    def test_invalid_inputs_and_snapshot_config_isolation(self):
        self.lua.execute('''
        assert(not c:join(0,'Extraction',3,0))
        assert(not c:join(1,'Future',3,0)) assert(not c:join(1,'Extraction',2,0))
        assert(not c:join(1,'Extraction',3,0/0)) assert(not c:join(1,'Extraction',3,-1))
        assert(not c:voteStart(1,1,math.huge)) assert(c:tick(0/0)==nil)
        config.maps[1].available=false config.teamSizes[1]=99
        join(1) local s=c:snapshot(1,0) assert(s.ready)
        s.maps[1].available=false s.queues[3]=999
        assert(c:snapshot(1,0).queues[3]==1)
        assert(not c:join(1,'Extraction',3,0))
        c:leave(1) assert(not c:snapshot(1,0).ready)
        ''')

    def test_studio_negative_ids_leaves_and_waited_vote_time(self):
        self.lua.execute('''
        for id=-6,-1 do join(id) end c:tick(0)
        local epoch=c:snapshot(-1,0).epoch
        assert(c:voteMap(-6,'Detroit',epoch,0))
        local selection=c:tick(12)
        assert(selection.players[1]==-6 and selection.players[6]==-1)
        c=Controller.new(config) join(1) join(2) join(3)
        local e=c:snapshot(1,90).epoch assert(c:voteStart(1,e,90))
        c:leave(1) assert(c:snapshot(2,90).startVotes==0)
        assert(c:voteStart(2,e,90)) assert(c:tick(90)==nil and c:snapshot(2,90).phase=='Queue')
        assert(c:voteStart(3,e,90)) c:tick(90)
        local v=c:snapshot(2,90).epoch
        assert(not c:voteMap(2,'Alpha',v,89))
        assert(c:voteMap(2,'Alpha',v,90))
        assert(not c:voteMap(2,'Detroit',v,102))
        assert(c:tick(102).teamSize==1)
        ''')


if __name__ == '__main__':
    unittest.main()
