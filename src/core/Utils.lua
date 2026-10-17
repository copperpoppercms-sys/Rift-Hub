-- Luau | Roblox | Xeno/Synapse-class executor | shared helpers for RiftHub
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Utils = {}
Utils.LocalPlayer = LocalPlayer
Utils.Camera = Camera

function Utils.GetCharacter(plr)
	plr = plr or LocalPlayer
	return plr.Character
end

function Utils.GetHumanoid(plr)
	local char = Utils.GetCharacter(plr)
	return char and char:FindFirstChildOfClass("Humanoid")
end

function Utils.GetRoot(plr)
	local char = Utils.GetCharacter(plr)
	return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

function Utils.GetHead(plr)
	local char = Utils.GetCharacter(plr)
	return char and char:FindFirstChild("Head")
end

-- other players, alive, excludes local player and (optionally) same-team
function Utils.GetTargets(excludeTeam)
	local out = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local hum = Utils.GetHumanoid(plr)
			local root = Utils.GetRoot(plr)
			if hum and root and hum.Health > 0 then
				if not excludeTeam or not (plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
					table.insert(out, plr)
				end
			end
		end
	end
	return out
end

-- world point -> screen point + onscreen flag, clamped depth check
function Utils.WorldToScreen(pos)
	local cam = Workspace.CurrentCamera
	if not cam then return Vector2.new(0, 0), false end
	local screen, onScreen = cam:WorldToViewportPoint(pos)
	return Vector2.new(screen.X, screen.Y), onScreen and screen.Z > 0
end

-- unobstructed line of sight check from camera to target part
function Utils.IsVisible(targetPart, ignoreList)
	local cam = Workspace.CurrentCamera
	if not cam or not targetPart then return false end
	local origin = cam.CFrame.Position
	local dir = targetPart.Position - origin
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList or { Utils.GetCharacter() }
	local result = Workspace:Raycast(origin, dir, params)
	if not result then return true end
	return result.Instance:IsDescendantOf(targetPart:FindFirstAncestorOfClass("Model") or targetPart)
end

function Utils.Distance3D(a, b)
	return (a - b).Magnitude
end

function Utils.Round(n, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(n * mult + 0.5) / mult
end

function Utils.Lerp(a, b, t)
	return a + (b - a) * t
end

-- connection bucket so features can tear themselves down cleanly on disable
function Utils.NewJanitor()
	local conns = {}
	local janitor = {}
	function janitor.Add(conn)
		table.insert(conns, conn)
		return conn
	end
	function janitor.Clean()
		for _, c in ipairs(conns) do
			if typeof(c) == "RBXScriptConnection" then
				c:Disconnect()
			elseif typeof(c) == "Instance" then
				c:Destroy()
			elseif type(c) == "function" then
				pcall(c)
			end
		end
		table.clear(conns)
	end
	return janitor
end

RunService.RenderStepped:Connect(function()
	Camera = Workspace.CurrentCamera
	Utils.Camera = Camera
end)

return Utils
