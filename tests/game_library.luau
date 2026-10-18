-- Unit tests for fetch/compile/execute handoff, without running the supplied MM2 features.
local env = {}
local warn = function() end
local getgenv = function() return env end
local game = { PlaceId = 142823291, GameId = 66654135 }
local source, fetchError, fetchHook,lastUrl
function game:HttpGet(url)
	lastUrl=url
	if fetchHook then fetchHook() end
	if fetchError then error("network failed") end
	return source
end
local task = { spawn = function(fn) fn() end }
local LibraryCtor = (function()
-- LIBRARY
end)()
local function controller()
	local events, cleanup, restarts, open = {}, 0, 0, true
	local ctx = { Janitor = { add = function(fn) table.insert(events, fn) end } }
	ctx.Unload = function()
		cleanup += 1; open = false
		for _, fn in ipairs(events) do fn() end
	end
	ctx.Restart = function() restarts += 1; open = true end
	local m = LibraryCtor(ctx)
	return m, function() return cleanup, restarts, open end
end
source = "return {Game='Murder Mystery 2',Gui={Parent=true}}"
local m, state = controller()
assert(m.Games[1].Url == "https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-MM2/main/main.lua")
assert(m.Games[1].IconUrl == "https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-MM2/main/assets/mm2_icon.png")
assert(m.Execute(m.Games[1]))
local closed, restarted, open = state(); assert(closed == 1 and restarted == 0 and not open)
assert(m.Status == "MM2 open", "successful handoff did not finish")

fetchError = true; m, state = controller()
assert(not m.Execute(m.Games[1])); closed, restarted, open = state(); assert(closed == 0 and open)
fetchError = false; source = "this is invalid Luau syntax"; m, state = controller()
assert(not m.Execute(m.Games[1])); closed, restarted, open = state(); assert(closed == 0 and open)

local partial, rollback = 0, 0
for _, broken in ipairs({ "error('runtime failure')", "return nil" }) do
	source = broken
	env.MONO_Unload = function() partial += 1 end
	env.RiftMM2StartupCleanup = function() rollback += 1 end
	m, state = controller(); assert(not m.Execute(m.Games[1]))
	closed, restarted, open = state(); assert(closed == 1 and restarted == 1 and open)
end
assert(partial == 2 and rollback == 2, "partial MM2 startup was not cleaned up")

source = "return {Game='Murder Mystery 2',Gui={Parent=true}}"
m, state = controller()
fetchHook = function() m.Dispose() end
assert(not m.Execute(m.Games[1])); closed, restarted, open = state(); assert(closed == 0 and open, "closed library still executed")
fetchHook = nil
m, state = controller()
local duplicateResult
fetchHook = function() duplicateResult = m.Execute(m.Games[1]) end
assert(m.Execute(m.Games[1])); assert(duplicateResult == false, "double execution was accepted")
fetchHook = nil

game.PlaceId, game.GameId = 1, 1; m, state = controller()
assert(not m.Execute(m.Games[1])); closed, restarted, open = state(); assert(closed == 0 and open, "wrong-game launch closed the hub")
print("PASS: MM2 handoff, network/compile failures, runtime rollback, duplicate clicks, cancelled loading, and wrong-game protection.")

-- Superhero Arena uses a distinct repository, game guard, icon and cleanup.
m,state=controller(); local hero=m.Games[2]
assert(#m.Games==3 and hero.Id=="superhero-arena")
assert(hero.PlaceId==78710221869926 and hero.UniverseId==10765491459)
assert(hero.Url=="https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua")
assert(hero.IconUrl:find("Rift-Hub-Superhero-Arena/main/assets/superhero_arena_icon.png",1,true))
assert(hero.Handoff=="Opens Superhero Arena and closes hub")
assert(not m.Execute(hero)); closed,restarted,open=state(); assert(closed==0 and open and m.Status=="Open Superhero Arena first")
game.PlaceId,game.GameId=hero.PlaceId,hero.UniverseId
source="return {Game='Superhero Arena',Gui={Parent=true},Enabled=false}"
m,state=controller(); assert(m.Execute(m.Games[2]))
closed,restarted,open=state(); assert(closed==1 and not open and restarted==0)
assert(lastUrl:find("Rift-Hub-Superhero-Arena/main/main.lua?cb=",1,true) and m.Status=="Superhero Arena open")
-- Subplaces in the same universe are accepted.
game.PlaceId=1; m,state=controller(); assert(m.Execute(m.Games[2]))
-- Wrong script/failed startup must close the partial panel and reopen the main hub.
local heroCleanup=0
env.SuperheroArenaHub={Unload=function() heroCleanup+=1 end}
source="return {Game='Murder Mystery 2',Gui={Parent=true}}"
m,state=controller(); assert(not m.Execute(m.Games[2]))
closed,restarted,open=state(); assert(closed==1 and restarted==1 and open and heroCleanup==1)
fetchError=true; m,state=controller(); assert(not m.Execute(m.Games[2])); closed,restarted,open=state(); assert(closed==0 and open)
fetchError=false; source="return {Game='Superhero Arena',Gui={Parent=true}}"
m,state=controller(); fetchHook=function() m.Dispose() end
assert(not m.Execute(m.Games[2])); closed,restarted,open=state(); assert(closed==0 and open)
fetchHook=nil
m,state=controller(); duplicateResult=nil
fetchHook=function() duplicateResult=m.Execute(m.Games[2]) end
assert(m.Execute(m.Games[2]) and duplicateResult==false); fetchHook=nil
m,state=controller(); assert(not m.Execute({Url=hero.Url})); closed,restarted,open=state(); assert(closed==0 and open)
print("PASS: Superhero Arena repository, game IDs, handoff, rollback, cancellation and duplicate protection.")

-- Hulk launcher follows the same handoff and isolates cleanup from the other scripts.
m,state=controller(); local hulk=m.Games[3]
assert(hulk.Id=="survive-the-hulk" and hulk.PlaceId==109166720609444 and hulk.UniverseId==10742937135)
assert(hulk.Url=="https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Survive-The-Hulk/main/main.lua")
assert(hulk.IconUrl=="https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Survive-The-Hulk/main/assets/hulk_icon.png")
assert(hulk.Handoff=="Opens Survive The Hulk and closes hub")
assert(not m.Execute(hulk)); closed,restarted,open=state(); assert(closed==0 and open)
game.PlaceId,game.GameId=hulk.PlaceId,hulk.UniverseId
source="return {Game='Survive The Hulk',Gui={Parent=true}}"
m,state=controller(); assert(m.Execute(m.Games[3]))
closed,restarted,open=state(); assert(closed==1 and not open and restarted==0)
assert(lastUrl:find("Rift-Hub-Survive-The-Hulk/main/main.lua?cb=",1,true))
game.PlaceId=1; m,state=controller(); assert(m.Execute(m.Games[3]))
fetchError=true; m,state=controller(); assert(not m.Execute(m.Games[3]))
closed,restarted,open=state(); assert(closed==0 and open); fetchError=false
source="invalid @@ code"; m,state=controller(); assert(not m.Execute(m.Games[3]))
closed,restarted,open=state(); assert(closed==0 and open)
local hulkCleanup,partialCleanup=0,0
env.RiftHulkHub={Unload=function() hulkCleanup+=1 end}
local orphan={Destroy=function() partialCleanup+=1 end}
function game:GetService(name)
	if name=="CoreGui" then return {FindFirstChild=function(_,key) if key=="RiftSurviveTheHulk" then return orphan end end} end
	if name=="Players" then return {LocalPlayer={FindFirstChild=function() return nil end}} end
	error(name)
end
source="error('Hulk startup failed')"; m,state=controller(); assert(not m.Execute(m.Games[3]))
closed,restarted,open=state(); assert(closed==1 and restarted==1 and open and hulkCleanup==1 and partialCleanup==1)
assert(heroCleanup==1,"Hulk failure incorrectly unloaded Superhero Arena")
source="return {Game='Murder Mystery 2',Gui={Parent=true}}"; m,state=controller(); assert(not m.Execute(m.Games[3]))
closed,restarted,open=state(); assert(closed==1 and restarted==1 and open and hulkCleanup==2)
source="return {Game='Survive The Hulk',Gui={Parent=true}}"
m,state=controller(); fetchHook=function() m.Dispose() end
assert(not m.Execute(m.Games[3])); closed,restarted,open=state(); assert(closed==0 and open); fetchHook=nil
m,state=controller(); fetchHook=function() duplicateResult=m.Execute(m.Games[3]) end
assert(m.Execute(m.Games[3]) and duplicateResult==false); fetchHook=nil
print("PASS: Hulk card metadata, handoff, subplaces, fetch/compile/startup failure, isolated cleanup, cancellation and duplicate protection.")

-- Slider/keybind handlers must disappear when the main window is destroyed.
local function signal()
	local event = { handlers = {} }
	function event:Connect(fn)
		local c = { Connected = true, fn = fn }
		function c:Disconnect() self.Connected = false end
		table.insert(self.handlers, c); return c
	end
	function event:Fire(...) for _, c in ipairs(self.handlers) do if c.Connected then c.fn(...) end end end
	return event
end
local function enum() return setmetatable({}, { __index = function(t,k) local v=enum(); rawset(t,k,v); return v end }) end
local Enum = enum()
local Color3 = { new = function(...) return {...} end, fromRGB = function(...) return {...} end }
local UDim2 = { new = function(...) return {...} end, fromOffset = function(...) return {...} end, fromScale = function(...) return {...} end }
local UDim, Vector2 = { new = function(...) return {...} end }, { new = function(...) return {...} end }
local Font = { fromName = function() return {} end, fromEnum = function() return {} end }
local TweenInfo = { new = function() return {} end }
local input = { InputChanged = signal(), InputEnded = signal(), InputBegan = signal() }
local tween = { Create = function(_, item, _, values)
	return { Play = function() for k,v in pairs(values) do item[k] = v end end }
end }
function game:GetService(name) return name == "TweenService" and tween or input end
local widgets = {}
local Instance = { new = function(class)
	local item = { ClassName = class, AbsolutePosition = { X=0 }, AbsoluteSize = { X=100 },
		MouseButton1Click = signal(), InputBegan = signal(), Destroying = signal() }
	function item:Destroy() self.Destroying:Fire(); self.Parent = nil end
	table.insert(widgets,item); return item
end }
local Kit = (function()
-- KIT
end)()
local calls = 0
Kit.Slider({ Body={}, _order=0 }, "Test", nil, 0,100,50,{ OnChanged=function() calls+=1 end })
local track
for _, item in ipairs(widgets) do if #item.InputBegan.handlers > 0 then track=item end end
assert(track)
track.InputBegan:Fire({ UserInputType=Enum.UserInputType.MouseButton1, Position={X=50} })
assert(calls==1)
track:Destroy(); input.InputChanged:Fire({ UserInputType=Enum.UserInputType.MouseMovement, Position={X=80} })
assert(calls==1,"destroyed slider still receives input")
local bindCalls = 0
Kit.KeybindRow({ Body={}, _order=0 }, "Test", nil,nil,function() bindCalls+=1 end)
local button
for i=#widgets,1,-1 do if #widgets[i].MouseButton1Click.handlers>0 then button=widgets[i];break end end
button.MouseButton1Click:Fire(); button:Destroy()
input.InputBegan:Fire({ UserInputType=Enum.UserInputType.Keyboard, KeyCode=Enum.KeyCode.E },false)
assert(bindCalls==0,"destroyed keybind still captures keys")
print("PASS: main-window slider and keybind handlers are disconnected on destruction.")
