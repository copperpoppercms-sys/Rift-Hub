-- Camera-relative cruise flight, held boost, charged launch, and touch controls.
return function(Utils)
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local player = Players.LocalPlayer
	local M = { Config = {
		Enabled = false, Armed = false, CruiseSpeed = 80, TopSpeed = 240,
		LaunchPower = 180, TimeToTopSpeed = 2, FullChargeTime = 1.5,
		SonicBoomSpeed = 2.125, LandOnWayDown = true, ResumeOnRespawn = true,
	}, OnLaunch = function() end, LastError = nil }
	local controls, activeRoot, activeHumanoid, saved, velocity, orientation = {}, nil, nil, nil, nil, nil
	local flying, stopped, charge, charging, chargeStart, boostTime, speed = false, false, 0, false, 0, 0, 0
	local touches, touchLaunch, touchBoost, stick = {}, false, false, Vector3.zero
	local touchEnds = {}
	local connections, gui, running = {}, nil, false
	local function own(instance) table.insert(controls, instance); return instance end
	local function connect(signal, fn) local c = signal:Connect(fn); table.insert(connections, c); return c end
	local function key(code)
		if code == Enum.KeyCode.ButtonA or code == Enum.KeyCode.ButtonB or code == Enum.KeyCode.ButtonR2 then
			return UIS:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, code)
		end
		return UIS:IsKeyDown(code)
	end
	local function clearInputs()
		touches = {}; touchLaunch = false; touchBoost = false; stick = Vector3.zero
		for input, c in pairs(touchEnds) do
			c:Disconnect(); local index = table.find(connections, c)
			if index then table.remove(connections, index) end
			touchEnds[input] = nil
		end
	end
	local function stopFlight()
		flying = false; speed = 0; boostTime = 0
		for _, item in ipairs(controls) do item:Destroy() end
		table.clear(controls)
		if activeHumanoid and activeHumanoid.Parent and saved then
			activeHumanoid.PlatformStand = saved.PlatformStand
			activeHumanoid.AutoRotate = saved.AutoRotate
			if activeHumanoid.Health > 0 and not saved.PlatformStand then activeHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
		end
		if activeRoot and activeRoot.Parent then
			activeRoot.AssemblyLinearVelocity = Vector3.zero
			activeRoot.AssemblyAngularVelocity = Vector3.zero
		end
		activeRoot, activeHumanoid, saved, velocity, orientation = nil, nil, nil, nil, nil
	end
	local function startFlight(root, hum)
		activeRoot, activeHumanoid = root, hum
		saved = { PlatformStand = hum.PlatformStand, AutoRotate = hum.AutoRotate }
		local ok, err = pcall(function()
			local attachment = own(Instance.new("Attachment")); attachment.Name = "RiftFlightAttachment"; attachment.Parent = root
			velocity = own(Instance.new("LinearVelocity"))
			velocity.Name = "RiftFlightVelocity"; velocity.Attachment0 = attachment
			velocity.RelativeTo = Enum.ActuatorRelativeTo.World
			velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
			velocity.ForceLimitsEnabled = false; velocity.VectorVelocity = Vector3.zero; velocity.Parent = root
			orientation = own(Instance.new("AlignOrientation"))
			orientation.Name = "RiftFlightOrientation"; orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
			orientation.Attachment0 = attachment; orientation.MaxTorque = 1e9
			orientation.Responsiveness = 20; orientation.CFrame = root.CFrame; orientation.Parent = root
			hum.AutoRotate = false; hum.PlatformStand = true
		end)
		if not ok then stopFlight(); M.LastError = tostring(err); M.Config.Enabled = false; return end
		flying = true; M.LastError = nil
	end
	local function vertical()
		local value = 0
		for _, axis in pairs(touches) do value += axis end
		if key(Enum.KeyCode.Space) or key(Enum.KeyCode.ButtonA) then value += 1 end
		if key(Enum.KeyCode.LeftShift) or key(Enum.KeyCode.ButtonB) then value -= 1 end
		return math.clamp(value, -1, 1)
	end
	local function direction(cam, hum)
		if UIS:GetFocusedTextBox() then return Vector3.zero, 0 end
		local forward, sideways = 0, 0
		if key(Enum.KeyCode.W) then forward += 1 end
		if key(Enum.KeyCode.S) then forward -= 1 end
		if key(Enum.KeyCode.D) then sideways += 1 end
		if key(Enum.KeyCode.A) then sideways -= 1 end
		local up = vertical()
		local move
		if forward ~= 0 or sideways ~= 0 then
			move = cam.CFrame.LookVector * forward + cam.CFrame.RightVector * sideways
		elseif stick.Magnitude > 0.12 then
			move = cam.CFrame.LookVector * stick.Y + cam.CFrame.RightVector * stick.X
		else move = hum.MoveDirection end
		move += Vector3.new(0, up, 0)
		return move.Magnitude > 0.01 and move.Unit or Vector3.zero, up
	end
	function M.SetFlying(on)
		M.Config.Enabled = on and true or false
		charging = false; charge = 0; clearInputs()
		if not M.Config.Enabled then stopFlight() end
	end
	function M.ToggleFly() M.SetFlying(not M.Config.Enabled) end
	function M.IsFlying() return flying end
	function M.CurrentCharge() return charge end
	function M.CurrentSpeed() return speed end
	function M.Reconcile()
		for name, limits in pairs({ CruiseSpeed = {16, 1000}, TopSpeed = {16, 2000}, LaunchPower = {0, 2000}, TimeToTopSpeed = {0.2, 60}, FullChargeTime = {0.2, 10} }) do
			M.Config[name] = math.clamp(tonumber(M.Config[name]) or limits[1], limits[1], limits[2])
		end
	end
	local function step(dt)
		if stopped then return end
		local root, hum, cam = Utils.GetRoot(player), Utils.GetHumanoid(player), Workspace.CurrentCamera
		local valid = root and root.Parent and hum and hum.Parent and hum.Health > 0 and not root.Anchored and cam
		if flying and (not valid or root ~= activeRoot or hum ~= activeHumanoid) then stopFlight() end
		if M.Config.Enabled and valid and not flying then startFlight(root, hum) end
		if not M.Config.Enabled and flying then stopFlight() end
		if gui then gui.Enabled = flying or M.Config.Armed end
		if flying then
			local wish = direction(cam, hum)
			local held = not UIS:GetFocusedTextBox() and (touchBoost or key(Enum.KeyCode.E) or key(Enum.KeyCode.ButtonR2))
			boostTime = held and wish.Magnitude > 0 and math.min(boostTime + dt, M.Config.TimeToTopSpeed) or 0
			local cruise = math.clamp(M.Config.CruiseSpeed, 16, 1000)
			local top = math.max(cruise, math.clamp(M.Config.TopSpeed, 16, 2000))
			speed = wish.Magnitude > 0 and cruise + (top - cruise) * math.clamp(boostTime / math.max(M.Config.TimeToTopSpeed, 0.2), 0, 1) or 0
			velocity.VectorVelocity = wish * speed
			local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
			if look.Magnitude > 0.01 then orientation.CFrame = CFrame.lookAt(root.Position, root.Position + look.Unit) end
			if M.Config.LandOnWayDown and wish.Y < -0.1 then
				local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { player.Character }; params.RespectCanCollide = true
				local distance = math.max(3, hum.HipHeight + root.Size.Y * 0.5 + 1.25 + math.max(0, -wish.Y * speed * dt))
				if Workspace:Raycast(root.Position, Vector3.new(0, -distance, 0), params) then M.SetFlying(false) end
			end
		end
		if not M.Config.Armed or flying or not valid or UIS:GetFocusedTextBox() then charging = false; charge = 0; return end
		local held = touchLaunch or key(Enum.KeyCode.Space)
		if held then
			if not charging then charging = true; chargeStart = os.clock() end
			charge = math.clamp((os.clock() - chargeStart) / math.max(M.Config.FullChargeTime, 0.2), 0, 1)
		elseif charging then
			charging = false
			local power = math.clamp(M.Config.LaunchPower, 0, 2000) * charge
			root.AssemblyLinearVelocity = cam.CFrame.LookVector * power + Vector3.new(0, power * 0.6, 0)
			pcall(M.OnLaunch, charge, power); charge = 0
		end
	end
	function M.Panic() M.Config.Armed = false; M.SetFlying(false) end
	function M.Start()
		if running then return end
		running = true; stopped = false
		connect(RunService.Heartbeat, step)
		connect(player.CharacterRemoving, function()
			stopFlight(); charging = false; charge = 0; clearInputs()
			if not M.Config.ResumeOnRespawn then M.Config.Enabled = false end
		end)
		connect(UIS.InputChanged, function(input)
			if input.KeyCode == Enum.KeyCode.Thumbstick1 then stick = input.Position end
		end)
		connect(UIS.InputEnded, function(input)
			touches[input] = nil
			if input.KeyCode == Enum.KeyCode.Thumbstick1 then stick = Vector3.zero end
		end)
		connect(UIS.WindowFocusReleased, function() clearInputs(); charging = false; charge = 0 end)
	end
	function M.Stop()
		stopped = true; running = false; M.Panic()
		for _, c in ipairs(connections) do c:Disconnect() end
		table.clear(connections)
		if gui then gui:Destroy(); gui = nil end
	end
	if UIS.TouchEnabled then
		gui = Instance.new("ScreenGui"); gui.Name = "RiftFlyControls"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 901; gui.Enabled = false
		local ok = pcall(function() gui.Parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui") end)
		if not ok then gui.Parent = player:WaitForChild("PlayerGui") end
		local function button(label, x, y, kind, axis)
			local btn = Instance.new("TextButton"); btn.Size = UDim2.fromOffset(52, 46)
			btn.AnchorPoint = Vector2.new(1, 1); btn.Position = UDim2.new(1, x, 1, y)
			btn.BackgroundColor3 = Color3.fromRGB(23, 19, 21); btn.TextColor3 = Color3.fromRGB(234, 224, 203)
			btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.Text = label; btn.Parent = gui
			local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 10); corner.Parent = btn
			local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(176, 49, 43); stroke.Parent = btn
			connect(btn.InputBegan, function(input)
				if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				if kind == "axis" then touches[input] = axis elseif kind == "boost" then touchBoost = true else touchLaunch = true end
				local ending
				ending = connect(input.Changed, function()
					if input.UserInputState == Enum.UserInputState.End then
						touches[input] = nil; if kind == "boost" then touchBoost = false elseif kind == "launch" then touchLaunch = false end
						if ending then
							ending:Disconnect(); local index = table.find(connections, ending)
							if index then table.remove(connections, index) end
						end
						touchEnds[input] = nil
					end
				end)
				touchEnds[input] = ending
			end)
		end
		button("UP", -150, -176, "axis", 1); button("DOWN", -150, -124, "axis", -1)
		button("BOOST", -92, -176, "boost"); button("LAUNCH", -92, -124, "launch")
	end
	M.Start()
	return M
end
