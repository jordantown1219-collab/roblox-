from pathlib import Path
import sys,os
P=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(Path(os.environ['TEMP'])/'smallsignals-test-deps'))
from lupa import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
rules=lua.execute((P/'src/Rules.lua').read_text(encoding='utf-8-sig'))
lua.execute((P/'tests/Rules.spec.lua').read_text(encoding='utf-8-sig'))(rules)
s=(P/'src/SmallSignalsClient.client.lua').read_text(encoding='utf-8')
a=s.index('local function refreshPanels()');b=s.index('local function closeButton',a)
lua.execute('''
player={Neutral=true} workspace={GetServerTimeNow=function() return 100 end}
menu={} vote={} reopen={} snapshot={phase="Lobby",ready=true,teamSize=3,queueCount=2}
lobbyClosed=false voteClosed=false
'''+s[a:b]+'''
refreshPanels() assert(menu.Visible and not reopen.Visible)
lobbyClosed=true refreshPanels() assert(not menu.Visible and reopen.Visible and reopen.Text=="WAITING • 2/6")
snapshot.queueCount=3 refreshPanels() assert(not menu.Visible and reopen.Text=="WAITING • 3/6")
lobbyClosed=false refreshPanels() assert(menu.Visible and not reopen.Visible)
snapshot.phase="Vote" snapshot.deadline=112 player.Neutral=false refreshPanels() assert(vote.Visible and not menu.Visible)
voteClosed=true refreshPanels() assert(not vote.Visible and reopen.Visible and reopen.Text=="GEAR UP • 12s")
snapshot.phase="Match" refreshPanels() assert(not vote.Visible and not menu.Visible and not reopen.Visible)
''')
print('Existing lobby close/reopen, queue updates, vote and match visibility checks passed.')
