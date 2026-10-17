-- Three session-local saved spots and an undo for jumps to players/saved spots.
return function(Utils)
	local player = game:GetService("Players").LocalPlayer
	local M = { Config = { Slot = "A" } }
	local slots, previous = {}, nil
	local function root()
		local r, hum = Utils.GetRoot(player), Utils.GetHumanoid(player)
		if not r or not hum or hum.Health <= 0 or r.Anchored then return nil end
		return r
	end
	function M.Save()
		local r = root(); if not r then return false, "Your character is not ready" end
		slots[M.Config.Slot] = r.CFrame; return true, "Saved slot " .. M.Config.Slot
	end
	function M.Teleport(cframe)
		local r = root(); if not r then return false, "Your character is not ready" end
		previous = r.CFrame; r.CFrame = cframe; r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero
		return true, "Moved to saved position"
	end
	function M.GoTo()
		local saved = slots[M.Config.Slot]; if not saved then return false, "Save slot " .. M.Config.Slot .. " first" end
		return M.Teleport(saved)
	end
	function M.Return()
		if not previous then return false, "No previous position yet" end
		return M.Teleport(previous)
	end
	function M.Status() return slots[M.Config.Slot] and "Slot " .. M.Config.Slot .. " saved" or "Slot " .. M.Config.Slot .. " empty" end
	function M.Stop() slots = {}; previous = nil end
	return M
end
