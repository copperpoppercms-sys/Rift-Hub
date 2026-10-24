-- Main-entry orchestration fixture: fake modules, real startup/reload/error flow.
local env, modules, requests, compiled={}, {}, {}, {}
local warn=function() end
local getgenv=function() return env end
local task={wait=function() end,spawn=function(fn) fn() end}
local Enum={KeyCode={RightShift="RightShift"}}
local opened,unloaded,characterStops,featureStops,launches=0,0,0,0,0
local badPath,badSource,throwFeature,fetchHook
local featureCalls=0
local function feature()
 featureCalls+=1
 if throwFeature and featureCalls==2 then error("simulated feature constructor failure") end
 return {Stop=function() featureStops+=1 end}
end
modules['src/core/Utils.lua']={}
modules['src/core/Config.lua']={}
modules['src/ui/Kit.lua']={}
modules['src/ui/GameLibrary.lua']=function() launches+=1;error("startup should not execute a character") end
modules['src/ui/Hub.lua']=function(opts)
 opened+=1
 assert(type(opts.GameLibrary)=="function" and opts.ToggleKey=="RightShift")
 local hub={Game="Rift Hub",Gui={Name="RiftHub",Parent=true}}
 local disposed=false
 function hub.Unload()
  if disposed then return end;disposed=true;unloaded+=1;hub.Gui.Parent=nil
  for _,f in pairs(opts.Features) do if f.Stop then f.Stop() end end
 end
 hub.Restart=opts.OnRestart
 return hub
end
for _,name in ipairs({'AimAssist','ESP','Fly','AntiAFK','Movement','Triggerbot','Chams','Fullbright','Freecam','CameraTools','Waypoints','ServerTools'}) do modules['src/features/'..name..'.lua']=feature end
local game={}
function game:HttpGet(url)
 table.insert(requests,url)
 assert(url:find('https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub/main/',1,true)==1,"startup requested an unrelated repo")
 local path=url:match('/main/(.-)%?cb=')
 assert(path and path:find('src/',1,true)==1,"startup fetched a character")
 if fetchHook then local hook=fetchHook;fetchHook=nil;hook() end
 if path==badPath then return badSource end
 if path=='src/ui/Hub.lua' then return '-- RiftHub-Module: main-ui\n'..path end
 if path=='src/ui/GameLibrary.lua' then return '-- RiftHub-Module: game-library\n'..path end
 return path
end
local loadstring=function(source,name)
 local path=name:match('^=RiftHub/(.*)$')
 table.insert(compiled,path)
 return function() return modules[path] end
end
local function run()
 return (function()
-- ENTRY
 end)()
end
env.__RiftHubLoaded=true
env.RiftHulkCharacter={Unload=function() characterStops+=1;env.RiftHulkCharacter=nil end}
local app=run()
assert(app and app.Game=='Rift Hub' and app.Version=='2.5.0' and app.Hub.Gui.Parent)
assert(opened==1 and characterStops==1 and launches==0 and env.__RiftHubLoaded,"stale loaded flag blocked main UI")
local first=app
app=run()
assert(opened==2 and unloaded==1 and not first.Hub.Gui.Parent and app~=first,"rerun did not replace the main UI")
assert(launches==0,"startup ran the game/character loader")
-- Constructor failure clears the loaded flag and permits another attempt.
throwFeature=true;featureCalls=0
local previousStops=featureStops
assert(run()==nil and not env.__RiftHubLoaded and env.Rift==nil)
assert(featureStops>previousStops,"partial feature constructor was not cleaned up")
throwFeature=false
assert(run() and env.__RiftHubLoaded,"failed startup prevented retry")
-- UI mismatch is refused before its body can run.
badPath,badSource='src/ui/Hub.lua','unrelated Spider-Man source'
local before=#compiled
assert(run()==nil and not env.__RiftHubLoaded)
for i=before+1,#compiled do assert(compiled[i]~='src/ui/Hub.lua',"mismatched UI was compiled") end
badPath,badSource=nil,nil
assert(run() and launches==0)
-- If a newer execution finishes while an older fetch yields, the old startup cannot clear it.
fetchHook=function() assert(run()) end
local interrupted=run()
assert((interrupted==nil or interrupted==env.Rift) and env.Rift and env.Rift.Hub.Gui.Parent and env.__RiftHubLoaded,"older startup erased the newer main UI")
assert(launches==0 and characterStops==1)
print('PASS: main startup opens only Rift UI; stale flag, rerun, failure recovery, wrong UI source and superseded startup checks.')

-- The phone execution snippet rejects an unrelated HTTP response before compilation.
local loaderCompiles=0
local priorLoadstring=loadstring
loadstring=function(source,name)
 if name=="=RiftHub/main.lua" then loaderCompiles+=1;return function() return run() end end
 return priorLoadstring(source,name)
end
local mainResponse="unrelated Spider-Man source"
local priorHttpGet=game.HttpGet
function game:HttpGet(url)
 if url:find("Rift-Hub/main/main.lua?cb=",1,true) then return mainResponse end
 return priorHttpGet(self,url)
end
local function runLoader()
 return (function()
-- LOADER
 end)()
end
assert(not pcall(runLoader) and loaderCompiles==0,"main loader compiled a mismatched script")
mainResponse="-- RiftHub-Entry: universal\nmain fixture"
local loaded=runLoader()
assert(loaded==env.Rift and loaded.Game=="Rift Hub" and loaderCompiles==1 and launches==0)
print("PASS: main execution snippet rejects wrong source before execution and returns the main Rift UI.")
