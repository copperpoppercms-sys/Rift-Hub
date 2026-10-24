-- Small client UI. Test reveals ESP + Noclip; X restores and unloads.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local player = Players.LocalPlayer
assert(player, "Run this from a Roblox client, not a server Script")

local env = type(getgenv) == "function" and getgenv() or _G
if type(env.SmallTestUI) == "table" and type(env.SmallTestUI.Unload) == "function" then
    pcall(env.SmallTestUI.Unload)
end
local api = { ESP = false, Noclip = false }
local connections, highlights, collisions = {}, {}, {}
local alive, expanded = true, false
local function connect(event, fn)
    local connection = event:Connect(fn)
    table.insert(connections, connection)
    return connection
end
local function make(class, properties, parent)
    local object = Instance.new(class)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end
local function restoreCollisions()
    for part, original in pairs(collisions) do
        pcall(function()
            if part.Parent and part.CanCollide == false then part.CanCollide = original end
        end)
    end
    table.clear(collisions)
end
local function clearESP()
    for _, highlight in pairs(highlights) do highlight:Destroy() end
    table.clear(highlights)
end
local gui = make("ScreenGui", {
    Name = "SmallTestUI", ResetOnSpawn = false, DisplayOrder = 950,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, nil)
local parent = player:WaitForChild("PlayerGui")
if type(gethui) == "function" then
    local ok, hidden = pcall(gethui)
    if ok and typeof(hidden) == "Instance" then parent = hidden end
end
local ok = pcall(function() gui.Parent = parent end)
if not ok then gui.Parent = player:WaitForChild("PlayerGui") end

local frame = make("Frame", {
    Position = UDim2.fromOffset(24, 90), Size = UDim2.fromOffset(220, 44),
    BackgroundColor3 = Color3.fromRGB(22, 24, 32), BorderSizePixel = 0,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 9) }, frame)
make("UIStroke", { Color = Color3.fromRGB(78, 85, 112), Thickness = 1 }, frame)
local function button(name, label, position, size)
    local b = make("TextButton", {
        Name = name, Text = label, Position = position, Size = size,
        BackgroundColor3 = Color3.fromRGB(39, 43, 57), BorderSizePixel = 0,
        TextColor3 = Color3.fromRGB(240, 241, 247), Font = Enum.Font.GothamBold,
        TextSize = 13, AutoButtonColor = true,
    }, frame)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    return b
end
local test = button("Test", "TEST", UDim2.fromOffset(8, 7), UDim2.fromOffset(168, 30))
local close = button("Close", "X", UDim2.fromOffset(182, 7), UDim2.fromOffset(30, 30))
local esp = button("ESP", "ESP: OFF", UDim2.fromOffset(8, 51), UDim2.fromOffset(204, 34))
local noclip = button("Noclip", "NOCLIP: OFF", UDim2.fromOffset(8, 93), UDim2.fromOffset(204, 34))
esp.Visible, noclip.Visible = false, false
local function paint(b, title, on)
    b.Text = title .. (on and ": ON" or ": OFF")
    b.BackgroundColor3 = on and Color3.fromRGB(62, 92, 151) or Color3.fromRGB(39, 43, 57)
end
connect(test.Activated, function()
    expanded = not expanded
    esp.Visible, noclip.Visible = expanded, expanded
    frame.Size = UDim2.fromOffset(220, expanded and 136 or 44)
    test.Text = expanded and "TEST / HIDE" or "TEST"
end)
connect(esp.Activated, function()
    api.ESP = not api.ESP
    paint(esp, "ESP", api.ESP)
    if not api.ESP then clearESP() end
end)
connect(noclip.Activated, function()
    api.Noclip = not api.Noclip
    paint(noclip, "NOCLIP", api.Noclip)
    if not api.Noclip then restoreCollisions() end
end)
function api.Unload()
    if not alive then return end
    alive = false
    api.ESP, api.Noclip = false, false
    restoreCollisions(); clearESP()
    for _, connection in ipairs(connections) do connection:Disconnect() end
    table.clear(connections)
    gui:Destroy()
    if env.SmallTestUI == api then env.SmallTestUI = nil end
end
connect(close.Activated, api.Unload)
connect(gui.Destroying, api.Unload)
connect(player.CharacterRemoving, restoreCollisions)
connect(Players.PlayerRemoving, function(plr)
    if highlights[plr] then highlights[plr]:Destroy(); highlights[plr] = nil end
end)
connect(RunService.Stepped, function()
    if not alive or not api.Noclip then return end
    local character = player.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            if collisions[part] == nil then collisions[part] = part.CanCollide end
            part.CanCollide = false
        end
    end
end)
local elapsed = 0
connect(RunService.Heartbeat, function(dt)
    if not alive or not api.ESP then return end
    elapsed += dt
    if elapsed < 0.2 then return end
    elapsed = 0
    for plr, highlight in pairs(highlights) do
        local char = plr.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not plr.Parent or not char or not char.Parent or not humanoid or humanoid.Health <= 0
            or highlight.Adornee ~= char or highlight.Parent ~= char then
            highlight:Destroy(); highlights[plr] = nil
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and not highlights[plr] then
            local char = plr.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if char and char.Parent and humanoid and humanoid.Health > 0 then
                highlights[plr] = make("Highlight", {
                    Name = "SmallTestESP", Adornee = char,
                    FillColor = Color3.fromRGB(105, 173, 255), OutlineColor = Color3.new(1, 1, 1),
                    FillTransparency = 0.55, OutlineTransparency = 0,
                    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                }, char)
            end
        end
    end
end)
env.SmallTestUI = api
return api
