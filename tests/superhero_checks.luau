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
local services={Lighting=lighting,Players=players,RunService=run,UserInputService=input,TweenService=tweens,CoreGui=coreGui,VirtualInputManager=vim,ReplicatedStorage=replicated}
local game={GetService=function(_,name) return assert(services[name],name) end}
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
check(api==env.SuperheroArenaHub,"public API not exposed")
check(api.ESP.Config.Enabled==false,"ESP should start off")
check(api.CustomDash==nil and not api.Movement.Enabled,"dash must be removed and noclip must start off")
check(api.ResolveHero(other)==nil,"unknown data was guessed")
local namedHero=player("Hulk",3); character(namedHero)
local nameplate=node("BillboardGui","Nameplate",namedHero.Character)
local nameText=node("TextLabel","Username",nameplate); nameText.Text="Hulk"
check(api.ResolveHero(namedHero)==nil,"a player's username was mistaken for their hero")
local actualRole=node("TextLabel","Role",nameplate); actualRole.Text="Hulk"
check(api.ResolveHero(namedHero)=="Hulk","an explicitly labeled role was discarded because it matched a username")
namedHero.Character:Destroy(); namedHero:Destroy(); table.remove(people,3)

-- Invalid early matches must not hide valid nested hero information.
other.Character:SetAttribute("Hero","Fighter")
local data=node("Folder","Data",other)
local equipped=node("StringValue","EquippedCharacter",data,"<b>SPIDER-MAN</b>")
check(api.ResolveHero(other)=="Spiderman","invalid first source shadowed a valid nested hero")
other.Character:SetAttribute("CurrentHero","RED_HULK")
check(api.ResolveHero(other)=="Red Hulk","current character state did not outrank a selected player value")
other.Character:SetAttribute("CurrentHero",nil)
equipped.Value="Dr. Strange"
check(api.ResolveHero(other)=="Doctor Strange","alias normalization failed")
equipped.Value="Galactic Thanos"
check(api.ResolveHero(other)=="Galactic Thanos","Galactic Thanos merged into Thanos")
equipped.Value=""
other:SetAttribute("PreviousHero","Hulk")
check(api.ResolveHero(other)==nil,"previous hero incorrectly treated as current")
other:SetAttribute("PreviousHero",nil)
other.Character:SetAttribute("Hero",nil)

-- Overhead labels, object references, nested named values and unrecognized IDs.
local overhead=node("BillboardGui","HeroNameplate",other.Character)
local overheadText=node("TextLabel","Role",overhead); overheadText.Text="HERO: WOLVERINE"
check(api.ResolveHero(other)=="Wolverine","character overhead role not recognized")
overhead:Destroy()
local ref=node("Folder","ChosenModel"); ref:SetAttribute("HeroName","IRON MAN")
local ov=node("ObjectValue","CurrentCharacter",data,ref)
check(api.ResolveHero(other)=="Iron Man","object reference metadata not resolved")
ov:Destroy(); ref:Destroy()
local heroFolder=node("Folder","Hero",data)
local inner=node("StringValue","Value",heroFolder,"GHOST RIDER")
check(api.ResolveHero(other)=="Ghost Rider","folder-nested hero value not recognized")
heroFolder:Destroy()
local id=node("IntValue","HeroId",data,123)
local found,_,evidence=api.ResolveHero(other)
check(found==nil,"unmapped numeric hero ID was guessed")
local sawID=false
for _,e in ipairs(evidence) do if e.raw=="123" then sawID=true end end
check(sawID,"diagnostics omitted a numeric hero ID")
id:Destroy()

-- Only the local equipped HUD is eligible; shop/selection buttons are excluded.
local pg=localPlayer:FindFirstChildOfClass("PlayerGui")
local shop=node("TextButton","HeroShopItem",pg); shop.Text="Batman"
check(api.ResolveHero(localPlayer)==nil,"shop option treated as equipped hero")
local hud=node("TextLabel","Equipped",pg); hud.Text="<b>EQUIPPED:</b> IRON-MAN"
check(api.ResolveHero(localPlayer)=="Iron Man","local equipped HUD failed")
local fakeGui=node("ScreenGui","RiftSHA_Old",pg)
local fake=node("TextLabel","FakeRole",fakeGui); fake.Text="EQUIPPED: THOR"
check(api.ResolveHero(localPlayer)=="Iron Man","hub GUI contaminated role lookup")

-- Actual v2.1 in-game report: MorphCurrent=Spiderman and power=Spiderman.
other.Character:SetAttribute("MorphCurrent","Spiderman")
other.Character:SetAttribute("power","Spiderman")
other.Character:SetAttribute("MorphAppearanceReady",true)
local actualHero,actualSource=api.ResolveHero(other)
check(actualHero=="Spiderman","confirmed live-game MorphCurrent was not detected")
check(actualSource:find(".@MorphCurrent",1,true)~=nil,"confirmed source not recorded")
other.Character:SetAttribute("power","Hulk")
check(api.ResolveHero(other)=="Spiderman","power overrode the active morph")
other.Character:SetAttribute("MorphCurrent",nil)
local powerHero,powerSource=api.ResolveHero(other)
check(powerHero=="Hulk" and powerSource:find(".@power",1,true)~=nil,"confirmed power fallback failed")
other.Character:SetAttribute("MorphCurrent","Loading")
check(api.ResolveHero(other)=="Hulk","unrecognized morph prevented valid power fallback")
localPlayer.Character:SetAttribute("MorphCurrent","Spiderman")
localPlayer.Character:SetAttribute("power","Spiderman")
check(api.ResolveHero(localPlayer)=="Spiderman","stale equipped HUD overrode the active morph")
localPlayer.Character:SetAttribute("MorphCurrent",nil); localPlayer.Character:SetAttribute("power",nil)
other.Character:SetAttribute("MorphCurrent","Spiderman"); other.Character:SetAttribute("power","Spiderman")
run.Heartbeat:Fire(1.1); api.SetESP(true); run.RenderStepped:Fire()
local actualTag=findName(workspace,"RiftSHA_Tag")
check(find(actualTag,"TextLabel","Spiderman")~=nil,"live-game source did not reach the ESP label")
other.Character:SetAttribute("MorphCurrent","Iron Man"); other.Character:SetAttribute("power","Iron Man")
run.Heartbeat:Fire(1.1); run.RenderStepped:Fire()
check(find(actualTag,"TextLabel","Iron Man")~=nil,"confirmed morph change did not update the ESP label")
-- Second live report: both confirmed fields say Fire, not a roster display name.
api.SetGuessing(false)
other.Character:SetAttribute("MorphCurrent","Fire"); other.Character:SetAttribute("power","Fire")
local internal,internalSource,internalEvidence=api.ResolveHero(other)
check(internal=="Fire" and internalSource:find(".@MorphCurrent",1,true)~=nil,"unmapped confirmed identifier was discarded")
local morphEntries=0
for _,e in ipairs(internalEvidence) do if e.path==internalSource then morphEntries+=1; check(e.unmapped,"raw identifier was presented as a confirmed hero name") end end
check(morphEntries==1,"report duplicated the confirmed root attribute")
run.Heartbeat:Fire(1.1); run.RenderStepped:Fire()
check(find(actualTag,"TextLabel","Fire")~=nil,"unmapped identifier not shown in ESP")
other.Character:SetAttribute("power","Spiderman")
check(api.ResolveHero(other)=="Fire","stale known power overrode current unmapped morph")
other.Character:SetAttribute("MorphCurrent",nil); other.Character:SetAttribute("power","Fire")
check(api.ResolveHero(other)=="Fire","power-only unfamiliar identifier was lost")
other.Character:SetAttribute("MorphCurrent","Loading"); other.Character:SetAttribute("power","Hulk")
check(api.ResolveHero(other)=="Hulk","loading placeholder was treated as a hero identifier")
other.Character:SetAttribute("MorphCurrent","123456"); other.Character:SetAttribute("power",nil)
check(api.ResolveHero(other)==nil,"numeric identifier was presented as a hero name")
api.SetGuessing(true)
for id,hero in pairs({Knight="Thor",Samurai="Deadpool",Nature="Groot"}) do
	other.Character:SetAttribute("MorphCurrent",id)
	local name,_,_,_,kind=api.ResolveHero(other)
	check(name==hero and kind=="confirmed",id.." was not treated as a user-confirmed mapping")
end
for name in pairs(api.HeroColors) do
	other.Character:SetAttribute("MorphCurrent",name)
	local found,_,_,_,kind=api.ResolveHero(other)
	check(found==name and kind=="confirmed","roster hero not preserved: "..name)
end
for id,hero in pairs({Fire="Ghost Rider",Ice="Frozone",Wind="Storm",Angel="Superman"}) do
	other.Character:SetAttribute("MorphCurrent",id)
	local name,_,_,_,kind=api.ResolveHero(other)
	check(name==hero and kind=="guess","estimated alias did not expose its uncertainty: "..id)
end
other.Character:SetAttribute("MorphCurrent","Wind")
run.Heartbeat:Fire(1.1); run.RenderStepped:Fire()
check(find(actualTag,"TextLabel","Storm (guess)")~=nil,"ESP displayed a guess as a confirmed hero")
api.SetGuessing(false); run.RenderStepped:Fire()
check(find(actualTag,"TextLabel","Wind")~=nil,"turning guesses off did not restore the game identifier")
api.SetGuessing(true)
-- User-confirmed internal identifiers must resolve to the proper hero and color.
other.Character:SetAttribute("MorphCurrent","Water"); other.Character:SetAttribute("power","Water")
check(api.ResolveHero(other)=="Aquaman","Water was not mapped to Aquaman")
run.Heartbeat:Fire(1.1); run.RenderStepped:Fire()
check(find(actualTag,"TextLabel","Aquaman")~=nil,"Aquaman mapping did not reach ESP")
local mappedHighlight=findName(workspace,"RiftSHA_Highlight")
check(mappedHighlight.FillColor==api.HeroColors.Aquaman,"Aquaman did not receive its hero color")
other.Character:SetAttribute("MorphCurrent","EARTH"); other.Character:SetAttribute("power","Earth")
check(api.ResolveHero(other)=="Hulk","Earth was not mapped to Hulk")
run.Heartbeat:Fire(1.1); run.RenderStepped:Fire()
check(find(actualTag,"TextLabel","Hulk")~=nil,"Hulk mapping did not reach ESP")
check(mappedHighlight.FillColor==api.HeroColors.Hulk,"Earth did not receive Hulk's color")
-- A menu report can identify several mappings without treating shared parents as proof.
local selector=node("ScreenGui","HeroSelection",pg)
local waterCard=node("Frame","Water",selector)
local waterLabel=node("TextLabel","HeroTitle",waterCard); waterLabel.Text="Aquaman"
waterCard:SetAttribute("MorphId","Water")
local earthCard=node("TextButton","Earth",selector)
earthCard.Text="Hulk"
local earthID=node("StringValue","PowerId",earthCard,"Earth")
local menu=api.HeroMenuReport()
check(menu:find("Label: Aquaman",1,true) and menu:find("@MorphId = Water",1,true),"menu report lost Aquaman's nearby metadata")
check(menu:find("Label: Hulk",1,true) and menu:find("PowerId [StringValue] = Earth",1,true),"menu report lost Hulk's nearby metadata")
check(menu:find("RiftSHA_",1,true)==nil,"menu report included the hub's own labels")
local menuButton=find(api.Gui,"TextLabel","Copy hero menu report")
menuButton.Parent.Activated:Fire()
check(clipboard:find("Rift Hub / Hero menu",1,true)~=nil,"menu report button did not copy its report")
-- Unambiguous explicit menu metadata can replace a guess; shared containers cannot.
local angelCard=node("Frame","AngelCard",selector)
angelCard:SetAttribute("MorphId","Angel")
local angelTitle=node("TextLabel","HeroTitle",angelCard); angelTitle.Text="Raven"
api.ScanHeroMenu()
other.Character:SetAttribute("MorphCurrent","Angel")
local menuHero,_,_,_,menuKind=api.ResolveHero(other)
check(menuHero=="Raven" and menuKind=="menu","menu metadata did not override a guess")
run.Heartbeat:Fire(1.1); run.RenderStepped:Fire()
check(find(actualTag,"TextLabel","Raven")~=nil,"menu-verified label retained a guess marker")
local shared=node("Frame","Shared",selector); shared:SetAttribute("MorphId","SharedAbility")
local titleA=node("TextLabel","First",shared); titleA.Text="Iron Man"
local titleB=node("TextLabel","Second",shared); titleB.Text="Raven"
api.ScanHeroMenu(); other.Character:SetAttribute("MorphCurrent","SharedAbility")
check(api.ResolveHero(other)=="SharedAbility","multi-hero container produced a false mapping")
local cloud=node("Frame","CloudA",selector); cloud:SetAttribute("PowerId","CloudType")
local cloudLabel=node("TextLabel","Title",cloud); cloudLabel.Text="Storm"
api.ScanHeroMenu(); other.Character:SetAttribute("MorphCurrent","CloudType")
check(api.ResolveHero(other)=="Storm","explicit new ID was not learned")
local conflict=node("Frame","CloudB",selector); conflict:SetAttribute("PowerId","CloudType")
local conflictLabel=node("TextLabel","Title",conflict); conflictLabel.Text="Superman"
api.ScanHeroMenu()
check(api.ResolveHero(other)=="CloudType","conflicting menu labels did not invalidate the learned mapping")
angelCard:SetAttribute("MorphId","Knight")
api.ScanHeroMenu(); other.Character:SetAttribute("MorphCurrent","Knight")
check(api.ResolveHero(other)=="Thor","menu metadata overrode a user-confirmed alias")
selector:Destroy()
other.Character:SetAttribute("MorphCurrent",nil); other.Character:SetAttribute("power",nil)
other.Character:SetAttribute("MorphAppearanceReady",nil)
other.Character:SetAttribute("CurrentHero","Hulk")
run.Heartbeat:Fire(1.1)

-- Render -> disable -> enable must restore the same attached objects.
api.SetESP(true); run.RenderStepped:Fire()
local world=findName(workspace,"RiftSHA_World")
local highlight=findName(world,"RiftSHA_Highlight")
local tag=findName(world,"RiftSHA_Tag")
check(highlight.Enabled and highlight.Adornee==other.Character,"highlight not attached")
check(tag.Enabled and tag.Adornee.Name=="Head","billboard not attached")
check(find(tag,"TextLabel","Hulk")~=nil,"resolved hero missing from ESP")
api.SetESP(false)
check(not highlight.Enabled and not tag.Enabled,"disable left ESP visible")
api.SetESP(true); run.RenderStepped:Fire()
check(highlight.Enabled and highlight.Adornee==other.Character,"ESP did not recover after toggling")
check(tag.Enabled,"billboard did not recover after toggling")

-- Missing body parts can arrive later in the same character; old roles never leak across respawns.
local oldChar=other.Character
local newChar=node("Model",other.Name,workspace); other.Character=newChar
run.RenderStepped:Fire()
check(not tag.Enabled and not highlight.Enabled,"incomplete spawn showed stale overlays")
local newHead=node("Part","Head",newChar)
local newRoot=node("Part","HumanoidRootPart",newChar); newRoot.Position=Vector3.new()
newChar.PrimaryPart=newRoot
run.RenderStepped:Fire()
check(tag.Adornee==newHead and tag.Enabled,"late head did not reattach")
check(find(tag,"TextLabel","Hero not detected")~=nil,"old role survived a respawn")
newChar:SetAttribute("Hero","Thor"); run.Heartbeat:Fire(1.1); run.RenderStepped:Fire()
check(find(tag,"TextLabel","Thor")~=nil,"respawned role did not refresh")
local humanoid=node("Humanoid","Humanoid",newChar); humanoid.Health=0
run.RenderStepped:Fire(); check(not highlight.Enabled and not tag.Enabled,"dead character remained highlighted")
humanoid.Health=100
api.ESP.Config.MaxDistance=100
newRoot.Position=Vector3.new(200,0,0); run.RenderStepped:Fire()
check(not highlight.Enabled and not tag.Enabled,"maximum distance was ignored")
newRoot.Position=Vector3.new(); api.ESP.Config.MaxDistance=1500
run.RenderStepped:Fire()
check(highlight.Enabled,"ESP did not resume after coming in range")
newChar:SetAttribute("Hero","Venom"); run.Heartbeat:Fire(1.1); run.RenderStepped:Fire()
check(find(tag,"TextLabel","Venom")~=nil,"same-character hero change did not refresh")
newChar:SetAttribute("Hero","Thor"); run.Heartbeat:Fire(1.1); run.RenderStepped:Fire()

-- Exercise actual tab, toggle, diagnostic and player search callbacks.
api.SelectTab("players")
check(find(api.Gui,"TextButton","Inspect")~=nil,"player roster missing inspect button")
local otherCard=findName(api.Gui,"Other")
check(otherCard~=nil,"player card not built")
find(otherCard,"TextButton","Inspect").Activated:Fire()
check(find(api.Gui,"TextLabel","@Other  /  Thor")~=nil,"player inspect did not update diagnostic target")
local copyLabel=find(api.Gui,"TextLabel","Copy full detection report")
copyLabel.Parent.Activated:Fire()
check(clipboard and clipboard:find("CurrentHero",1,true)==nil and clipboard:find("Thor",1,true),"diagnostic copy failed")
check(clipboard:find(".Hero",1,true)~=nil or clipboard:find(".@Hero",1,true)~=nil,"diagnostic omitted source")
newChar:SetAttribute("FighterCode",1234)
local unfamiliar=node("StringValue","AvatarType",data,"ArenaFighterV2")
local privateGui=node("PlayerGui","PlayerGui",other)
local hidden=node("StringValue","PrivateText",privateGui,"Do not collect GUI contents")
copyLabel.Parent.Activated:Fire()
check(clipboard:find("FighterCode = 1234",1,true)~=nil,"report omitted an unfamiliar attribute name")
check(clipboard:find("AvatarType [StringValue] = ArenaFighterV2",1,true)~=nil,"report omitted an unfamiliar value name")
check(clipboard:find("Do not collect GUI contents",1,true)==nil,"broad report collected GUI contents")
unfamiliar:Destroy(); privateGui:Destroy(); newChar:SetAttribute("FighterCode",nil)
api.SelectTab("players")
local search
for _,i in ipairs(allInstances) do if i.PlaceholderText=="Search username, display name or hero…" then search=i end end
search.Text="Thor"
check(otherCard.Visible,"hero search hid matching player")
search.Text="no_such_player"
check(not otherCard.Visible,"search did not hide nonmatching players")
search.Text=""

api.SetMinimized(true); flush()
local window=findName(api.Gui,"Window")
local bubble=findName(api.Gui,"RiftSHA_Logo")
check(not window.Visible and bubble.Visible,"minimize failed")
api.SetMinimized(false)
check(window.Visible and not bubble.Visible,"restore failed")
api.SetMinimized(true); api.SetMinimized(false); flush()
check(window.Visible and not bubble.Visible,"stale minimize callback hid restored window")
camera.ViewportSize=Vector2.new(480,320); run.RenderStepped:Fire()
local scale=window:FindFirstChildOfClass("UIScale").Scale
check(scale<1 and scale>0,"small viewport was not fitted")

-- Actual slider handlers: unrelated touch inputs cannot move another finger's slider.
api.SelectTab("visuals")
local opacityLabel=find(api.Gui,"TextLabel","Fill opacity")
local sliderHit
for _,child in ipairs(opacityLabel.Parent:GetChildren()) do if child.ClassName=="TextButton" then sliderHit=child end end
local touch={UserInputType=Enum.UserInputType.Touch,Position=Vector3.new(sliderHit.AbsolutePosition.X,0,0)}
sliderHit.InputBegan:Fire(touch)
check(api.ESP.Config.FillTransparency==1,"slider did not read its starting input")
input.InputChanged:Fire({UserInputType=Enum.UserInputType.Touch,Position=Vector3.new(9999,0,0)})
check(api.ESP.Config.FillTransparency==1,"unrelated touch hijacked the slider")
touch.Position=Vector3.new(sliderHit.AbsolutePosition.X+sliderHit.AbsoluteSize.X,0,0)
input.InputChanged:Fire(touch)
check(api.ESP.Config.FillTransparency==0,"active touch did not move the slider")
input.InputEnded:Fire(touch)
touch.Position=Vector3.new(sliderHit.AbsolutePosition.X,0,0); input.InputChanged:Fire(touch)
check(api.ESP.Config.FillTransparency==0,"slider kept changing after release")
sliderHit.InputBegan:Fire(touch); input.WindowFocusReleased:Fire()
touch.Position=Vector3.new(sliderHit.AbsolutePosition.X+sliderHit.AbsoluteSize.X,0,0); input.InputChanged:Fire(touch)
check(api.ESP.Config.FillTransparency==1,"focus loss left a slider captured")

-- A bubble drag must not also activate the restore click, regardless of event order.
api.SetMinimized(true); flush()
local dragTouch={UserInputType=Enum.UserInputType.Touch,Position=Vector3.new(30,100,0)}
bubble.InputBegan:Fire(dragTouch)
local before=bubble.Position
input.InputChanged:Fire({UserInputType=Enum.UserInputType.Touch,Position=Vector3.new(200,150,0)})
check(bubble.Position==before,"unrelated touch moved the minimized logo")
dragTouch.Position=Vector3.new(200,150,0); input.InputChanged:Fire(dragTouch)
check(bubble.Position.X.Offset~=before.X.Offset,"logo drag did not move")
bubble.Activated:Fire()
check(not window.Visible,"activation before release restored a dragged logo")
input.InputEnded:Fire(dragTouch); bubble.Activated:Fire()
check(not window.Visible,"activation after release restored a dragged logo")
api.SetMinimized(false)

-- Noclip changes only the current body's collisions and restores original values.
api.SelectTab("movement")
local m=api.Movement
local ownChar=localPlayer.Character
local ownHead=ownChar:FindFirstChild("Head")
local ownRoot=ownChar:FindFirstChild("HumanoidRootPart")
local ownHumanoid=ownChar:FindFirstChildOfClass("Humanoid")
local originalFalse=node("Part","NonColliding",ownChar); originalFalse.CanCollide=false
local worldPart=node("Part","Wall",workspace)
local otherHead=other.Character:FindFirstChild("Head")
ownHead.CanTouch=true; ownHead.CanQuery=true; ownHead.CollisionGroup="Characters"
check(find(api.Gui,"TextLabel","Noclip")~=nil,"noclip control missing")
check(find(api.Gui,"TextLabel","Custom dash")==nil and find(api.Gui,"TextLabel","Auto leap")==nil,"old movement tools remain")
check(findName(coreGui,"RiftSHA_DashCover")==nil,"invisible dash cover remains")
run.PreSimulation:Fire(0.016)
check(ownHead.CanCollide and ownRoot.CanCollide,"disabled noclip changed collisions")
local noclipRow=find(api.Gui,"TextLabel","Noclip").Parent
local noclipButton=noclipRow:IsA("TextButton") and noclipRow
check(noclipButton~=nil,"noclip toggle button missing")
noclipButton.Activated:Fire()
check(m.Enabled and not ownHead.CanCollide and not ownRoot.CanCollide,"noclip UI did not enable collisions override")
check(not originalFalse.CanCollide,"originally noncolliding part became collidable")
check(worldPart.CanCollide and otherHead.CanCollide,"noclip altered the world or another player")
check(ownHead.CanTouch and ownHead.CanQuery and ownHead.CollisionGroup=="Characters","noclip changed unrelated physics settings")
local accessory=node("Accessory","NewAccessory",ownChar)
local handle=node("MeshPart","Handle",accessory)
run.PreSimulation:Fire(0.016)
check(not handle.CanCollide,"new accessory was not included")
ownRoot.CanCollide=true; run.PreSimulation:Fire(0.016)
check(not ownRoot.CanCollide,"noclip did not maintain collisions override")
accessory.Parent=workspace; run.PreSimulation:Fire(0.016)
check(handle.CanCollide,"removed accessory did not regain original collisions")
noclipButton.Activated:Fire()
check(not m.Enabled and ownHead.CanCollide and ownRoot.CanCollide,"disabling through UI did not restore body collisions")
check(not originalFalse.CanCollide,"disabling overwrote an originally false collision flag")
m.SetEnabled(true); ownHumanoid.Health=0; run.PreSimulation:Fire(0.016)
check(m.Enabled and ownHead.CanCollide and ownRoot.CanCollide,"death did not restore the body while retaining desired setting")
local newChar=character(localPlayer)
local newRoot=newChar:FindFirstChild("HumanoidRootPart")
run.PreSimulation:Fire(0.016)
check(not newRoot.CanCollide and ownRoot.CanCollide,"noclip did not resume for a new body")
local thirdChar=character(localPlayer)
local thirdRoot=thirdChar:FindFirstChild("HumanoidRootPart")
run.PreSimulation:Fire(0.016)
check(newRoot.CanCollide and not thirdRoot.CanCollide,"character replacement did not restore the previous living body")
localPlayer.Character=nil; run.PreSimulation:Fire(0.016)
check(thirdRoot.CanCollide,"missing character left previous body noncollidable")
localPlayer.Character=thirdChar; run.PreSimulation:Fire(0.016)
check(not thirdRoot.CanCollide,"noclip did not resume when character became available")
thirdChar.Parent=nil; run.PreSimulation:Fire(0.016)
check(thirdRoot.CanCollide,"unparented character retained noclip")
thirdChar.Parent=workspace; run.PreSimulation:Fire(0.016)
local detached=node("Part","Detached",thirdChar)
run.PreSimulation:Fire(0.016); detached.Parent=nil; run.PreSimulation:Fire(0.016)
check(detached.CanCollide,"unparented part did not regain original collision setting")
m.SetEnabled(false)
check(thirdRoot.CanCollide,"final disabling failed to restore collision")

-- Targeting: real eligibility filters, sticky/cycle behavior and camera control.
camera.ViewportSize=Vector2.new(1280,720); input.WindowFocused:Fire()
local aim=api.Aim
check(aim~=nil and not aim.Config.Enabled,"lock-on should start off")
check(renderBindings.RiftSHA_TargetLock.priority==201,"aim must update after the native camera")
api.SelectTab("abilities")
check(find(api.Gui,"TextLabel","Auto lock-on")~=nil,"ability page missing")
local aimButton=find(api.Gui,"TextLabel","Auto lock-on").Parent
local targetPanel=findName(coreGui,"RiftSHA_TargetPanel")
local radius=findName(coreGui,"RiftSHA_AimRadius")
local holdButton=findName(coreGui,"RiftSHA_HoldLock")
local lockGlow=findName(workspace,"RiftSHA_LockHighlight")
-- Isolate a deterministic candidate set after prior roster tests.
local savedPeople=table.clone(people)
local enemy=player("AimTarget",9101); local enemyChar=character(enemy)
local enemyRoot=enemyChar:FindFirstChild("HumanoidRootPart")
local enemyHead=enemyChar:FindFirstChild("Head")
local enemyHum=enemyChar:FindFirstChildOfClass("Humanoid")
enemyRoot.Position=Vector3.new(5,0,0); enemyHead.Position=Vector3.new(5,4,0)
local rival=player("AimRival",9102); local rivalChar=character(rival)
local rivalRoot=rivalChar:FindFirstChild("HumanoidRootPart")
local rivalHum=rivalChar:FindFirstChildOfClass("Humanoid")
rivalRoot.Position=Vector3.new(10,0,0)
people={localPlayer,enemy,rival}
local beforeLook=lookCalls
renderAim()
check(lookCalls==beforeLook and not radius.Visible,"disabled targeting moved the camera")
aimButton.Activated:Fire(); renderAim(0.1)
check(aim.Target==enemy and lookCalls==beforeLook+1,"lock-on failed to acquire the crosshair target")
check(lastAlpha>0 and lastAlpha<1,"camera response did not smooth rotation")
check(targetPanel.Visible and radius.Visible and lockGlow.Enabled,"target overlay missing")
check(lockGlow.Adornee==enemyChar,"target outline attached to wrong body")
check(find(targetPanel,"TextLabel","@AimTarget")~=nil,"live target panel omitted username")
check((lastLook-enemyRoot.Position).Magnitude<0.0001,"body aim targeted wrong position")
aim.Config.AimPart="Head"; renderAim()
check((lastLook-enemyHead.Position).Magnitude<0.0001,"head aiming did not use head")
aim.Config.AimPart="Body"; aim.Config.Prediction=0.2
enemyRoot.AssemblyLinearVelocity=Vector3.new(10,0,0); renderAim()
check(lastLook.X==7,"movement prediction not applied")
enemyRoot.AssemblyLinearVelocity=Vector3.new(10000,0,0); renderAim()
check(math.abs(lastLook.X-30)<0.001,"prediction offset not capped")
aim.Config.Prediction=0; enemyRoot.AssemblyLinearVelocity=Vector3.new()
rivalRoot.Position=Vector3.new(1,0,0); renderAim()
check(aim.Target==enemy,"sticky targeting unexpectedly switched")
aim.Config.Sticky=false; renderAim()
check(aim.Target==rival,"nonsticky targeting did not choose better target")
aim.Config.Sticky=true; aim.Cycle(); renderAim()
check(aim.Target==enemy,"next target cycling failed")
aim.Config.Priority="Lowest health"; aim.Config.Sticky=false
rivalHum.Health=10; renderAim()
check(aim.Target==rival,"lowest health priority failed")
aim.Config.Priority="Nearest"; renderAim()
check(aim.Target==rival,"nearest priority failed")
localPlayer.Team="Blue"; rival.Team="Blue"; enemy.Team="Red"; renderAim()
check(aim.Target==enemy,"team filter included teammate")
rival.Neutral=true; renderAim()
check(aim.Target==rival,"neutral player incorrectly excluded as teammate")
rival.Neutral=false; aim.Config.TeamCheck=false; renderAim()
check(aim.Target==rival,"team filter toggle failed")
aim.Config.TeamCheck=true; localPlayer.Team=nil; rival.Team=nil; enemy.Team=nil
wall=true; beforeLook=lookCalls; renderAim()
check(aim.Target==nil and lookCalls==beforeLook and not lockGlow.Enabled,"wall-occluded targets were acquired")
forcedHit=enemyRoot; people={localPlayer,enemy}; renderAim()
check(aim.Target==enemy,"raycast hitting target body was treated as a wall")
forcedHit=nil; aim.Config.WallCheck=false; renderAim()
check(aim.Target==enemy,"wall check toggle failed")
wall=false; aim.Config.WallCheck=true
local originalProjection=camera.WorldToViewportPoint
function camera:WorldToViewportPoint(p) return Vector3.new(640,360,-10),true end
renderAim(); check(aim.Target==nil,"target behind camera was accepted")
function camera:WorldToViewportPoint(p) return Vector3.new(640,360,10),false end
renderAim(); check(aim.Target==nil,"off-screen target was accepted")
camera.WorldToViewportPoint=originalProjection
aim.Config.Radius=40; renderAim()
check(aim.Target==nil,"screen radius filter failed")
aim.Config.Radius=180; aim.Config.MaxRange=3; renderAim()
check(aim.Target==nil,"range filter failed")
aim.Config.MaxRange=350; enemyHum.Health=0; renderAim()
check(aim.Target==nil,"dead target was acquired")
enemyHum.Health=100; localPlayer.Character:FindFirstChildOfClass("Humanoid").Health=0; renderAim()
check(aim.Target==nil,"dead local player acquired target")
localPlayer.Character:FindFirstChildOfClass("Humanoid").Health=100
focusedBox={}; beforeLook=lookCalls; renderAim()
check(lookCalls==beforeLook and not radius.Visible,"typing did not pause aim")
focusedBox=nil; camera.CameraType=Enum.CameraType.Scriptable; renderAim()
check(aim.Target==nil and not targetPanel.Visible,"scriptable camera was overridden")
camera.CameraType=Enum.CameraType.Custom
input.WindowFocusReleased:Fire(); beforeLook=lookCalls; renderAim()
check(lookCalls==beforeLook and not lockGlow.Enabled,"unfocused window still aimed")
input.WindowFocused:Fire(); aim.Config.HoldToLock=true; renderAim()
check(aim.Target==nil and holdButton.Visible,"hold-only lock should wait for a press")
local mouseLock={UserInputType=Enum.UserInputType.MouseButton2}
input.InputBegan:Fire(mouseLock,false); renderAim()
check(aim.Target==enemy,"right mouse hold failed")
input.InputEnded:Fire(mouseLock); renderAim()
check(aim.Target==nil,"right mouse release did not stop lock")
local touchLock={UserInputType=Enum.UserInputType.Touch}
holdButton.InputBegan:Fire(touchLock); renderAim()
check(aim.Target==enemy,"touch hold failed")
input.InputEnded:Fire({UserInputType=Enum.UserInputType.Touch}); renderAim()
check(aim.Target==enemy,"unrelated finger released lock")
input.InputEnded:Fire(touchLock); renderAim()
check(aim.Target==nil,"touch release did not stop lock")
aim.Config.HoldToLock=false
local toggleKey={KeyCode=Enum.KeyCode.L}
input.InputBegan:Fire(toggleKey,true)
check(aim.Config.Enabled,"processed key toggled aim")
input.InputBegan:Fire(toggleKey,false)
check(not aim.Config.Enabled,"L key did not disable aim")
check(not lockGlow.Enabled and not targetPanel.Visible and not radius.Visible,"disable left aim overlays visible")
aim.SetEnabled(true); renderAim()
players.PlayerRemoving:Fire(enemy)
check(aim.Target==nil and not lockGlow.Enabled,"departed target not cleared immediately")
aim.SetEnabled(false)
people=savedPeople; enemyChar:Destroy(); rivalChar:Destroy(); enemy:Destroy(); rival:Destroy()

-- Combat/farm automation exercises actual controls rather than client-side damage.
local function expansionChecks()
local bot=api.Automation
local extras=api.Extras
check(bot.Config.Mode=="Off" and not extras.Config.Speed,"automation/extras should start off")
local nav=findName(api.Gui,"Navigation")
check(nav and nav:IsA("ScrollingFrame"),"expanded navigation must scroll")
for _,tab in ipairs({"combat","farming","world","utility"}) do api.SelectTab(tab) end
check(find(api.Gui,"TextLabel","Auto farm NPCs")~=nil and find(api.Gui,"TextLabel","Kill aura · nearby attacks")~=nil,"combat/farming controls missing")
local autoPeople=table.clone(people)
local opponent=player("AutomationEnemy",9221); local opponentChar=character(opponent)
local opponentRoot=opponentChar:FindFirstChild("HumanoidRootPart"); opponentRoot.Position=Vector3.new(5,0,0)
local ownHum=localPlayer.Character:FindFirstChildOfClass("Humanoid")
local ownPos=localPlayer.Character:FindFirstChild("HumanoidRootPart").Position
people={localPlayer,opponent}
local tool=node("Tool","Sword",localPlayer.Character)
bot.Config.AttackMethod="Equipped tool"; bot.Config.Interval=0.15
bot.SetMode("Aura"); bot.Step(0.2)
check(not tool.Activations and bot.Status:find("Paused",1,true),"automation should pause while menu is open")
api.SetMinimized(true); flush(); bot.Step(0.2)
check(tool.Activations==1 and bot.Target==opponentChar,"aura did not use equipped tool on nearby target")
check(opponentChar:FindFirstChildOfClass("Humanoid").Health==100,"automation must not fabricate damage locally")
local attempts=tool.Activations
focusedBox={}; bot.Step(0.2); focusedBox=nil
check(tool.Activations==attempts,"automation attacked while typing")
local activeRoot=localPlayer.Character:FindFirstChild("HumanoidRootPart")
activeRoot.Anchored=true; bot.Step(0.2); activeRoot.Anchored=false
check(tool.Activations==attempts,"anchored character attempted an attack")
wall=true; bot.Step(0.2); wall=false
check(tool.Activations==attempts and bot.Target==nil,"aura attacked through blocked visibility")
localPlayer.Team="Team"; opponent.Team="Team"; bot.Step(0.2)
check(tool.Activations==attempts,"aura ignored teammate filter")
localPlayer.Team=nil; opponent.Team=nil
ownHum.Health=5; bot.Step(0.2); ownHum.Health=100
check(tool.Activations==attempts and bot.Status:find("low health",1,true),"low health pause failed")
input.WindowFocusReleased:Fire(); bot.Step(0.2); input.WindowFocused:Fire()
check(tool.Activations==attempts,"automation did not pause on focus loss")
opponentRoot.Position=Vector3.new(40,0,0); bot.SetMode("Fight"); bot.Step(0.2)
check(ownHum.LastMoveTo==opponentRoot.Position and tool.Activations==attempts,"pursuit did not walk without attacking distant target")
bot.SetMode("Off")
check(ownHum.LastMoveTo==ownPos,"stop did not cancel pursuit walking")
opponentRoot.Position=Vector3.new(5,0,0)
local npc=node("Model","Bandit",workspace)
local npcRoot=node("Part","HumanoidRootPart",npc); npcRoot.Position=Vector3.new(4,0,0)
local npcHum=node("Humanoid","Humanoid",npc)
bot.Config.FarmName="Bandit"; bot.SetMode("Farm"); bot.Step(0.2)
check(bot.Target==npc and tool.Activations==attempts+1,"farm did not select matching living NPC")
bot.Config.FarmName="Absent"; bot.Step(0.2)
check(bot.Target==nil,"NPC name filter ignored")
bot.Config.FarmName="Bandit"; npcHum.Health=0; bot.Step(0.2)
check(bot.Target==nil,"dead NPC was targeted")
npcHum.Health=100; bot.Config.FarmName="AutomationEnemy"; bot.Step(0.2)
check(bot.Target==nil,"NPC farm targeted a player body")
bot.Config.FarmName=""; bot.SetMode("Off")
local hud=node("ScreenGui","NativeCombatHUD",localPlayer:FindFirstChild("PlayerGui"))
local nativeButton=node("TextButton","AttackButton",hud); nativeButton.Text="Attack"
local nativeCalls=0
nativeButton.MouseButton1Click:Connect(function() nativeCalls+=1 end)
check(bot.FindAttackButton()==nativeButton,"attack button detection failed")
local duplicate=node("TextButton","AttackButton",hud); duplicate.Text="Attack"
check(bot.FindAttackButton()==nil,"ambiguous attack buttons should not be activated")
duplicate:Destroy(); nativeButton.Visible=false
check(bot.FindAttackButton()==nil,"hidden attack button should not be detected")
nativeButton.Visible=true; bot.Config.AttackMethod="HUD attack"; bot.SetMode("Aura"); bot.Step(0.2)
check(nativeCalls==1,"HUD attack did not use connected native click event")
bot.SetMode("Off")
bot.Config.AttackMethod="Keyboard key"; bot.Config.AttackKey="E"
bot.SetMode("Aura"); bot.Step(0.2)
check(sentKeys[#sentKeys].down and sentKeys[#sentKeys].key==Enum.KeyCode.E,"attack key not sent")
local staleRelease=pending[#pending]
bot.SetMode("Off")
check(not sentKeys[#sentKeys].down,"disabling left attack key held")
bot.SetMode("Aura"); bot.Step(0.2); local presses=#sentKeys; staleRelease()
check(#sentKeys==presses,"stale delayed release cancelled a newer press")
flush(); check(not sentKeys[#sentKeys].down,"key did not release after pulse")
check(bot.ParseKeys("F8")==nil and bot.ParseKeys("L")==nil,"reserved hub shortcut accepted as attack")
local keys=bot.ParseKeys("1, 2, E")
check(#keys==3 and keys[1]==Enum.KeyCode.One and keys[3]==Enum.KeyCode.E,"ability keys not parsed")
bot.Config.Abilities=true; bot.Config.Keys={Enum.KeyCode.One,Enum.KeyCode.Two}; bot.Config.AbilityInterval=0.25
bot.Step(0.25)
check(sentKeys[#sentKeys].down and sentKeys[#sentKeys].key==Enum.KeyCode.One,"ability rotation did not start with first key")
flush(); bot.Step(0.25)
check(sentKeys[#sentKeys].down and sentKeys[#sentKeys].key==Enum.KeyCode.Two,"ability rotation did not advance")
bot.SetMode("Off"); bot.Config.Abilities=false; flush()
bot.Config.AttackMethod="Equipped tool"; tool:Destroy(); bot.SetMode("Aura"); bot.Step(0.2)
check(bot.Config.Mode=="Off" and bot.Status:find("Equip",1,true),"missing attack method did not stop with actionable status")
hud:Destroy(); npc:Destroy(); opponentChar:Destroy(); opponent:Destroy(); people=autoPeople

-- World and movement toggles restore only the settings they own.
local oldSpeed=ownHum.WalkSpeed; local oldPower=ownHum.JumpPower; local oldHeight=ownHum.JumpHeight
extras.Config.Speed=true; extras.Step()
check(ownHum.WalkSpeed==32 and ownHum.JumpPower==oldPower,"speed toggle altered wrong properties")
extras.Config.Jump=true; extras.Step()
check(ownHum.JumpPower==70,"jump power not applied")
extras.Config.Speed=false; extras.Step()
check(ownHum.WalkSpeed==oldSpeed and ownHum.JumpPower==70,"disabling speed broke jump or failed restoration")
ownHum.UseJumpPower=false; extras.Step()
check(ownHum.JumpPower==oldPower and math.abs(ownHum.JumpHeight-70^2/(2*workspace.Gravity))<0.001,"jump-height character not supported")
extras.Config.Jump=false; extras.Step()
check(ownHum.JumpHeight==oldHeight,"original jump height not restored")
ownHum.UseJumpPower=true
extras.Config.Speed=true; extras.Step()
local previousCharacter=localPlayer.Character
local freshCharacter=character(localPlayer); local freshHum=freshCharacter:FindFirstChildOfClass("Humanoid")
extras.Step()
check(ownHum.WalkSpeed==oldSpeed and freshHum.WalkSpeed==32,"respawn did not restore old body and apply speed to new body")
freshHum.Health=0; extras.Step()
check(freshHum.WalkSpeed==16,"death did not restore speed")
localPlayer.Character=previousCharacter; freshCharacter:Destroy(); extras.Reset()
extras.Config.AirJump=true; input.JumpRequest:Fire()
check(ownHum.LastState==Enum.HumanoidStateType.Jumping,"air jump did not request jumping")
ownHum.LastState=nil; focusedBox={}; input.JumpRequest:Fire(); focusedBox=nil
check(ownHum.LastState==nil,"air jump activated while typing")
extras.Config.Fullbright=true; extras.Config.NoFog=true; extras.Config.FOV=true; extras.Step()
check(lighting.Brightness==2 and not lighting.GlobalShadows,"fullbright missing")
check(lighting.FogEnd==100000 and atmosphere.Density==0 and atmosphere.Haze==0,"fog/haze not cleared")
check(camera.FieldOfView==80,"camera FOV not applied")
extras.Config.Fullbright=false; extras.Step()
check(lighting.Brightness==1 and lighting.GlobalShadows and lighting.FogEnd==100000,"restoring brightness should preserve active fog toggle")
local replacementCamera={FieldOfView=65}
workspace.CurrentCamera=replacementCamera; extras.Step()
check(camera.FieldOfView==70 and replacementCamera.FieldOfView==80,"camera replacement did not restore old camera")
workspace.CurrentCamera=camera; extras.Step()
check(replacementCamera.FieldOfView==65,"replacement camera FOV not restored")
extras.Reset()
check(camera.FieldOfView==70 and lighting.FogStart==15 and lighting.FogEnd==400,"reset did not restore camera/lighting")
check(atmosphere.Density==0.4 and atmosphere.Haze==2,"atmosphere settings not restored")
extras.Config.Speed=true; extras.Config.Fullbright=true; extras.Step(); api.Movement.SetEnabled(true)
focusedBox={}; input.InputBegan:Fire({KeyCode=Enum.KeyCode.F8},true); focusedBox=nil
check(not extras.Config.Speed and not extras.Config.Fullbright and not api.Movement.Enabled and bot.Config.Mode=="Off" and not api.Aim.Config.Enabled,"F8 did not stop every master feature")
check(ownHum.WalkSpeed==oldSpeed and lighting.Brightness==1,"emergency stop did not restore settings")
api.SetMinimized(false); flush()

return {Humanoid=ownHum,Speed=oldSpeed}
end
local expansionState=expansionChecks()

-- Removing a player must destroy all their overlays, including the billboard.
table.remove(people,2); players.PlayerRemoving:Fire(other); other.Parent=nil
check(highlight.Parent==nil and tag.Parent==nil,"player removal leaked a highlight or billboard")
check(otherCard.Parent==nil,"player removal leaked a roster card")

-- Re-execution restores collisions and closes the previous window.
local oldGui=api.Gui
m.SetEnabled(true)
check(not thirdRoot.CanCollide,"cleanup fixture did not enable noclip")
aim.SetEnabled(true); renderAim()
api.Extras.Config.Speed=true; api.Extras.Config.NoFog=true; api.Extras.Config.FOV=true; api.Extras.Step()
api=boot()
check(expansionState.Humanoid.WalkSpeed==expansionState.Speed and lighting.FogEnd==400 and camera.FieldOfView==70,"re-execution failed to restore extras")
check(thirdRoot.CanCollide,"re-execution did not restore collisions")
check(not api.Movement.Enabled,"re-execution did not start with noclip off")
check(oldGui.Parent==nil,"re-execution left the previous window open")
check(env.SuperheroArenaHub==api,"re-execution API not replaced")
local falsePart=node("Part","FalsePart",thirdChar); falsePart.CanCollide=false
api.Movement.SetEnabled(true)
api.Unload(); api.Unload(); flush()
check(thirdRoot.CanCollide and not falsePart.CanCollide,"unload did not preserve original collision settings")
check(api.Gui.Parent==nil and env.SuperheroArenaHub==nil,"unload not idempotent")
check(next(renderBindings)==nil,"unload leaked a camera render binding")
beforeLook=lookCalls; renderAim(); check(lookCalls==beforeLook,"camera still controlled after unload")
local leaks=0
for _,s in ipairs(allSignals) do for _,c in ipairs(s.handlers) do if c.Connected then leaks+=1 end end end
check(leaks==0,"unload leaked "..leaks.." signal handlers")
print("PASS: "..checks.." checks covering hero detection, ESP, UI, targeting, combat/farming, world/movement, noclip, re-execution and cleanup.")
