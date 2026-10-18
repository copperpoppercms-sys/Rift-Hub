"""Exercise asynchronous logo delivery and fallbacks using the actual Brand module."""
from pathlib import Path
import os,shutil,subprocess,tempfile
root=Path(__file__).resolve().parents[1]
luau=os.environ.get('LUAU_BIN') or shutil.which('luau')
if not luau: raise SystemExit('Set LUAU_BIN to the native Luau executable.')
fixture=(root/'tests/brand_checks.luau').read_text().replace('-- INSERT BRAND',(root/'src/ui/Brand.lua').read_text())
with tempfile.NamedTemporaryFile(mode='w',suffix='.luau') as f:
    f.write(fixture); f.flush(); subprocess.run([luau,f.name],check=True)
