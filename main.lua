-- Luau | Roblox | Xeno/Synapse-class executor | RiftHub entrypoint
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub/main/main.lua"))()

if getgenv then
	if getgenv().__RiftHubLoaded then
		return
	end
	getgenv().__RiftHubLoaded = true
end

local REPO_OWNER = "copperpoppercms-sys"
local REPO_NAME = "Rift-Hub"
local REPO_BRANCH = "main"
local RAW_BASE = string.format("https://raw.githubusercontent.com/%s/%s/%s/", REPO_OWNER, REPO_NAME, REPO_BRANCH)
-- Temporarily disabled. Intro.lua and every media asset are preserved; see docs/IntroRestore.md.
local INTRO_ENABLED = false

-- fetches a raw file from the repo, cache-busted, with one retry on transient HttpGet failure
local function fetchRaw(path)
	local url = RAW_BASE .. path .. "?cb=" .. tostring(os.time())
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
local function loadModule(path)
	local source, fetchErr = fetchRaw(path)
	if not source then
		warn(string.format("[RiftHub] could not fetch %s: %s", path, tostring(fetchErr)))
		return nil
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

local Rift = {}
Rift.Utils = loadModule("src/core/Utils.lua")
Rift.Config = loadModule("src/core/Config.lua")

if not Rift.Utils or not Rift.Config then
	warn("[RiftHub] core modules failed to load, aborting")
	return
end

-- runs once the intro finishes; opens the main window
local function onReady()
	if type(getgenv) == "function" then getgenv().__RiftHubLoaded = true end
	local Kit = loadModule("src/ui/Kit.lua")
	local BrandCtor = loadModule("src/ui/Brand.lua")
	local Brand = BrandCtor and BrandCtor(RAW_BASE .. "assets/rift_logo.jpg")
	local OpenHub = loadModule("src/ui/Hub.lua")
	local MakeIsland = loadModule("src/ui/Island.lua")
	local HomeVideo = loadModule("src/ui/HomeVideo.lua")
	local GameLibrary = loadModule("src/ui/GameLibrary.lua")

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

	if not (Kit and OpenHub and AimAssistCtor and ESPCtor and FlyCtor and AntiAFKCtor) then
		warn("[RiftHub] UI modules failed to load, no window opened")
		if getgenv then getgenv().Rift = Rift end
		return
	end

	Rift.Kit = Kit
	Rift.Features = {
		AimAssist = AimAssistCtor(Rift.Utils),
		ESP = ESPCtor(Rift.Utils),
		Fly = FlyCtor(Rift.Utils),
		AntiAFK = AntiAFKCtor(),
	}
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
		OnRestart = onReady,
		ToggleKey = Enum.KeyCode.RightShift,
	})

	if getgenv then
		getgenv().Rift = Rift
	end
end

if INTRO_ENABLED then
	local PlayIntro = loadModule("src/ui/Intro.lua")
	if PlayIntro then PlayIntro({ OnComplete = onReady }) else onReady() end
else
	onReady()
end
