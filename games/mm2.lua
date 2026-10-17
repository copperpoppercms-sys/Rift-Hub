-- Compatibility loader: MM2 is maintained in the separate RiftHubMM2 repository.
local url = "https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-MM2/main/main.lua"
local source = game:HttpGet(url .. "?cb=" .. tostring(os.time()))
local chunk, err = loadstring(source, "=RiftHubMM2/main.lua")
if not chunk then error(err, 0) end
return chunk()
