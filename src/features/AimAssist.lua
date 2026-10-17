-- Luau | Roblox | Xeno/Synapse-class executor | camera-based aim assist
return function(Utils)
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local M = {}
	M.Config = {
		Active = false,
		Mode = "While held", -- "While held" | "Toggle" | "Always"
		AimAt = "Head", -- "Head" | "Root"
		PickBy = "Crosshair", -- "Crosshair" | "You" | "Lowest health"
		FOV = 100,
		Range = 3000,
		StayOnTarget = true,
		WaitBeforeNext = 0,
		OnlyMarked = false,
		Smoothing = 0,
		SmoothSeparate = false,
		MouseStrength = 5,
		DeadZone = 0,
		Silent = false, -- snap only at the moment of a click instead of tracking continuously
		ShowFOV = false,
	}
	M.Marked = {}

	local GUI_PARENT = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
	local toggledOn = false
	local currentTarget, lastSwitchTime = nil, 0
	local conn, inputConn

	local function keyHeld()
		local mode = M.Config.Mode
		if mode == "Always" then return true end
		if mode == "Toggle" then return toggledOn end
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	end

	local function eligiblePlayers()
		local list = Utils.GetTargets(false)
		if not M.Config.OnlyMarked then return list end
		local filtered = {}
		for _, p in ipairs(list) do
			if M.Marked[p] then table.insert(filtered, p) end
		end
		return filtered
	end

	local function scoreFor(plr, mousePos)
		local part = (M.Config.AimAt == "Head") and Utils.GetHead(plr) or Utils.GetRoot(plr)
		if not part then return nil end
		local screen, onScreen = Utils.WorldToScreen(part.Position)
		if not onScreen then return nil end
		local dist = Utils.Distance3D(Utils.Camera.CFrame.Position, part.Position)
		if dist > M.Config.Range then return nil end
		local pxDist = (screen - mousePos).Magnitude
		if pxDist > M.Config.FOV then return nil end

		local score
		if M.Config.PickBy == "You" then
			score = dist
		elseif M.Config.PickBy == "Lowest health" then
			local hum = Utils.GetHumanoid(plr)
			score = hum and hum.Health or math.huge
		else
			score = pxDist
		end
		return score, part
	end

	local function pickTarget()
		local mousePos = UserInputService:GetMouseLocation()
		if M.Config.StayOnTarget and currentTarget and currentTarget.Parent then
			local score, part = scoreFor(currentTarget, mousePos)
			if score then return currentTarget, part end
		end
		local best, bestScore, bestPart
		for _, plr in ipairs(eligiblePlayers()) do
			local score, part = scoreFor(plr, mousePos)
			if score and (not bestScore or score < bestScore) then
				best, bestScore, bestPart = plr, score, part
			end
		end
		return best, bestPart
	end

	-- a thin ring at the crosshair sized to the FOV radius, like every universal aim script has
	local fovCircle = Instance.new("Frame")
	fovCircle.Name = "RiftFOV"
	fovCircle.BackgroundTransparency = 1
	fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	fovCircle.Visible = false
	local fovStroke = Instance.new("UIStroke")
	fovStroke.Color = Color3.fromRGB(176, 49, 43)
	fovStroke.Transparency = 0.25
	fovStroke.Thickness = 1.5
	fovStroke.Parent = fovCircle
	local fovCorner = Instance.new("UICorner")
	fovCorner.CornerRadius = UDim.new(1, 0)
	fovCorner.Parent = fovCircle
	do
		local gui = Instance.new("ScreenGui")
		gui.Name = "RiftAimFOV"
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		fovCircle.Parent = gui
		local parented = pcall(function() gui.Parent = GUI_PARENT end)
		if not parented then
			gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
		end
	end

	local function step()
		if M.Config.ShowFOV and M.Config.Active then
			local mousePos = UserInputService:GetMouseLocation()
			fovCircle.Visible = true
			fovCircle.Size = UDim2.fromOffset(M.Config.FOV * 2, M.Config.FOV * 2)
			fovCircle.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
		else
			fovCircle.Visible = false
		end

		if not M.Config.Active or not keyHeld() or M.Config.Silent then
			currentTarget = nil
			return
		end

		local now = os.clock()
		if currentTarget == nil and now - lastSwitchTime < (M.Config.WaitBeforeNext / 1000) then
			return
		end

		local target, part = pickTarget()
		if target ~= currentTarget then
			currentTarget = target
			lastSwitchTime = now
		end
		if not target or not part then return end

		local cam = Utils.Camera
		local toTarget = part.Position - cam.CFrame.Position
		if toTarget.Magnitude < M.Config.DeadZone then return end

		local desired = CFrame.new(cam.CFrame.Position, part.Position)
		local strength = math.clamp(M.Config.MouseStrength / 100, 0, 1)
		local smooth = 1 - math.clamp(M.Config.Smoothing / 100, 0, 0.98)
		local alpha = math.clamp(strength * smooth, 0.01, 1)
		cam.CFrame = cam.CFrame:Lerp(desired, alpha)
	end

	-- silent aim: the camera only snaps for the instant of the click that fires the
	-- game's own weapon raycast, instead of visibly tracking the target beforehand
	local function trySnapOnFire()
		if not M.Config.Active or not M.Config.Silent or not keyHeld() then return end
		local target, part = pickTarget()
		if not target or not part then return end
		local cam = Utils.Camera
		cam.CFrame = CFrame.new(cam.CFrame.Position, part.Position)
	end

	function M.ToggleKeyPressed()
		toggledOn = not toggledOn
	end

	function M.SetMark(plr, marked)
		M.Marked[plr] = marked or nil
	end

	function M.Panic()
		M.Config.Active = false
		M.Config.Silent = false
	end

	function M.Start()
		if conn then return end
		conn = RunService.RenderStepped:Connect(step)
		inputConn = UserInputService.InputBegan:Connect(function(input, processed)
			if M.Config.Mode == "Toggle" and not processed and input.UserInputType == Enum.UserInputType.MouseButton2 then
				M.ToggleKeyPressed()
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				trySnapOnFire()
			end
		end)
	end

	function M.Stop()
		if conn then conn:Disconnect() conn = nil end
		if inputConn then inputConn:Disconnect() inputConn = nil end
		currentTarget = nil
		fovCircle.Visible = false
	end

	M.Start()
	return M
end
