-- Standalone Spider-Man entry; never run by main hub startup.
local source=game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-spiderman/main/main.lua?cb="..tostring(os.time()))
local header="-- RiftHub-Entry: spiderman-character"
assert(type(source)=="string" and source:sub(1,#header)==header,"Wrong Spider-Man script response")
local chunk,err=loadstring(source,"=RiftHubSpiderMan/main.lua")
assert(chunk,err)
local app=chunk()
assert(type(app)=="table" and app.Game=="Spider-Man" and app.Gui and app.Gui.Parent,"Spider-Man did not finish opening")
return app
