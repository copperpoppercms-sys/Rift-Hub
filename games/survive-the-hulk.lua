-- Compatibility loader: the current script is maintained in its separate repository.
local url = "https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Survive-The-Hulk/main/main.lua"
local source = game:HttpGet(url .. "?cb=" .. tostring(os.time()))
local chunk, err = loadstring(source, "=RiftHubSurviveTheHulk/main.lua")
if not chunk then error(err, 0) end
return chunk()
