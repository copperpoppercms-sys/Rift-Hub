-- Luau | Roblox | Xeno/Synapse-class executor | flattens map lighting so nothing stays dark
return function()
	local Lighting = game:GetService("Lighting")

	local M = {}
	M.Config = { Enabled = false }

	local saved = nil
	local function snapshot()
		saved = {
			Brightness = Lighting.Brightness,
			ClockTime = Lighting.ClockTime,
			FogEnd = Lighting.FogEnd,
			GlobalShadows = Lighting.GlobalShadows,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			Ambient = Lighting.Ambient,
			ColorShift_Bottom = Lighting.ColorShift_Bottom,
			ColorShift_Top = Lighting.ColorShift_Top,
		}
	end

	local function apply(on)
		if on then
			if not saved then snapshot() end
			Lighting.Brightness = 2
			Lighting.ClockTime = 14
			Lighting.FogEnd = 1e8
			Lighting.GlobalShadows = false
			Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
			Lighting.Ambient = Color3.new(1, 1, 1)
			Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
			Lighting.ColorShift_Top = Color3.new(0, 0, 0)
		elseif saved then
			for k, v in pairs(saved) do
				pcall(function() Lighting[k] = v end)
			end
			saved = nil
		end
	end

	function M.SetEnabled(on)
		M.Config.Enabled = on
		apply(on)
	end

	-- re-applies a Config.Enabled that may have just been restored from a saved
	-- session, rather than set through M.SetEnabled
	function M.Reconcile()
		apply(M.Config.Enabled)
	end

	function M.Panic()
		M.SetEnabled(false)
	end

	function M.Stop()
		M.SetEnabled(false)
	end

	return M
end
