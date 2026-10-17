"""Run the feature lifecycle fixture with the standalone Luau CLI.
Install Luau and put luau / luau-compile on PATH, then: python tests/run_features.py
These mocks test lifecycle and controls; they cannot simulate Roblox physics/server rules.
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
for file in [root / 'main.lua', *sorted((root / 'src').rglob('*.lua'))]:
    compiled = subprocess.run([compiler, '--null', str(file)], text=True, capture_output=True)
    if compiled.returncode:
        raise SystemExit(compiled.stdout + compiled.stderr)
modules = []
for name in ['Fly', 'Movement', 'CameraTools', 'Waypoints', 'ServerTools', 'Fullbright']:
    source = (root / 'src/features' / (name + '.lua')).read_text()
    modules.append(f'local {name}Ctor = (function()\n{source}\nend)()')
hub = (root / 'src/ui/Hub.lua').read_text()
start = hub.index('local function buildMovement(')
end = hub.index('local function buildPlayers(', start)
modules.append(hub[start:end])
fixture = (root / 'tests/feature_lifecycle.luau').read_text().replace('-- MODULES', '\n'.join(modules))
with tempfile.TemporaryDirectory() as directory:
    script = Path(directory) / 'feature_lifecycle.luau'
    script.write_text(fixture)
    subprocess.run([luau, str(script)], check=True)
