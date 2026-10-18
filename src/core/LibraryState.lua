-- UI-only preferences. No gameplay options are enabled or restored here.
local HttpService = game:GetService("HttpService")
local PATH = "RiftHub/library.json"
local ALLOWED = { mm2=true, ["superhero-arena"]=true, ["survive-the-hulk"]=true }
return function()
	local M = { Favorites = {}, LastGame = nil, ReducedMotion = false, Saved = false }
	local function valid(data)
		if type(data) ~= "table" or data.Version ~= 1 then return end
		if type(data.Favorites) == "table" then
			for id in pairs(ALLOWED) do M.Favorites[id] = data.Favorites[id] == true or nil end
		end
		if ALLOWED[data.LastGame] then M.LastGame = data.LastGame end
		M.ReducedMotion = data.ReducedMotion == true
	end
	if type(isfile) == "function" and type(readfile) == "function" then
		pcall(function() if isfile(PATH) then valid(HttpService:JSONDecode(readfile(PATH))) end end)
	end
	local function save()
		M.Saved = false
		if type(writefile) ~= "function" then return false end
		local ok = pcall(function()
			if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder("RiftHub") then makefolder("RiftHub") end
			writefile(PATH, HttpService:JSONEncode({ Version=1, Favorites=M.Favorites, LastGame=M.LastGame, ReducedMotion=M.ReducedMotion }))
		end)
		M.Saved = ok
		return ok
	end
	function M.ToggleFavorite(id)
		if not ALLOWED[id] then return false end
		M.Favorites[id] = not M.Favorites[id] or nil
		save()
		return M.Favorites[id] == true
	end
	function M.RecordLaunch(id)
		if not ALLOWED[id] then return false end
		M.LastGame=id; save(); return true
	end
	function M.SetReducedMotion(on)
		M.ReducedMotion=on == true; save()
	end
	function M.IsCurrent(item)
		return game.PlaceId == item.PlaceId or game.GameId == item.UniverseId
	end
	function M.Filter(games, query, filter)
		local tokens, result, order = {}, {}, {}
		for word in tostring(query or ""):lower():gmatch("%S+") do table.insert(tokens, word) end
		for index, item in ipairs(games) do
			order[item] = index
			local show = filter ~= "Favorites" or M.Favorites[item.Id] == true
			if filter == "This game" then show = M.IsCurrent(item) end
			local text=(item.Name .. " " .. (item.ShortName or "") .. " " .. (item.ScriptName or "")):lower()
			for _, word in ipairs(tokens) do if not text:find(word,1,true) then show=false; break end end
			if show then table.insert(result,item) end
		end
		local function rank(item)
			return (M.IsCurrent(item) and 8 or 0) + (M.Favorites[item.Id] and 4 or 0) + (M.LastGame == item.Id and 2 or 0)
		end
		table.sort(result,function(a,b) local ra,rb=rank(a),rank(b); if ra ~= rb then return ra > rb end; return order[a] < order[b] end)
		return result
	end
	function M.Columns(width) return width >= 580 and 2 or 1 end
	return M
end
