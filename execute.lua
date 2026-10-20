-- Opens the main Rift Hub UI. Character scripts run only from their card buttons.
local source=game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub/main/main.lua?cb="..tostring(os.time()).."-"..tostring(math.floor(os.clock()*1000)))
local header="-- RiftHub-Entry: universal"
assert(type(source)=="string" and source:sub(1,#header)==header,"Wrong main script response; reopen Rift and retry")
local chunk,err=loadstring(source,"=RiftHub/main.lua")
assert(chunk,err)
local app=chunk()
assert(type(app)=="table" and app.Game=="Rift Hub" and app.Hub and app.Hub.Gui and app.Hub.Gui.Parent,"Main Rift UI did not open; see console")
return app
