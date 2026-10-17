-- Universal FOV, zoom distance, and reversible player spectating.
return function(Utils)
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local player = Players.LocalPlayer
	local M = { Config = { FOVEnabled = false, FOV = 80, ZoomEnabled = false, MaxZoom = 128 } }
	local fovCamera, fovSaved, zoomSaved, target, watchedCamera, subjectSaved, typeSaved
	local stopped = false
	local function restoreFOV()
		if fovCamera and fovCamera.Parent then fovCamera.FieldOfView = fovSaved end
		fovCamera, fovSaved = nil, nil
	end
	local function restoreSubject()
		if watchedCamera and watchedCamera.Parent then
			local ownHum = Utils.GetHumanoid(player)
			watchedCamera.CameraSubject = ownHum or subjectSaved
			watchedCamera.CameraType = typeSaved or Enum.CameraType.Custom
		end
		watchedCamera, subjectSaved, typeSaved = nil, nil, nil
	end
	function M.Spectate(plr)
		if plr == player then M.StopSpectating(); return true end
		local hum = plr and Utils.GetHumanoid(plr)
		if not hum or hum.Health <= 0 then return false, "That player has no living character" end
		restoreSubject(); target = plr; return true
	end
	function M.StopSpectating() target = nil; restoreSubject() end
	function M.SpectatingName() return target and target.DisplayName or "Your character" end
	local function step()
		if stopped then return end
		local cam = Workspace.CurrentCamera
		if M.Config.FOVEnabled and cam then
			if fovCamera ~= cam then restoreFOV(); fovCamera = cam; fovSaved = cam.FieldOfView end
			cam.FieldOfView = math.clamp(M.Config.FOV, 30, 120)
		else restoreFOV() end
		if M.Config.ZoomEnabled then
			if not zoomSaved then zoomSaved = player.CameraMaxZoomDistance end
			player.CameraMaxZoomDistance = math.max(player.CameraMinZoomDistance, math.clamp(M.Config.MaxZoom, 8, 1000))
		elseif zoomSaved then player.CameraMaxZoomDistance = math.max(player.CameraMinZoomDistance, zoomSaved); zoomSaved = nil end
		if target then
			local hum = Utils.GetHumanoid(target)
			if not target.Parent or not hum or hum.Health <= 0 then M.StopSpectating(); return end
			if cam then
				if watchedCamera ~= cam then restoreSubject(); watchedCamera = cam; subjectSaved = cam.CameraSubject; typeSaved = cam.CameraType end
				cam.CameraType = Enum.CameraType.Custom; cam.CameraSubject = hum
			end
		end
	end
	function M.Reconcile() step() end
	function M.Panic() M.Config.FOVEnabled = false; M.Config.ZoomEnabled = false; M.StopSpectating(); step() end
	local render = RunService.RenderStepped:Connect(step)
	local leaving = Players.PlayerRemoving:Connect(function(plr) if plr == target then M.StopSpectating() end end)
	function M.Stop() M.Panic(); stopped = true; render:Disconnect(); leaving:Disconnect() end
	return M
end
