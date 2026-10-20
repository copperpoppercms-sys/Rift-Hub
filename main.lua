-- RiftHub-Entry: universal
-- Luau | Roblox | Xeno/Synapse-class executor | RiftHub entrypoint
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub/main/main.lua"))()

local env = type(getgenv)=="function" and getgenv() or _G
-- Re-execution must reopen the main UI, even after a failed startup or character handoff.
local startupTicket={}
env.__RiftHubStartupTicket=startupTicket
local function currentStartup() return env.__RiftHubStartupTicket==startupTicket end
local previous=env.Rift
if type(previous)=="table" then
 if type(previous.Hub)=="table" and type(previous.Hub.Unload)=="function" then pcall(previous.Hub.Unload)
 elseif type(previous.Features)=="table" then
  for _,feature in pairs(previous.Features) do
   if type(feature)=="table" and type(feature.Stop)=="function" then pcall(feature.Stop) end
  end
 end
end
for _,key in ipairs({"RiftHulkCharacter","RiftHulkHub","SuperheroArenaHub"}) do
 local active=env[key]
 if type(active)=="table" and type(active.Unload)=="function" then pcall(active.Unload) end
end
if type(env.MONO_Unload)=="function" then pcall(env.MONO_Unload) end
if type(env.RiftMM2StartupCleanup)=="function" then pcall(env.RiftMM2StartupCleanup) end
env.__RiftHubLoaded=false
env.Rift=nil

local REPO_OWNER = "copperpoppercms-sys"
local REPO_NAME = "Rift-Hub"
local REPO_BRANCH = "main"
local RAW_BASE = string.format("https://raw.githubusercontent.com/%s/%s/%s/", REPO_OWNER, REPO_NAME, REPO_BRANCH)
-- Temporarily disabled. Intro.lua and every media asset are preserved; see docs/IntroRestore.md.
local INTRO_ENABLED = false

-- fetches a raw file from the repo, cache-busted, with one retry on transient HttpGet failure
local function fetchRaw(path)
	local url = RAW_BASE .. path .. "?cb=" .. tostring(os.time()) .. "-" .. tostring(math.floor(os.clock()*1000))
	local ok, body = pcall(game.HttpGet, game, url)
	if not ok then
		task.wait(0.5)
		ok, body = pcall(game.HttpGet, game, url)
	end
	if not ok then
		return nil, body
	end
	return body, nil
end

-- fetch + compile + run a module file, returning whatever it returns
local moduleHeaders={
 ["src/ui/Hub.lua"]="-- RiftHub-Module: main-ui",
 ["src/ui/GameLibrary.lua"]="-- RiftHub-Module: game-library",
}
local function loadModule(path)
	if not currentStartup() then return nil end
	local source, fetchErr = fetchRaw(path)
	if not source then
		warn(string.format("[RiftHub] could not fetch %s: %s", path, tostring(fetchErr)))
		return nil
	end

	if not currentStartup() then return nil end
	local header=moduleHeaders[path]
	if header and source:sub(1,#header)~=header then
		warn("[RiftHub] mismatched module refused: "..path);return nil
	end

	local chunk, compileErr = loadstring(source, "=RiftHub/" .. path)
	if not chunk then
		warn(string.format("[RiftHub] could not compile %s: %s", path, tostring(compileErr)))
		return nil
	end

	local ok, result = pcall(chunk)
	if not ok then
		warn(string.format("[RiftHub] error running %s: %s", path, tostring(result)))
		return nil
	end

	return result
end

local Rift = {Game="Rift Hub",Version="2.3.1"}
Rift.Utils = loadModule("src/core/Utils.lua")
Rift.Config = loadModule("src/core/Config.lua")

if type(Rift.Utils)~="table" or type(Rift.Config)~="table" then
	if currentStartup() then env.__RiftHubLoaded=false end
	warn("[RiftHub] core modules failed to load, aborting")
	return
end

-- runs once the intro finishes; opens the main window
local openHub
local function onReady()
	if not currentStartup() then return nil end
	local Kit = loadModule("src/ui/Kit.lua")
	local BrandCtor = loadModule("src/ui/Brand.lua")
	local Brand = BrandCtor and BrandCtor(RAW_BASE .. "assets/rift_logo.jpg")
	local OpenHub = loadModule("src/ui/Hub.lua")
	local MakeIsland = loadModule("src/ui/Island.lua")
	local HomeVideo = loadModule("src/ui/HomeVideo.lua")
	local GameLibrary = loadModule("src/ui/GameLibrary.lua")
	local LibraryStateCtor = loadModule("src/core/LibraryState.lua")
	local LibraryView = loadModule("src/ui/LibraryView.lua")
	local QuickSearch = loadModule("src/ui/QuickSearch.lua")
	local LibraryState = LibraryStateCtor and LibraryStateCtor()
	if Kit then Kit.ReduceMotion = LibraryState and LibraryState.ReducedMotion or false end

	local AimAssistCtor = loadModule("src/features/AimAssist.lua")
	local ESPCtor = loadModule("src/features/ESP.lua")
	local FlyCtor = loadModule("src/features/Fly.lua")
	local AntiAFKCtor = loadModule("src/features/AntiAFK.lua")
	local MovementCtor = loadModule("src/features/Movement.lua")
	local TriggerbotCtor = loadModule("src/features/Triggerbot.lua")
	local ChamsCtor = loadModule("src/features/Chams.lua")
	local FullbrightCtor = loadModule("src/features/Fullbright.lua")
	local FreecamCtor = loadModule("src/features/Freecam.lua")
	local CameraToolsCtor = loadModule("src/features/CameraTools.lua")
	local WaypointsCtor = loadModule("src/features/Waypoints.lua")
	local ServerToolsCtor = loadModule("src/features/ServerTools.lua")

	if not (type(Kit)=="table" and type(OpenHub)=="function" and type(GameLibrary)=="function" and type(AimAssistCtor)=="function" and type(ESPCtor)=="function" and type(FlyCtor)=="function" and type(AntiAFKCtor)=="function") then
		if currentStartup() then env.__RiftHubLoaded=false end
		warn("[RiftHub] UI modules failed to load, no window opened")
		return nil
	end

	Rift.Kit = Kit
	Rift.Features = {}
	Rift.Features.AimAssist = AimAssistCtor(Rift.Utils)
	Rift.Features.ESP = ESPCtor(Rift.Utils)
	Rift.Features.Fly = FlyCtor(Rift.Utils)
	Rift.Features.AntiAFK = AntiAFKCtor()
	-- newer, optional feature modules -- the hub still opens if one of these
	-- fails to fetch, just without that tab's section
	if MovementCtor then Rift.Features.Movement = MovementCtor(Rift.Utils) end
	if TriggerbotCtor then Rift.Features.Triggerbot = TriggerbotCtor(Rift.Utils) end
	if ChamsCtor then Rift.Features.Chams = ChamsCtor(Rift.Utils) end
	if FullbrightCtor then Rift.Features.Fullbright = FullbrightCtor() end
	if FreecamCtor then Rift.Features.Freecam = FreecamCtor() end
	if CameraToolsCtor then Rift.Features.CameraTools = CameraToolsCtor(Rift.Utils) end
	if WaypointsCtor then Rift.Features.Waypoints = WaypointsCtor(Rift.Utils) end
	if ServerToolsCtor then Rift.Features.ServerTools = ServerToolsCtor() end

	Rift.Hub = OpenHub({
		Kit = Kit,
		Brand = Brand,
		Utils = Rift.Utils,
		Config = Rift.Config,
		Features = Rift.Features,
		Island = MakeIsland,
		HomeVideo = HomeVideo,
		GameLibrary = GameLibrary,
		LibraryState = LibraryState, LibraryView = LibraryView, QuickSearch = QuickSearch,
		OnRestart = function() return openHub() end,
		ToggleKey = Enum.KeyCode.RightShift,
	})

 if not currentStartup() then if Rift.Hub and Rift.Hub.Unload then pcall(Rift.Hub.Unload) end;return nil end
 assert(type(Rift.Hub)=="table" and Rift.Hub.Game=="Rift Hub" and Rift.Hub.Gui and Rift.Hub.Gui.Parent,
  "Main hub window did not finish opening")
 env.Rift=Rift;env.__RiftHubLoaded=true
 return Rift
end
openHub=function()
 local ok,result=pcall(onReady)
 if ok and result then return result end
 for _,feature in pairs(Rift.Features or {}) do
  if type(feature)=="table" and type(feature.Stop)=="function" then pcall(feature.Stop) end
 end
 if Rift.Hub and type(Rift.Hub.Unload)=="function" then pcall(Rift.Hub.Unload) end
 if currentStartup() then env.__RiftHubLoaded=false;env.Rift=nil end
 warn("[RiftHub] main startup failed: "..tostring(result or "required module unavailable"))
 return nil
end

if INTRO_ENABLED then
	local PlayIntro = loadModule("src/ui/Intro.lua")
	if PlayIntro then PlayIntro({ OnComplete = openHub }) else openHub() end
else
	openHub()
end

return env.Rift
