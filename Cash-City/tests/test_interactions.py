from pathlib import Path
import sys,os
sys.path.insert(0,str(Path(os.environ['TEMP'])/'smallsignals-test-deps'))
from lupa import LuaRuntime
p=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
rules=lua.execute((p/'src/InteractionRules.lua').read_text(encoding='utf-8-sig'))
lua.execute((p/'tests/InteractionRules.spec.lua').read_text(encoding='utf-8-sig'))(rules)
