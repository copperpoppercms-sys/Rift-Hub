-- Luau | Roblox | Xeno/Synapse-class executor | shared palette + widget kit for the Rift hub UI
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = {}

-- Midnight charcoal, bone lettering, blood red, and candlelight orange.
Kit.BASE, Kit.INK, Kit.SUB, Kit.FAINT, Kit.ACCENT = Color3.fromRGB(13, 12, 14), Color3.fromRGB(234, 224, 203),
	Color3.fromRGB(181, 165, 151), Color3.fromRGB(144, 129, 121), Color3.fromRGB(176, 49, 43)
Kit.PANEL = Color3.fromRGB(23, 19, 21)
Kit.TRACK = Color3.fromRGB(44, 31, 33)
Kit.BORDER = Color3.fromRGB(83, 48, 46)
Kit.DANGER = Color3.fromRGB(233, 98, 76)
Kit.CANDLE = Color3.fromRGB(208, 132, 64)
Kit.VOID = Color3.fromRGB(8, 8, 10)

-- animation speed scales every tween this kit produces; Settings > Motion & sound > Animation speed writes here
Kit.AnimSpeed = 1
Kit.SoundEnabled = true
Kit.SoundVolume = 0.6

-- best-effort UI click using a built-in engine sound asset; a missing/blocked asset just stays silent
function Kit.Click()
	if not Kit.SoundEnabled then return end
	pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		s.Volume = Kit.SoundVolume
		s.PlaybackSpeed = 0.7
		s.Parent = game:GetService("SoundService")
		s:Play()
		game:GetService("Debris"):AddItem(s, 2)
	end)
end

function Kit.face(name, weight, style)
	local ok, made = pcall(Font.fromName, name, weight or Enum.FontWeight.Regular, style or Enum.FontStyle.Normal)
	return ok and made or Font.fromEnum(Enum.Font.Gotham)
end

function Kit.create(class, props, parent)
	local item = Instance.new(class)
	for key, value in pairs(props) do item[key] = value end
	if parent then item.Parent = parent end
	return item
end

function Kit.tween(instance, props, time, style, dir)
	local scaled = (time or 0.15) / math.max(Kit.AnimSpeed, 0.05)
	local info = TweenInfo.new(scaled, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(instance, info, props)
	t:Play()
	return t
end

-- Static vector details: no image downloads, animation loops, or flashing overlays.
function Kit.Surface(parent)
	return Kit.create("UIGradient", {
		Rotation = 115,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 247, 236)),
			ColorSequenceKeypoint.new(0.58, Color3.fromRGB(204, 189, 191)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(155, 122, 129)),
		}),
	}, parent)
end

function Kit.Web(parent, size, right)
	local web = Kit.create("Frame", {
		Name = "CornerWeb", Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(right and 1 or 0, 0), Position = UDim2.new(right and 1 or 0, 0, 0, 0),
		Active = false, ZIndex = 1,
	}, parent)
	local function line(x1, y1, x2, y2)
		if right then x1, x2 = size - x1, size - x2 end
		local dx, dy = x2 - x1, y2 - y1
		Kit.create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2),
			Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), 1), Rotation = math.deg(math.atan2(dy, dx)),
			BackgroundColor3 = Kit.INK, BackgroundTransparency = 0.90, BorderSizePixel = 0,
			Active = false, ZIndex = 1,
		}, web)
	end
	local rays = { 0, math.pi / 8, math.pi / 4, 3 * math.pi / 8, math.pi / 2 }
	for _, angle in ipairs(rays) do line(0, 0, math.cos(angle) * size, math.sin(angle) * size) end
	for _, radius in ipairs({ size * 0.24, size * 0.48, size * 0.74, size }) do
		for i = 1, #rays - 1 do
			line(math.cos(rays[i]) * radius, math.sin(rays[i]) * radius,
				math.cos(rays[i + 1]) * radius, math.sin(rays[i + 1]) * radius)
		end
	end
	return web
end

-- Sidebar line icons share one stroke weight and tint without relying on fonts.
function Kit.Icon(name, parent)
	local icon = Kit.create("CanvasGroup", {
		Name = name .. "Icon", Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1,
		GroupColor3 = Kit.SUB, GroupTransparency = 0, Active = false,
	}, parent)
	local white = Color3.new(1, 1, 1)
	local function line(x1, y1, x2, y2, width)
		local dx, dy = x2 - x1, y2 - y1
		local part = Kit.create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2),
			Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), width or 1.6),
			Rotation = math.deg(math.atan2(dy, dx)), BackgroundColor3 = white, BorderSizePixel = 0,
			Active = false,
		}, icon)
		Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, part)
	end
	local function circle(x, y, diameter, hollow)
		local part = Kit.create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(diameter, diameter), BackgroundColor3 = white,
			BackgroundTransparency = hollow and 1 or 0, BorderSizePixel = 0, Active = false,
		}, icon)
		Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, part)
		if hollow then Kit.create("UIStroke", { Color = white, Thickness = 1.5 }, part) end
	end
	local function person(x, top, scale)
		local function segment(x1, y1, x2, y2)
			line(x + x1 * scale, top + y1 * scale, x + x2 * scale, top + y2 * scale, 1.5 * scale)
		end
		circle(x, top + 2 * scale, 3.6 * scale)
		segment(0, 5, 0, 10)
		segment(0, 5.5, -3.2, 8.5); segment(0, 5.5, 3.2, 8.5)
		segment(0, 10, -2.7, 16.5); segment(0, 10, 2.7, 16.5)
	end
	if name == "hub" then
		for _, xy in ipairs({ {5, 5}, {15, 5}, {5, 15}, {15, 15} }) do
			local part = Kit.create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(xy[1], xy[2]),
				Size = UDim2.fromOffset(5, 5), BackgroundTransparency = 1, BorderSizePixel = 0, Active = false,
			}, icon)
			Kit.create("UICorner", { CornerRadius = UDim.new(0, 1) }, part)
			Kit.create("UIStroke", { Color = white, Thickness = 1.5 }, part)
		end
	elseif name == "combat" then
		circle(10, 10, 11, true); circle(10, 10, 2)
		line(10, 1, 10, 6); line(10, 14, 10, 19)
		line(1, 10, 6, 10); line(14, 10, 19, 10)
	elseif name == "visuals" then
		local points = { {1.5, 10}, {4, 6.5}, {7, 4.5}, {10, 4}, {13, 4.5}, {16, 6.5}, {18.5, 10} }
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			line(a[1], a[2], b[1], b[2]); line(a[1], 20 - a[2], b[1], 20 - b[2])
		end
		circle(10, 10, 5)
	elseif name == "movement" then
		circle(12, 3, 3.6)
		line(10.7, 6.3, 9, 11.5)
		line(10.7, 7, 7, 7.2); line(7, 7.2, 5.5, 4.8)
		line(10.7, 7, 14.2, 9); line(14.2, 9, 16, 6.8)
		line(9, 11.5, 6, 14); line(6, 14, 3, 13.5)
		line(9, 11.5, 13, 14.5); line(13, 14.5, 12, 18.5)
	elseif name == "players" then
		person(10, 1, 1)
	elseif name == "server" then
		person(4.5, 5, 0.63); person(15.5, 5, 0.63); person(10, 1.5, 0.85)
	elseif name == "settings" then
		for i = 0, 7 do
			local angle = i * math.pi / 4
			Kit.create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(10 + math.cos(angle) * 7.2, 10 + math.sin(angle) * 7.2),
				Size = UDim2.fromOffset(2.8, 3.7), Rotation = math.deg(angle) + 90,
				BackgroundColor3 = white, BorderSizePixel = 0, Active = false,
			}, icon)
		end
		circle(10, 10, 12, true); circle(10, 10, 4.5, true)
	else
		line(2, 9, 10, 2); line(10, 2, 18, 9)
		line(4, 8, 4, 18); line(16, 8, 16, 18); line(4, 18, 16, 18)
		line(8, 18, 8, 12); line(8, 12, 12, 12); line(12, 12, 12, 18)
	end
	return icon
end

function Kit.newJanitor()
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

----------------------------------------------------------------------
-- layout primitives
----------------------------------------------------------------------

-- vertical scrolling column a tab panel's content lives in
function Kit.Scroller(parent)
	local scroller = Kit.create("ScrollingFrame", {
		Name = "Scroller",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Kit.ACCENT,
		CanvasSize = UDim2.fromScale(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	Kit.create("UIPadding", {
		PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20),
		PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 20),
	}, scroller)
	Kit.create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 12),
	}, scroller)
	return scroller
end

-- rounded dark card with a header (glyph + title) and a body list rows get added to
function Kit.Section(parent, title, glyph, order)
	local card = Kit.create("Frame", {
		Name = title,
		LayoutOrder = order or 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Kit.PANEL,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Kit.create("UICorner", { Name = "Corner", CornerRadius = UDim.new(0, 10) }, card)
	Kit.Surface(card)
	Kit.create("UIStroke", { Color = Kit.BORDER, Transparency = 0.48, Thickness = 1 }, card)
	Kit.create("UIPadding", {
		PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14),
	}, card)
	Kit.create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }, card)

	local header = Kit.create("Frame", {
		Name = "Header", LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
	}, card)
	if glyph then
		Kit.create("TextLabel", {
			Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium),
			TextSize = 13, TextColor3 = Kit.CANDLE, Text = glyph,
		}, header)
	end
	Kit.create("TextLabel", {
		Position = UDim2.new(0, glyph and 24 or 0, 0, 0),
		Size = UDim2.new(1, glyph and -24 or 0, 1, 0),
		BackgroundTransparency = 1,
		FontFace = Kit.face("Merriweather", Enum.FontWeight.Bold),
		TextSize = 15, TextColor3 = Kit.INK, TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
	}, header)

	local body = Kit.create("Frame", {
		Name = "Body", LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, card)
	Kit.create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) }, body)

	return { Frame = card, Body = body, _order = 0 }
end

-- a single row: left name+desc block, right control slot. returns the right slot to populate.
function Kit.Row(section, name, desc)
	section._order = section._order + 1
	local row = Kit.create("Frame", {
		LayoutOrder = section._order,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, section.Body)

	local left = Kit.create("Frame", {
		Size = UDim2.new(0.56, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, row)
	Kit.create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, left)
	Kit.create("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium),
		TextSize = 13, TextColor3 = Kit.INK, TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true, Text = name,
	}, left)
	if desc then
		Kit.create("TextLabel", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, FontFace = Kit.face("BuilderSans"),
			TextSize = 11, TextColor3 = Kit.FAINT, TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true, Text = desc,
		}, left)
	end

	local right = Kit.create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0.44, -8, 0, 24),
		BackgroundTransparency = 1,
	}, row)
	Kit.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
	}, right)

	return row, right
end

----------------------------------------------------------------------
-- controls
----------------------------------------------------------------------

function Kit.Toggle(section, name, desc, default, onChanged)
	local _, right = Kit.Row(section, name, desc)
	local track = Kit.create("TextButton", {
		Size = UDim2.fromOffset(38, 20), BackgroundColor3 = Kit.TRACK, AutoButtonColor = false,
		Text = "", BorderSizePixel = 0,
	}, right)
	Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
	Kit.create("UIStroke", { Color = Kit.BORDER, Transparency = 0.25, Thickness = 1 }, track)
	local knob = Kit.create("Frame", {
		Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = Kit.SUB, BorderSizePixel = 0,
	}, track)
	Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

	local state = default and true or false
	local function paint(instant)
		local t = instant and 0 or 0.12
		Kit.tween(track, { BackgroundColor3 = state and Kit.ACCENT or Kit.TRACK }, t)
		Kit.tween(knob, { Position = state and UDim2.new(1, -18, 0, 2) or UDim2.fromOffset(2, 2), BackgroundColor3 = state and Kit.INK or Kit.SUB }, t)
	end
	paint(true)

	track.MouseButton1Click:Connect(function()
		Kit.Click()
		state = not state
		paint(false)
		if onChanged then onChanged(state) end
	end)

	return {
		Get = function() return state end,
		Set = function(v) state = v and true or false; paint(false) end,
	}
end

function Kit.Slider(section, name, desc, min, max, default, opts)
	opts = opts or {}
	local onChanged = opts.OnChanged
	local decimals = opts.Decimals or 0
	local suffix = opts.Suffix or ""
	local format = opts.Format

	local _, right = Kit.Row(section, name, desc)
	local valueLabel = Kit.create("TextLabel", {
		Size = UDim2.fromOffset(56, 20), BackgroundTransparency = 1,
		FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium),
		TextSize = 12, TextColor3 = Kit.SUB, TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
	}, right)
	local track = Kit.create("Frame", {
		Size = UDim2.new(0, 110, 0, 4), BackgroundColor3 = Kit.TRACK, BorderSizePixel = 0,
	}, right)
	Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
	local fill = Kit.create("Frame", {
		Size = UDim2.fromScale(0, 1), BackgroundColor3 = Kit.ACCENT, BorderSizePixel = 0,
	}, track)
	Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	local knob = Kit.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Kit.INK, BorderSizePixel = 0,
		ZIndex = 2,
	}, track)
	Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

	local value = math.clamp(default or min, min, max)
	local mult = 10 ^ decimals

	local function render()
		local alpha = (value - min) / math.max(max - min, 1e-6)
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.fromScale(alpha, 0.5)
		if format then
			valueLabel.Text = format(value)
		else
			local shown = math.floor(value * mult + 0.5) / mult
			valueLabel.Text = (decimals > 0 and string.format("%." .. decimals .. "f", shown) or tostring(math.floor(shown))) .. suffix
		end
	end
	render()

	local function setFromAlpha(alpha)
		alpha = math.clamp(alpha, 0, 1)
		value = min + (max - min) * alpha
		render()
		if onChanged then onChanged(value) end
	end

	local dragging = false
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromAlpha((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
		end
	end)
	local changed = UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			setFromAlpha((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
		end
	end)
	local ended = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	track.Destroying:Connect(function()
		dragging = false; changed:Disconnect(); ended:Disconnect()
	end)

	return {
		Get = function() return value end,
		Set = function(v) value = math.clamp(v, min, max); render() end,
	}
end

function Kit.Segmented(section, name, desc, options, default, onChanged)
	local _, right = Kit.Row(section, name, desc)
	right.Size = UDim2.new(0.44, -8, 0, 24)
	local buttons = {}
	local current = default or options[1]

	local function paint()
		for opt, btn in pairs(buttons) do
			local on = opt == current
			Kit.tween(btn, { BackgroundTransparency = on and 0 or 1 }, 0.1)
			btn.TextLabel.TextColor3 = on and Kit.INK or Kit.SUB
		end
	end

	for _, opt in ipairs(options) do
		local btn = Kit.create("TextButton", {
			Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Kit.ACCENT, BackgroundTransparency = 1, AutoButtonColor = false,
			Text = "", BorderSizePixel = 0,
		}, right)
		Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, btn)
		Kit.create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, btn)
		local lbl = Kit.create("TextLabel", {
			Name = "TextLabel", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium),
			TextSize = 12, TextColor3 = Kit.SUB, Text = opt,
		}, btn)
		buttons[opt] = btn
		btn.MouseButton1Click:Connect(function()
			if current == opt then return end
			Kit.Click()
			current = opt
			paint()
			if onChanged then onChanged(current) end
		end)
	end
	paint()

	return {
		Get = function() return current end,
		Set = function(v) current = v; paint() end,
	}
end

function Kit.Cycle(section, name, desc, options, default, onChanged)
	local _, right = Kit.Row(section, name, desc)
	local idx = 1
	for i, v in ipairs(options) do
		if v == default then idx = i break end
	end

	local function arrow(glyph)
		local b = Kit.create("TextButton", {
			Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Kit.TRACK, AutoButtonColor = false,
			FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium), TextSize = 11,
			TextColor3 = Kit.SUB, Text = glyph, BorderSizePixel = 0,
		}, right)
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
		return b
	end

	local left = arrow("<")
	local label = Kit.create("TextLabel", {
		Size = UDim2.fromOffset(84, 20), BackgroundTransparency = 1,
		FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium),
		TextSize = 12, TextColor3 = Kit.INK, Text = tostring(options[idx]),
	}, right)
	local rightBtn = arrow(">")

	local function render() label.Text = tostring(options[idx]) end
	local function step(dir)
		Kit.Click()
		idx = ((idx - 1 + dir) % #options) + 1
		render()
		if onChanged then onChanged(options[idx]) end
	end
	left.MouseButton1Click:Connect(function() step(-1) end)
	rightBtn.MouseButton1Click:Connect(function() step(1) end)

	return {
		Get = function() return options[idx] end,
		Set = function(v)
			for i, o in ipairs(options) do if o == v then idx = i break end end
			render()
		end,
	}
end

function Kit.Button(section, name, desc, buttonText, onClick, opts)
	opts = opts or {}
	local _, right = Kit.Row(section, name, desc)
	local btn = Kit.create("TextButton", {
		Size = UDim2.new(0, 0, 0, 26), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = opts.Danger and Kit.DANGER or Kit.ACCENT,
		BackgroundTransparency = opts.Danger and 0.85 or 0.1,
		AutoButtonColor = false, BorderSizePixel = 0,
		FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium),
		TextSize = 12, TextColor3 = opts.Danger and Kit.DANGER or Kit.INK, Text = buttonText,
	}, right)
	Kit.create("UICorner", { CornerRadius = UDim.new(0, 7) }, btn)
	Kit.create("UIStroke", { Color = Kit.BORDER, Transparency = 0.25, Thickness = 1 }, btn)
	Kit.create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, btn)
	btn.MouseButton1Click:Connect(function()
		Kit.Click()
		if onClick then onClick() end
	end)
	return btn
end

function Kit.PlainRow(section, name, value)
	local _, right = Kit.Row(section, name, nil)
	local lbl = Kit.create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
		FontFace = Kit.face("BuilderSans"), TextSize = 12, TextColor3 = Kit.SUB,
		TextXAlignment = Enum.TextXAlignment.Right, Text = tostring(value),
	}, right)
	return { Set = function(v) lbl.Text = tostring(v) end }
end

function Kit.ColorRow(section, name, desc, colors, default, onChanged)
	local _, right = Kit.Row(section, name, desc)
	local current = default or colors[1]
	local swatches = {}
	for _, color in ipairs(colors) do
		local dot = Kit.create("TextButton", {
			Size = UDim2.fromOffset(18, 18), BackgroundColor3 = color, AutoButtonColor = false,
			Text = "", BorderSizePixel = 0,
		}, right)
		Kit.create("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
		local ring = Kit.create("UIStroke", { Color = Kit.INK, Thickness = 2, Transparency = 1 }, dot)
		swatches[dot] = { color = color, ring = ring }
		dot.MouseButton1Click:Connect(function()
			current = color
			for d, info in pairs(swatches) do info.ring.Transparency = (info.color == current) and 0 or 1 end
			if onChanged then onChanged(current) end
		end)
	end
	for d, info in pairs(swatches) do info.ring.Transparency = (info.color == current) and 0 or 1 end
	return { Get = function() return current end }
end

function Kit.KeybindRow(section, name, desc, default, onChanged)
	local _, right = Kit.Row(section, name, desc)
	local btn = Kit.create("TextButton", {
		Size = UDim2.fromOffset(72, 22), BackgroundColor3 = Kit.TRACK, AutoButtonColor = false,
		FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium), TextSize = 11,
		TextColor3 = Kit.INK, Text = default and default.Name or "None", BorderSizePixel = 0,
	}, right)
	Kit.create("UICorner", { CornerRadius = UDim.new(0, 7) }, btn)
	Kit.create("UIStroke", { Color = Kit.BORDER, Transparency = 0.25, Thickness = 1 }, btn)

	local listening = false
	local current = default
	btn.MouseButton1Click:Connect(function()
		listening = true
		btn.Text = "..."
	end)
	local inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if not listening then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			current = input.KeyCode
			btn.Text = current.Name
			if onChanged then onChanged(current) end
		end
	end)

	btn.Destroying:Connect(function()
		listening = false; inputConnection:Disconnect()
	end)

	return {
		Get = function() return current end,
		Set = function(kc) current = kc; btn.Text = kc and kc.Name or "None" end,
	}
end

function Kit.SearchBox(parent, placeholder, onChanged)
	local box = Kit.create("Frame", {
		Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Kit.PANEL, BackgroundTransparency = 0.3, BorderSizePixel = 0,
	}, parent)
	Kit.create("UICorner", { CornerRadius = UDim.new(0, 8) }, box)
	Kit.create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, box)
	local input = Kit.create("TextBox", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		FontFace = Kit.face("BuilderSans"), TextSize = 12, TextColor3 = Kit.INK,
		PlaceholderText = placeholder, PlaceholderColor3 = Kit.FAINT,
		Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
	}, box)
	input:GetPropertyChangedSignal("Text"):Connect(function()
		if onChanged then onChanged(input.Text) end
	end)
	return box, input
end

return Kit
