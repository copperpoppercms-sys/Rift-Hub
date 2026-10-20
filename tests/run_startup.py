from pathlib import Path
import os,subprocess,tempfile
root=Path(__file__).resolve().parents[1]
luau=os.environ['LUAU_BIN']
compiler=os.environ['LUAU_COMPILE_BIN']
for path in ['main.lua','execute.lua','heroes/hulk.lua','src/ui/GameLibrary.lua','src/ui/Hub.lua']:
 subprocess.run([compiler,'--null',str(root/path)],check=True,capture_output=True)
source=(root/'tests/startup.luau').read_text().replace('-- ENTRY',(root/'main.lua').read_text()).replace('-- LOADER',(root/'execute.lua').read_text())
with tempfile.NamedTemporaryFile(mode='w',suffix='.luau') as f:
 f.write(source);f.flush();subprocess.run([luau,f.name],check=True)
assert (root/'execute.lua').read_text().find('Rift-Hub/main/main.lua?cb=')>=0
assert 'RiftHub-Entry: universal' in (root/'execute.lua').read_text()
assert 'local INTRO_ENABLED = false' in (root/'main.lua').read_text()
