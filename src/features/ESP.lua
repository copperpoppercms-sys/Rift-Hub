-- Luau | Roblox | Xeno/Synapse-class executor | screen-space player ESP (box/name/distance/tracer)
return function(Utils)
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer

	local GUI_PARENT = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")

	local M = {}
	M.Config = {
		Enabled = false,
		Elements = { Box = true, Name = true, Distance = true, Tracer = true },
		BoxStyle = "Corners", -- "Corners" | "Full"
		FillBox = false,
		BoxWidthPct = 55,
		TracerOrigin = "Bottom", -- "Bottom" | "Centre" | "Top" | "Mouse"
		ColorBy = "One colour", -- "One colour" | "Friends" | "Team"
		Color = Color3.fromRGB(142, 125, 255),
		FriendColor = Color3.fromRGB(100, 220, 140),
		SelfColor = Color3.fromRGB(245, 220, 100),
	}
	M.ForceOn = {}

	local gui = Instance.new("ScreenGui")
	gui.Name = "RiftESP"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 850
	local parented = pcall(function() gui.Parent = GUI_PARENT end)
	if not parented then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	local rows = {}
	local renderConn, removingConn

	local function colorFor(plr)
		if plr == LocalPlayer then return M.Config.SelfColor end
		if M.Config.ColorBy == "Friends" then
			local ok, friends = pcall(LocalPlayer.IsFriendsWith, LocalPlayer, plr.UserId)
			if ok and friends then return M.Config.FriendColor end
		end
		return M.Config.Color
	end

	local function makeRow(plr)
		local holder = Instance.new("Frame")
		holder.Name = plr.Name
		holder.BackgroundTransparency = 1
		holder.BorderSizePixel = 0
		holder.Visible = false
		holder.Parent = gui

		local box = Instance.new("Frame")
		box.BackgroundTransparency = 1
		box.BorderSizePixel = 0
		box.Parent = holder
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Parent = box

		local nameLbl = Instance.new("TextLabel")
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 13
		nameLbl.TextColor3 = Color3.new(1, 1, 1)
		nameLbl.TextStrokeTransparency = 0.4
		nameLbl.Text = plr.Name
		nameLbl.Parent = holder

		local distLbl = Instance.new("TextLabel")
		distLbl.BackgroundTransparency = 1
		distLbl.Font = Enum.Font.Gotham
		distLbl.TextSize = 12
		distLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
		distLbl.TextStrokeTransparency = 0.4
		distLbl.Parent = holder

		local tracer = Instance.new("Frame")
		tracer.AnchorPoint = Vector2.new(0, 0.5)
		tracer.BorderSizePixel = 0
		tracer.Parent = holder

		return { holder = holder, box = box, stroke = stroke, name = nameLbl, dist = distLbl, tracer = tracer }
	end

	local function update(plr, el)
		local on = M.Config.Enabled or M.ForceOn[plr]
		if not on then
			el.holder.Visible = false
			return
		end

		local head, root = Utils.GetHead(plr), Utils.GetRoot(plr)
		if not head or not root then
			el.holder.Visible = false
			return
		end

		local topPos, topOn = Utils.WorldToScreen(head.Position + Vector3.new(0, 0.6, 0))
		local botPos, botOn = Utils.WorldToScreen(root.Position - Vector3.new(0, 3, 0))
		if not topOn and not botOn then
			el.holder.Visible = false
			return
		end

		local height = math.max(botPos.Y - topPos.Y, 4)
		local width = height * (M.Config.BoxWidthPct / 100)
		local boxX, boxY = topPos.X - width / 2, topPos.Y

		el.holder.Visible = true
		local color = colorFor(plr)

		if M.Config.Elements.Box then
			el.box.Visible = true
			el.box.Position = UDim2.fromOffset(boxX, boxY)
			el.box.Size = UDim2.fromOffset(width, height)
			el.box.BackgroundTransparency = M.Config.FillBox and 0.75 or 1
			el.box.BackgroundColor3 = color
			el.stroke.Color = color
			el.stroke.Transparency = (M.Config.BoxStyle == "Full") and 0 or 0.1
		else
			el.box.Visible = false
		end

		if M.Config.Elements.Name then
			el.name.Visible = true
			el.name.Size = UDim2.fromOffset(width, 16)
			el.name.Position = UDim2.fromOffset(boxX, boxY - 18)
			el.name.Text = plr.DisplayName
		else
			el.name.Visible = false
		end

		if M.Config.Elements.Distance then
			local dist = Utils.Distance3D(Utils.Camera.CFrame.Position, root.Position)
			el.dist.Visible = true
			el.dist.Size = UDim2.fromOffset(width, 14)
			el.dist.Position = UDim2.fromOffset(boxX, boxY + height + 2)
			el.dist.Text = tostring(Utils.Round(dist)) .. " st"
		else
			el.dist.Visible = false
		end

		if M.Config.Elements.Tracer then
			local viewport = Utils.Camera.ViewportSize
			local origin
			if M.Config.TracerOrigin == "Top" then
				origin = Vector2.new(viewport.X / 2, 0)
			elseif M.Config.TracerOrigin == "Centre" then
				origin = Vector2.new(viewport.X / 2, viewport.Y / 2)
			elseif M.Config.TracerOrigin == "Mouse" then
				origin = UserInputService:GetMouseLocation()
			else
				origin = Vector2.new(viewport.X / 2, viewport.Y)
			end
			local target = Vector2.new(boxX + width / 2, boxY + height)
			local delta = target - origin
			el.tracer.Visible = true
			el.tracer.Position = UDim2.fromOffset(origin.X, origin.Y)
			el.tracer.Size = UDim2.fromOffset(delta.Magnitude, 1)
			el.tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
			el.tracer.BackgroundColor3 = color
		else
			el.tracer.Visible = false
		end
	end

	renderConn = RunService.RenderStepped:Connect(function()
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer or M.ForceOn[plr] then
				if not rows[plr] then rows[plr] = makeRow(plr) end
				update(plr, rows[plr])
			end
		end
		for plr, el in pairs(rows) do
			if not plr.Parent then
				el.holder:Destroy()
				rows[plr] = nil
			end
		end
	end)

	removingConn = Players.PlayerRemoving:Connect(function(plr)
		if rows[plr] then
			rows[plr].holder:Destroy()
			rows[plr] = nil
		end
	end)

	function M.Panic()
		M.Config.Enabled = false
		table.clear(M.ForceOn)
	end

	function M.Stop()
		if renderConn then renderConn:Disconnect() renderConn = nil end
		if removingConn then removingConn:Disconnect() removingConn = nil end
	end

	function M.Destroy()
		M.Stop()
		gui:Destroy()
	end

	return M
end
