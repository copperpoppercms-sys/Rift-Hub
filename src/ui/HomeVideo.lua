-- Looping hub cinema. Raw GitHub videos cannot be assigned to a Roblox VideoFrame;
-- this small cached JPEG pack is decoded once and reused by a single ImageLabel.
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local RAW = "https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub/main/assets/"
local VERSION = "3"
local ROOT = "RiftHub/home-video-" .. VERSION

local function fetch(url)
	local requester = request or http_request or (type(syn) == "table" and syn.request)
	if type(requester) == "function" then
		local ok, response = pcall(requester, { Url = url, Method = "GET" })
		local status = ok and type(response) == "table" and tonumber(response.StatusCode)
		if status and status >= 200 and status < 300 and type(response.Body) == "string" then
			return response.Body
		end
	end
	return game:HttpGet(url)
end

local function prepare(alive)
	assert(type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
		and type(makefolder) == "function" and type(isfolder) == "function" and type(getcustomasset) == "function",
		"This executor cannot cache the cinema assets")
	if not isfolder("RiftHub") then makefolder("RiftHub") end
	if not isfolder(ROOT) then makefolder(ROOT) end
	local manifest = ROOT .. "/manifest.txt"
	local count, fps
	local cached = false
	if isfile(manifest) then
		count, fps = readfile(manifest):match("^(%d+) (%d+)$")
		count, fps = tonumber(count), tonumber(fps)
		cached = count and fps and count > 0 and count <= 2000 and fps > 0 and fps <= 60
		if cached then
			for i = 1, count do
				local path = string.format("%s/f%04d.jpg", ROOT, i)
				if not isfile(path) or #readfile(path) == 0 then cached = false; break end
			end
		end
	end
	if not cached then
		local data = fetch(RAW .. "home_video.pack?v=" .. VERSION)
		local first = data:find("\n", 1, true)
		local second = first and data:find("\n", first + 1, true)
		assert(second, "Invalid cinema pack header")
		count, fps = data:sub(1, first - 1):match("^XHVP1 (%d+) (%d+)$")
		count, fps = tonumber(count), tonumber(fps)
		assert(count and fps and count > 0 and count <= 2000 and fps > 0 and fps <= 60, "Invalid cinema pack")
		local sizes, total = {}, 0
		for value in data:sub(first + 1, second - 1):gmatch("%d+") do
			local size = tonumber(value)
			assert(size > 0, "Empty cinema frame")
			table.insert(sizes, size)
			total += size
		end
		assert(#sizes == count and #data - second == total, "Incomplete cinema download")
		local offset = second + 1
		for i, size in ipairs(sizes) do
			if not alive() then return end
			writefile(string.format("%s/f%04d.jpg", ROOT, i), data:sub(offset, offset + size - 1))
			offset += size
			if i % 24 == 0 then task.wait() end
		end
		writefile(manifest, string.format("%d %d", count, fps))
	end
	local images = {}
	for i = 1, count do
		if not alive() then return end
		images[i] = getcustomasset(string.format("%s/f%04d.jpg", ROOT, i))
		if i % 24 == 0 then
			local batch = {}
			for j = i - 23, i do table.insert(batch, images[j]) end
			ContentProvider:PreloadAsync(batch)
			task.wait()
		end
	end
	local tail = count % 24
	if tail > 0 then
		local batch = {}
		for j = count - tail + 1, count do table.insert(batch, images[j]) end
		ContentProvider:PreloadAsync(batch)
	end
	return images, fps
end

return function(ctx, dock)
	local Kit, janitor = ctx.Kit, ctx.Janitor
	local destroyed, expanded, ready, muted = false, false, false, true
	local images, fps, elapsed, lastFrame, sound = nil, 12, 0, 0, nil
	local function alive() return not destroyed end
	janitor.add(function() destroyed = true end)

	local stage = Kit.create("Frame", {
		Name = "CinemaStage", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Kit.VOID,
		BorderSizePixel = 0, ClipsDescendants = true,
	}, dock)
	Kit.create("UICorner", { CornerRadius = UDim.new(0, 12) }, stage)
	Kit.create("UIStroke", { Color = Kit.BORDER, Transparency = 0.15, Thickness = 1 }, stage)
	local image = Kit.create("ImageLabel", {
		Name = "CinemaFrame", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit, Image = "", ZIndex = 83,
	}, stage)
	local status = Kit.create("TextLabel", {
		Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1,
		FontFace = Kit.face("BuilderSans"), TextSize = 12, TextColor3 = Kit.SUB,
		Text = "Loading cinema…", TextWrapped = true, ZIndex = 84,
	}, stage)
	local open = Kit.create("TextButton", {
		Name = "ExpandCinema", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Text = "", AutoButtonColor = false, ZIndex = 84,
	}, stage)
	local caption = Kit.create("TextLabel", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10), Size = UDim2.fromOffset(138, 24),
		BackgroundColor3 = Kit.VOID, BackgroundTransparency = 0.2, BorderSizePixel = 0,
		FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium), TextSize = 10, TextColor3 = Kit.INK,
		Text = "↗  CLICK TO EXPAND", ZIndex = 85,
	}, stage)
	Kit.create("UICorner", { CornerRadius = UDim.new(0, 6) }, caption)
	local mute = Kit.create("TextButton", {
		Name = "CinemaSound", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -10),
		Size = UDim2.fromOffset(58, 26), BackgroundColor3 = Kit.VOID, BackgroundTransparency = 0.2,
		BorderSizePixel = 0, AutoButtonColor = false, FontFace = Kit.face("BuilderSans"),
		TextSize = 10, TextColor3 = Kit.INK, Text = "MUTED", ZIndex = 86,
	}, stage)
	Kit.create("UICorner", { CornerRadius = UDim.new(0, 6) }, mute)

	-- The expanded player stays inside the hub, never becoming a full-screen GUI.
	local overlay = Kit.create("Frame", {
		Name = "CinemaOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35, BorderSizePixel = 0, Visible = false, Active = true, ZIndex = 80,
	}, ctx.Card)
	local modal = Kit.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.88, 0.86), BackgroundColor3 = Kit.BASE, BorderSizePixel = 0, ZIndex = 81,
	}, overlay)
	Kit.create("UICorner", { CornerRadius = UDim.new(0, 14) }, modal)
	Kit.Surface(modal)
	Kit.create("UIStroke", { Color = Kit.BORDER, Transparency = 0.2, Thickness = 1 }, modal)
	Kit.create("TextLabel", {
		Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -80, 0, 42), BackgroundTransparency = 1,
		FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium), TextSize = 11, TextColor3 = Kit.SUB,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "RIFT  /  MIDNIGHT CINEMA", ZIndex = 82,
	}, modal)
	local close = Kit.create("TextButton", {
		Name = "ShrinkCinema", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 7),
		Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Kit.TRACK, AutoButtonColor = false, BorderSizePixel = 0,
		FontFace = Kit.face("BuilderSans"), TextSize = 18, TextColor3 = Kit.INK, Text = "×", ZIndex = 87,
	}, modal)
	Kit.create("UICorner", { CornerRadius = UDim.new(0, 8) }, close)
	Kit.create("UIStroke", { Color = Kit.ACCENT, Transparency = 0.4, Thickness = 1 }, close)
	local largeDock = Kit.create("Frame", {
		Position = UDim2.fromOffset(10, 42), Size = UDim2.new(1, -20, 1, -52), BackgroundTransparency = 1, ZIndex = 82,
	}, modal)

	local function setExpanded(value)
		if destroyed then return end
		expanded = value
		overlay.Visible = value
		stage.Parent = value and largeDock or dock
		stage.ZIndex = value and 82 or 1
		-- GUI ZIndex is sibling-based: the parent stage stays below the modal overlay.
		caption.Visible = not value
		open.Active = not value
		open.Visible = not value
	end
	janitor.add(open.Activated:Connect(function() setExpanded(true) end))
	janitor.add(close.Activated:Connect(function() setExpanded(false) end))
	janitor.add(mute.Activated:Connect(function()
		muted = not muted
		mute.Text = muted and "MUTED" or "SOUND"
		if sound then sound.Volume = muted and 0 or 0.35 end
	end))

	task.spawn(function()
		local ok, result, rate = pcall(prepare, alive)
		if not alive() then return end
		if not ok or not result then
			status.Text = "Cinema unavailable"
			warn("[RiftHub] cinema: " .. tostring(result))
			caption.Visible = false
			mute.Visible = false
			return
		end
		images, fps = result, rate
		image.Image = images[1]
		status.Visible = false
		ready = true
		-- Audio is optional: visual playback still works if its asset fails.
		local audioOk, audioResult = pcall(function()
			local path = ROOT .. "/audio.ogg"
			if not isfile(path) or #readfile(path) == 0 then writefile(path, fetch(RAW .. "home_audio.ogg?v=" .. VERSION)) end
			if not alive() then return end
			local s = Kit.create("Sound", { Name = "RiftCinemaAudio", SoundId = getcustomasset(path), Volume = muted and 0 or 0.35, Looped = true }, SoundService)
			janitor.add(s)
			ContentProvider:PreloadAsync({ s })
			return s
		end)
		if not alive() then return end
		if audioOk then sound = audioResult else warn("[RiftHub] cinema audio: " .. tostring(audioResult)) end
		if not sound then mute.Visible = false end
	end)

	janitor.add(RunService.Heartbeat:Connect(function(dt)
		if destroyed or not ready then return end
		local active = ctx.IsVisible() and ctx.IsHomeVisible()
		if not active then
			if expanded then setExpanded(false) end
			if sound and sound.IsPlaying then sound:Pause() end
			return
		end
		local duration = #images / fps
		elapsed = (elapsed + dt) % duration
		if sound then
			if not sound.IsPlaying then
				sound:Play()
				sound.TimePosition = elapsed
			elseif not muted and sound.TimeLength > 0 then
				elapsed = sound.TimePosition % duration
			end
		end
		local index = math.clamp(math.floor(elapsed * fps) + 1, 1, #images)
		if index ~= lastFrame then image.Image = images[index]; lastFrame = index end
	end))
	return { Shrink = function() setExpanded(false) end }
end
