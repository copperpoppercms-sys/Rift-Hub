-- Luau | Roblox | Xeno/Synapse-class executor | fires automatically when a target crosses the crosshair
return function(Utils)
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local M = {}
	M.Config = {
		Active = false,
		Mode = "While held", -- "While held" | "Always"
		FOV = 40,
		Delay = 100, -- ms between shots
	}

	local lastFire = 0
	local conn

	local function keyHeld()
		if M.Config.Mode == "Always" then return true end
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	end

	local function hasTarget()
		local mousePos = UserInputService:GetMouseLocation()
		for _, plr in ipairs(Utils.GetTargets(false)) do
			local part = Utils.GetHead(plr) or Utils.GetRoot(plr)
			if part then
				local screen, onScreen = Utils.WorldToScreen(part.Position)
				if onScreen and (screen - mousePos).Magnitude <= M.Config.FOV then
					return true
				end
			end
		end
		return false
	end

	-- mouse1click/mouse1press+mouse1release are the standard executor (UNC) virtual
	-- mouse-input globals; where the executor doesn't expose them this just no-ops
	local function fire()
		pcall(function()
			if type(mouse1click) == "function" then
				mouse1click()
			elseif type(mouse1press) == "function" and type(mouse1release) == "function" then
				mouse1press()
				task.wait()
				mouse1release()
			end
		end)
	end

	local function step()
		if not M.Config.Active or not keyHeld() then return end
		local now = os.clock()
		if now - lastFire < (M.Config.Delay / 1000) then return end
		if hasTarget() then
			fire()
			lastFire = now
		end
	end

	function M.Panic()
		M.Config.Active = false
	end

	function M.Start()
		if conn then return end
		conn = RunService.Heartbeat:Connect(step)
	end

	function M.Stop()
		if conn then conn:Disconnect() conn = nil end
	end

	M.Start()
	return M
end
