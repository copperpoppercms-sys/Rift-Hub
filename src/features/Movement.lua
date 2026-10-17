-- Reversible character overrides. Never replace a game's defaults when a feature is off.
return function(Utils)
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local player = game:GetService("Players").LocalPlayer
	local M = { Config = { SpeedEnabled = false, WalkSpeed = 16, JumpEnabled = false, JumpPower = 50,
		InfiniteJump = false, Noclip = false, SprintEnabled = false, SprintSpeed = 32 } }
	local hum, savedSpeed, savedJump, speedOwned, jumpOwned = nil, nil, nil, false, false
	local collision = setmetatable({}, { __mode = "k" })
	local connections, stopped = {}, false
	local function restoreStats()
		if hum and hum.Parent then
			if speedOwned then hum.WalkSpeed = savedSpeed end
			if jumpOwned then hum.UseJumpPower = savedJump.UseJumpPower; hum.JumpPower = savedJump.JumpPower; hum.JumpHeight = savedJump.JumpHeight end
		end
		speedOwned = false; jumpOwned = false
	end
	local function restoreCollision()
		for part, value in pairs(collision) do if part.Parent then part.CanCollide = value end; collision[part] = nil end
	end
	local function stats()
		local current = Utils.GetHumanoid(player)
		if current ~= hum then restoreStats(); hum = current end
		if not hum or not hum.Parent or hum.Health <= 0 then return end
		local sprinting = M.Config.SprintEnabled and not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.LeftControl)
		if M.Config.SpeedEnabled or sprinting then
			if not speedOwned then savedSpeed = hum.WalkSpeed; speedOwned = true end
			hum.WalkSpeed = sprinting and math.clamp(M.Config.SprintSpeed, 16, 250) or math.clamp(M.Config.WalkSpeed, 0, 500)
		elseif speedOwned then hum.WalkSpeed = savedSpeed; speedOwned = false end
		if M.Config.JumpEnabled then
			if not jumpOwned then savedJump = { UseJumpPower = hum.UseJumpPower, JumpPower = hum.JumpPower, JumpHeight = hum.JumpHeight }; jumpOwned = true end
			hum.UseJumpPower = true; hum.JumpPower = math.clamp(M.Config.JumpPower, 0, 500)
		elseif jumpOwned then
			hum.UseJumpPower = savedJump.UseJumpPower; hum.JumpPower = savedJump.JumpPower; hum.JumpHeight = savedJump.JumpHeight; jumpOwned = false
		end
	end
	function M.SetNoclip(on) M.Config.Noclip = on and true or false; if not on then restoreCollision() end end
	function M.Reconcile() stats(); if not M.Config.Noclip then restoreCollision() end end
	function M.Panic()
		M.Config.SpeedEnabled = false; M.Config.JumpEnabled = false; M.Config.InfiniteJump = false; M.Config.SprintEnabled = false
		M.SetNoclip(false); restoreStats()
	end
	table.insert(connections, RunService.Heartbeat:Connect(function() if not stopped then stats() end end))
	table.insert(connections, RunService.Stepped:Connect(function()
		if stopped then return end
		if not M.Config.Noclip then restoreCollision(); return end
		local character = player.Character
		if not character then return end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				if collision[part] == nil then collision[part] = part.CanCollide end
				part.CanCollide = false
			end
		end
	end))
	table.insert(connections, player.CharacterRemoving:Connect(function() restoreStats(); restoreCollision(); hum = nil end))
	table.insert(connections, UIS.JumpRequest:Connect(function()
		if stopped or not M.Config.InfiniteJump or UIS:GetFocusedTextBox() then return end
		local current = Utils.GetHumanoid(player)
		if current and current.Health > 0 then current:ChangeState(Enum.HumanoidStateType.Jumping) end
	end))
	function M.Stop() stopped = true; M.Panic(); for _, c in ipairs(connections) do c:Disconnect() end; table.clear(connections) end
	return M
end
