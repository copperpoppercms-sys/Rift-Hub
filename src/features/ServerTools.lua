-- Select a different non-full public server, with cursor pagination and useful errors.
return function()
	local HttpService = game:GetService("HttpService")
	local TeleportService = game:GetService("TeleportService")
	local player = game:GetService("Players").LocalPlayer
	local M = { Config = { Prefer = "Smallest" }, Status = "Ready" }
	local busy, stopped = false, false
	function M.Hop()
		if busy then return false, "Already searching" end
		if stopped then return false, "Hub is unloaded" end
		busy = true; M.Status = "Searching public servers…"
		local ok, result = pcall(function()
			local cursor, candidates = nil, {}
			for page = 1, 3 do
				if stopped then return nil end
				local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
				if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
				local data = HttpService:JSONDecode(game:HttpGet(url))
				if type(data) ~= "table" or type(data.data) ~= "table" then error("Invalid server response") end
				for _, server in ipairs(data.data) do
					if type(server.id) == "string" and server.id ~= game.JobId and tonumber(server.playing) and tonumber(server.maxPlayers) and tonumber(server.playing) < tonumber(server.maxPlayers) then
						server.playing = tonumber(server.playing); server.maxPlayers = tonumber(server.maxPlayers); table.insert(candidates, server)
					end
				end
				cursor = data.nextPageCursor
				if not cursor or cursor == "" then break end
			end
			if stopped then return nil end
			if #candidates == 0 then return false end
			table.sort(candidates, function(a, b)
				if M.Config.Prefer == "Lowest ping" then return (tonumber(a.ping) or math.huge) < (tonumber(b.ping) or math.huge) end
				return a.playing < b.playing
			end)
			local selected = M.Config.Prefer == "Random" and candidates[math.random(#candidates)] or candidates[1]
			M.Status = "Joining server…"
			TeleportService:TeleportToPlaceInstance(game.PlaceId, selected.id, player)
			return true
		end)
		busy = false
		if stopped then return false, "Hub is unloaded" end
		if not ok then M.Status = "Server search failed"; return false, tostring(result) end
		if not result then M.Status = "No other available servers"; return false, M.Status end
		return true, M.Status
	end
	local failure = TeleportService.TeleportInitFailed:Connect(function(plr, _, message)
		if plr == player then M.Status = "Teleport failed: " .. tostring(message) end
	end)
	function M.Stop() stopped = true; failure:Disconnect() end
	return M
end
