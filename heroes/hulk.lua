-- The complete Hulk controller is maintained in its own repository.
local source=game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Hulk/main/main.lua")
local chunk,err=loadstring(source,"=RiftHubHulk/main.lua")
assert(chunk,err)
return chunk()
