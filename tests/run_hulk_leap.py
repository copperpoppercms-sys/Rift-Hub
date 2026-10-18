"""Native input/lifecycle fixtures; Roblox physics and asset permissions require live testing."""
from pathlib import Path
import os,shutil,subprocess,tempfile
root=Path(__file__).resolve().parents[1]
luau=os.environ.get('LUAU_BIN') or shutil.which('luau')
assert luau,'Set LUAU_BIN'
source=(root/'tests/hulk_leap.luau').read_text().replace('-- HULK LEAP',(root/'src/features/HulkLeap.lua').read_text())
with tempfile.NamedTemporaryFile(mode='w',suffix='.luau') as file:
    file.write(source);file.flush();subprocess.run([luau,file.name],check=True)
