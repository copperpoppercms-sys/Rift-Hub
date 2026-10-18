-- Lifecycle/input fixture. Does not simulate Roblox physics, animation access, or server rules.
local checks=0
local function check(value,why) assert(value,why);checks+=1 end
local function near(actual,expected) check(math.abs(actual-expected)<.00001,tostring(actual).." differs from "..tostring(expected)) end
local function signal()
	local s={connections={}}
	function s:Connect(fn)
		local c={Connected=true,fn=fn};function c:Disconnect() self.Connected=false end
		table.insert(self.connections,c);return c
	end
	function s:Fire(...) for _,c in ipairs(self.connections) do if c.Connected then c.fn(...) end end end
	function s:Count() local n=0;for _,c in ipairs(self.connections) do if c.Connected then n+=1 end end;return n end
	return s
end
local Enum=setmetatable({},{__index=function(t,k)
	local child=setmetatable({},{__index=function(_,v) return k.."."..v end});rawset(t,k,child);return child
end})
local vector={}
local Vector3={}
function Vector3.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vector) end
Vector3.zero=Vector3.new()
vector.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vector.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vector.__mul=function(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vector.__index=function(a,key)
	if key=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
	if key=="Unit" then return Vector3.new(a.X/a.Magnitude,a.Y/a.Magnitude,a.Z/a.Magnitude) end
end
local Vector2={new=function(x,y) return Vector3.new(x,y,0) end}
local UDim2={new=function(xs,xo,ys,yo) return {X={Scale=xs,Offset=xo},Y={Scale=ys,Offset=yo}} end}
function UDim2.fromOffset(x,y) return UDim2.new(0,x,0,y) end
function UDim2.fromScale(x,y) return UDim2.new(x,0,y,0) end
local UDim={new=function(...) return {...} end}
local Color3={fromRGB=function(...) return {...} end}
local created,failClass={},nil
local function object(class,props,parent)
	if class==failClass then error("simulated UI failure") end
	local o={ClassName=class,children={},InputBegan=signal(),Activated=signal(),Parent=parent}
	for key,value in pairs(props or {}) do o[key]=value end
	if parent and parent.children then table.insert(parent.children,o) end
	function o:Destroy() for _,child in ipairs(self.children) do child:Destroy() end;self.Parent=nil;self.Destroyed=true end
	table.insert(created,o);return o
end
local Instance={new=function(class) return object(class) end}
local animationTracks,animationFailure={},false
local function character()
	local animator={}
	function animator:LoadAnimation(animation)
		if animationFailure then error("animation access denied") end
		local t={Id=animation.AnimationId,Length=2,IsPlaying=false,TimePosition=0,Destroyed=false}
		function t:Play(_,_,speed) self.IsPlaying=true;self.Speed=speed end
		function t:AdjustSpeed(speed) self.Speed=speed end
		function t:Stop() self.IsPlaying=false end
		function t:Destroy() self.Destroyed=true end
		table.insert(animationTracks,t);return t
	end
	local root={Parent={},Anchored=false,AssemblyMass=10,AssemblyLinearVelocity=Vector3.zero,CFrame={LookVector=Vector3.new(0,0,-1)},impulses=0}
	function root:ApplyImpulse(impulse) self.impulses+=1;self.AssemblyLinearVelocity=self.AssemblyLinearVelocity+impulse*(1/self.AssemblyMass) end
	local hum={Health=100,FloorMaterial=Enum.Material.Concrete,PlatformStand=false,Sit=false,WalkSpeed=24,MoveDirection=Vector3.zero}
	function hum:FindFirstChildOfClass(class) if class=="Animator" then return animator end end
	function hum:ChangeState(state) self.LastState=state end
	local char={root=root,hum=hum,attributes={}}
	function char:FindFirstChildOfClass(class) if class=="Humanoid" then return hum end end
	function char:FindFirstChild(name) if name=="HumanoidRootPart" then return root end end
	function char:GetAttribute(key) return self.attributes[key] end
	return char
end
local player={Character=character(),CharacterRemoving=signal()}
function player:WaitForChild() return {} end
local UIS={InputEnded=signal(),InputChanged=signal(),WindowFocusReleased=signal()}
local run={Heartbeat=signal()}
local workspace={CurrentCamera={ViewportSize=Vector3.new(390,844,0)}}
local game={GetService=function(_,name)
	if name=="Players" then return {LocalPlayer=player} elseif name=="RunService" then return run elseif name=="UserInputService" then return UIS else return {} end
end}
local Kit={create=object,face=function() return "font" end,SUB="sub",INK="ink"}
local Utils={GetCharacter=function() return player.Character end}
local clock=0
local os={clock=function() return clock end}
local create=(function()
-- HULK LEAP
end)()
local function step(dt) clock+=dt;run.Heartbeat:Fire(dt) end
local function widget(name)
	for i=#created,1,-1 do if created[i].Name==name and not created[i].Destroyed then return created[i] end end
	error("missing widget "..name)
end
local function touch() return {UserInputType=Enum.UserInputType.Touch,UserInputState=Enum.UserInputState.Begin,Position=Vector3.new(200,200,0)} end
local function mouse() return {UserInputType=Enum.UserInputType.MouseButton1,UserInputState=Enum.UserInputState.Begin,Position=Vector3.new(200,200,0)} end
local function land(m)
	player.Character.hum.FloorMaterial=Enum.Material.Air;step(.2)
	player.Character.hum.FloorMaterial=Enum.Material.Concrete;step(.4)
	check(m.Phase=="ready","landing did not reset the charge")
end
local m=create(Utils,Kit)
check(not m.Enabled and m.Phase=="off","leap enabled itself")
check(m.SetEnabled(true),"control could not open")
local button=widget("HoldLeap")
local a,b=touch(),touch()
button.InputBegan:Fire(a);step(1.1)
near(m.Power,.5);check(m.Phase=="charging","hold did not charge")
local squat=animationTracks[1]
check(squat.Id=="rbxassetid://99086193071059" and squat.IsPlaying,"wrong squat animation")
near(squat.TimePosition,.5);near(squat.Speed,0)
UIS.InputEnded:Fire(b)
check(m.Phase=="charging" and player.Character.root.impulses==0,"other finger released the charge")
button.InputBegan:Fire(b);step(5)
near(m.Power,1);near(squat.TimePosition,1)
check(player.Character.root.impulses==0,"full charge launched while still held")
check(m.SetEnabled(true) and m.Phase=="charging","opening existing controls reset an active charge")
UIS.InputEnded:Fire(a)
check(m.Phase=="airborne" and player.Character.root.impulses==1,"release did not launch exactly once")
near(player.Character.root.AssemblyLinearVelocity.Y,140);near(player.Character.root.AssemblyLinearVelocity.Z,-125)
check(not squat.IsPlaying and animationTracks[2].Id=="rbxassetid://74116059836265","launch animation missing")
UIS.InputEnded:Fire(a);button.InputBegan:Fire(b)
check(player.Character.root.impulses==1 and m.Phase=="airborne","repeated release or midair input launched twice")
land(m)
-- Partial charge respects the current movement direction and does not accumulate old velocity.
player.Character.hum.MoveDirection=Vector3.new(1,0,0)
local c=mouse();button.InputBegan:Fire(c);step(1.1);UIS.InputEnded:Fire(mouse())
near(player.Character.root.AssemblyLinearVelocity.X,82.5);near(player.Character.root.AssemblyLinearVelocity.Y,97.5);near(player.Character.root.AssemblyLinearVelocity.Z,0)
near(player.Character.hum.WalkSpeed,24)
land(m)
local count=player.Character.root.impulses
button.InputBegan:Fire(a);step(.3);UIS.WindowFocusReleased:Fire();UIS.InputEnded:Fire(a)
check(m.Phase=="ready" and player.Character.root.impulses==count,"focus loss launched instead of cancelling")
button.InputBegan:Fire(a);a.UserInputState=Enum.UserInputState.Cancel;UIS.InputEnded:Fire(a);a.UserInputState=Enum.UserInputState.Begin
check(m.Phase=="ready" and player.Character.root.impulses==count,"cancelled touch launched")
player.Character.root.Anchored=true;button.InputBegan:Fire(a)
check(m.Phase=="ready","anchored body charged")
player.Character.root.Anchored=false;player.Character.hum.FloorMaterial=Enum.Material.Air;button.InputBegan:Fire(a)
check(m.Phase=="ready","midair body charged")
player.Character.hum.FloorMaterial=Enum.Material.Concrete
player.Character.attributes.LOCKED_INPUTS=true;button.InputBegan:Fire(a)
check(m.Phase=="ready","game input lock was bypassed")
player.Character.attributes.LOCKED_INPUTS=false
button.InputBegan:Fire(a);player.Character.attributes.canRun=false;step(.1);UIS.InputEnded:Fire(a)
check(m.Phase=="ready" and player.Character.root.impulses==count,"movement lock during hold still launched")
player.Character.attributes.canRun=true
m.CanUse=function() return false,"Flight active" end;button.InputBegan:Fire(a)
check(m.Phase=="ready","flight conflict was ignored")
m.CanUse=nil
button.InputBegan:Fire(a);step(.2);m.SetEnabled(false);UIS.InputEnded:Fire(a)
check(not m.Enabled and player.Character.root.impulses==count,"disabling while held launched")
m.SetEnabled(true);button.InputBegan:Fire(a);step(.2);player.CharacterRemoving:Fire(player.Character)
local old=player.Character;player.Character=character();UIS.InputEnded:Fire(a)
check(old.root.impulses==count and player.Character.root.impulses==0,"respawn released an old charge")
check(squat.Destroyed,"respawn leaked the old animation")
-- Animation permission errors must not crash charging or the physics request.
animationFailure=true
button.InputBegan:Fire(a);step(.5);UIS.InputEnded:Fire(a)
check(m.Phase=="airborne" and player.Character.root.impulses==1,"animation failure broke the leap")
land(m)
-- New-character death cancels without releasing an impulse.
button.InputBegan:Fire(a);player.Character.hum.Health=0;step(.1);UIS.InputEnded:Fire(a)
check(player.Character.root.impulses==1,"death launched the character")
m.Stop();m.Stop()
check(UIS.InputEnded:Count()==0 and UIS.InputChanged:Count()==0 and UIS.WindowFocusReleased:Count()==0 and run.Heartbeat:Count()==0 and player.CharacterRemoving:Count()==0,"unload leaked an input or frame listener")
check(not m.SetEnabled(true),"stopped feature reopened")
-- A partially built control must not block a later attempt.
player.Character=character();animationFailure=false
local retry=create(Utils,Kit);failClass="TextButton"
check(not retry.SetEnabled(true) and not retry.Enabled,"failed UI setup left the feature enabled")
failClass=nil;check(retry.SetEnabled(true),"UI failure prevented retry")
retry.Stop()
check(run.Heartbeat:Count()==0 and UIS.InputEnded:Count()==0,"retry cleanup leaked listeners")
print("PASS: "..checks.." Hulk leap checks for charge scaling, animation IDs, release, touch ownership, physics request, cancellation, locks, landing, respawn, failures and cleanup.")
