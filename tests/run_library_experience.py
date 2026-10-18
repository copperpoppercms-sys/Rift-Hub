"""Client fixtures only: native rendering and executor storage need live Roblox checks."""
from pathlib import Path
import os,subprocess,tempfile,shutil
root=Path(__file__).resolve().parents[1]
luau=os.environ.get('LUAU_BIN') or shutil.which('luau')
assert luau,'Set LUAU_BIN'
source=(root/'tests/library_experience.luau').read_text()
for marker,path in [('STATE','src/core/LibraryState.lua'),('VIEW','src/ui/LibraryView.lua'),('SEARCH','src/ui/QuickSearch.lua')]:
    source=source.replace('-- '+marker,(root/path).read_text())
hub=(root/'src/ui/Hub.lua').read_text()
start=hub.index('\tfunction ctx.FitWindow()')
end=hub.index('\n\tlocal lastViewport',start)
fit=hub[start:end]
source=source.replace('-- FIT',fit)
with tempfile.NamedTemporaryFile(mode='w',suffix='.luau') as file:
    file.write(source);file.flush();subprocess.run([luau,file.name],check=True)
