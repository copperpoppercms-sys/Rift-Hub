from pathlib import Path
import os,shutil,subprocess,tempfile
r=Path(__file__).resolve().parents[1]
s=(r/'src/ui/Hub.lua').read_text()
a=s.index('local function buildHeroVillain');b=s.index('local function buildCombat',a)
fixture=(r/'tests/character_cards.luau').read_text().replace('-- HERO BUILDER',s[a:b])
with tempfile.NamedTemporaryFile(mode='w',suffix='.luau') as f:
 f.write(fixture);f.flush();subprocess.run([os.environ.get('LUAU_BIN') or shutil.which('luau') or '/workspace/luau-check/luau',f.name],check=True)
