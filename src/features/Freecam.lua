-- Luau | Roblox | Xeno/Synapse-class executor | detached scriptable camera (PC: WASD + mouse-look)
return function()
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local M = {}
	M.Config = { Active = false, Speed = 80 }

	local active = false
	local camCFrame, savedType
	local yaw, pitch = 0, 0

	local function begin()
		local camera = workspace.CurrentCamera
		savedType = camera.CameraType
		camCFrame = camera.CFrame
		local look = camCFrame.LookVector
		yaw = math.atan2(-look.X, -look.Z)
		pitch = math.asin(math.clamp(look.Y, -1, 1))
		camera.CameraType = Enum.CameraType.Scriptable
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end

	local function finish()
		local camera = workspace.CurrentCamera
		camera.CameraType = savedType or Enum.CameraType.Custom
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	function M.SetActive(on)
		if on == active then return end
		active = on
		M.Config.Active = on
		if on then begin() else finish() end
	end

	function M.IsActive()
		return active
	end

	function M.Panic()
		M.SetActive(false)
	end

	-- re-applies a Config.Active that may have just been restored from a saved
	-- session, rather than set through M.SetActive
	function M.Reconcile()
		if M.Config.Active then
			M.SetActive(true)
		end
	end

	local inputConn = UserInputService.InputChanged:Connect(function(input)
		if not active then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			yaw -= input.Delta.X * 0.003
			pitch = math.clamp(pitch - input.Delta.Y * 0.003, -1.5, 1.5)
		end
	end)

	local renderConn = RunService.RenderStepped:Connect(function(dt)
		if not active then return end
		local camera = workspace.CurrentCamera
		local rotation = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)

		local move = Vector3.new()
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move -= Vector3.new(0, 0, 1) end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0, 0, 1) end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Vector3.new(1, 0, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(1, 0, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end
		if move.Magnitude > 0 then move = move.Unit end

		local worldMove = (rotation * move) * (M.Config.Speed * dt)
		camCFrame = CFrame.new(camCFrame.Position + worldMove) * rotation
		camera.CFrame = camCFrame
	end)

	function M.Stop()
		if inputConn then inputConn:Disconnect() inputConn = nil end
		if renderConn then renderConn:Disconnect() renderConn = nil end
		M.SetActive(false)
	end

	return M
end
