-- Luau | Roblox | Xeno/Synapse-class executor | defeats the 20-minute idle kick via VirtualUser
return function()
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local VirtualUser = game:GetService("VirtualUser")

	local M = {}
	M.Config = { Enabled = false }

	local conn = LocalPlayer.Idled:Connect(function()
		if not M.Config.Enabled then return end
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end)

	function M.Panic()
		M.Config.Enabled = false
	end

	function M.Stop()
		if conn then conn:Disconnect() conn = nil end
	end

	return M
end
