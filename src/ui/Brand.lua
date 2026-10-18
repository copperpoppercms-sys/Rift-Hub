-- Exact user-supplied Rift logo. ImageRect selects the R emblem for compact controls.
-- One asynchronous download per script; failed image loading leaves the text fallback usable.
return function(url)
	local M={}
	local asset,started=nil,false
	local targets=setmetatable({},{__mode="k"})
	local function paint(image,fallback)
		if not image.Parent or not asset then return end
		image.Image=asset; image.Visible=true
		if fallback and fallback.Parent then fallback.Text="" end
	end
	function M.Apply(image,fallback)
		image.Name="RiftLogo"; image.ImageRectOffset=Vector2.new(380,295); image.ImageRectSize=Vector2.new(510,525)
		image.ImageColor3=Color3.new(1,1,1); image.ScaleType=Enum.ScaleType.Fit; image.Visible=false
		targets[image]=fallback or false
		if asset then paint(image,fallback); return end
		if started then return end; started=true
		task.spawn(function()
			local ok,result=pcall(function()
				local customAsset=type(getcustomasset)=="function" and getcustomasset or type(getsynasset)=="function" and getsynasset
				assert(customAsset and type(writefile)=="function" and type(isfile)=="function","Custom images unavailable")
				local path="RiftHub/rift-logo-92145dc6000c.jpg"
				if type(isfolder)=="function" and type(makefolder)=="function" and not isfolder("RiftHub") then makefolder("RiftHub") end
				if not isfile(path) then
					local bytes=game:HttpGet(url)
					assert(type(bytes)=="string" and bytes:sub(1,3)==string.char(255,216,255),"Invalid Rift logo")
					writefile(path,bytes)
				end
				local content=customAsset(path)
				assert(type(content)=="string" and content~="","Image registration failed")
				return content
			end)
			if not ok then return end
			asset=result
			for image,fallback in pairs(targets) do paint(image,fallback) end
			table.clear(targets)
		end)
	end
	return M
end
