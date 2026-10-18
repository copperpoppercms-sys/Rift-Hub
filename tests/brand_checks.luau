-- Exercises the actual shared logo loader, not Roblox networking/rendering.
local function check(value,reason) assert(value,reason) end
local jobs={}
local task={spawn=function(fn) table.insert(jobs,fn) end}
local function flush() local calls=jobs; jobs={}; for _,fn in ipairs(calls) do fn() end end
local Vector2={new=function(x,y) return {X=x or 0,Y=y or 0} end}
local Color3={new=function(...) return {...} end}
local Enum={ScaleType={Fit="Fit",Stretch="Stretch"}}
local UDim2={fromScale=function(x,y) return {X={Scale=x},Y={Scale=y}} end}
local Instance={new=function() return {} end}
local files={}
local fetches,writes,registrations=0,0,0
local response=string.char(255,216,255).."JPEG fixture"
local game={HttpGet=function(_,url) fetches+=1; check(url:find("/assets/rift_logo.jpg",1,true),"wrong logo URL"); return response end}
local isfile=function(path) return files[path]~=nil end
local isfolder=function() return false end
local makefolder=function() end
local writefile=function(path,bytes) files[path]=bytes; writes+=1 end
local getcustomasset=function(path) check(files[path],"registered nonexistent logo"); registrations+=1; return "customasset://"..path end
local getsynasset
local makeBrand=(function()
-- INSERT BRAND
end)()
local url="https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub/main/assets/rift_logo.jpg"
local brand=makeBrand(url)
local image,fallback={Parent={Parent=true}},{Parent={Parent=true},Text="R",Visible=true}
local second,button={Parent={Parent=true}},{Parent={Parent=true},Text="R",Visible=true}
brand.Apply(image,fallback); brand.Apply(second,button)
check(#jobs==1 and not image.Visible and fallback.Text=="R","loader blocked or hid fallback while pending")
flush()
check(fetches==1 and writes==1 and registrations==1,"header and minimized logo downloaded separately")
check(image.Visible and second.Visible and image.Image==second.Image,"shared logo not assigned")
check(image.Parent.ClipsDescendants and image.ImageRectOffset.X==0 and math.abs(image.Position.X.Scale+374/520)<0.00001 and math.abs(image.Size.Y.Scale-1254/520)<0.00001,"wrong normalized R emblem crop")
check(button.Text=="" and button.Visible and fallback.Text=="","logo hid the restore button instead of its letter")
local late={Parent={Parent=true}}; brand.Apply(late)
check(late.Visible and late.Image==image.Image and #jobs==0,"late minimized control did not reuse registered asset")
local cached={Parent={Parent=true}}; makeBrand(url).Apply(cached); flush()
check(cached.Visible and fetches==1 and writes==1,"file cache was ignored")
local destroyed={Parent={Parent=true}}; makeBrand(url).Apply(destroyed); destroyed.Parent=nil; flush()
check(not destroyed.Image and not destroyed.Visible,"late download touched a destroyed UI")
files={}; response="<html>download failed</html>"
local bad,backup={Parent={Parent=true}},{Parent={Parent=true},Text="R",Visible=true}
makeBrand(url).Apply(bad,backup); flush()
check(not bad.Image and not bad.Visible and backup.Text=="R" and writes==1,"invalid downloaded file replaced fallback or was saved")
getcustomasset=nil; response=string.char(255,216,255).."JPEG fixture"
local unavailable,backup2={Parent={Parent=true}},{Parent={Parent=true},Text="R",Visible=true}
local before=fetches; makeBrand(url).Apply(unavailable,backup2); flush()
check(fetches==before and not unavailable.Visible and backup2.Text=="R","missing executor image support broke fallback")
print("PASS: Rift logo crop, shared download, file cache, late controls, destroyed windows, invalid downloads and executor fallback.")
