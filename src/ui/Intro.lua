-- Luau | Roblox | Xeno/Synapse-class executor | RiftHub loading intro
-- Standalone: loadstring(game:HttpGet(RAW_URL))() plays it immediately with defaults.
-- Also returns Play(opts) so main.lua can trigger it with a custom OnComplete/overrides.
--
-- Primary path: a single-request "frame pack" (assets/frames.pack, concatenated jpgs) +
-- assets/audio.ogg, cached to disk and played back as a fake video via one reused
-- ImageLabel -- real video playback needs a Roblox-uploaded rbxassetid, which an
-- external clip doesn't have, so this fakes it client-side instead. Frame textures are
-- preloaded via ContentProvider before anything is shown -- skipping that is what causes
-- the cold-decode stutter/flash on first play. One accumulated-time clock drives frames so
-- playback never drifts from audio. Just the footage, the small RIFT HUB wordmark
-- (top-left), and a matching skip button (bottom-right) -- no overlay text/pops. When the
-- footage ends (or is skipped), a short glitch cutscene plays: a baked horror-poster still
-- (assets/welcome_bg.jpg) with restrained native "WELCOME TO RIFT" typography
-- and a slow camera push over assets/laugh.ogg -- timed to
-- run exactly as long as that audio, before handing off. Falls back to a text-only intro
-- (no video) on any executor missing the file API this needs, so the hub is always
-- reachable either way.

local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui         = game:GetService("CoreGui")
local SoundService    = game:GetService("SoundService")

-- gethui() is an executor-provided container that renders above CoreGui (leaderboard,
-- top bar, chat, backpack -- everything the engine itself draws) and is hidden from the
-- game's own scripts; CoreGui is the sane fallback on an executor that lacks it. Neither
-- can reach a native overlay the executor app itself draws outside Roblox's UI tree (e.g.
-- Delta's own menu icon) -- that's not part of this GUI tree at all, nothing drawn here
-- can cover it.
local GUI_PARENT = (type(gethui) == "function" and gethui()) or CoreGui

local ACCENT = Color3.fromRGB(176, 49, 43) -- Halloween blood red
local BG = Color3.fromRGB(13, 12, 14)
local WHITE = Color3.fromRGB(234, 224, 203)
local MAX_DISPLAY_ORDER = 2147483647

local REPO_OWNER, REPO_NAME, REPO_BRANCH = "copperpoppercms-sys", "Rift-Hub", "main"
local RAW_BASE = string.format("https://raw.githubusercontent.com/%s/%s/%s/", REPO_OWNER, REPO_NAME, REPO_BRANCH)
local DEFAULT_PACK_URL = RAW_BASE .. "assets/frames.pack"
local DEFAULT_AUDIO_URL = RAW_BASE .. "assets/audio.ogg"
local DEFAULT_LAUGH_URL = RAW_BASE .. "assets/laugh.ogg"
local DEFAULT_WELCOME_BG_URL = RAW_BASE .. "assets/welcome_bg.jpg"
local DEFAULT_WELCOME_TEXT_URL = RAW_BASE .. "assets/welcome_text.png"

local ROOT = "RiftHub"
local FRAMES_DIR = ROOT .. "/frames"
local AUDIO_PATH = ROOT .. "/audio.ogg"
local LAUGH_PATH = ROOT .. "/laugh.ogg"
local WELCOME_BG_PATH = ROOT .. "/welcome_bg.jpg"
local WELCOME_TEXT_PATH = ROOT .. "/welcome_text.png"
local FPS = 15
-- bump any time assets/frames.pack, assets/audio.ogg, assets/laugh.ogg, or the welcome
-- images actually change, or a stale local cache will keep the old versions instead of
-- refetching
local PACK_VERSION = "8"

local LAUGH_DURATION = 10.3  -- assets/laugh.ogg's actual length -- update if that clip changes
-- Used only if welcome audio fails to load. Normal timing follows Sound.Ended.

local DEFAULT_FEATURES = {
	"Silent Aim", "ESP", "Triggerbot", "Fly", "Speed",
	"NoClip", "Infinite Jump", "Chams", "FOV Circle", "Anti-AFK",
}

----------------------------------------------------------------------
-- shared helpers
----------------------------------------------------------------------

local function newJanitor()
	local items = {}
	local j = {}
	function j.add(x)
		table.insert(items, x)
		return x
	end
	function j.clean()
		for _, x in ipairs(items) do
			if typeof(x) == "RBXScriptConnection" then
				x:Disconnect()
			elseif typeof(x) == "Instance" then
				x:Destroy()
			elseif type(x) == "function" then
				pcall(x)
			end
		end
		table.clear(items)
	end
	return j
end

local function tween(instance, props, time, style, dir)
	local info = TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(instance, info, props)
	t:Play()
	return t
end

local function create(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then inst[k] = v end
	end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

local function shuffleCopy(pool)
	local out = {}
	for i, v in ipairs(pool) do out[i] = v end
	for i = #out, 2, -1 do
		local j = math.random(i)
		out[i], out[j] = out[j], out[i]
	end
	return out
end

local function mkLabel(parent, text, size, pos, fontSize)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = text,
		TextColor3 = WHITE,
		TextSize = fontSize,
		TextTransparency = 1,
		Size = size,
		Position = pos,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = parent,
	})
	create("UIStroke", {
		Thickness = 2,
		Color = Color3.fromRGB(0, 0, 0),
		Transparency = 1, -- starts hidden alongside the label, callers tween it in
		Parent = label,
	})
	return label
end

-- shown only while prepareAssets() is fetching/unpacking (first run can mean several
-- MB over the network before anything else exists to show) -- without this, a cold
-- start is a blank screen for however long that takes, indistinguishable from the
-- script having silently failed. No real byte-level progress is available from
-- game:HttpGet, so the bar just sweeps to show activity instead of sitting frozen.
local function showPreloadSplash()
	local gui = create("ScreenGui", {
		Name = "RiftPreload",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = MAX_DISPLAY_ORDER,
		Parent = GUI_PARENT,
	})

	local bg = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BG,
		BorderSizePixel = 0,
		Parent = gui,
	})

	local brand = mkLabel(bg, "RIFT HUB", UDim2.fromScale(0.8, 0.08), UDim2.fromScale(0.5, 0.46), 28)
	brand.TextColor3 = ACCENT
	tween(brand, { TextTransparency = 0 }, 0.3)
	for _, child in ipairs(brand:GetChildren()) do
		if child:IsA("UIStroke") then tween(child, { Transparency = 0.3 }, 0.3) end
	end

	local barHolder = create("Frame", {
		Size = UDim2.fromScale(0.28, 0.01),
		Position = UDim2.fromScale(0.5, 0.56),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(44, 31, 33),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = bg,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barHolder })
	tween(barHolder, { BackgroundTransparency = 0 }, 0.3)

	local barFill = create("Frame", {
		Size = UDim2.fromScale(0.22, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = ACCENT,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = barHolder,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barFill })
	tween(barFill, { BackgroundTransparency = 0 }, 0.3)

	local sweep = TweenService:Create(
		barFill,
		TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Position = UDim2.fromScale(0.78, 0) }
	)
	sweep:Play()

	return function()
		sweep:Cancel()
		gui:Destroy()
	end
end

----------------------------------------------------------------------
-- frame-pack fetch / cache / unpack (video path only)
----------------------------------------------------------------------

local canFS = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
	and type(makefolder) == "function" and type(isfolder) == "function" and type(getcustomasset) == "function"

local requester = (type(request) == "function" and request)
	or (type(http_request) == "function" and http_request)
	or (type(syn) == "table" and type(syn.request) == "function" and syn.request)
	or nil

local function fetch(url)
	if requester then
		local ok, response = pcall(requester, { Url = url, Method = "GET" })
		if ok and type(response) == "table" then
			local status = tonumber(response.StatusCode) or 0
			if status >= 200 and status < 300 and type(response.Body) == "string" then
				return response.Body
			end
		end
	end
	local ok, body = pcall(function() return game:HttpGet(url) end)
	if ok and type(body) == "string" then return body end
	return nil
end

local function ensureFolder(path)
	local built = ""
	for part in string.gmatch(path, "([^/]+)") do
		built = built == "" and part or (built .. "/" .. part)
		local ok, present = pcall(isfolder, built)
		if not (ok and present) then pcall(makefolder, built) end
	end
end

-- format: "XHPK1 <count>\n<size1> <size2> ... <sizeN>\n<raw bytes concatenated>"
local function unpackFrames(data, force)
	local headEnd = string.find(data, "\n", 1, true)
	local sizesEnd = headEnd and string.find(data, "\n", headEnd + 1, true)
	if not sizesEnd then return nil, "bad pack header" end
	local count = tonumber(string.match(string.sub(data, 1, headEnd - 1), "^XHPK1 (%d+)$"))
	if not count then return nil, "bad pack signature" end

	local sizes = {}
	for digits in string.gmatch(string.sub(data, headEnd + 1, sizesEnd - 1), "%d+") do
		sizes[#sizes + 1] = tonumber(digits)
	end
	if #sizes ~= count then return nil, "pack frame count mismatch" end

	ensureFolder(FRAMES_DIR)
	local at = sizesEnd + 1
	for i = 1, count do
		local size = sizes[i]
		local path = string.format("%s/f%04d.jpg", FRAMES_DIR, i)
		if force or not isfile(path) then
			writefile(path, string.sub(data, at, at + size - 1))
		end
		at += size
		if i % 30 == 0 then task.wait() end
	end
	return count
end

local function pruneOldFrames(fromCount, keepCount)
	for i = keepCount + 1, fromCount do
		pcall(function()
			local path = string.format("%s/f%04d.jpg", FRAMES_DIR, i)
			if isfile(path) and type(delfile) == "function" then delfile(path) end
		end)
	end
end

local function framesAlreadyCached(expectedCount)
	if not isfolder(FRAMES_DIR) then return false end
	if not isfile(string.format("%s/f%04d.jpg", FRAMES_DIR, 1)) then return false end
	if not isfile(string.format("%s/f%04d.jpg", FRAMES_DIR, expectedCount)) then return false end
	return true
end

-- fetch+cache+getcustomasset for a single optional file (not core playback): a failure
-- anywhere in this chain warns and returns nil instead of aborting the whole intro
local function fetchOptionalAsset(url, path, upToDate, label)
	if not upToDate or not (isfile(path) and #readfile(path) > 0) then
		local data = fetch(url)
		if data then
			writefile(path, data)
		else
			warn("[RiftHub] could not download " .. url)
		end
	end
	if isfile(path) then
		local ok, result = pcall(getcustomasset, path)
		if ok then return result end
		warn("[RiftHub] getcustomasset failed for " .. path .. ": " .. tostring(result))
	else
		warn("[RiftHub] " .. label .. " unavailable (no cached file and fetch failed)")
	end
	return nil
end

local function prepareAssets(packUrl, audioUrl, laughUrl, welcomeBgUrl, welcomeTextUrl)
	ensureFolder(ROOT)

	local manifestPath = ROOT .. "/frame_count.txt"
	local cachedVersion, cachedCount
	if isfile(manifestPath) then
		local version, count = string.match(readfile(manifestPath), "^(%S+)|(%d+)$")
		cachedVersion, cachedCount = version, tonumber(count)
	end

	local upToDate = cachedVersion == PACK_VERSION and cachedCount and framesAlreadyCached(cachedCount)
	local frameCount

	if upToDate then
		frameCount = cachedCount
	else
		local packData = fetch(packUrl)
		if not packData then return false, "could not download the intro frames" end
		local count, err = unpackFrames(packData, true)
		if not count then return false, err end
		if cachedCount and cachedCount > count then pruneOldFrames(cachedCount, count) end
		frameCount = count
		writefile(manifestPath, PACK_VERSION .. "|" .. tostring(count))
	end

	local frameContents = {}
	for i = 1, frameCount do
		frameContents[i] = getcustomasset(string.format("%s/f%04d.jpg", FRAMES_DIR, i))
	end

	-- decode every frame while the screen is still black -- a cold first-show decode
	-- is exactly what causes mid-playback flicker
	pcall(function() ContentProvider:PreloadAsync(frameContents) end)

	if not upToDate or not (isfile(AUDIO_PATH) and #readfile(AUDIO_PATH) > 0) then
		local audioData = fetch(audioUrl)
		if not audioData then return false, "could not download the intro audio" end
		writefile(AUDIO_PATH, audioData)
	end
	local soundId = getcustomasset(AUDIO_PATH)

	-- the welcome cutscene's laugh/background/text are all nice-to-haves, not core
	-- playback -- each falls back gracefully (silence, plain black card) on its own
	local laughSoundId = fetchOptionalAsset(laughUrl, LAUGH_PATH, upToDate, "welcome-cutscene laugh")
	local welcomeBgId = fetchOptionalAsset(welcomeBgUrl, WELCOME_BG_PATH, upToDate, "welcome-cutscene background")
	-- Native typography replaces the baked title; no additional text image needed.
	local welcomeTextId = nil

	return true, frameCount, frameContents, soundId, laughSoundId, welcomeBgId, welcomeTextId
end

----------------------------------------------------------------------
-- fallback path: no video, GUI-only (used when the executor lacks the file
-- API the frame pack needs, or the download fails)
----------------------------------------------------------------------

local function playFallback(opts)
	local duration = opts.Duration or 3.2
	local features = opts.Features or DEFAULT_FEATURES
	local onComplete = opts.OnComplete

	local janitor = newJanitor()

	local gui = create("ScreenGui", {
		Name = "RiftIntro",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = MAX_DISPLAY_ORDER,
		Parent = GUI_PARENT,
	})
	janitor.add(gui)

	local bg = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BG,
		BorderSizePixel = 0,
		Parent = gui,
	})

	local brand = mkLabel(bg, "RIFT HUB", UDim2.fromScale(0.8, 0.08), UDim2.fromScale(0.5, 0.22), 34)
	brand.TextColor3 = ACCENT
	tween(brand, { TextTransparency = 0 }, 0.5)
	for _, child in ipairs(brand:GetChildren()) do
		if child:IsA("UIStroke") then tween(child, { Transparency = 0.3 }, 0.5) end
	end

	local barHolder = create("Frame", {
		Size = UDim2.fromScale(0.42, 0.012),
		Position = UDim2.fromScale(0.5, 0.8),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(44, 31, 33),
		BorderSizePixel = 0,
		Parent = bg,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barHolder })

	local barFill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = ACCENT,
		BorderSizePixel = 0,
		Parent = barHolder,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barFill })

	local statusLabel = mkLabel(bg, "loading...", UDim2.fromScale(0.5, 0.03), UDim2.fromScale(0.5, 0.855), 15)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextColor3 = Color3.fromRGB(181, 165, 151)
	local statusStroke = statusLabel:FindFirstChildOfClass("UIStroke")
	statusStroke.Thickness = 1
	tween(statusLabel, { TextTransparency = 0.2 }, 0.5)
	tween(statusStroke, { Transparency = 0.7 }, 0.5)

	tween(barFill, { Size = UDim2.fromScale(1, 1) }, duration, Enum.EasingStyle.Linear)

	local popLayer = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = bg })
	local cutCover = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = bg,
	})

	local function popFeature(text)
		local offsetX = (math.random() - 0.5) * 0.16
		local offsetY = (math.random() - 0.5) * 0.08
		local label = mkLabel(popLayer, text, UDim2.fromScale(0.9, 0.12), UDim2.fromScale(0.5 + offsetX, 0.5 + offsetY), 52)
		label.Rotation = (math.random() - 0.5) * 4

		local stroke = label:FindFirstChildOfClass("UIStroke")
		stroke.Transparency = 1

		tween(label, { TextTransparency = 0 }, 0.15, Enum.EasingStyle.Back)
		tween(stroke, { Transparency = 0.25 }, 0.15, Enum.EasingStyle.Back)
		label.Size = UDim2.fromScale(0.75, 0.1)
		tween(label, { Size = UDim2.fromScale(0.9, 0.12) }, 0.2, Enum.EasingStyle.Back)

		task.delay(0.32, function()
			tween(label, { TextTransparency = 1, Position = UDim2.fromScale(0.5 + offsetX, 0.5 + offsetY - 0.02) }, 0.18)
			tween(stroke, { Transparency = 1 }, 0.18)
			task.delay(0.2, function() label:Destroy() end)
		end)
	end

	local popLoop = task.spawn(function()
		local shuffled = shuffleCopy(features)
		local startTime = os.clock()
		local index = 1
		while os.clock() - startTime < duration - 0.3 do
			popFeature(shuffled[((index - 1) % #shuffled) + 1])
			index += 1
			task.wait(0.3 + math.random() * 0.2)
		end
	end)
	janitor.add(function() task.cancel(popLoop) end)

	local startTime = os.clock()
	local statusConn = RunService.RenderStepped:Connect(function()
		local pct = math.clamp((os.clock() - startTime) / duration, 0, 1)
		statusLabel.Text = string.format("loading rift hub... %d%%", math.floor(pct * 100))
	end)
	janitor.add(statusConn)

	task.delay(duration, function()
		tween(cutCover, { BackgroundTransparency = 0 }, 0.18)
		task.delay(0.3, function()
			janitor.clean()
			if onComplete then task.spawn(onComplete) end
		end)
	end)

	return janitor
end

----------------------------------------------------------------------
-- video path: frame-pack playback
----------------------------------------------------------------------

local function playVideo(opts, frameCount, frameContents, soundId, laughSoundId, welcomeBgId, welcomeTextId)
	local onComplete = opts.OnComplete
	local janitor = newJanitor()

	local gui = create("ScreenGui", {
		Name = "RiftIntro",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = MAX_DISPLAY_ORDER,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = GUI_PARENT,
	})
	janitor.add(gui)

	local backdrop = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = gui,
	})

	-- true edge-to-edge footage, no frame/border/card -- fills every pixel of the
	-- screen behind it (leaderboard included)
	local videoImage = create("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Crop,
		Image = frameContents[1],
		ZIndex = 1,
		Parent = backdrop,
	})

	-- small corner wordmark: letter-spaced caps + a thin underline, matching the
	-- reference logo -- plain white, no accent color, deliberately understated
	local wordmark = create("TextLabel", {
		Size = UDim2.fromOffset(170, 16),
		Position = UDim2.new(0, 28, 0, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "X E N O   H U B",
		ZIndex = 5,
		Parent = gui,
	})
	local wordmarkRule = create("Frame", {
		Size = UDim2.fromOffset(150, 1),
		Position = UDim2.new(0, 28, 0, 46),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = gui,
	})

	-- Bottom-right skip button, matching the top-left wordmark.
	local skipBtn = create("TextButton", {
		Size = UDim2.fromOffset(120, 36),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -28, 1, -24),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "S K I P",
		ZIndex = 5,
		Parent = gui,
	})

	local titleCard = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BG,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = backdrop,
	})

	-- Photographic horror treatment: slow camera movement and restrained type.
	-- Keep all artwork clipped so the push-in cannot cover the intro controls.
	titleCard.ClipsDescendants = true
	local welcomeBg = create("ImageLabel", {
		Size = UDim2.fromScale(1.025, 1.025),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Crop,
		Image = welcomeBgId or "",
		ImageColor3 = Color3.fromRGB(190, 192, 200),
		ImageTransparency = 1,
		ZIndex = 3,
		Parent = titleCard,
	})

	local shade = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = titleCard,
	})
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.28),
			NumberSequenceKeypoint.new(0.32, 0.94),
			NumberSequenceKeypoint.new(0.56, 0.78),
			NumberSequenceKeypoint.new(0.82, 0.12),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = shade,
	})
	local edgeShade = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = titleCard,
	})
	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.12),
			NumberSequenceKeypoint.new(0.22, 0.85),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(0.78, 0.85),
			NumberSequenceKeypoint.new(1, 0.12),
		}),
		Parent = edgeShade,
	})

	local welcomeWrap = create("Frame", {
		Size = UDim2.fromScale(0.84, 0.24),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.80),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = titleCard,
	})
	local welcomeEyebrow = create("TextLabel", {
		Size = UDim2.fromScale(0.72, 0.16),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = "W E L C O M E   T O",
		TextColor3 = Color3.fromRGB(184, 180, 172),
		TextTransparency = 1,
		TextScaled = true,
		ZIndex = 5,
		Parent = welcomeWrap,
	})
	create("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = 15, Parent = welcomeEyebrow })
	local welcomeMain = create("TextLabel", {
		Size = UDim2.fromScale(1, 0.75),
		Position = UDim2.fromScale(0, 0.17),
		BackgroundTransparency = 1,
		Font = Enum.Font.Bodoni,
		Text = "RIFT",
		TextColor3 = Color3.fromRGB(229, 225, 216),
		TextTransparency = 1,
		TextScaled = true,
		ZIndex = 5,
		Parent = welcomeWrap,
	})
	create("UITextSizeConstraint", { MinTextSize = 26, MaxTextSize = 118, Parent = welcomeMain })
	local welcomeRule = create("Frame", {
		Size = UDim2.fromScale(0.06, 0),
		Position = UDim2.fromScale(0.5, 0.98),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(120, 35, 29),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = welcomeWrap,
	})
	welcomeRule.Size = UDim2.new(0.06, 0, 0, 1)
	-- Preload during footage playback so the welcome does not reveal an empty image.
	task.spawn(function()
		pcall(function() ContentProvider:PreloadAsync({ welcomeBg }) end)
	end)

	local laughSound
	if laughSoundId then
		-- SoundService, not GUI_PARENT/gui: a Sound's parent has nothing to do with
		-- where UI lives, and SoundService is the one place guaranteed to both exist
		-- and actually play audio regardless of how a given executor's gethui() is
		-- implemented. Its lifetime follows the welcome screen.
		laughSound = create("Sound", { Name = "RiftWelcomeLaugh", Volume = 1, SoundId = laughSoundId, Parent = SoundService })
		janitor.add(laughSound)
		task.spawn(function()
			local ok, err = pcall(function() ContentProvider:PreloadAsync({ laughSound }) end)
			if not ok then warn("[RiftHub] welcome audio preload failed: " .. tostring(err)) end
		end)
		-- Completion and the safety timeout are connected when welcome playback starts.
	else
		warn("[RiftHub] welcome-cutscene laugh unavailable (no laughSoundId -- asset fetch/cache likely failed)")
	end

	local welcomeMotion
	local function playWelcome()
		tween(welcomeBg, { ImageTransparency = 0 }, 0.65)
		tween(shade, { BackgroundTransparency = 0 }, 0.65)
		tween(edgeShade, { BackgroundTransparency = 0 }, 0.65)
		tween(welcomeEyebrow, { TextTransparency = 0 }, 0.55)
		tween(welcomeMain, { TextTransparency = 0 }, 0.85)
		tween(welcomeRule, { BackgroundTransparency = 0.15 }, 0.85)

		-- Move with actual playback progress. No looping title pulse or random shake.
		local elapsed = 0
		local envelope = 0
		welcomeMotion = RunService.Heartbeat:Connect(function(dt)
			elapsed += dt
			local duration = LAUGH_DURATION
			local position = elapsed
			if laughSound and laughSound.Parent and laughSound.IsPlaying then
				duration = laughSound.TimeLength > 0 and laughSound.TimeLength or duration
				position = laughSound.TimePosition
				envelope += (math.clamp(laughSound.PlaybackLoudness / 900, 0, 1) - envelope) * math.min(dt * 4, 1)
			end
			local progress = math.clamp(position / duration, 0, 1)
			local zoom = 1.025 + progress * 0.035
			welcomeBg.Size = UDim2.fromScale(zoom, zoom)
			welcomeBg.Position = UDim2.fromScale(0.5 - progress * 0.006, 0.5 + progress * 0.004)
			local exposure = 190 - envelope * 8
			welcomeBg.ImageColor3 = Color3.fromRGB(exposure, exposure + 2, exposure + 10)
		end)
		janitor.add(welcomeMotion)
	end

	local sound = create("Sound", { Name = "RiftIntroAudio", Volume = 1, SoundId = soundId, Parent = gui })
	janitor.add(sound)

	local welcomeFinished = false
	local function endWelcome()
		if welcomeFinished then return end
		welcomeFinished = true
		if welcomeMotion then welcomeMotion:Disconnect() end
		tween(titleCard, { BackgroundTransparency = 1 }, 0.35)
		tween(welcomeBg, { ImageTransparency = 1 }, 0.3)
		tween(welcomeMain, { TextTransparency = 1 }, 0.3)
		tween(welcomeEyebrow, { TextTransparency = 1 }, 0.3)
		tween(welcomeRule, { BackgroundTransparency = 1 }, 0.3)
		tween(shade, { BackgroundTransparency = 1 }, 0.3)
		tween(edgeShade, { BackgroundTransparency = 1 }, 0.3)
		task.delay(0.4, function()
			janitor.clean()
			if onComplete then task.spawn(onComplete) end
		end)
	end

	local function finish()
		sound:Stop()
		skipBtn.Active = false
		skipBtn.Visible = false -- hidden instantly; no tween needed, there's nothing left to fade
		tween(wordmark, { TextTransparency = 1 }, 0.25)
		tween(wordmarkRule, { BackgroundTransparency = 1 }, 0.25)
		tween(videoImage, { ImageTransparency = 1 }, 0.2)
		tween(titleCard, { BackgroundTransparency = 0 }, 0.2)

		task.delay(0.22, function()
			if laughSound then
				local deadline = os.clock() + 5
				while laughSound.Parent and not laughSound.IsLoaded and os.clock() < deadline do
					task.wait(0.05)
				end
			end
			if laughSound and laughSound.Parent and laughSound.IsLoaded then
				janitor.add(laughSound.Ended:Connect(endWelcome))
				laughSound.TimePosition = 0
				local ok, err = pcall(function() laughSound:Play() end)
				if not ok then
					warn("[RiftHub] laughSound:Play() failed: " .. tostring(err))
					task.delay(LAUGH_DURATION, endWelcome)
				else
					-- safety net only: Sound.Ended (connected above) is what normally
					-- ends the welcome screen -- this just guarantees a handoff even if
					-- that event never fires
					local duration = laughSound.TimeLength > 0 and laughSound.TimeLength or LAUGH_DURATION
					task.delay(duration + 5, function()
						if not welcomeFinished then
							warn("[RiftHub] welcome audio did not finish; closing welcome")
							endWelcome()
						end
					end)
				end
			else
				warn("[RiftHub] welcome audio unavailable or not loaded; using fallback duration")
				task.delay(LAUGH_DURATION, endWelcome)
			end
			playWelcome()
		end)
	end

	tween(wordmark, { TextTransparency = 0 }, 0.4)
	tween(wordmarkRule, { BackgroundTransparency = 0 }, 0.4)
	tween(skipBtn, { TextTransparency = 0 }, 0.4)
	sound:Play()

	local elapsed = 0
	local frameIndex = 1
	local duration = frameCount / FPS
	local finished = false

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt

		local wanted = math.clamp(math.floor(elapsed * FPS) + 1, 1, frameCount)
		if wanted ~= frameIndex then
			frameIndex = wanted
			videoImage.Image = frameContents[frameIndex]
		end

		if elapsed >= duration and not finished then
			finished = true
			conn:Disconnect()
			finish()
		end
	end)
	janitor.add(conn)

	skipBtn.MouseButton1Click:Connect(function()
		if finished then return end
		finished = true
		if conn.Connected then conn:Disconnect() end
		finish()
	end)

	return janitor
end

----------------------------------------------------------------------
-- entry point
----------------------------------------------------------------------

local function Play(opts)
	opts = opts or {}

	local existing = GUI_PARENT:FindFirstChild("RiftIntro")
	if existing then existing:Destroy() end
	local existingPreload = GUI_PARENT:FindFirstChild("RiftPreload")
	if existingPreload then existingPreload:Destroy() end

	if not canFS then
		return playFallback(opts)
	end

	local packUrl = opts.PackUrl or DEFAULT_PACK_URL
	local audioUrl = opts.AudioUrl or DEFAULT_AUDIO_URL
	local laughUrl = opts.LaughUrl or DEFAULT_LAUGH_URL
	local welcomeBgUrl = opts.WelcomeBgUrl or DEFAULT_WELCOME_BG_URL
	local welcomeTextUrl = opts.WelcomeTextUrl or DEFAULT_WELCOME_TEXT_URL

	local closeSplash = showPreloadSplash()
	local ok, frameCountOrErr, frameContents, soundId, laughSoundId, welcomeBgId, welcomeTextId =
		prepareAssets(packUrl, audioUrl, laughUrl, welcomeBgUrl, welcomeTextUrl)
	closeSplash()
	if not ok then
		warn("[RiftHub] intro video unavailable (" .. tostring(frameCountOrErr) .. "), falling back to text-only")
		return playFallback(opts)
	end

	return playVideo(opts, frameCountOrErr, frameContents, soundId, laughSoundId, welcomeBgId, welcomeTextId)
end

return Play
