"""Compile the standalone file, then run mocked Roblox role and lifecycle checks.

Set LUAU_BIN and LUAU_COMPILE_BIN if the standalone Luau tools are not on PATH.
This cannot verify the live game's data schema or reproduce Roblox rendering.
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
luau = os.environ.get("LUAU_BIN") or shutil.which("luau")
compiler = os.environ.get("LUAU_COMPILE_BIN") or shutil.which("luau-compile")
if not luau or not compiler:
    raise SystemExit("Install Luau or set LUAU_BIN and LUAU_COMPILE_BIN.")
source = root / "games" / "superhero-arena.lua"
subprocess.run([compiler, "--null", str(source)], check=True)
fixture = (root / "tests" / "superhero_checks.luau").read_text()
fixture = fixture.replace("-- INSERT STANDALONE HUB", source.read_text())
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / "checks.luau"
    path.write_text(fixture)
    subprocess.run([luau, str(path)], check=True)
