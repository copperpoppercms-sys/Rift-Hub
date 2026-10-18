-- Luau | Roblox | Xeno/Synapse-class executor | RiftHub main window
-- Halloween shell, live player portraits, and an optional docked cinema on Home.
-- Feature controls continue to use the existing modules and shared widget kit.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local GUI_PARENT = (type(gethui) == "function" and gethui()) or CoreGui

local headshots = {}
local function addHeadshot(Kit, parent, plr, position, size)
	local avatar = Kit.create("Frame", {
		Position = position, Size = UDim2.fromOffset(size, size), BackgroundColor3 = Kit.TRACK,
		BorderSizePixel = 0, ClipsDescendants = true,
	}, parent)
	Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, avatar)
	local initial = Kit.create("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium), TextSize = 14,
		TextColor3 = Kit.SUB, Text = plr.DisplayName:sub(1, 1):upper(),
	}, avatar)
	local image = Kit.create("ImageLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "", ScaleType = Enum.ScaleType.Fit,
	}, avatar)
	Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, image)
	task.spawn(function()
		local content = headshots[plr.UserId]
		if not content then
			for attempt = 1, 3 do
				local ok, url, ready = pcall(Players.GetUserThumbnailAsync, Players,
					plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
				if ok and ready and url ~= "" then content = url; headshots[plr.UserId] = url; break end
				if not avatar.Parent then return end
				task.wait(0.3 * attempt)
			end
		end
		if content and avatar.Parent and image.Parent then
			image.Image = content
			initial.Visible = false
		end
	end)
	return avatar
end

local function getPlaceName()
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
	if ok and info and info.Name then return info.Name end
	return "this place"
end

----------------------------------------------------------------------
-- tab builders -- each takes (panel, ctx) and is only ever invoked once,
-- after every ctx field below is already populated
----------------------------------------------------------------------

local function buildHome(panel, ctx)
	local Kit, Utils, Features, janitor = ctx.Kit, ctx.Utils, ctx.Features, ctx.Janitor
	local scroller = Kit.Scroller(panel)

	Kit.create("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
		FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium), TextSize = 12, TextColor3 = Kit.FAINT,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "WELCOME BACK, " .. string.upper(LocalPlayer.Name),
	}, scroller)

	local hero = Kit.create("Frame", {
		Name = "HomeHero", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 218),
		BackgroundColor3 = Kit.PANEL, BackgroundTransparency = 0.08, BorderSizePixel = 0,
	}, scroller)
	Kit.create("UICorner", { CornerRadius = UDim.new(0, 14) }, hero)
	Kit.Surface(hero)
	Kit.Web(hero, 74, true)
	Kit.create("UIStroke", { Color = Kit.BORDER, Transparency = 0.4, Thickness = 1 }, hero)
	Kit.create("TextLabel", {
		Position = UDim2.fromOffset(20, 22), Size = UDim2.new(0.46, -20, 0, 16), BackgroundTransparency = 1,
		FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium), TextSize = 10, TextColor3 = Kit.CANDLE,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "●  UNIVERSAL / AFTER DARK",
	}, hero)
	Kit.create("TextLabel", {
		Position = UDim2.fromOffset(20, 49), Size = UDim2.new(0.46, -20, 0, 48), BackgroundTransparency = 1,
		FontFace = Kit.face("Merriweather", Enum.FontWeight.Regular, Enum.FontStyle.Italic),
		TextSize = 32, TextColor3 = Kit.INK, TextXAlignment = Enum.TextXAlignment.Left, Text = "After dark.",
	}, hero)
	Kit.create("TextLabel", {
		Position = UDim2.fromOffset(20, 110), Size = UDim2.new(0.46, -24, 0, 66), BackgroundTransparency = 1,
		FontFace = Kit.face("BuilderSans"), TextSize = 12, TextColor3 = Kit.SUB, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Text = "The night is yours. Your players, tools and session are ready.",
	}, hero)
	local videoDock = Kit.create("Frame", {
		Name = "HomeCinema", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.new(0.5, -12, 1, -24), BackgroundColor3 = Kit.BASE, BorderSizePixel = 0,
	}, hero)
	Kit.create("UICorner", { CornerRadius = UDim.new(0, 12) }, videoDock)
	if ctx.HomeVideo then
		ctx.HomeVideo(ctx, videoDock)
	else
		Kit.create("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, FontFace = Kit.face("BuilderSans"),
			TextSize = 12, TextColor3 = Kit.SUB, Text = "Cinema unavailable",
		}, videoDock)
	end

	local quick = Kit.Section(scroller, "Quick actions", "⚡", 4)
	Kit.Button(quick, "Rejoin this server", "Leave and come straight back.", "Rejoin", function()
		pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
	end)

	local library = Kit.Section(scroller, "Library", "▣", 5)
	Kit.PlainRow(library, ctx.PlaceName, "Universal")

	local statsRow = Kit.create("Frame", {
		LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 76), BackgroundTransparency = 1,
	}, scroller)
	Kit.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
	}, statsRow)

	local function statTile(title, order)
		local tile = Kit.create("Frame", {
			LayoutOrder = order, Size = UDim2.new(0.25, -7.5, 1, 0), BackgroundColor3 = Kit.PANEL,
			BackgroundTransparency = 0.1, BorderSizePixel = 0,
		}, statsRow)
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 10) }, tile)
		Kit.Surface(tile)
		Kit.create("UIStroke", { Color = Kit.BORDER, Transparency = 0.5, Thickness = 1 }, tile)
		Kit.create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 8) }, tile)
		Kit.create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, FontFace = Kit.face("BuilderSans"),
			TextSize = 10, TextColor3 = Kit.FAINT, TextXAlignment = Enum.TextXAlignment.Left, Text = title,
		}, tile)
		local value = Kit.create("TextLabel", {
			Position = UDim2.new(0, 0, 0, 16), Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderExtended", Enum.FontWeight.Bold), TextSize = 18, TextColor3 = Kit.INK,
			TextXAlignment = Enum.TextXAlignment.Left, Text = "--",
		}, tile)
		return value
	end

	local fpsVal = statTile("FPS", 1)
	local pingVal = statTile("PING", 2)
	local playersVal = statTile("PLAYERS", 3)
	local sessionVal = statTile("SESSION", 4)

	local tip = Kit.Section(scroller, "Good to know", nil, 6)
	Kit.PlainRow(tip, "Move the hub", "Drag the top bar.")
	Kit.PlainRow(tip, "Show / hide", ctx.ToggleKey.Name)

	local frames, lastSecond = 0, os.clock()
	janitor.add(RunService.Heartbeat:Connect(function()
		frames += 1
		local now = os.clock()
		if now - lastSecond >= 1 then
			fpsVal.Text = tostring(frames)
			lastSecond = now
			frames = 0
			local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
			pingVal.Text = ok and string.format("%.0f", ping) or "--"
			playersVal.Text = tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
			local elapsed = now - ctx.SessionStart
			sessionVal.Text = string.format("%d:%02d", math.floor(elapsed / 60), math.floor(elapsed % 60))
		end
	end))
end

local function buildHub(panel, ctx)
	local Kit = ctx.Kit
	local scroller = Kit.Scroller(panel)
	Kit.create("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
		FontFace = Kit.face("Merriweather", Enum.FontWeight.Bold), TextSize = 18, TextColor3 = Kit.INK,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "Game scripts",
	}, scroller)
	if not ctx.GameLibrary then
		Kit.create("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans"), TextSize = 12, TextColor3 = Kit.SUB, Text = "Game library unavailable" }, scroller)
		return
	end
	local library = ctx.GameLibrary(ctx)
	local rows = math.ceil(#library.Games / 2)
	local cards = Kit.create("Frame", {
		Name = "GameCards", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, rows * 156 - 12), BackgroundTransparency = 1,
	}, scroller)
	Kit.create("UIGridLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, CellSize = UDim2.fromOffset(320, 144),
		CellPadding = UDim2.fromOffset(12, 12), FillDirectionMaxCells = 2,
	}, cards)
	for order, item in ipairs(library.Games) do
		local tile = Kit.create("Frame", {
			Name = item.Id, LayoutOrder = order + 1, Size = UDim2.fromOffset(320, 144),
			BackgroundColor3 = Kit.PANEL, BorderSizePixel = 0,
		}, cards)
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 12) }, tile)
		Kit.create("UIStroke", { Color = Kit.BORDER, Transparency = 0.3, Thickness = 1 }, tile)
		Kit.Surface(tile)
		local image = Kit.create("ImageLabel", {
			Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(40, 40),
			BackgroundColor3 = Kit.VOID, BorderSizePixel = 0, Image = item.Thumbnail, ScaleType = Enum.ScaleType.Fit,
		}, tile)
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 8) }, image)
		library.LoadIcon(item, image)
		Kit.create("TextLabel", {
			Position = UDim2.fromOffset(66, 14), Size = UDim2.new(1, -80, 0, 20), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium), TextSize = 14, TextColor3 = Kit.INK,
			TextXAlignment = Enum.TextXAlignment.Left, Text = item.Name,
		}, tile)
		Kit.create("TextLabel", {
			Position = UDim2.fromOffset(66, 36), Size = UDim2.new(1, -80, 0, 16), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans"), TextSize = 11, TextColor3 = Kit.SUB,
			TextXAlignment = Enum.TextXAlignment.Left, Text = item.ScriptName,
		}, tile)
		local execute = Kit.create("TextButton", {
			Position = UDim2.fromOffset(14, 66), Size = UDim2.fromOffset(94, 30),
			BackgroundColor3 = Kit.ACCENT, BorderSizePixel = 0, AutoButtonColor = false,
			FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium), TextSize = 12, TextColor3 = Kit.INK, Text = "Execute",
		}, tile)
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 7) }, execute)
		local status = Kit.create("TextLabel", {
			Position = UDim2.fromOffset(14, 110), Size = UDim2.new(1, -28, 0, 18), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans"), TextSize = 10, TextColor3 = Kit.FAINT,
			TextXAlignment = Enum.TextXAlignment.Left, Text = item.Handoff,
		}, tile)
		local loading = false
		ctx.Janitor.add(execute.Activated:Connect(function()
			if loading then return end
			loading = true; execute.Text = "Loading…"
			task.spawn(function()
				local ok, result = library.Execute(item)
				loading = false
				if tile.Parent then
					execute.Text = "Execute"
					if not ok then status.Text = tostring(result) end
				end
			end)
		end))
	end
end

local function buildCombat(panel, ctx)
	local Kit = ctx.Kit
	local AimAssist = ctx.Features.AimAssist
	local Triggerbot = ctx.Features.Triggerbot
	local scroller = Kit.Scroller(panel)

	local assist = Kit.Section(scroller, "Aim assist", "◎", 1)
	Kit.Toggle(assist, "Active", "Turns toward the nearest player in range.", AimAssist.Config.Active, function(v)
		AimAssist.Config.Active = v
	end)
	Kit.Segmented(assist, "Aim key", "Used by While held and Toggle. Fixed to the right mouse button.", { "While held", "Toggle", "Always" }, AimAssist.Config.Mode, function(v)
		AimAssist.Config.Mode = v
	end)
	Kit.Toggle(assist, "Silent aim", "Snaps only for the instant you click, instead of tracking the target beforehand.", AimAssist.Config.Silent, function(v)
		AimAssist.Config.Silent = v
	end)
	Kit.Toggle(assist, "Show FOV circle", "Draws the field-of-view ring at your crosshair.", AimAssist.Config.ShowFOV, function(v)
		AimAssist.Config.ShowFOV = v
	end)

	if Triggerbot then
		local trigger = Kit.Section(scroller, "Triggerbot", "◉", 2)
		Kit.Toggle(trigger, "Active", "Fires the instant a target crosses your crosshair.", Triggerbot.Config.Active, function(v)
			Triggerbot.Config.Active = v
		end)
		Kit.Segmented(trigger, "Key", nil, { "While held", "Always" }, Triggerbot.Config.Mode, function(v)
			Triggerbot.Config.Mode = v
		end)
		Kit.Slider(trigger, "Field of view", nil, 5, 200, Triggerbot.Config.FOV, { Suffix = " px", OnChanged = function(v) Triggerbot.Config.FOV = v end })
		Kit.Slider(trigger, "Delay between shots", nil, 0, 1000, Triggerbot.Config.Delay, { Suffix = " ms", OnChanged = function(v) Triggerbot.Config.Delay = v end })
	end

	local target = Kit.Section(scroller, "Target", "⊙", 3)
	Kit.Cycle(target, "Aim at", nil, { "Head", "Root" }, AimAssist.Config.AimAt, function(v) AimAssist.Config.AimAt = v end)
	Kit.Cycle(target, "Pick by", "With several in range: nearest to crosshair, nearest to you, or lowest health.", { "Crosshair", "You", "Lowest health" }, AimAssist.Config.PickBy, function(v) AimAssist.Config.PickBy = v end)
	Kit.Slider(target, "Field of view", "Players inside this circle are considered.", 10, 500, AimAssist.Config.FOV, { Suffix = " px", OnChanged = function(v) AimAssist.Config.FOV = v end })
	Kit.Slider(target, "Range", nil, 50, 5000, AimAssist.Config.Range, { Suffix = " st", OnChanged = function(v) AimAssist.Config.Range = v end })
	Kit.Toggle(target, "Stay on one target", "Keeps the same player until they leave the circle.", AimAssist.Config.StayOnTarget, function(v) AimAssist.Config.StayOnTarget = v end)
	Kit.Slider(target, "Wait before the next target", "After one leaves the circle.", 0, 1000, AimAssist.Config.WaitBeforeNext, { Suffix = " ms", OnChanged = function(v) AimAssist.Config.WaitBeforeNext = v end })
	Kit.Toggle(target, "Only marked targets", "If anyone is marked in the Players tab, no one else is picked.", AimAssist.Config.OnlyMarked, function(v) AimAssist.Config.OnlyMarked = v end)
	Kit.Slider(target, "Smoothing", "0 snaps. Higher glides.", 0, 100, AimAssist.Config.Smoothing, { Suffix = "%", OnChanged = function(v) AimAssist.Config.Smoothing = v end })
	Kit.Slider(target, "Mouse strength", nil, 0, 100, AimAssist.Config.MouseStrength, { Suffix = "%", OnChanged = function(v) AimAssist.Config.MouseStrength = v end })
	Kit.Slider(target, "Dead zone", "This close to the target it stops correcting.", 0, 50, AimAssist.Config.DeadZone, { OnChanged = function(v) AimAssist.Config.DeadZone = v end })
end

local function buildVisuals(panel, ctx)
	local Kit = ctx.Kit
	local ESP = ctx.Features.ESP
	local Chams = ctx.Features.Chams
	local Fullbright = ctx.Features.Fullbright
	local Freecam = ctx.Features.Freecam
	local CameraTools = ctx.Features.CameraTools
	local scroller = Kit.Scroller(panel)

	local draw = Kit.Section(scroller, "What to draw", "◈", 1)
	Kit.Toggle(draw, "Box", nil, ESP.Config.Elements.Box, function(v) ESP.Config.Elements.Box = v end)
	Kit.Toggle(draw, "Name", nil, ESP.Config.Elements.Name, function(v) ESP.Config.Elements.Name = v end)
	Kit.Toggle(draw, "Distance", nil, ESP.Config.Elements.Distance, function(v) ESP.Config.Elements.Distance = v end)
	Kit.Toggle(draw, "Tracer", nil, ESP.Config.Elements.Tracer, function(v) ESP.Config.Elements.Tracer = v end)
	Kit.Segmented(draw, "Box style", nil, { "Corners", "Full" }, ESP.Config.BoxStyle, function(v) ESP.Config.BoxStyle = v end)
	Kit.Toggle(draw, "Fill the box", nil, ESP.Config.FillBox, function(v) ESP.Config.FillBox = v end)
	Kit.Slider(draw, "Box width", "As a share of its height.", 20, 100, ESP.Config.BoxWidthPct, { Suffix = "%", OnChanged = function(v) ESP.Config.BoxWidthPct = v end })
	Kit.Cycle(draw, "Tracers start at", nil, { "Bottom", "Centre", "Top", "Mouse" }, ESP.Config.TracerOrigin, function(v) ESP.Config.TracerOrigin = v end)

	local playerEsp = Kit.Section(scroller, "Player ESP", "▣", 2)
	Kit.Toggle(playerEsp, "Draws the box above on every player", nil, ESP.Config.Enabled, function(v) ESP.Config.Enabled = v end)

	local colorSec = Kit.Section(scroller, "Colour & weight", "◐", 3)
	Kit.Segmented(colorSec, "Colour by", nil, { "One colour", "Friends" }, ESP.Config.ColorBy, function(v) ESP.Config.ColorBy = v end)
	Kit.ColorRow(colorSec, "Colour", nil, {
		Color3.fromRGB(142, 125, 255), Color3.fromRGB(100, 220, 140), Color3.fromRGB(240, 100, 100),
		Color3.fromRGB(240, 200, 90), Color3.fromRGB(255, 255, 255),
	}, ESP.Config.Color, function(c) ESP.Config.Color = c end)
	Kit.ColorRow(colorSec, "Friends", nil, { Color3.fromRGB(100, 220, 140), Color3.fromRGB(90, 200, 255) }, ESP.Config.FriendColor, function(c) ESP.Config.FriendColor = c end)
	Kit.ColorRow(colorSec, "Own colour when in view", nil, { Color3.fromRGB(245, 220, 100), Color3.fromRGB(255, 255, 255) }, ESP.Config.SelfColor, function(c) ESP.Config.SelfColor = c end)

	if Chams then
		local chams = Kit.Section(scroller, "Chams", "◆", 4)
		Kit.Toggle(chams, "Through walls", "Highlights every player's model, visible behind anything.", Chams.Config.Enabled, function(v)
			Chams.Config.Enabled = v
			Chams.Repaint()
		end)
		Kit.ColorRow(chams, "Fill", nil, {
			Color3.fromRGB(176, 49, 43), Color3.fromRGB(100, 220, 140), Color3.fromRGB(90, 160, 255), Color3.fromRGB(240, 200, 90),
		}, Chams.Config.FillColor, function(c) Chams.Config.FillColor = c; Chams.Repaint() end)
		Kit.Slider(chams, "Fill transparency", nil, 0, 100, Chams.Config.FillTransparency * 100, {
			Suffix = "%", OnChanged = function(v) Chams.Config.FillTransparency = v / 100; Chams.Repaint() end,
		})
	end

	if Fullbright then
		local lighting = Kit.Section(scroller, "Lighting", "☀", 5)
		Kit.Toggle(lighting, "Fullbright", "Flattens the map's lighting so nothing stays dark.", Fullbright.Config.Enabled, function(v)
			Fullbright.SetEnabled(v)
		end)
	end

	if Freecam then
		local freecam = Kit.Section(scroller, "Freecam", "⬡", 6)
		Kit.Toggle(freecam, "Active", "Detaches the camera for free PC look-around: WASD to move, Space/Shift for up and down.", Freecam.Config.Active, function(v)
			if v and CameraTools then CameraTools.StopSpectating() end
			Freecam.SetActive(v)
		end)
		Kit.Slider(freecam, "Speed", nil, 10, 400, Freecam.Config.Speed, { Suffix = " st/s", OnChanged = function(v) Freecam.Config.Speed = v end })
	end
	if CameraTools then
		local camera = Kit.Section(scroller, "Camera", "◉", 7)
		Kit.Toggle(camera, "Custom field of view", nil, CameraTools.Config.FOVEnabled, function(v) CameraTools.Config.FOVEnabled = v end)
		Kit.Slider(camera, "Field of view", nil, 30, 120, CameraTools.Config.FOV, { Suffix = "°", OnChanged = function(v) CameraTools.Config.FOV = v end })
		Kit.Toggle(camera, "Extended zoom", "Lets the game camera zoom farther out.", CameraTools.Config.ZoomEnabled, function(v) CameraTools.Config.ZoomEnabled = v end)
		Kit.Slider(camera, "Maximum zoom", nil, 8, 1000, CameraTools.Config.MaxZoom, { Suffix = " st", OnChanged = function(v) CameraTools.Config.MaxZoom = v end })
		local spectating = Kit.PlainRow(camera, "Watching", CameraTools.SpectatingName())
		Kit.Button(camera, "Stop spectating", "Watch players using the eye button in Players.", "Return", CameraTools.StopSpectating)
		ctx.Janitor.add(RunService.Heartbeat:Connect(function() spectating.Set(CameraTools.SpectatingName()) end))
	end

end

local function buildMovement(panel, ctx)
	local Kit = ctx.Kit
	local Fly = ctx.Features.Fly
	local Movement = ctx.Features.Movement
	local Waypoints = ctx.Features.Waypoints
	local scroller = Kit.Scroller(panel)

	if Movement then
		local stats = Kit.Section(scroller, "Speed & jump", "⚡", 1)
		Kit.Toggle(stats, "Speed", "Overrides your walk speed.", Movement.Config.SpeedEnabled, function(v) Movement.Config.SpeedEnabled = v end)
		Kit.Slider(stats, "Walk speed", nil, 16, 500, Movement.Config.WalkSpeed, { Suffix = " st/s", OnChanged = function(v) Movement.Config.WalkSpeed = v end })
		Kit.Toggle(stats, "Jump", "Overrides how high you jump.", Movement.Config.JumpEnabled, function(v) Movement.Config.JumpEnabled = v end)
		Kit.Slider(stats, "Jump power", nil, 50, 500, Movement.Config.JumpPower, { Suffix = "", OnChanged = function(v) Movement.Config.JumpPower = v end })
		Kit.Toggle(stats, "Sprint", "Hold Left Ctrl to sprint on keyboard.", Movement.Config.SprintEnabled, function(v) Movement.Config.SprintEnabled = v end)
		Kit.Slider(stats, "Sprint speed", nil, 16, 250, Movement.Config.SprintSpeed, { Suffix = " st/s", OnChanged = function(v) Movement.Config.SprintSpeed = v end })
		Kit.Toggle(stats, "Infinite jump", "Jump again in midair, as many times as you tap it. Works with the mobile jump button too.", Movement.Config.InfiniteJump, function(v) Movement.Config.InfiniteJump = v end)

		local noclip = Kit.Section(scroller, "Noclip", "◫", 2)
		Kit.Toggle(noclip, "Walk through walls and floors", nil, Movement.Config.Noclip, function(v) Movement.SetNoclip(v) end)
	end

	Fly.OnLaunch = function(charge, power)
		local pseudoMach = power / 1000
		if pseudoMach >= Fly.Config.SonicBoomSpeed then
			ctx.SpawnBoom()
		end
	end

	local flight = Kit.Section(scroller, "Flight", "⟁", 3)
	Kit.Toggle(flight, "Charge launch", "When not flying, hold Space or the touch Launch button, then release.", Fly.Config.Armed, function(v) Fly.Config.Armed = v end)
	local flyToggle = Kit.Toggle(flight, "Fly", "WASD / thumbstick to steer; Space / Shift or touch buttons for height.", Fly.Config.Enabled, Fly.SetFlying)
	Kit.Toggle(flight, "Resume after respawn", nil, Fly.Config.ResumeOnRespawn, function(v) Fly.Config.ResumeOnRespawn = v end)
	local status = Kit.PlainRow(flight, "State", "Off")
	ctx.Janitor.add(RunService.Heartbeat:Connect(function()
		if flyToggle.Get() ~= Fly.Config.Enabled then flyToggle.Set(Fly.Config.Enabled) end
		local state = Fly.IsFlying() and string.format("Flying · %.0f st/s", Fly.CurrentSpeed()) or (Fly.Config.Enabled and "Waiting for character" or "Off")
		if Fly.LastError then state = "Flight could not start" end
		status.Set(state)
	end))
	Kit.Slider(flight, "Boost speed", "Hold E, controller R2, or the touch Boost button.", 16, 2000, Fly.Config.TopSpeed, { Suffix = " st/s", OnChanged = function(v) Fly.Config.TopSpeed = v end })
	Kit.Slider(flight, "Cruise speed", nil, 16, 1000, Fly.Config.CruiseSpeed, { Suffix = " st/s", OnChanged = function(v) Fly.Config.CruiseSpeed = v end })

	local launch = Kit.Section(scroller, "Charged launch", "➤", 4)
	Kit.Slider(launch, "Launch power", "Maximum speed of a fully charged launch.", 0, 2000, Fly.Config.LaunchPower, { Suffix = " st/s", OnChanged = function(v) Fly.Config.LaunchPower = v end })
	Kit.Slider(launch, "Boost ramp time", "Seconds of held boost to reach boost speed.", 0.2, 60, Fly.Config.TimeToTopSpeed, { Decimals = 1, Suffix = " s", OnChanged = function(v) Fly.Config.TimeToTopSpeed = v end })
	Kit.Slider(launch, "Launch flash threshold", "Optional flash above this launch power / 1000.", 0.5, 10, Fly.Config.SonicBoomSpeed, { Decimals = 2, Suffix = " st/s", OnChanged = function(v) Fly.Config.SonicBoomSpeed = v end })
	Kit.Slider(launch, "Full charge", "How long Space is held for the strongest launch.", 0.2, 10, Fly.Config.FullChargeTime, { Decimals = 1, Suffix = " s", OnChanged = function(v) Fly.Config.FullChargeTime = v end })

	local land = Kit.Section(scroller, "Landing", nil, 5)
	Kit.Toggle(land, "Land on the way down", "Flying down at the ground ends in the landing instead of clipping through it.", Fly.Config.LandOnWayDown, function(v) Fly.Config.LandOnWayDown = v end)
	if Waypoints then
		local spots = Kit.Section(scroller, "Saved positions", "⌖", 6)
		local result = Kit.PlainRow(spots, "Session slot", Waypoints.Status())
		Kit.Cycle(spots, "Slot", "Saved spots stay in this session.", { "A", "B", "C" }, Waypoints.Config.Slot, function(v) Waypoints.Config.Slot = v; result.Set(Waypoints.Status()) end)
		local function action(fn) local _, message = fn(); result.Set(message) end
		Kit.Button(spots, "Save current position", nil, "Save", function() action(Waypoints.Save) end)
		Kit.Button(spots, "Go to saved position", nil, "Go", function() action(Waypoints.GoTo) end)
		Kit.Button(spots, "Return to previous position", "Undo your last saved-position or player teleport.", "Return", function() action(Waypoints.Return) end)
	end

end

local function buildPlayers(panel, ctx)
	local Kit, Utils = ctx.Kit, ctx.Utils
	local ESP, AimAssist = ctx.Features.ESP, ctx.Features.AimAssist
	local CameraTools, Waypoints = ctx.Features.CameraTools, ctx.Features.Waypoints
	local scroller = Kit.Scroller(panel)
	local rows = {}
	local searchText = ""
	local sortMode = "Name"
	local refreshPlayers -- forward-declared so the controls below can close over it before it's assigned

	local countLbl = Kit.create("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
		FontFace = Kit.face("BuilderExtended", Enum.FontWeight.Bold), TextSize = 13, TextColor3 = Kit.INK,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "0 players",
	}, scroller)

	local _, searchInput = Kit.SearchBox(scroller, "Search players", function(t)
		searchText = t:lower()
		refreshPlayers()
	end)
	searchInput.Parent.LayoutOrder = 2

	local sortSection = { Body = scroller, _order = 2 }
	Kit.Segmented(sortSection, "Sort by", nil, { "Name", "Nearest", "Team", "Health" }, "Name", function(v)
		sortMode = v
		refreshPlayers()
	end)

	local listFrame = Kit.create("Frame", {
		LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
	}, scroller)
	Kit.create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, listFrame)

	local function makeRow(plr, order)
		local row = Kit.create("Frame", {
			LayoutOrder = order, Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = Kit.PANEL,
			BackgroundTransparency = 0.12, BorderSizePixel = 0,
		}, listFrame)
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 10) }, row)
		Kit.create("UIStroke", { Color = Kit.BORDER, Transparency = 0.6, Thickness = 1 }, row)

		addHeadshot(Kit, row, plr, UDim2.fromOffset(10, 10), 40)

		Kit.create("TextLabel", {
			Position = UDim2.fromOffset(62, 13), Size = UDim2.new(1, -280, 0, 16), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium), TextSize = 13, TextColor3 = Kit.INK,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = plr.DisplayName,
		}, row)
		Kit.create("TextLabel", {
			Position = UDim2.fromOffset(62, 33), Size = UDim2.new(1, -280, 0, 14), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans"), TextSize = 11, TextColor3 = Kit.FAINT,
			TextXAlignment = Enum.TextXAlignment.Left, Text = "@" .. plr.Name,
		}, row)

		local healthBar = Kit.create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -166, 0.5, 0), Size = UDim2.fromOffset(48, 4),
			BackgroundColor3 = Kit.TRACK, BorderSizePixel = 0,
		}, row)
		Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, healthBar)
		local healthFill = Kit.create("Frame", {
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(148, 162, 119), BorderSizePixel = 0,
		}, healthBar)
		Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, healthFill)

		local function pillButton(offsetX, glyph)
			local b = Kit.create("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, offsetX, 0.5, 0),
				Size = UDim2.fromOffset(22, 22), BackgroundColor3 = Kit.TRACK, AutoButtonColor = false,
				FontFace = Kit.face("BuilderSans"), TextSize = 12, TextColor3 = Kit.SUB, Text = glyph, BorderSizePixel = 0,
			}, row)
			Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, b)
			return b
		end

		local espBtn = pillButton(-96, "◎")
		espBtn.MouseButton1Click:Connect(function()
			Kit.Click()
			ESP.ForceOn[plr] = not ESP.ForceOn[plr] or nil
			espBtn.BackgroundColor3 = ESP.ForceOn[plr] and Kit.ACCENT or Kit.TRACK
		end)

		local tpBtn = pillButton(-68, "➤")
		tpBtn.MouseButton1Click:Connect(function()
			Kit.Click()
			local myRoot, theirRoot = Utils.GetRoot(LocalPlayer), Utils.GetRoot(plr)
			if myRoot and theirRoot then
				if Waypoints then Waypoints.Teleport(theirRoot.CFrame + Vector3.new(0, 3, 0)) else myRoot.CFrame = theirRoot.CFrame + Vector3.new(0, 3, 0) end
			end
		end)

		local markBtn = pillButton(-40, "★")
		markBtn.MouseButton1Click:Connect(function()
			Kit.Click()
			local marked = not AimAssist.Marked[plr]
			AimAssist.SetMark(plr, marked)
			markBtn.TextColor3 = marked and Kit.ACCENT or Kit.SUB
		end)

		if CameraTools then
			local watch = pillButton(-124, "")
			local icon = Kit.Icon("visuals", watch)
			icon.AnchorPoint = Vector2.new(0.5, 0.5); icon.Position = UDim2.fromScale(0.5, 0.5)
			watch.Activated:Connect(function()
				if ctx.Features.Freecam then ctx.Features.Freecam.SetActive(false) end
				local ok, err = CameraTools.Spectate(plr)
				if not ok then warn("[RiftHub] spectate: " .. tostring(err)) end
			end)
		end

		return { frame = row, health = healthFill }
	end

	function refreshPlayers(excluded)
		for _, info in pairs(rows) do info.frame:Destroy() end
		table.clear(rows)

		local list = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= excluded and (searchText == "" or plr.Name:lower():find(searchText, 1, true) or plr.DisplayName:lower():find(searchText, 1, true)) then
				table.insert(list, plr)
			end
		end

		local myRoot = Utils.GetRoot(LocalPlayer)
		table.sort(list, function(a, b)
			if sortMode == "Nearest" then
				local ra, rb = Utils.GetRoot(a), Utils.GetRoot(b)
				local da = (myRoot and ra) and Utils.Distance3D(myRoot.Position, ra.Position) or math.huge
				local db = (myRoot and rb) and Utils.Distance3D(myRoot.Position, rb.Position) or math.huge
				return da < db
			elseif sortMode == "Team" then
				return tostring(a.Team) < tostring(b.Team)
			elseif sortMode == "Health" then
				local ha, hb = Utils.GetHumanoid(a), Utils.GetHumanoid(b)
				return (ha and ha.Health or 0) > (hb and hb.Health or 0)
			end
			return a.Name:lower() < b.Name:lower()
		end)

		countLbl.Text = tostring(#list) .. " players"
		for i, plr in ipairs(list) do
			rows[plr] = makeRow(plr, i)
		end
	end

	ctx.Janitor.add(Players.PlayerAdded:Connect(function() refreshPlayers() end))
	ctx.Janitor.add(Players.PlayerRemoving:Connect(function(plr) headshots[plr.UserId] = nil; refreshPlayers(plr) end))
	ctx.Janitor.add(RunService.Heartbeat:Connect(function()
		for plr, info in pairs(rows) do
			local hum = Utils.GetHumanoid(plr)
			if hum then
				info.health.Size = UDim2.fromScale(math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1), 1)
			end
		end
	end))

	refreshPlayers()
end

local function buildServer(panel, ctx)
	local Kit = ctx.Kit
	local AntiAFK = ctx.Features.AntiAFK
	local ServerTools = ctx.Features.ServerTools
	local scroller = Kit.Scroller(panel)

	local session = Kit.Section(scroller, "Session", "⬡", 1)
	Kit.Toggle(session, "Anti-AFK", "Stops the 20-minute idle kick.", AntiAFK.Config.Enabled, function(v) AntiAFK.Config.Enabled = v end)

	local thisServer = Kit.Section(scroller, "This server", "▦", 2)
	Kit.Button(thisServer, "Rejoin", "Leave and come straight back.", "Rejoin", function()
		pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
	end)
	if ServerTools then
		local hopStatus = Kit.PlainRow(thisServer, "Server search", ServerTools.Status)
		Kit.Cycle(thisServer, "Choose server by", nil, { "Smallest", "Lowest ping", "Random" }, ServerTools.Config.Prefer, function(v) ServerTools.Config.Prefer = v end)
		Kit.Button(thisServer, "Server hop", "Searches other public servers with a free slot.", "Hop", function()
			task.spawn(function()
				local ok, err = ServerTools.Hop()
				if not ok then warn("[RiftHub] server hop: " .. tostring(err)) end
			end)
		end)
		ctx.Janitor.add(RunService.Heartbeat:Connect(function() hopStatus.Set(ServerTools.Status) end))
	end
	local fpsOptions = { "Unlimited", "240", "165", "144", "120", "60", "30" }
	Kit.Cycle(thisServer, "FPS limit", nil, fpsOptions, "Unlimited", function(v)
		pcall(function()
			if type(setfpscap) == "function" then
				setfpscap(v == "Unlimited" and 0 or tonumber(v))
			end
		end)
	end)

	local info = Kit.Section(scroller, "Server", "ⓘ", 3)
	Kit.Button(info, "Copy server ID", "A line that identifies this exact server.", "Copy", function()
		pcall(function() if type(setclipboard) == "function" then setclipboard(game.JobId) end end)
	end)
	Kit.Button(info, "Copy join script", "A line that lands in this exact server.", "Copy", function()
		pcall(function()
			if type(setclipboard) == "function" then
				setclipboard(string.format(
					'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, %q, game:GetService("Players").LocalPlayer)',
					game.PlaceId, game.JobId))
			end
		end)
	end)
	local playersRow = Kit.PlainRow(info, "Players", tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers))
	local upForRow = Kit.PlainRow(info, "Up for", "0:00")

	local serverStart = os.clock()
	local lastTick = 0
	ctx.Janitor.add(RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastTick < 1 then return end
		lastTick = now
		playersRow.Set(tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers))
		local elapsed = now - serverStart
		upForRow.Set(string.format("%d:%02d:%02d", math.floor(elapsed / 3600), math.floor(elapsed / 60) % 60, math.floor(elapsed % 60)))
	end))
end

local function buildSettings(panel, ctx)
	local Kit, Config = ctx.Kit, ctx.Config
	local scroller = Kit.Scroller(panel)

	local appearance = Kit.Section(scroller, "Appearance", "◐", 1)
	Kit.ColorRow(appearance, "Accent", "Changes apply live to anything drawn from now on.", {
		Kit.ACCENT, Kit.CANDLE, Color3.fromRGB(158, 174, 128),
		Color3.fromRGB(174, 140, 192), Color3.fromRGB(226, 211, 177), Kit.DANGER,
	}, Kit.ACCENT, function(c)
		Kit.ACCENT = c
		Config.Flags["Appearance.Accent"] = { c.R, c.G, c.B }
		ctx.RepaintChrome()
	end)
	Kit.Slider(appearance, "Interface size", "It never grows past the screen.", 70, 130, 100, {
		Suffix = "%", OnChanged = function(v) ctx.InterfaceScale = v / 100; ctx.FitWindow() end,
	})
	Kit.Slider(appearance, "Corner roundness", nil, 0, 24, 16, {
		OnChanged = function(v) ctx.CardCorner.CornerRadius = UDim.new(0, v) end,
	})
	Kit.Toggle(appearance, "Real blur", "Blurs the game behind the window.", false, function(v)
		ctx.Blur.Enabled = v
	end)
	Kit.Slider(appearance, "Blur size", nil, 4, 32, 18, {
		OnChanged = function(v) ctx.Blur.Size = v end,
	})
	Kit.Slider(appearance, "Glass", "How see-through the card is while open.", 0, 60, 6, {
		Suffix = "%", OnChanged = function(v)
			ctx.GlassAlpha = v / 100
			if ctx.IsVisible() then ctx.Card.BackgroundTransparency = ctx.GlassAlpha end
		end,
	})

	local motion = Kit.Section(scroller, "Motion & sound", "⚙", 2)
	Kit.Slider(motion, "Animation speed", nil, 50, 200, 100, {
		Suffix = "%", OnChanged = function(v) Kit.AnimSpeed = v / 100 end,
	})
	Kit.Toggle(motion, "Interface sounds", nil, Kit.SoundEnabled, function(v) Kit.SoundEnabled = v end)
	Kit.Slider(motion, "Sound volume", nil, 0, 100, Kit.SoundVolume * 100, {
		Suffix = "%", OnChanged = function(v) Kit.SoundVolume = v / 100 end,
	})

	local onscreen = Kit.Section(scroller, "On screen", "◫", 3)
	Kit.Toggle(onscreen, "The island", "Frame rate, ping, and a way back in, shown while the hub is hidden.", true, function(v)
		ctx.IslandEnabled = v
		if not v and ctx.Island then ctx.Island.Hide() end
	end)

	local access = Kit.Section(scroller, "Controls", "⌨", 4)
	Kit.KeybindRow(access, "Open / close the hub", nil, ctx.ToggleKey, function(kc) ctx.ToggleKey = kc end)
	Kit.Toggle(access, "Free the cursor while open", "Unlocks the mouse in first-person games.", true, function(v)
		ctx.FreeCursor = v
	end)


	local configs = Kit.Section(scroller, "Configs", "⌸", 5)
	Kit.Button(configs, "Copy settings", "Share a setup as text.", "Copy", function()
		pcall(function()
			local encoded = HttpService:JSONEncode(Config.Flags)
			if type(setclipboard) == "function" then setclipboard(encoded) end
		end)
	end)
	local _, pasteInput = Kit.SearchBox(configs.Body, "Paste settings, then Enter", nil)
	pasteInput.Parent.LayoutOrder = 99
	pasteInput.FocusLost:Connect(function(enterPressed)
		if not enterPressed or pasteInput.Text == "" then return end
		local ok, decoded = pcall(function() return HttpService:JSONDecode(pasteInput.Text) end)
		if ok and type(decoded) == "table" then
			for k, v in pairs(decoded) do Config.Flags[k] = v end
		end
		pasteInput.Text = ""
	end)
	Kit.Button(configs, "Reset every feature", "Appearance and keys are kept.", "Reset", function()
		for k in pairs(Config.Flags) do
			if not (k:match("^Appearance%.") or k:match("^Keys%.")) then
				Config.Flags[k] = nil
			end
		end
	end, { Danger = true })

	local about = Kit.Section(scroller, "About", "ⓘ", 6)
	local executorName = "Unknown"
	pcall(function()
		if type(identifyexecutor) == "function" then
			executorName = identifyexecutor()
		end
	end)
	Kit.PlainRow(about, "Version", "1.0.0")
	Kit.PlainRow(about, "Executor", executorName)
	Kit.PlainRow(about, "Place", ctx.PlaceName)
	Kit.PlainRow(about, "Started", os.date("%H:%M:%S", os.time()))
	Kit.Button(about, "Copy diagnostics", nil, "Copy", function()
		pcall(function()
			local diag = string.format(
				"Rift hub 1.0.0 | executor: %s | place: %s (%d) | players: %d/%d",
				executorName, ctx.PlaceName, game.PlaceId, #Players:GetPlayers(), Players.MaxPlayers)
			if type(setclipboard) == "function" then setclipboard(diag) end
		end)
	end)

	local danger = Kit.Section(scroller, "Unload", "⨯", 7)
	Kit.Button(danger, "Panic", "Turns off every feature. The window stays open.", "Panic", function()
		ctx.Panic()
	end, { Danger = true })
	Kit.Button(danger, "Unload Rift hub", "Unloads Rift instantly: every feature off, nothing left behind.", "Unload", function()
		ctx.Unload()
	end, { Danger = true })
end

----------------------------------------------------------------------
-- window shell
----------------------------------------------------------------------

-- keeps only JSON-safe values (drops Color3/Instance/function fields) so Config.Save never
-- fails outright because one nested field wasn't serializable
local function sanitizeConfig(tbl)
	local out = {}
	for k, v in pairs(tbl) do
		local t = typeof(v)
		if t == "boolean" or t == "number" or t == "string" then
			out[k] = v
		elseif t == "table" then
			out[k] = sanitizeConfig(v)
		end
	end
	return out
end

local NAV = {
	{ id = "home", label = "Home", icon = "home", build = buildHome },
	{ id = "hub", label = "Hub", icon = "hub", build = buildHub },
	{ id = "combat", label = "Combat", icon = "combat", group = "UNIVERSAL", build = buildCombat },
	{ id = "visuals", label = "Visuals", icon = "visuals", group = "UNIVERSAL", build = buildVisuals },
	{ id = "movement", label = "Movement", icon = "movement", group = "UNIVERSAL", build = buildMovement },
	{ id = "players", label = "Players", icon = "players", group = "UNIVERSAL", build = buildPlayers },
	{ id = "server", label = "Server", icon = "server", group = "UNIVERSAL", build = buildServer },
	{ id = "settings", label = "Settings", icon = "settings", build = buildSettings },
}

local function Open(opts)
	opts = opts or {}
	local Kit = opts.Kit
	local Utils = opts.Utils
	local Config = opts.Config
	local Features = opts.Features or {}

	-- restore last session's feature settings (if the executor's file API saved any) before
	-- any tab builds its controls, so sliders/toggles pick up the saved values as their default
	do
		local loaded = Config.Load("default")
		if loaded then
			for name, feature in pairs(Features) do
				local saved = Config.Flags[name]
				if saved and feature.Config then
					for k, v in pairs(saved) do
						if type(v) == type(feature.Config[k]) then
							feature.Config[k] = v
						end
					end
				end
			end
		end
		-- a feature whose "on" state only takes effect through an explicit setter call
		-- (Noclip, Fullbright, Freecam, Chams' painted highlights) rather than being
		-- read fresh every frame needs that setter re-run now, since the restore above
		-- lands after that feature's constructor already ran with the un-restored defaults
		for _, feature in pairs(Features) do
			if feature.Reconcile then pcall(feature.Reconcile) end
		end
	end

	local function persistSettings()
		for name, feature in pairs(Features) do
			if feature.Config then
				Config.Flags[name] = sanitizeConfig(feature.Config)
			end
		end
		Config.Save("default")
	end

	local OPEN_TIME, CLOSE_TIME = 0.22, 0.18

	local existing = GUI_PARENT:FindFirstChild("RiftHubWindow")
	if existing then existing:Destroy() end
	local existingIsland = GUI_PARENT:FindFirstChild("RiftIsland")
	if existingIsland then existingIsland:Destroy() end

	local janitor = Kit.newJanitor()

	local gui = Kit.create("ScreenGui", {
		Name = "RiftHubWindow", IgnoreGuiInset = true, ResetOnSpawn = false,
		DisplayOrder = 900, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	janitor.add(gui)

	local card = Kit.create("Frame", {
		Name = "Card", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(900, 580), BackgroundColor3 = Kit.BASE, BackgroundTransparency = 1,
		BorderSizePixel = 0, ClipsDescendants = true, Parent = gui,
	})
	local cardCorner = Kit.create("UICorner", { CornerRadius = UDim.new(0, 14) }, card)
	Kit.Surface(card)
	local rim = Kit.create("UIStroke", { Color = Kit.BORDER, Transparency = 1, Thickness = 1 }, card)
	local zoom = Kit.create("UIScale", { Scale = 0.94 }, card)

	local topBar = Kit.create("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = card })
	Kit.Web(topBar, 52, false)
	local seam = Kit.create("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Kit.ACCENT, BackgroundTransparency = 0.3, BorderSizePixel = 0,
	}, topBar)
	Kit.create("UIGradient", { Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.5), NumberSequenceKeypoint.new(1, 1),
	}) }, seam)

	local brand = Kit.create("Frame", {
		Name = "Brand", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 24, 0.5, 0), Size = UDim2.new(0, 0, 0, 24),
		AutomaticSize = Enum.AutomaticSize.X, Parent = topBar,
	})
	Kit.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6),
	}, brand)

	local faders = {}
	local function fade(instance, prop, visibleValue)
		table.insert(faders, { instance = instance, prop = prop, value = visibleValue })
		instance[prop] = 1
		return instance
	end

	local function label(name, text, font, size, color, props, parent)
		local item = Kit.create("TextLabel", {
			Name = name, BackgroundTransparency = 1, FontFace = font, TextSize = size, TextColor3 = color,
			Text = text, TextTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, TextXAlignment = Enum.TextXAlignment.Left,
		}, parent)
		for key, value in pairs(props or {}) do item[key] = value end
		fade(item, "TextTransparency", 0)
		return item
	end

	if opts.Brand then
		local logo = Kit.create("ImageLabel", { LayoutOrder = 0, Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1 }, brand)
		opts.Brand.Apply(logo)
		fade(logo, "ImageTransparency", 0)
	end
	label("Word", "RIFT", Kit.face("Merriweather", Enum.FontWeight.Bold), 23, Kit.INK, { LayoutOrder = 1 }, brand)
	local subWord = label("Sub", "hub", Kit.face("Merriweather", Enum.FontWeight.Regular, Enum.FontStyle.Italic), 18, Kit.CANDLE, { LayoutOrder = 2 }, brand)

	local function roundButton(name, glyph, offsetX)
		local btn = Kit.create("TextButton", {
			Name = name, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, offsetX, 0.5, 0),
			Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Kit.PANEL, BackgroundTransparency = 1,
			BorderSizePixel = 0, AutoButtonColor = false, Text = glyph,
			FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium), TextSize = 14, TextColor3 = Kit.SUB,
			TextTransparency = 1, Parent = topBar,
		})
		Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, btn)
		fade(btn, "BackgroundTransparency", 0.88)
		fade(btn, "TextTransparency", 0)
		return btn
	end
	local closeBtn = roundButton("Close", "×", -24)
	label("Season", "H A L L O W E E N", Kit.face("BuilderSans", Enum.FontWeight.Medium), 9, Kit.CANDLE,
		{ Position = UDim2.fromOffset(204, 22) }, topBar)
	local minimizeBtn = roundButton("Minimize", "_", -60)

	local sidebar = Kit.create("Frame", {
		Name = "Sidebar", Position = UDim2.fromOffset(0, 56), Size = UDim2.new(0, 190, 1, -56),
		BackgroundColor3 = Kit.PANEL, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = card,
	})
	fade(sidebar, "BackgroundTransparency", 0.3)

	local tabList = Kit.create("Frame", {
		Name = "Tabs", Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 1, -94),
		BackgroundTransparency = 1, Parent = sidebar,
	})
	Kit.create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, tabList)

	local profile = Kit.create("Frame", {
		Name = "Profile", Position = UDim2.new(0, 12, 1, -70), Size = UDim2.new(1, -24, 0, 58),
		BackgroundColor3 = Kit.BASE, BackgroundTransparency = 0.15, BorderSizePixel = 0,
	}, sidebar)
	Kit.create("UICorner", { CornerRadius = UDim.new(0, 10) }, profile)
	Kit.create("UIStroke", { Color = Kit.BORDER, Transparency = 0.35, Thickness = 1 }, profile)
	addHeadshot(Kit, profile, LocalPlayer, UDim2.fromOffset(10, 11), 36)
	Kit.create("TextLabel", {
		Position = UDim2.fromOffset(54, 11), Size = UDim2.new(1, -64, 0, 18), BackgroundTransparency = 1,
		FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium), TextSize = 12, TextColor3 = Kit.INK,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = LocalPlayer.DisplayName,
	}, profile)
	Kit.create("TextLabel", {
		Position = UDim2.fromOffset(54, 31), Size = UDim2.new(1, -64, 0, 15), BackgroundTransparency = 1,
		FontFace = Kit.face("BuilderSans"), TextSize = 10, TextColor3 = Kit.FAINT,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "@" .. LocalPlayer.Name,
	}, profile)
	local divider = Kit.create("Frame", {
		Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Kit.BORDER,
		BackgroundTransparency = 0.6, BorderSizePixel = 0,
	}, sidebar)

	local content = Kit.create("Frame", {
		Name = "Content", Position = UDim2.fromOffset(190, 56), Size = UDim2.new(1, -190, 1, -56),
		BackgroundTransparency = 1, ClipsDescendants = true, Parent = card,
	})

	local tabs, panels, activeTab = {}, {}, nil
	local order = 0

	local function selectTab(id)
		if activeTab == id or not tabs[id] then return end
		activeTab = id
		for tabId, entry in pairs(tabs) do
			local on = tabId == id
			panels[tabId].Visible = on
			Kit.tween(entry.indicator, { BackgroundTransparency = on and 0 or 1 }, 0.15)
			for _, f in ipairs(faders) do
				if f.instance == entry.indicator then f.value = on and 0 or 1 end
			end
			Kit.tween(entry.button, { BackgroundTransparency = on and 0.85 or 1 }, 0.15)
			Kit.tween(entry.glyph, { GroupColor3 = on and Kit.ACCENT or Kit.SUB }, 0.15)
			Kit.tween(entry.label, { TextColor3 = on and Kit.INK or Kit.SUB }, 0.15)
		end
	end

	for _, navItem in ipairs(NAV) do
		if navItem.group and tabList:FindFirstChild("Group_" .. navItem.group) == nil then
			order += 1
			Kit.create("TextLabel", {
				Name = "Group_" .. navItem.group, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1, FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium),
				TextSize = 10, TextColor3 = Kit.FAINT, TextXAlignment = Enum.TextXAlignment.Left,
				Text = navItem.group,
			}, tabList)
		end
		order += 1

		local btn = Kit.create("TextButton", {
			Name = navItem.id, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Kit.ACCENT,
			BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = tabList,
		})
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)

		local indicator = Kit.create("Frame", {
			Name = "ActiveMark", Position = UDim2.new(0, 0, 0.25, 0), Size = UDim2.new(0, 2, 0.5, 0),
			BackgroundColor3 = Kit.ACCENT, BackgroundTransparency = 1, BorderSizePixel = 0,
		}, btn)
		fade(indicator, "BackgroundTransparency", navItem.id == "home" and 0 or 1)
		local glyph = Kit.Icon(navItem.icon, btn)
		glyph.Name = "Glyph"
		glyph.AnchorPoint = Vector2.new(0, 0.5)
		glyph.Position = UDim2.new(0, 10, 0.5, 0)
		glyph.GroupColor3 = Kit.SUB
		fade(glyph, "GroupTransparency", 0)

		local labelText = Kit.create("TextLabel", {
			Name = "Label", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 36, 0.5, 0),
			Size = UDim2.new(1, -44, 1, 0), BackgroundTransparency = 1, FontFace = Kit.face("BuilderSans"),
			TextSize = 14, TextColor3 = Kit.SUB, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			Text = navItem.label, Parent = btn,
		})
		fade(labelText, "TextTransparency", 0)

		local panel = Kit.create("Frame", {
			Name = navItem.id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = content,
		})

		tabs[navItem.id] = { button = btn, glyph = glyph, label = labelText, indicator = indicator }
		panels[navItem.id] = panel
		janitor.add(btn.MouseButton1Click:Connect(function() selectTab(navItem.id) end))
	end
	panels[NAV[1].id].Visible = true
	activeTab = NAV[1].id
	Kit.tween(tabs[NAV[1].id].button, { BackgroundTransparency = 0.85 }, 0)
	Kit.tween(tabs[NAV[1].id].glyph, { GroupColor3 = Kit.ACCENT }, 0)
	Kit.tween(tabs[NAV[1].id].label, { TextColor3 = Kit.INK }, 0)

	do
		local dragging, dragStart, startPos
		janitor.add(topBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = card.Position
			end
		end))
		janitor.add(UserInputService.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - dragStart
				card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end))
		janitor.add(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))
	end

	local parented = pcall(function() gui.Parent = GUI_PARENT end)
	if not parented then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	local blur = Kit.create("BlurEffect", { Size = 18, Enabled = false }, Lighting)
	janitor.add(blur)

	local glassAlpha = 0.06
	local visible = false
	local setVisible -- forward-declared: the island's reopen button needs it before it's assigned

	local island = opts.Island and opts.Island(Kit, function()
		if setVisible then setVisible(true) end
	end, opts.Brand)

	local ctx = {
		Kit = Kit, Utils = Utils, Config = Config, Features = Features, Janitor = janitor,
		PlaceName = getPlaceName(), SessionStart = os.clock(), ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift,
		Card = card, CardCorner = cardCorner, Zoom = zoom, Blur = blur, Island = island,
		IslandEnabled = true, FreeCursor = true, GlassAlpha = glassAlpha,
		IsVisible = function() return visible end,
		IsHomeVisible = function() return activeTab == "home" end,
		HomeVideo = opts.HomeVideo, GameLibrary = opts.GameLibrary, InterfaceScale = 1,
		SelectTab = selectTab,
	}

	local fit = 1
	function ctx.FitWindow()
		local camera = workspace.CurrentCamera
		if not camera then return end
		local viewport = camera.ViewportSize
		fit = math.min(ctx.InterfaceScale, math.max(0.1, (viewport.X - 32) / 900), math.max(0.1, (viewport.Y - 32) / 580))
		zoom.Scale = fit * (visible and 1 or 0.94)
	end
	local lastViewport
	janitor.add(RunService.Heartbeat:Connect(function()
		local camera = workspace.CurrentCamera
		if camera and camera.ViewportSize ~= lastViewport then
			lastViewport = camera.ViewportSize
			ctx.FitWindow()
		end
	end))
	ctx.FitWindow()

	function ctx.RepaintChrome()
		subWord.TextColor3 = Kit.CANDLE
		rim.Color = Kit.BORDER
		if activeTab then
			Kit.tween(tabs[activeTab].glyph, { GroupColor3 = Kit.ACCENT }, 0.1)
			tabs[activeTab].indicator.BackgroundColor3 = Kit.ACCENT
		end
	end

	function ctx.SpawnBoom()
		local flash = Kit.create("Frame", {
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55,
			ZIndex = 50, Parent = gui,
		})
		Kit.tween(flash, { BackgroundTransparency = 1 }, 0.4)
		task.delay(0.45, function() flash:Destroy() end)
	end

	local function stopAllFeatures()
		for _, feature in pairs(Features) do
			if feature.Stop then pcall(feature.Stop) end
		end
	end

	function ctx.Panic()
		for _, feature in pairs(Features) do
			if feature.Panic then pcall(feature.Panic) end
		end
	end

	local handle
	local unloaded = false
	function ctx.Restart()
		if type(opts.OnRestart) == "function" then task.spawn(opts.OnRestart) end
	end
	function ctx.Unload()
		if unloaded then return end
		unloaded = true; visible = false
		persistSettings()
		ctx.Panic()
		stopAllFeatures()
		if Features.ESP and Features.ESP.Destroy then pcall(Features.ESP.Destroy) end
		if island then island.Destroy() end
		janitor.clean()
		if type(getgenv) == "function" then getgenv().__RiftHubLoaded = false end
	end

	for _, navItem in ipairs(NAV) do
		navItem.build(panels[navItem.id], ctx)
	end

	local function animateTo(isOpen, time)
		Kit.tween(card, { BackgroundTransparency = isOpen and ctx.GlassAlpha or 1 }, time)
		Kit.tween(rim, { Transparency = isOpen and 0.15 or 1 }, time)
		Kit.tween(zoom, { Scale = fit * (isOpen and 1 or 0.94) }, time, Enum.EasingStyle.Back)
		for _, f in ipairs(faders) do
			Kit.tween(f.instance, { [f.prop] = isOpen and f.value or 1 }, time)
		end
	end

	setVisible = function(isOpen)
		if unloaded then return end
		if visible == isOpen then return end
		visible = isOpen
		if isOpen then card.Visible = true end
		if not isOpen then
			task.delay(CLOSE_TIME, function() if not visible then card.Visible = false end end)
		end
		animateTo(isOpen, isOpen and OPEN_TIME or CLOSE_TIME)
		if ctx.FreeCursor then
			UserInputService.MouseIconEnabled = true
		end
		if island then
			if isOpen then island.Hide() elseif ctx.IslandEnabled then island.Show() end
		end
	end

	setVisible(true)

	janitor.add(closeBtn.MouseButton1Click:Connect(function()
		Kit.Click()
		setVisible(false)
		task.delay(CLOSE_TIME + 0.05, function()
			if not visible then ctx.Unload() end
		end)
	end))
	janitor.add(minimizeBtn.MouseButton1Click:Connect(function()
		Kit.Click()
		setVisible(not visible)
	end))
	janitor.add(UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == ctx.ToggleKey then
			setVisible(not visible)
		end
	end))

	handle = {
		Gui = gui,
		SelectTab = selectTab,
		SetVisible = setVisible,
		Features = Features,
		Unload = ctx.Unload,
		Close = function()
			setVisible(false)
			task.delay(CLOSE_TIME + 0.05, function() ctx.Unload() end)
		end,
	}
	return handle
end

return Open
