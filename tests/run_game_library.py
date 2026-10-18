"""Compile the game launcher and test handoff to the separate MM2 repository.
Requires the standalone Luau CLI on PATH (or LUAU_BIN/LUAU_COMPILE_BIN).
The supplied MM2's game-specific features need testing inside Roblox/MM2.
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
luau = os.environ.get('LUAU_BIN') or shutil.which('luau')
compiler = os.environ.get('LUAU_COMPILE_BIN') or shutil.which('luau-compile')
if not luau or not compiler:
    raise SystemExit('Install Luau or set LUAU_BIN and LUAU_COMPILE_BIN.')
hub = (root / 'src/ui/Hub.lua').read_text()
assert 'label = "Hub", icon = "hub"' in hub
assert 'Size = UDim2.fromOffset(320, 144)' in hub
assert 'Size = UDim2.fromOffset(40, 40)' in hub
assert 'CellSize = UDim2.fromOffset(320, 144)' in hub and 'FillDirectionMaxCells = 2' in hub
assert 'Text = item.Handoff' in hub
with tempfile.TemporaryDirectory() as directory:
    directory = Path(directory)
    for file in [root/'games/mm2.lua', root/'games/survive-the-hulk.lua', root/'src/ui/Hub.lua', root/'src/ui/Kit.lua', root/'src/ui/GameLibrary.lua', root/'main.lua']:
        result = subprocess.run([compiler, '--null', str(file)], text=True, capture_output=True)
        if result.returncode:
            raise SystemExit(result.stdout + result.stderr)
    script = directory / 'library_checks.luau'
    fixture = (root/'tests/game_library.luau').read_text().replace('-- LIBRARY', (root/'src/ui/GameLibrary.lua').read_text()).replace('-- KIT', (root/'src/ui/Kit.lua').read_text())
    script.write_text(fixture)
    subprocess.run([luau, str(script)], check=True)
print('PASS: main Hub launcher and legacy forwarding loader compilation; compact card defaults.')
