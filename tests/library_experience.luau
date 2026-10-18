-- Actual UI preference/filter modules and native UI wiring against a small client fixture.
local checks=0
local function check(value,message) assert(value,message); checks+=1 end
local files,encoded,serial={}, {},0
local function clone(value)
	if type(value)~="table" then return value end
	local result={};for key,item in pairs(value) do result[key]=clone(item) end;return result
end
local Http={}
function Http:JSONEncode(value) serial+=1;encoded[tostring(serial)]=clone(value);return tostring(serial) end
function Http:JSONDecode(value) assert(encoded[value],"bad JSON");return clone(encoded[value]) end
local isfile=function(path) return files[path]~=nil end
local readfile=function(path) return files[path] end
local writefile=function(path,value) files[path]=value end
local isfolder=function() return true end
local makefolder=function() end
local function signal()
	local event={connections={}}
	function event:Connect(fn)
		local c={Connected=true,fn=fn};function c:Disconnect() self.Connected=false end
		table.insert(self.connections,c);return c
	end
	function event:Fire(...) for _,c in ipairs(self.connections) do if c.Connected then c.fn(...) end end end
	function event:Stop() for _,c in ipairs(self.connections) do c:Disconnect() end end
	function event:Count() local n=0;for _,c in ipairs(self.connections) do if c.Connected then n+=1 end end;return n end
	return event
end
local input={TouchEnabled=true,InputBegan=signal(),focus=nil,ctrl=false}
function input:GetFocusedTextBox() return self.focus end
function input:IsKeyDown() return self.ctrl end
local game={PlaceId=142823291,GameId=66654135,GetService=function(_,name) if name=="HttpService" then return Http else return input end end}
local StateCtor=(function()
-- STATE
end)()
local games={
	{Id="mm2",Name="Murder Mystery 2",ShortName="MM2",PlaceId=142823291,UniverseId=66654135,ScriptName="Rift MM2",Handoff="Opens MM2 and closes hub",Thumbnail="mm2"},
	{Id="superhero-arena",Name="Superhero Arena",PlaceId=78710221869926,UniverseId=10765491459,ScriptName="Rift Superhero",Handoff="Opens Superhero Arena and closes hub",Thumbnail="hero"},
	{Id="survive-the-hulk",Name="Survive The Hulk",PlaceId=109166720609444,UniverseId=10742937135,ScriptName="Rift Hulk",Handoff="Opens Survive The Hulk and closes hub",Thumbnail="hulk"},
}
local state=StateCtor()
check(#state.Filter(games,"","Favorites")==0,"new preferences contain favorites")
check(state.ToggleFavorite("superhero-arena") and state.Saved,"favorite was not saved")
check(not state.ToggleFavorite("unknown"),"unknown game was persisted")
check(state.RecordLaunch("mm2"),"launch history failed")
state.SetReducedMotion(true)
local restored=StateCtor()
check(restored.Favorites["superhero-arena"] and restored.LastGame=="mm2" and restored.ReducedMotion,"preferences failed to round trip")
check(restored.Filter(games,"  SUPERHERO   arena ","All")[1]==games[2],"multiword search failed")
check(restored.Filter(games,"mm2","All")[1]==games[1],"short-name search failed")
check(#restored.Filter(games,"%[","All")==0,"search interpreted pattern characters")
check(restored.Filter(games,"","All")[1]==games[1],"current game did not rank first")
check(restored.Filter(games,"","Favorites")[1]==games[2],"favorites filter failed")
game.PlaceId=1;check(#restored.Filter(games,"","This game")==1,"same-universe subplace not recognized")
game.GameId=2;check(#restored.Filter(games,"","This game")==0,"wrong game classified current")
check(restored.Columns(400)==1 and restored.Columns(580)==2,"responsive breakpoint failed")
files["RiftHub/library.json"]="broken"
check(next(StateCtor().Favorites)==nil,"malformed preferences did not recover")
files["RiftHub/library.json"]=Http:JSONEncode({Version=1,Favorites={mm2="true",["superhero-arena"]=true,unknown=true},LastGame="unknown",ReducedMotion="true"})
local validated=StateCtor()
check(validated.Favorites.mm2==nil and validated.Favorites.unknown==nil and validated.Favorites["superhero-arena"]==true,"unvalidated favorite accepted")
check(validated.LastGame==nil and not validated.ReducedMotion,"invalid history/motion accepted")
local priorWrite=writefile;writefile=function() error("write denied") end
check(validated.ToggleFavorite("mm2") and not validated.Saved,"write failure discarded live preference")
writefile=nil;check(validated.RecordLaunch("mm2"),"missing file API broke session history")
writefile=priorWrite
local Enum=setmetatable({},{__index=function(t,k)
	local child=setmetatable({},{__index=function(_,v) return v end});rawset(t,k,child);return child
end})
local UDim2={new=function(xs,xo,ys,yo) return {X={Scale=xs,Offset=xo},Y={Scale=ys,Offset=yo}} end}
function UDim2.fromOffset(x,y) return UDim2.new(0,x,0,y) end
function UDim2.fromScale(x,y) return UDim2.new(x,0,y,0) end
local UDim={new=function(s,o) return {Scale=s,Offset=o} end}
local Vector2={new=function(x,y) return {X=x,Y=y} end}
local task={spawn=function(fn) fn() end}
local all={}
local function object(class,props,parent)
	local o={ClassName=class,children={},signals={},AbsoluteSize={X=640,Y=400},Visible=true}
	for _,name in ipairs({"Activated","MouseEnter","MouseLeave","FocusLost"}) do o[name]=signal() end
	for key,value in pairs(props or {}) do o[key]=value end
	o.Parent=parent;if parent then table.insert(parent.children,o) end
	function o:GetPropertyChangedSignal(key) if not self.signals[key] then self.signals[key]=signal() end;return self.signals[key] end
	function o:GetChildren() return self.children end
	function o:CaptureFocus() input.focus=self end
	function o:ReleaseFocus() if input.focus==self then input.focus=nil end end
	function o:Destroy()
		for _,child in ipairs(self.children) do child:Destroy() end
		for _,event in pairs(self.signals) do event:Stop() end
		for _,name in ipairs({"Activated","MouseEnter","MouseLeave","FocusLost"}) do self[name]:Stop() end
		self.Parent=nil
	end
	table.insert(all,o);return o
end
local Kit={BASE="base",PANEL="panel",TRACK="track",BORDER="border",SUB="sub",INK="ink",FAINT="faint",ACCENT="accent",VOID="void",CANDLE="candle",DANGER="danger"}
Kit.create=object;Kit.face=function() return "font" end;Kit.Surface=function() end;Kit.Click=function() end
Kit.tween=function(obj,props) for key,value in pairs(props) do obj[key]=value end end
Kit.Scroller=function(parent) return object("ScrollingFrame",{},parent) end
Kit.SearchBox=function(parent,placeholder,onChanged)
	local frame=object("Frame",{},parent)
	local box=object("TextBox",{Text="",PlaceholderText=placeholder},frame)
	box:GetPropertyChangedSignal("Text"):Connect(function() onChanged(box.Text) end)
	return frame,box
end
local View=(function()
-- VIEW
end)()
local Search=(function()
-- SEARCH
end)()
local root=object("Frame",{},nil)
local ctx={Kit=Kit,Card=root,Zoom=object("UIScale",{Scale=1},root),LibraryState=validated,selected=nil,executed=0,iconCalls=0,cleanup={}}
ctx.Janitor={add=function(value) table.insert(ctx.cleanup,value);return value end}
ctx.IsVisible=function() return true end
ctx.SelectTab=function(tab) ctx.selected=tab end
ctx.GameLibrary=function()
	return {Games=games,LoadIcon=function() ctx.iconCalls+=1 end,Execute=function() ctx.executed+=1;return false,"Open the game first" end}
end
local panel=object("Frame",{},root)
View(panel,ctx)
local function find(predicate)
	for _,item in ipairs(all) do if predicate(item) then return item end end
	error("widget not found")
end
local cards=find(function(o) return o.Name=="GameCards" end)
local grid=find(function(o) return o.ClassName=="UIGridLayout" end)
check(ctx.iconCalls==3 and grid.CellSize.X.Scale==.5,"wide library construction failed")
cards.AbsoluteSize.X=400;cards:GetPropertyChangedSignal("AbsoluteSize"):Fire()
check(grid.CellSize.X.Scale==1,"narrow library did not switch to one column")
local hero=find(function(o) return o.Name=="superhero-arena" end)
local search=find(function(o) return o.PlaceholderText=="Search games…" end)
search.Text="not-a-game";search:GetPropertyChangedSignal("Text"):Fire()
check(not cards.Visible,"empty search did not hide the grid")
ctx.LibraryFocus("superhero-arena")
check(cards.Visible and hero.Visible,"deep link did not reveal selected game")
local mm2=find(function(o) return o.Name=="mm2" end)
check(not mm2.Visible,"deep link left unrelated game visible")
local favorite=find(function(o) return o.Parent==hero and (o.Text=="★" or o.Text=="☆") end)
local before=validated.Favorites["superhero-arena"]
favorite.Activated:Fire()
check(validated.Favorites["superhero-arena"]~=before,"favorite button not wired")
local execute=find(function(o) return o.Parent==hero and o.Text=="Execute" end)
execute.Activated:Fire();check(ctx.executed==1,"execute button not wired")
local palette=Search(ctx)
palette.Open()
local overlay=find(function(o) return o.Name=="QuickSearchOverlay" end)
check(overlay.Visible and input.focus==nil,"mobile search forced a keyboard")
local paletteInput=find(function(o) return o.PlaceholderText=="Try fly, ESP, MM2, settings…" end)
paletteInput.Text="esp";paletteInput:GetPropertyChangedSignal("Text"):Fire()
paletteInput.FocusLost:Fire(true)
check(ctx.selected=="visuals" and not overlay.Visible,"ESP search did not navigate")
palette.Open();paletteInput.Text="mm2";paletteInput:GetPropertyChangedSignal("Text"):Fire();paletteInput.FocusLost:Fire(true)
check(ctx.selected=="hub" and mm2.Visible and not hero.Visible,"game quick search failed to focus the library")
input.TouchEnabled=false;palette.Open();check(input.focus==paletteInput,"desktop search failed to focus")
input.InputBegan:Fire({KeyCode="Escape"},true)
check(not overlay.Visible and input.focus==nil,"Escape did not release focus")
input.ctrl=true;input.InputBegan:Fire({KeyCode="K"},false)
check(overlay.Visible,"Ctrl+K did not open the palette")
palette.Close()
for _,item in ipairs(ctx.cleanup) do item:Disconnect() end
root:Destroy()
check(input.InputBegan:Count()==0,"search kept a global input listener after unload")
-- Verify portrait/landscape switching using the actual shell layout function.
do
 local workspace={CurrentCamera={ViewportSize={X=390,Y=844}}}
 local card,sidebar,content,seasonLabel,searchButton,profile,profileAvatar={},{},{},{},{},{},{}
 local tabs={home={label={},glyph={}}}
 local tabList={GetChildren=function() return {} end}
 local ctx={InterfaceScale=1}
 local fit,zoom,visible=1,{},true
-- FIT
 ctx.FitWindow()
 check(card.Size.X.Offset==540 and sidebar.Size.X.Offset==64 and content.Position.X.Offset==64,"portrait shell did not compact")
 check(not seasonLabel.Visible and not tabs.home.label.Visible,"portrait chrome did not simplify")
 check(zoom.Scale*540<=390-24 and zoom.Scale*580<=844-32,"portrait hub exceeds viewport")
 workspace.CurrentCamera.ViewportSize={X=844,Y=390};ctx.FitWindow()
 check(card.Size.X.Offset==900 and sidebar.Size.X.Offset==190 and tabs.home.label.Visible,"landscape layout did not restore")
 check(zoom.Scale*580<=390-32,"landscape hub exceeds viewport")
end
print("PASS: "..checks.." library preference, search, ranking, mobile layout, quick search and cleanup checks.")
