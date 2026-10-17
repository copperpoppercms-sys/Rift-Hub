-- Luau | Roblox | Xeno/Synapse-class executor | through-wall player highlights
return function(Utils)
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer

	local M = {}
	M.Config = {
		Enabled = false,
		FillColor = Color3.fromRGB(176, 49, 43),
		OutlineColor = Color3.fromRGB(234, 224, 203),
		FillTransparency = 0.6,
	}

	local highlights = {}

	local function apply(plr, char)
		local highlight = Instance.new("Highlight")
		highlight.Name = "RiftChams"
		highlight.Adornee = char
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillColor = M.Config.FillColor
		highlight.OutlineColor = M.Config.OutlineColor
		highlight.FillTransparency = M.Config.FillTransparency
		highlight.Enabled = M.Config.Enabled
		highlight.Parent = char
		highlights[plr] = highlight
	end

	local function onCharacter(plr, char)
		apply(plr, char)
	end

	local conns = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			if plr.Character then onCharacter(plr, plr.Character) end
			table.insert(conns, plr.CharacterAdded:Connect(function(char) onCharacter(plr, char) end))
		end
	end
	table.insert(conns, Players.PlayerAdded:Connect(function(plr)
		table.insert(conns, plr.CharacterAdded:Connect(function(char) onCharacter(plr, char) end))
	end))
	table.insert(conns, Players.PlayerRemoving:Connect(function(plr)
		if highlights[plr] then highlights[plr]:Destroy() highlights[plr] = nil end
	end))

	local function repaint()
		for _, highlight in pairs(highlights) do
			highlight.Enabled = M.Config.Enabled
			highlight.FillColor = M.Config.FillColor
			highlight.OutlineColor = M.Config.OutlineColor
			highlight.FillTransparency = M.Config.FillTransparency
		end
	end
	M.Repaint = repaint
	M.Reconcile = repaint

	function M.Panic()
		M.Config.Enabled = false
		repaint()
	end

	function M.Stop()
		for _, c in ipairs(conns) do c:Disconnect() end
		for _, highlight in pairs(highlights) do highlight:Destroy() end
		table.clear(highlights)
	end

	return M
end
