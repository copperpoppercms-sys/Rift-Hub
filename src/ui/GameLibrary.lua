-- Small game catalogue with a guarded handoff to the standalone game window.
local MM2_RAW = "https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-MM2/main/"
local MM2 = {
	Id = "mm2", Name = "Murder Mystery 2", ScriptName = "Rift Hub · MM2",
	ShortName = "MM2", ChunkName = "RiftHubMM2/main.lua", Handoff = "Opens MM2 and closes hub",
	PlaceId = 142823291, UniverseId = 66654135, Url = MM2_RAW .. "main.lua",
	IconUrl = MM2_RAW .. "assets/mm2_icon.png",
	Thumbnail = "rbxthumb://type=GameIcon&id=142823291&w=150&h=150",
}
local SUPERHERO_RAW = "https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/"
local SUPERHERO = {
	Id = "superhero-arena", Name = "Superhero Arena", ScriptName = "Rift Hub · Superhero Arena",
	ShortName = "Superhero Arena", ChunkName = "RiftHubSuperheroArena/main.lua",
	PlaceId = 78710221869926, UniverseId = 10765491459, Url = SUPERHERO_RAW .. "main.lua",
	IconUrl = SUPERHERO_RAW .. "assets/superhero_arena_icon.png",
	Thumbnail = "rbxthumb://type=GameIcon&id=10765491459&w=150&h=150",
	Handoff = "Opens Superhero Arena and closes hub",
}

local HULK_RAW = "https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Survive-The-Hulk/main/"
local HULK = {
	Id = "survive-the-hulk", Name = "Survive The Hulk", ScriptName = "Rift Hub · Survive The Hulk",
	ShortName = "Survive The Hulk", ChunkName = "RiftHubSurviveTheHulk/main.lua",
	PlaceId = 109166720609444, UniverseId = 10742937135, Url = HULK_RAW .. "main.lua",
	IconUrl = HULK_RAW .. "assets/hulk_icon.png",
	Thumbnail = "rbxthumb://type=GameIcon&id=10742937135&w=150&h=150",
	Handoff = "Opens Survive The Hulk and closes hub",
}

return function(ctx)
	local M = { Games = { MM2, SUPERHERO, HULK }, Status = "Ready" }
	local busy, disposed = false, false
	local function cleanupGame(item)
		local env = type(getgenv) == "function" and getgenv() or _G
		if item.Id == "mm2" then
			if type(env.MONO_Unload) == "function" then pcall(env.MONO_Unload) end
			if type(env.RiftMM2StartupCleanup) == "function" then pcall(env.RiftMM2StartupCleanup) end
		else
			local key = item.Id == "survive-the-hulk" and "RiftHulkHub" or "SuperheroArenaHub"
			local name = item.Id == "survive-the-hulk" and "RiftSurviveTheHulk" or "RiftAutoPlay"
			if type(env[key]) == "table" and type(env[key].Unload) == "function" then pcall(env[key].Unload) end
			-- Also remove a window created before a startup error prevented API publication.
			pcall(function()
				local parents = { game:GetService("CoreGui"), game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") }
				if type(gethui) == "function" then table.insert(parents, gethui()) end
				for _, parent in ipairs(parents) do
					local window = parent:FindFirstChild(name)
					if window then window:Destroy() end
				end
			end)
		end
	end
	function M.Dispose() disposed = true end
	function M.Execute(item)
		if disposed then return false, "Hub is closed" end
		if busy then return false, "Already loading" end
		local known = false
		for _, entry in ipairs(M.Games) do if entry == item then known = true; break end end
		if not known then return false, "Unknown game" end
		if game.PlaceId ~= item.PlaceId and game.GameId ~= item.UniverseId then
			M.Status = "Open " .. item.Name .. " first"; return false, M.Status
		end
		busy = true; M.Status = "Fetching script…"
		local ok, source = pcall(function() return game:HttpGet(item.Url .. "?cb=" .. tostring(os.time())) end)
		if disposed then busy = false; return false, "Hub is closed" end
		if not ok or type(source) ~= "string" or source == "" then
			busy = false; M.Status = "Could not fetch script"; return false, M.Status
		end
		local chunk, compileError = loadstring(source, "=" .. item.ChunkName)
		if not chunk then
			busy = false; M.Status = "Script could not compile"
			warn("[RiftHub] " .. item.ShortName .. " compile: " .. tostring(compileError)); return false, M.Status
		end
		M.Status = "Opening Rift Hub " .. item.ShortName .. "…"
		-- Stop universal features before the game script takes its own snapshots.
		local started, result = pcall(function()
			ctx.Unload()
			local window = chunk()
			assert(type(window) == "table" and window.Game == item.Name and window.Gui and window.Gui.Parent,
				item.ShortName .. " did not finish building its window")
			return window
		end)
		busy = false
		if not started then
			cleanupGame(item)
			M.Status = item.ShortName .. " startup failed"
			warn("[RiftHub] " .. item.ShortName .. " startup: " .. tostring(result))
			if ctx.Restart then
				local restored, err = pcall(ctx.Restart)
				if not restored then warn("[RiftHub] reopening hub: " .. tostring(err)) end
			end
			return false, M.Status
		end
		M.Status = item.ShortName .. " open"
		return true, result
	end
	function M.LoadIcon(item, image)
		task.spawn(function()
			local ok, asset = pcall(function()
				if type(writefile) ~= "function" or type(getcustomasset) ~= "function" or type(isfile) ~= "function" then return item.Thumbnail end
				local path = "RiftHub/" .. item.Id .. "_icon.png"
				if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder("RiftHub") then makefolder("RiftHub") end
				if not isfile(path) then
					local data = game:HttpGet(item.IconUrl)
					assert(data:sub(2, 4) == "PNG", "Invalid game icon")
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
