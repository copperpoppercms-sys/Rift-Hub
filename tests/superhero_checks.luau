-- A minimal simulated Roblox client; exercises the complete standalone file.
local allSignals, allInstances, checks = {}, {}, 0
local function check(value, message)
	checks += 1
	assert(value, message)
end
local function signal()
	local s = { handlers = {} }; table.insert(allSignals, s)
	function s:Connect(fn)
		local c = { Connected = true, fn = fn, Function = fn }
		function c:Disconnect() self.Connected = false end
		table.insert(self.handlers, c)
		return c
	end
	function s:Fire(...)
		for _, c in ipairs(table.clone(self.handlers)) do if c.Connected then c.fn(...) end end
	end
	return s
end
local function enum()
	return setmetatable({}, { __index = function(t, key) local v = enum(); rawset(t, key, v); return v end })
end
local Enum = enum()
Enum.RenderPriority.Camera.Value = 200
local V2 = {}
V2.__index = function(t, k) if k == "Magnitude" then return math.sqrt(t.X*t.X+t.Y*t.Y) end; return V2[k] end
V2.__add = function(a,b) return setmetatable({ X=a.X+b.X, Y=a.Y+b.Y }, V2) end
V2.__sub = function(a,b) return setmetatable({ X=a.X-b.X, Y=a.Y-b.Y }, V2) end
V2.__eq = function(a,b) return a.X == b.X and a.Y == b.Y end
V2.__mul = function(a,b) return setmetatable({X=a.X*b,Y=a.Y*b},V2) end
local Vector2 = { new = function(x,y) return setmetatable({ X=x or 0, Y=y or 0 }, V2) end }
local V3 = {}
V3.__index = function(t,k)
	if k == "Magnitude" then return math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z) end
	if k == "Unit" then local m=math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z); return setmetatable({X=t.X/m,Y=t.Y/m,Z=t.Z/m},V3) end
	return V3[k]
end
V3.__sub = function(a,b) return setmetatable({ X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z }, V3) end
V3.__add = function(a,b) return setmetatable({ X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z }, V3) end
V3.__mul = function(a,b) if type(a)=="number" then a,b=b,a end; return setmetatable({ X=a.X*b,Y=a.Y*b,Z=a.Z*b }, V3) end
function V3:Dot(b) return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
local Vector3 = { new = function(x,y,z) return setmetatable({ X=x or 0,Y=y or 0,Z=z or 0 }, V3) end }
local RaycastParams={new=function() return {} end}
local UDim = { new = function(scale, offset) return { Scale=scale or 0, Offset=offset or 0 } end }
local UDim2 = {
	new = function(xs,xo,ys,yo) return { X=UDim.new(xs,xo), Y=UDim.new(ys,yo) } end,
	fromOffset = function(x,y) return { X=UDim.new(0,x), Y=UDim.new(0,y) } end,
	fromScale = function(x,y) return { X=UDim.new(x,0), Y=UDim.new(y,0) } end,
}
local Color3 = { new=function(...) return {...} end, fromRGB=function(...) return {...} end, fromHSV=function(...) return {...} end }
local ColorSequence = { new=function(...) return {...} end }
local TweenInfo = { new=function(...) return {...} end }
local pending = {}
local task = { delay = function(_,fn) table.insert(pending,fn) end }
local function flush() local calls=pending; pending={}; for _,fn in ipairs(calls) do fn() end end
local lookCalls, lastLook, lastAlpha = 0,nil,nil
local CFrame = {}
function CFrame.lookAt(position, point)
	return { Position=position, Point=point }
end
local cameraFrame = {Position=Vector3.new()}
function cameraFrame:Lerp(goal, alpha)
	lookCalls+=1; lastLook=goal.Point; lastAlpha=alpha
	return self
end
local camera = { FieldOfView=70, ViewportSize=Vector2.new(1280,720), CFrame=cameraFrame }

function camera:WorldToViewportPoint(p) return Vector3.new(640+p.X*10,360-p.Y*10,20),true end
local instanceMethods = {}
local guiClasses = { Frame=true, CanvasGroup=true, TextLabel=true, TextButton=true, TextBox=true, ScrollingFrame=true, ImageLabel=true }
local function isA(node, class)
	return node.ClassName == class or class == "Instance" or (class == "GuiObject" and guiClasses[node.ClassName])
		or (class == "GuiButton" and (node.ClassName == "TextButton" or node.ClassName == "ImageButton"))
		or (class == "BasePart" and (node.ClassName == "Part" or node.ClassName == "MeshPart"))
end
local mt = {}
mt.__index = function(t, key)
	if instanceMethods[key] then return instanceMethods[key] end
	local props=rawget(t,"_props")
	if key == "AbsoluteSize" then
		if props.ClassName == "ScreenGui" or props.ClassName == "Workspace" or not props.Parent then return camera.ViewportSize end
		local parentSize = props.Parent.AbsoluteSize
		local size=props.Size or UDim2.fromOffset(100,40)
		local scale=1
		for _, child in ipairs(rawget(t,"_children")) do if child.ClassName == "UIScale" then scale=child.Scale end end
		return Vector2.new((parentSize.X*size.X.Scale+size.X.Offset)*scale,(parentSize.Y*size.Y.Scale+size.Y.Offset)*scale)
	end
	if key == "AbsolutePosition" then
		local pos=props.Position or UDim2.new()
		local ps=props.Parent and props.Parent.AbsoluteSize or camera.ViewportSize
		return Vector2.new(ps.X*pos.X.Scale+pos.X.Offset,ps.Y*pos.Y.Scale+pos.Y.Offset)
	end
	return props[key]
end
mt.__newindex = function(t, key, value)
	local props = rawget(t,"_props")
	if key == "Parent" then
		if props.Parent then
			local children=rawget(props.Parent,"_children")
			local index=table.find(children,t); if index then table.remove(children,index) end
		end
		if value then table.insert(rawget(value,"_children"),t) end
	end
	props[key]=value
	local event = rawget(t,"_changes")[key]; if event then event:Fire() end
end
local Instance = {}
function Instance.new(class)
	local obj=setmetatable({ _props={ClassName=class,Name=class,Visible=true,Enabled=true,Text="",Health=100,MaxHealth=100,AssemblyLinearVelocity=Vector3.new(),
		IgnoreGuiInset=false,DisplayOrder=0,GroupTransparency=0,AbsoluteRotation=0,CanCollide=true},
		_children={},_attributes={},_changes={},_destroyed=false },mt)
	for _,name in ipairs({"Destroying","MouseEnter","MouseLeave","Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up","InputBegan","AnimationPlayed"}) do obj[name]=signal() end
	table.insert(allInstances,obj); return obj
end
function instanceMethods:IsA(class) return isA(self,class) end
function instanceMethods:GetChildren() return table.clone(rawget(self,"_children")) end
function instanceMethods:GetDescendants()
	local result={}
	local function visit(parent)
		for _,child in ipairs(parent:GetChildren()) do table.insert(result,child); visit(child) end
	end
	visit(self); return result
end
function instanceMethods:GetAttributes() return table.clone(rawget(self,"_attributes")) end
function instanceMethods:SetAttribute(key,value) rawget(self,"_attributes")[key]=value end
function instanceMethods:GetAttribute(key) return rawget(self,"_attributes")[key] end
function instanceMethods:FindFirstChild(name)
	for _,child in ipairs(self:GetChildren()) do if child.Name==name then return child end end
end
function instanceMethods:FindFirstChildOfClass(class)
	for _,child in ipairs(self:GetChildren()) do if child:IsA(class) then return child end end
end
function instanceMethods:FindFirstAncestorWhichIsA(class)
	local parent=self.Parent
	while parent do if parent:IsA(class) then return parent end; parent=parent.Parent end
end
function instanceMethods:GetFullName() return self.Parent and self.Parent:GetFullName().."."..self.Name or self.Name end
function instanceMethods:GetPropertyChangedSignal(name)
	local changes=rawget(self,"_changes"); if not changes[name] then changes[name]=signal() end; return changes[name]
end
function instanceMethods:WaitForChild(name) return assert(self:FindFirstChild(name)) end
function instanceMethods:IsDescendantOf(parent)
	local ancestor=self.Parent
	while ancestor do if ancestor==parent then return true end; ancestor=ancestor.Parent end
	return false
end
local guiHits={}
function instanceMethods:GetGuiObjectsAtPosition() return guiHits[self] or {} end
function instanceMethods:ReleaseFocus() end
function instanceMethods:MoveTo(position) self.LastMoveTo=position; self.Moves=(self.Moves or 0)+1 end
function instanceMethods:ChangeState(state) self.LastState=state end
function instanceMethods:Activate() self.Activations=(self.Activations or 0)+1 end
function instanceMethods:GetBoundingBox()
	return { PointToWorldSpace=function(_,p) return p end },Vector3.new(4,6,2)
end
local loadedTracks={}
function instanceMethods:LoadAnimation(animation)
	local track=Instance.new("AnimationTrack"); track.Animation=animation; track.Name=animation.Name
	track.Length=0.24; track.IsPlaying=false; track.Animator=self
	table.insert(loadedTracks,track); return track
end
function instanceMethods:Play() self.IsPlaying=true; if self.Animator then self.Animator.AnimationPlayed:Fire(self) end end
function instanceMethods:Stop() self.IsPlaying=false end
function instanceMethods:Destroy()
	if rawget(self,"_destroyed") then return end
	rawset(self,"_destroyed",true); self.Destroying:Fire()
	for _,child in ipairs(self:GetChildren()) do child:Destroy() end
	for _,v in pairs(rawget(self,"_props")) do if type(v)=="table" and v.handlers then for _,c in ipairs(v.handlers) do c:Disconnect() end end end
	for _,v in pairs(rawget(self,"_changes")) do for _,c in ipairs(v.handlers) do c:Disconnect() end end
	self.Parent=nil
end
local function node(class,name,parent,value)
	local obj=Instance.new(class); obj.Name=name; obj.Parent=parent
	if value~=nil then obj.Value=value end
	return obj
end
local workspace = node("Workspace","Workspace"); workspace.Gravity=196.2; workspace.CurrentCamera=camera
local wall=false
local forcedHit
function workspace:Raycast() return forcedHit and {Instance=forcedHit} or wall and {Instance=workspace} or nil end
local blockcasts=0
function workspace:Blockcast() blockcasts+=1; return wall and {Instance=workspace} or nil end
local replicated=node("Folder","ReplicatedStorage")
local players = node("Players","Players"); players.PlayerRemoving=signal()
local people={}
function players:GetPlayers() return table.clone(people) end
local function player(name,id)
	local p=node("Player",name,players); p.UserId=id; p.DisplayName=name.." Display"
	table.insert(people,p); return p
end
local localPlayer=player("Owner",1); players.LocalPlayer=localPlayer
local other=player("Other",2)
local function character(plr)
	local model=node("Model",plr.Name,workspace)
	local head=node("Part","Head",model); head.Position=Vector3.new(0,4,0)
	local root=node("Part","HumanoidRootPart",model); root.Position=Vector3.new()
	root.AssemblyLinearVelocity=Vector3.new(); root.Anchored=false
	root.Size=Vector3.new(2,2,1)
	root.CFrame={LookVector=Vector3.new(0,0,-1),RightVector=Vector3.new(1,0,0)}
	model.PrimaryPart=root
	local h=node("Humanoid","Humanoid",model); h.JumpPower=50; h.JumpHeight=7.2; h.UseJumpPower=true; h.MoveDirection=Vector3.new(); h.WalkSpeed=16; h.AutoRotate=true
	node("Animator","Animator",h); plr.Character=model
	return model
end
character(localPlayer); character(other)
node("PlayerGui","PlayerGui",localPlayer)
local coreGui=node("CoreGui","CoreGui")
local run={ Heartbeat=signal(), RenderStepped=signal(),PreSimulation=signal() }
local renderBindings={}
function run:BindToRenderStep(name, priority, fn) renderBindings[name]={priority=priority,fn=fn} end
function run:UnbindFromRenderStep(name) renderBindings[name]=nil end
local function renderAim(dt) for _,binding in pairs(renderBindings) do binding.fn(dt or 1/60) end end
local focusedBox
local input={ InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),WindowFocusReleased=signal(),WindowFocused=signal(),JumpRequest=signal(),GetFocusedTextBox=function() return focusedBox end }
local tweens={ Create=function(_,item,_,props)
	return { Cancel=function() end, Play=function() for k,v in pairs(props) do item[k]=v end end }
end }
local sentKeys, rejectKeys = {},false
local vim={SendKeyEvent=function(_,down,key)
	if rejectKeys then error("virtual input unavailable") end
	table.insert(sentKeys,{down=down,key=key})
end}
local lighting=node("Lighting","Lighting")
lighting.Brightness=1; lighting.Ambient="Ambient"; lighting.OutdoorAmbient="Outdoor"; lighting.GlobalShadows=true; lighting.FogStart=15; lighting.FogEnd=400
local atmosphere=node("Atmosphere","Atmosphere",lighting); atmosphere.Density=0.4; atmosphere.Haze=2
local teleports,lastTeleport=0,nil
local teleportService={TeleportToPlaceInstance=function(_,place,job,plr) teleports+=1; lastTeleport=job end,Teleport=function() teleports+=1 end}
local services={TeleportService=teleportService,Lighting=lighting,Players=players,RunService=run,UserInputService=input,TweenService=tweens,CoreGui=coreGui,VirtualInputManager=vim,ReplicatedStorage=replicated}
local game={PlaceId=123456,JobId="current-server",GetService=function(_,name) return assert(services[name],name) end}
local env={}
local getgenv=function() return env end
local clipboard
local setclipboard=function(value) clipboard=value end
local firesignal=function(s,...) s:Fire(...) end
local getconnections=function(s)
	local connected={}; for _,c in ipairs(s.handlers) do if c.Connected then table.insert(connected,c) end end
	return connected
end
local function boot()
-- INSERT STANDALONE HUB
end
local function find(root,class,text)
	if root.ClassName==class and root.Text==text then return root end
	for _,child in ipairs(root:GetChildren()) do local result=find(child,class,text); if result then return result end end
end
local function findName(root,name)
	if root.Name==name then return root end
	for _,child in ipairs(root:GetChildren()) do local result=findName(child,name); if result then return result end end
end
local api=boot()
check(api==env.SuperheroArenaHub and api.Version=="3.0","new API not exposed")
check(not api.Config.Aura and not api.Config.Hitbox and not api.Config.AutoDash,"features should start off")
local function button(label)
	local item=find(api.Gui,"TextLabel",label)
	check(item and item.Parent:IsA("TextButton"),"missing control: "..label)
	return item.Parent
end
for _,label in ipairs({"Kill Aura","Burst Hits","Auto Face Target","Auto Chase","Big Hitbox","Hero Selection: Iron Man","Auto Skills – Dynamic Hero","Dash Now","Infinite Dash · Unavailable","Auto Dash","Infinite Jump","WalkSpeed","Player ESP","Player Highlights","Fullbright","Rejoin Server"}) do button(label) end
local panels={}; for _,item in ipairs(allInstances) do if item:IsA("ScrollingFrame") and item.Name~="Navigation" and item:IsDescendantOf(api.Gui) then panels[item.Name]=true end end
check(panels.combat and panels.skills and panels.movement and panels.visuals and panels.server,"five required panels missing")
local count=0; for _ in pairs(panels) do count+=1 end
check(count==5,"extra UI panels remain")
check(find(api.Gui,"TextLabel","Auto farm NPCs")==nil and find(api.Gui,"TextLabel","Custom field of view")==nil,"removed feature controls remain")
other.Character:SetAttribute("MorphCurrent","Earth")
check(api.ResolveHero(other)=="Hulk","confirmed hero alias lost")
local own=localPlayer.Character; local ownRoot=own:FindFirstChild("HumanoidRootPart"); local hum=own:FindFirstChildOfClass("Humanoid")
local enemy=other.Character; local enemyRoot=enemy:FindFirstChild("HumanoidRootPart")
enemyRoot.Position=Vector3.new(5,0,0)
local more=player("Farther",3); local moreChar=character(more); moreChar:FindFirstChild("HumanoidRootPart").Position=Vector3.new(12,0,0)
check(api.NearestTarget()==other,"nearest target selection failed")
moreChar:FindFirstChildOfClass("Humanoid").Health=0
local pg=localPlayer:FindFirstChild("PlayerGui")
local native=node("ScreenGui","NativeHUD",pg)
local attack=node("TextButton","AttackButton",native); attack.Text="Attack"
local attackCount,dashCount,skill1Count,skill3Count=0,0,0,0
attack.MouseButton1Click:Connect(function() attackCount+=1 end)
local dash=node("TextButton","DashButton",native); dash.Text="Dash"
dash.Activated:Connect(function() dashCount+=1 end)
local p1=node("TextButton","PrimarySkill",native); p1:SetAttribute("SkillName","Repulsor Blast")
p1.Activated:Connect(function() skill1Count+=1 end)
local p3=node("TextButton","TertiarySkill",native); p3:SetAttribute("SkillName","Unibeam")
p3.Activated:Connect(function() skill3Count+=1 end)
own:SetAttribute("MorphCurrent","Iron Man"); api.RefreshControls()
check(api.Controls.Hero=="Iron Man" and api.Controls.Skills[1].Name=="Repulsor Blast" and api.Controls.Skills[3].Name=="Unibeam","Iron Man profile missing")
check(api.Controls.Skills[2]==nil and api.Controls.Skills[4]==nil,"Iron Man unavailable slots fabricated")
button("Primary Skill: Repulsor Blast"); button("Tertiary Skill: Unibeam"); button("Secondary Skill: Unavailable"); button("Quaternary Skill: Unavailable")
button("Kill Aura").Activated:Fire()
for _=1,10 do api.Step(0.1) end
check(attackCount==0,"combat should pause with menu open")
api.SetMinimized(true)
for _=1,4 do api.Step(0.1) end
check(attackCount==1,"native aura attack missing")
button("Burst Hits").Activated:Fire()
for _=1,6 do api.Step(0.1) end
check(attackCount==4,"burst must send three spaced attacks")
attack:SetAttribute("OnCooldown",true)
for _=1,4 do api.Step(0.1) end
check(api.Config.Aura,"native cooldown incorrectly disabled aura")
attack:SetAttribute("OnCooldown",nil)
focusedBox={}; local before=attackCount
for _=1,8 do api.Step(0.1) end
check(attackCount==before,"aura attacked while typing")
focusedBox=nil; input.WindowFocusReleased:Fire()
for _=1,8 do api.Step(0.1) end
check(attackCount==before,"aura attacked while unfocused")
input.WindowFocused:Fire(); api.Config.Aura=false
api.Config.Face=true; api.Config.Chase=true; enemyRoot.Position=Vector3.new(40,0,0); api.Step(0.1)
check(ownRoot.CFrame.Point.X==40 and ownRoot.CFrame.Position==ownRoot.Position,"facing changed position or failed to aim horizontally")
check(hum.LastMoveTo==enemyRoot.Position,"auto chase did not walk toward target")
api.Config.ChaseRange=20; api.Step(0.1)
check(api.Target==nil and hum.LastMoveTo==ownRoot.Position,"chase range did not stop pursuit")
api.Config.ChaseRange=180; api.Config.Chase=false; api.Config.Face=false; enemyRoot.Position=Vector3.new(5,0,0)
local oldSize=enemyRoot.Size; local oldCollide=enemyRoot.CanCollide
button("Big Hitbox").Activated:Fire()
check(enemyRoot.Size.X==6 and not enemyRoot.CanCollide,"hitbox not enlarged")
api.Config.HitboxSize=9; run.PreSimulation:Fire()
check(enemyRoot.Size.X==9,"hitbox size not updated")
button("Big Hitbox").Activated:Fire()
check(enemyRoot.Size==oldSize and enemyRoot.CanCollide==oldCollide,"hitbox originals not restored")
api.Config.Hitbox=true; run.PreSimulation:Fire()
local replacement=character(other); local replacementRoot=replacement:FindFirstChild("HumanoidRootPart"); replacementRoot.CanCollide=false
run.PreSimulation:Fire()
check(enemyRoot.Size==oldSize and replacementRoot.Size.X==9,"respawn did not restore old hitbox and update new body")
api.Config.Hitbox=false; run.PreSimulation:Fire()
check(not replacementRoot.CanCollide and replacementRoot.Size.X==2,"false collision state lost on hitbox restore")
replacementRoot.Position=Vector3.new(5,0,0)
api.Config.AutoSkills=true; api.Config.SkillInterval=0.2
for _=1,4 do api.Step(0.1) end
check(skill1Count==1 and skill3Count==1,"auto skills did not rotate available slots")
replacementRoot.Position=Vector3.new(40,0,0)
for _=1,4 do api.Step(0.1) end
check(skill1Count==2 and skill3Count==2,"ranged skills incorrectly depended on melee aura range")
replacementRoot.Position=Vector3.new(5,0,0)
api.Config.AutoSkills=false
own:SetAttribute("MorphCurrent","Hulk"); p1:SetAttribute("SkillName","Ground Smash"); p3.Visible=false; api.RefreshControls()
check(api.Controls.Hero=="Hulk" and api.Controls.Skills[1].Name=="Ground Smash" and api.Controls.Skills[3]==nil,"skills did not follow hero/HUD changes")
button("Primary Skill: Ground Smash")
local ambiguous=node("TextButton","OtherPrimary",native); ambiguous:SetAttribute("SkillSlot",1)
own:SetAttribute("MorphCurrent","Iron Man"); api.RefreshControls()
check(api.Controls.Skills[1].Control==nil,"ambiguous skill slots were guessed")
ambiguous:Destroy(); p1:SetAttribute("SkillName","Repulsor Blast")
api.Config.AutoDash=true; api.Config.DashInterval=0.2
for _=1,8 do api.Step(0.1) end
check(api.Controls.Hero=="Iron Man" and api.Controls.Skills[1].Name=="Repulsor Blast","auto dash prevented dynamic skill refresh")
api.Config.AutoDash=false; api.Step(0); dashCount=0
local heroChoice=node("TextButton","IronMan",native); heroChoice.Text="Iron Man"
local choices=0; heroChoice.Activated:Connect(function() choices+=1 end)
check(api.SelectIronMan() and choices==1,"hero selection did not use game menu control")
heroChoice.Visible=false
check(not api.SelectIronMan(),"hero selection claimed success without control")
check(api.DashNow() and dashCount==1,"Dash Now did not activate native dash")
dash:SetAttribute("OnCooldown",true)
local ok,err=api.DashNow()
check(not ok and err=="Cooldown" and dashCount==1,"native dash cooldown ignored")
check(not api.SetInfiniteDash() and not api.SupportsInfiniteDash,"unverified infinite dash claimed support")
dash:SetAttribute("OnCooldown",nil)
api.Config.AutoDash=true; api.Config.DashInterval=0.2
for _=1,4 do api.Step(0.1) end
check(dashCount==3,"auto dash interval failed")
api.Config.AutoDash=false
api.Config.AirJump=true; input.JumpRequest:Fire()
check(hum.LastState==Enum.HumanoidStateType.Jumping,"infinite jump did not request jump")
hum.LastState=nil; focusedBox={}; input.JumpRequest:Fire(); focusedBox=nil
check(hum.LastState==nil,"infinite jump fired while typing")
local speed=hum.WalkSpeed
api.Config.Speed=true; api.Config.SpeedValue=38; run.PreSimulation:Fire()
check(hum.WalkSpeed==38,"walk speed not applied")
api.Config.Speed=false; run.PreSimulation:Fire()
check(hum.WalkSpeed==speed,"walk speed not restored")
api.Config.ESP=true; run.PreSimulation:Fire()
local tag,glow
for _,item in ipairs(allInstances) do if item:IsA("BillboardGui") and item.Adornee==replacement:FindFirstChild("Head") and item.Parent then tag=item end; if item:IsA("Highlight") and item.Adornee==replacement and item.Parent then glow=item end end
check(tag and tag.Enabled and glow and not glow.Enabled,"ESP should work independently of highlights")
api.Config.Highlights=true; run.PreSimulation:Fire()
check(glow.Enabled,"player highlight missing")
api.Config.ESP=false; run.PreSimulation:Fire()
check(not tag.Enabled and glow.Enabled,"highlight should work independently of ESP")
api.Config.Fullbright=true; run.PreSimulation:Fire()
check(lighting.Brightness==2 and not lighting.GlobalShadows,"fullbright missing")
button("Rejoin Server").Activated:Fire()
check(teleports==1 and lastTeleport==game.JobId,"same-server rejoin not requested")
attack.Visible=false
local tool=node("Tool","Weapon",own); api.Config.Aura=true
for _=1,4 do api.Step(0.1) end
check(tool.Activations==1,"equipped attack tool fallback failed")
tool:Destroy(); input.TouchEnabled=true
for _=1,4 do api.Step(0.1) end
check(not api.Config.Aura and api.Status:find("Attack control unavailable",1,true),"missing mobile attack control did not stop with status")
input.TouchEnabled=false; attack.Visible=true
camera.ViewportSize=Vector2.new(390,320); run.RenderStepped:Fire()
local window=findName(api.Gui,"Window")
check(window.Size.X.Offset==366 and window.Size.Y.Offset==296,"mobile window did not fit viewport")
local oldGui=api.Gui; api.Config.Hitbox=true; api.Config.Speed=true; run.PreSimulation:Fire()
local beforeReboot=replacementRoot.Size
api=boot()
check(oldGui.Parent==nil and env.SuperheroArenaHub==api,"re-execution did not replace prior hub")
check(replacementRoot.Size.X==2 and hum.WalkSpeed==speed and lighting.Brightness==1 and lighting.GlobalShadows,"re-execution did not restore settings")
api.Config.Hitbox=true; run.PreSimulation:Fire()
players.PlayerRemoving:Fire(other)
check(replacementRoot.Size.X==2,"player removal did not restore hitbox")
native:Destroy(); api.Unload(); api.Unload(); flush()
check(api.Gui.Parent==nil and env.SuperheroArenaHub==nil,"unload not idempotent")
local leaks=0
for _,sig in ipairs(allSignals) do for _,connection in ipairs(sig.handlers) do if connection.Connected then leaks+=1 end end end
check(leaks==0,"unload leaked "..leaks.." signals")
print("PASS: "..checks.." checks covering focused UI, combat, bursts, hero skills, native dash, hitboxes, movement, visuals, rejoin and cleanup.")
