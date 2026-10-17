-- Small game catalogue with a guarded handoff to the standalone game window.
local MM2_RAW = "https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-MM2/main/"
local MM2 = {
	Id = "mm2", Name = "Murder Mystery 2", ScriptName = "Rift Hub · MM2",
	PlaceId = 142823291, UniverseId = 66654135, Url = MM2_RAW .. "main.lua",
	IconUrl = MM2_RAW .. "assets/mm2_icon.png",
	Thumbnail = "rbxthumb://type=GameIcon&id=142823291&w=150&h=150",
}

return function(ctx)
	local M = { Games = { MM2 }, Status = "Ready" }
	local busy, disposed = false, false
	local function cleanupMM2()
		local env = type(getgenv) == "function" and getgenv() or _G
		if type(env.MONO_Unload) == "function" then pcall(env.MONO_Unload) end
		if type(env.RiftMM2StartupCleanup) == "function" then pcall(env.RiftMM2StartupCleanup) end
	end
	function M.Dispose() disposed = true end
	function M.Execute(item)
		if disposed then return false, "Hub is closed" end
		if busy then return false, "Already loading" end
		if game.PlaceId ~= item.PlaceId and game.GameId ~= item.UniverseId then
			M.Status = "Open Murder Mystery 2 first"; return false, M.Status
		end
		busy = true; M.Status = "Fetching script…"
		local ok, source = pcall(function() return game:HttpGet(item.Url .. "?cb=" .. tostring(os.time())) end)
		if disposed then busy = false; return false, "Hub is closed" end
		if not ok or type(source) ~= "string" or source == "" then
			busy = false; M.Status = "Could not fetch script"; return false, M.Status
		end
		local chunk, compileError = loadstring(source, "=RiftHubMM2/main.lua")
		if not chunk then
			busy = false; M.Status = "Script could not compile"
			warn("[RiftHub] MM2 compile: " .. tostring(compileError)); return false, M.Status
		end
		M.Status = "Opening Rift Hub MM2…"
		-- Stop the universal features before MM2 takes its own character/camera snapshots.
		local started, result = pcall(function()
			ctx.Unload()
			local window = chunk()
			assert(type(window) == "table" and window.Game == "Murder Mystery 2" and window.Gui and window.Gui.Parent,
				"MM2 did not finish building its window")
			return window
		end)
		busy = false
		if not started then
			cleanupMM2()
			M.Status = "MM2 startup failed"
			warn("[RiftHub] MM2 startup: " .. tostring(result))
			if ctx.Restart then
				local restored, err = pcall(ctx.Restart)
				if not restored then warn("[RiftHub] reopening hub: " .. tostring(err)) end
			end
			return false, M.Status
		end
		M.Status = "MM2 open"
		return true, result
	end
	function M.LoadIcon(item, image)
		task.spawn(function()
			local ok, asset = pcall(function()
				if type(writefile) ~= "function" or type(getcustomasset) ~= "function" or type(isfile) ~= "function" then return item.Thumbnail end
				local path = "RiftHub/mm2_icon.png"
				if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder("RiftHub") then makefolder("RiftHub") end
				if not isfile(path) then
					local data = game:HttpGet(item.IconUrl)
					assert(data:sub(2, 4) == "PNG", "Invalid MM2 icon")
					writefile(path, data)
				end
				return getcustomasset(path)
			end)
			if ok and not disposed and image.Parent then image.Image = asset end
		end)
	end
	ctx.Janitor.add(M.Dispose)
	return M
end
