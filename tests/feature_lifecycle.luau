-- A small Roblox service fixture. Physics constraints and actual server authority
-- still require an in-game test; these checks cover input and reversible state.
local function signal()
	local s = { items = {} }
	function s:Connect(fn)
		local c = { Connected = true, fn = fn }
		function c:Disconnect() self.Connected = false end
		table.insert(self.items, c); return c
	end
	function s:Fire(...) for _, c in ipairs(self.items) do if c.Connected then c.fn(...) end end end
	return s
end
local function enum(prefix)
	return setmetatable({}, { __index = function(t, k)
		local v = enum(prefix .. "." .. k); rawset(t, k, v); return v
	end })
end
local Enum = enum("Enum")
local vec = {}
local Vector3 = {}
function Vector3.new(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vec) end
Vector3.zero = Vector3.new()
vec.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vec.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
vec.__mul = function(a, b) return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
vec.__index = function(a, k)
	if k == "Magnitude" then return math.sqrt(a.X*a.X + a.Y*a.Y + a.Z*a.Z) end
	if k == "Unit" then local m = a.Magnitude; return Vector3.new(a.X/m, a.Y/m, a.Z/m) end
end
local function pose(x, y, z)
	return { Position = Vector3.new(x, y, z), LookVector = Vector3.new(0, 0, -1), RightVector = Vector3.new(1, 0, 0) }
end
local CFrame = { lookAt = function(a, b) local p = pose(a.X, a.Y, a.Z); p.LookVector = (b-a).Unit; return p end }
local UDim2 = { new = function(...) return {...} end, fromOffset = function(...) return {...} end }
local Vector2, UDim, Color3 = { new = function(...) return {...} end }, { new = function(...) return {...} end },
	{ new = function(...) return {...} end, fromRGB = function(...) return {...} end }
local RaycastParams = { new = function() return {} end }
local objects, failConstraint = {}, false
local Instance = { new = function(class)
	if class == "LinearVelocity" and failConstraint then error("constraint unavailable") end
	local item = { ClassName = class, InputBegan = signal(), InputEnded = signal() }
	function item:Destroy() self.Parent = nil; self.Destroyed = true end
	table.insert(objects, item); return item
end }
local function character(speed)
	local root = { Parent = {}, Anchored = false, CFrame = pose(0, 10, 0), Position = Vector3.new(0, 10, 0), Size = Vector3.new(2, 2, 1), CanCollide = false }
	local body = { Parent = {}, CanCollide = true }
	function root:IsA(name) return name == "BasePart" end
	function body:IsA(name) return name == "BasePart" end
	local hum = { Parent = {}, Health = 100, PlatformStand = false, AutoRotate = true, HipHeight = 2,
		MoveDirection = Vector3.zero, WalkSpeed = speed, UseJumpPower = false, JumpPower = 67, JumpHeight = 9 }
	function hum:ChangeState(state) self.LastState = state end
	local c = { root = root, hum = hum, body = body }
	function c:GetDescendants() return { self.root, self.body } end
	return c
end
local player = { Character = character(24), CharacterRemoving = signal(), CharacterAdded = signal(),
	Parent = {}, DisplayName = "Self", CameraMinZoomDistance = 0.5, CameraMaxZoomDistance = 128 }
local Players = { LocalPlayer = player, PlayerRemoving = signal() }
local RunService = { Heartbeat = signal(), Stepped = signal(), RenderStepped = signal() }
local UIS = { TouchEnabled = true, InputChanged = signal(), InputEnded = signal(), WindowFocusReleased = signal(), JumpRequest = signal() }
local keys, focused = {}, false
function UIS:IsKeyDown(key) return keys[key] == true end
function UIS:IsGamepadButtonDown(_, key) return keys[key] == true end
function UIS:GetFocusedTextBox() return focused and {} or nil end
local cam = { Parent = {}, FieldOfView = 75, CFrame = pose(0, 0, 0), CameraSubject = player.Character.hum, CameraType = Enum.CameraType.Custom }
local grounded = false
local Workspace = { CurrentCamera = cam }
function Workspace:Raycast() return grounded and {} or nil end
local workspace = Workspace
local teleports, pages, pageIndex, urls = {}, {}, 0, {}
local TeleportService = { TeleportInitFailed = signal() }
function TeleportService:TeleportToPlaceInstance(place, job, who) table.insert(teleports, { place, job, who }) end
local HttpService = {}
function HttpService:JSONDecode(body) return body end
function HttpService:UrlEncode(cursor) return cursor end
local Lighting = { Brightness = 1, ClockTime = 20, FogEnd = 100, GlobalShadows = true,
	OutdoorAmbient = Color3.new(.1,.1,.1), Ambient = Color3.new(.1,.1,.1), ColorShift_Bottom = Color3.new(), ColorShift_Top = Color3.new() }
local services = { RunService = RunService, UserInputService = UIS, Players = Players, Workspace = Workspace,
	CoreGui = {}, TeleportService = TeleportService, HttpService = HttpService, Lighting = Lighting }
local game = { PlaceId = 123, JobId = "current" }
function game:GetService(name) assert(services[name], name); return services[name] end
function game:HttpGet(url) table.insert(urls,url); pageIndex += 1; assert(pages[pageIndex], "HTTP failed"); return pages[pageIndex] end
local Utils = { GetRoot = function(plr) return plr.Character and plr.Character.root end,
	GetHumanoid = function(plr) return plr.Character and plr.Character.hum end }

local clock = 0
local os = { clock = function() return clock end }

-- MODULES

local fly = FlyCtor(Utils)
fly.SetFlying(true); RunService.Heartbeat:Fire(.1)
assert(fly.IsFlying() and not fly.Config.Armed, "flight still depends on launch being armed")
assert(player.Character.hum.PlatformStand and not player.Character.hum.AutoRotate)
keys[Enum.KeyCode.W] = true; RunService.Heartbeat:Fire(.1)
assert(fly.CurrentSpeed() == fly.Config.CruiseSpeed)
local velocity
for _, item in ipairs(objects) do if item.Name == "RiftFlightVelocity" and item.Parent then velocity = item end end
assert(velocity and velocity.VectorVelocity.Z < 0, "WASD steering did not update the constraint")
keys[Enum.KeyCode.E] = true; RunService.Heartbeat:Fire(1)
assert(fly.CurrentSpeed() > fly.Config.CruiseSpeed and fly.CurrentSpeed() <= fly.Config.TopSpeed, "boost does not ramp")
focused = true; RunService.Heartbeat:Fire(.1); assert(fly.CurrentSpeed() == 0, "typing moves the character")
focused = false; keys = {}
local up
for _, item in ipairs(objects) do if item.Text == "UP" then up = item end end
assert(up, "touch controls missing")
local touch = { UserInputType = Enum.UserInputType.Touch, UserInputState = Enum.UserInputState.Begin, Changed = signal() }
up.InputBegan:Fire(touch); RunService.Heartbeat:Fire(.1); assert(velocity.VectorVelocity.Y > 0)
touch.UserInputState = Enum.UserInputState.End; touch.Changed:Fire(); RunService.Heartbeat:Fire(.1); assert(velocity.VectorVelocity.Magnitude == 0, "touch release stuck")
UIS.InputChanged:Fire({ KeyCode = Enum.KeyCode.Thumbstick1, Position = Vector3.new(1, 0, 0) })
RunService.Heartbeat:Fire(.1); assert(velocity.VectorVelocity.X > 0, "controller thumbstick did not steer")
UIS.InputEnded:Fire({ KeyCode = Enum.KeyCode.Thumbstick1 })
keys[Enum.KeyCode.LeftShift] = true; grounded = true; RunService.Heartbeat:Fire(.1)
assert(not fly.IsFlying() and not fly.Config.Enabled, "ground detection did not stop flight")
assert(not player.Character.hum.PlatformStand and player.Character.hum.AutoRotate)
keys = {}; grounded = false
fly.SetFlying(true); RunService.Heartbeat:Fire(.1)
local old = player.Character; player.CharacterRemoving:Fire(old); player.Character = nil; RunService.Heartbeat:Fire(.1)
assert(not fly.IsFlying() and fly.Config.Enabled)
player.Character = character(22); RunService.Heartbeat:Fire(.1); assert(fly.IsFlying(), "respawn did not restart flight")
fly.Config.ResumeOnRespawn = false; player.CharacterRemoving:Fire(player.Character)
assert(not fly.Config.Enabled and not fly.IsFlying())
fly.SetFlying(true); failConstraint = true; RunService.Heartbeat:Fire(.1)
assert(not fly.Config.Enabled and fly.LastError and not player.Character.hum.PlatformStand, "failed flight setup was not restored")
failConstraint = false
local launched = false
fly.Config.Armed = true; fly.OnLaunch = function(charge, power) launched = charge == 1 and power == fly.Config.LaunchPower end
keys[Enum.KeyCode.Space] = true; RunService.Heartbeat:Fire(.1)
clock = fly.Config.FullChargeTime; RunService.Heartbeat:Fire(.1); assert(fly.CurrentCharge() == 1)
keys = {}; RunService.Heartbeat:Fire(.1); assert(launched and player.Character.root.AssemblyLinearVelocity.Magnitude > 0, "charged launch did not apply")
fly.Stop()

local movement = MovementCtor(Utils)
RunService.Heartbeat:Fire(.1); assert(player.Character.hum.WalkSpeed == 22 and not player.Character.hum.UseJumpPower, "disabled overrides changed game defaults")
movement.Config.SpeedEnabled = true; movement.Config.WalkSpeed = 80; movement.Config.JumpEnabled = true; movement.Config.JumpPower = 90
movement.SetNoclip(true); RunService.Heartbeat:Fire(.1); RunService.Stepped:Fire()
assert(player.Character.hum.WalkSpeed == 80 and player.Character.hum.JumpPower == 90)
assert(not player.Character.body.CanCollide and not player.Character.root.CanCollide)
movement.Config.SpeedEnabled = false; movement.Config.JumpEnabled = false; movement.SetNoclip(false); RunService.Heartbeat:Fire(.1)
assert(player.Character.hum.WalkSpeed == 22 and not player.Character.hum.UseJumpPower and player.Character.hum.JumpHeight == 9)
assert(player.Character.body.CanCollide and not player.Character.root.CanCollide, "noclip invented collisions")
movement.Config.SprintEnabled = true; keys[Enum.KeyCode.LeftControl] = true; RunService.Heartbeat:Fire(.1); assert(player.Character.hum.WalkSpeed == 32)
keys = {}; RunService.Heartbeat:Fire(.1); assert(player.Character.hum.WalkSpeed == 22)
movement.Config.InfiniteJump = true; UIS.JumpRequest:Fire(); assert(player.Character.hum.LastState == Enum.HumanoidStateType.Jumping)
movement.Stop()

local camera = CameraToolsCtor(Utils)
camera.Config.FOVEnabled = true; camera.Config.FOV = 110; camera.Config.ZoomEnabled = true; camera.Config.MaxZoom = 400
RunService.RenderStepped:Fire(.1); assert(cam.FieldOfView == 110 and player.CameraMaxZoomDistance == 400)
local other = { Character = character(16), Parent = {}, DisplayName = "Other" }
assert(camera.Spectate(other)); RunService.RenderStepped:Fire(.1); assert(cam.CameraSubject == other.Character.hum)
Players.PlayerRemoving:Fire(other); assert(cam.CameraSubject == player.Character.hum and camera.SpectatingName() == "Your character")
camera.Stop(); assert(cam.FieldOfView == 75 and player.CameraMaxZoomDistance == 128)

local waypoints = WaypointsCtor(Utils)
assert(not waypoints.GoTo(), "empty waypoint accepted")
local original = player.Character.root.CFrame; assert(waypoints.Save())
player.Character.root.CFrame = pose(99, 20, 99); local beforeJump = player.Character.root.CFrame
assert(waypoints.GoTo()); assert(player.Character.root.CFrame == original)
assert(waypoints.Return()); assert(player.Character.root.CFrame == beforeJump, "waypoint undo failed")

pages = { { data = { {id="current",playing=1,maxPlayers=10}, {id="full",playing=10,maxPlayers=10} }, nextPageCursor="next" },
	{ data = { {id="fast",playing=8,maxPlayers=10,ping=20}, {id="small",playing=2,maxPlayers=10,ping=80} } } }
pageIndex = 0
local servers = ServerToolsCtor(); assert(servers.Hop()); assert(teleports[#teleports][2] == "small" and #urls == 2)
servers.Config.Prefer = "Lowest ping"; pageIndex = 0; assert(servers.Hop()); assert(teleports[#teleports][2] == "fast")
pages = {}; pageIndex = 0; assert(not servers.Hop() and servers.Status == "Server search failed")
servers.Stop(); assert(not servers.Hop())

local bright = FullbrightCtor(); bright.SetEnabled(true); bright.SetEnabled(false); assert(Lighting.ClockTime == 20)
Lighting.ClockTime = 5; bright.SetEnabled(true); bright.SetEnabled(false); assert(Lighting.ClockTime == 5, "fullbright restored a stale snapshot")
print("PASS: flight inputs, boost, landing, touch release, respawn, setup failure, reversible movement, camera/spectate, waypoints, server selection, and fullbright.")

local callbacks, sliders, buttons = {}, {}, {}
local Kit = {
	Scroller = function() return {} end,
	Section = function() return {} end,
	Toggle = function(_, name, _, default, fn)
		callbacks[name] = fn
		local value = default
		return { Get = function() return value end, Set = function(v) value = v end }
	end,
	Slider = function(_, name, _, _, _, _, options) sliders[name] = options.OnChanged end,
	PlainRow = function() return { Set = function() end } end,
	Button = function(_, name, _, _, fn) buttons[name] = fn end,
	Cycle = function() end,
}
local wiredFly, wiredMovement = FlyCtor(Utils), MovementCtor(Utils)
buildMovement({}, { Kit = Kit, Features = { Fly = wiredFly, Movement = wiredMovement, Waypoints = waypoints },
	Janitor = { add = function() end }, SpawnBoom = function() end })
callbacks.Fly(true); RunService.Heartbeat:Fire(.1); assert(wiredFly.IsFlying() and not wiredFly.Config.Armed)
sliders["Boost speed"](320); assert(wiredFly.Config.TopSpeed == 320)
callbacks.Fly(false); assert(not wiredFly.IsFlying())
callbacks.Speed(true); sliders["Walk speed"](85); RunService.Heartbeat:Fire(.1); assert(player.Character.hum.WalkSpeed == 85)
callbacks.Speed(false); RunService.Heartbeat:Fire(.1); assert(player.Character.hum.WalkSpeed == 22)
buttons["Save current position"](); assert(waypoints.Status() == "Slot A saved")
wiredFly.Stop(); wiredMovement.Stop()
print("PASS: Movement tab callbacks activate flight without launch mode, update sliders, restore speed, and save positions.")
