-- Luau | Roblox | Xeno/Synapse-class executor | the minimized FPS/ping pill shown while the hub is hidden
return function(Kit, onReopen, Brand)
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Stats = game:GetService("Stats")
	local GUI_PARENT = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")

	local gui = Kit.create("ScreenGui", {
		Name = "RiftIsland", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 899,
	})
	local parented = pcall(function() gui.Parent = GUI_PARENT end)
	if not parented then
		gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	end

	local pill = Kit.create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Kit.PANEL,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Visible = false,
		Parent = gui,
	})
	Kit.create("UICorner", { CornerRadius = UDim.new(0, 10) }, pill)
	Kit.Surface(pill)
	Kit.create("UIStroke", { Color = Kit.BORDER, Transparency = 0.2, Thickness = 1 }, pill)
	Kit.create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, pill)

	local row = Kit.create("Frame", {
		Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
	}, pill)
	Kit.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, row)

	local function stat(text, color, order)
		return Kit.create("TextLabel", {
			LayoutOrder = order, Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1, FontFace = Kit.face("BuilderExtended", Enum.FontWeight.Bold),
			TextSize = 13, TextColor3 = color, Text = text,
		}, row)
	end

	if Brand then
		local mark = Kit.create("Frame", {LayoutOrder=1,Size=UDim2.fromOffset(24,24),BackgroundTransparency=1}, row)
		local fallback = Kit.create("TextLabel", {Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="R",TextSize=19,
			Font=Enum.Font.GothamBold,TextColor3=Kit.INK}, mark)
		local image = Kit.create("ImageLabel", {Size=UDim2.fromScale(1,1),BackgroundTransparency=1}, mark)
		Brand.Apply(image, fallback)
	else stat("RIFT", Kit.CANDLE, 1) end
	local fpsLbl = stat("60 fps", Kit.SUB, 2)
	local msLbl = stat("16 ms", Kit.SUB, 3)
	local chevron = Kit.create("TextButton", {
		LayoutOrder = 4, Size = UDim2.fromOffset(16, 20), BackgroundTransparency = 1, AutoButtonColor = false,
		FontFace = Kit.face("BuilderSans", Enum.FontWeight.Medium), TextSize = 12, TextColor3 = Kit.FAINT, Text = "v",
	}, row)
	chevron.MouseButton1Click:Connect(function()
		if onReopen then onReopen() end
	end)

	do
		local dragging, dragStart, startPos
		pill.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = pill.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - dragStart
				pill.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end

	local frames, lastSecond = 0, os.clock()
	local heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		frames += 1
		local now = os.clock()
		if now - lastSecond >= 1 then
			fpsLbl.Text = tostring(frames) .. " fps"
			lastSecond = now
			frames = 0
		end
		local ok, ping = pcall(function()
			return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
		end)
		msLbl.Text = string.format("%.0f ms", ok and ping or dt * 1000)
	end)

	local M = {}
	function M.Show() pill.Visible = true end
	function M.Hide() pill.Visible = false end
	function M.Destroy()
		heartbeatConn:Disconnect()
		gui:Destroy()
	end
	return M
end
