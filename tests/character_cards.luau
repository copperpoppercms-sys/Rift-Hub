local function signal()
 local s={items={}}
 function s:Connect(fn) table.insert(self.items,fn);return {Disconnect=function() end} end
 function s:Fire(...) for _,fn in ipairs(self.items) do fn(...) end end
 return s
end
local objects={}
local function create(class,props,parent)
 local o={Parent=parent,AbsoluteSize={X=640},MouseEnter=signal(),MouseLeave=signal(),Activated=signal()}
 for k,v in pairs(props) do o[k]=v end
 function o:GetPropertyChangedSignal() self.Changed=self.Changed or signal();return self.Changed end
 objects[o.Name or tostring(o)]=o
 return o
end
local UDim2={new=function(a,b,c,d) return {X={Scale=a,Offset=b},Y={Scale=c,Offset=d}} end}
UDim2.fromOffset=function(x,y) return UDim2.new(0,x,0,y) end
UDim2.fromScale=function(x,y) return UDim2.new(x,0,y,0) end
local UDim={new=function(...) return {...} end}
local Color3={fromRGB=function(...) return {...} end}
local Enum=setmetatable({},{__index=function() return {} end})
local task={spawn=function(fn) fn() end}
local Kit={create=create,face=function() end,Surface=function() end,Click=function() end,tween=function() end}
Kit.Scroller=function() return create('Frame',{},true) end
local launched={}
local library={Characters={{Id='hulk'},{Id='spider'}},Execute=function(c) table.insert(launched,c.Id);return true end}
local ctx={Kit=Kit,GameLibrary=function() return library end,Janitor={add=function() end},Zoom={Scale=1,GetPropertyChangedSignal=function() return signal() end}}
local build=(function()
-- HERO BUILDER
return buildHeroVillain
end)()
build({},ctx)
assert(objects.HulkCard and objects.SpiderManCard,'both character cards are required')
assert(objects.Exterminate.Text=='Exterminate' and objects.Execute.Text=='Execute','button text changed')
objects.Execute.Activated:Fire();objects.Exterminate.Activated:Fire()
assert(launched[1]=='spider' and launched[2]=='hulk','loop closure launched wrong character')
local cards=objects.CharacterCards
assert(cards.Size.Y.Offset==156,'wide character grid height wrong')
cards.AbsoluteSize.X=320;cards.Changed:Fire()
assert(cards.Size.Y.Offset==324,'narrow grid clips second card')
assert(objects.SpiderManCardStatus.Text=='Studio server package required','wrong handoff text')
print('PASS: separate character cards, correct Execute routing, narrow-screen rows and Hulk button preserved.')
