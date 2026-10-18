-- The complete gameplay checks live in the separate Superhero Arena repo.
local requested
local source="return {Game='Superhero Arena',Version='4.6',Gui={Parent=true}}"
local game={HttpGet=function(_,url) requested=url; return source end}
local function run()
-- INSERT STANDALONE HUB
end
local result=run()
assert(result.Game=="Superhero Arena" and result.Version=="4.6")
assert(requested:find("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Superhero-Arena/main/main.lua?cb=",1,true)==1)
source="this is not valid Luau"
assert(not pcall(run),"invalid fetched code must fail compilation")
source="error('startup failed')"
assert(not pcall(run),"startup failures must propagate to the caller")
print("PASS: Superhero Arena forwarding URL, returned window, compile and startup errors.")
