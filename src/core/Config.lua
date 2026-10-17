-- Luau | Roblox | Xeno/Synapse-class executor | flag persistence via executor filesystem API
local HttpService = game:GetService("HttpService")

local FOLDER = "RiftHub"
local CONFIG_FOLDER = FOLDER .. "/configs"

local Config = {}
Config.Flags = {} -- live flag table, shared by reference with UI elements

local function fileApiAvailable()
	return type(isfile) == "function" and type(writefile) == "function" and type(readfile) == "function"
end

function Config.EnsureFolders()
	if not fileApiAvailable() then return end
	if type(isfolder) == "function" and type(makefolder) == "function" then
		if not isfolder(FOLDER) then makefolder(FOLDER) end
		if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
	end
end

function Config.Save(name)
	if not fileApiAvailable() then return false, "executor has no file API" end
	Config.EnsureFolders()
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, Config.Flags)
	if not ok then return false, encoded end
	local path = string.format("%s/%s.json", CONFIG_FOLDER, name)
	local writeOk, err = pcall(writefile, path, encoded)
	if not writeOk then return false, err end
	return true
end

function Config.Load(name)
	if not fileApiAvailable() then return false, "executor has no file API" end
	local path = string.format("%s/%s.json", CONFIG_FOLDER, name)
	if not isfile(path) then return false, "no such config" end
	local ok, raw = pcall(readfile, path)
	if not ok then return false, raw end
	local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not decodeOk then return false, data end
	for k, v in pairs(data) do
		Config.Flags[k] = v
	end
	return true, data
end

function Config.List()
	if not fileApiAvailable() or type(listfiles) ~= "function" then return {} end
	Config.EnsureFolders()
	local out = {}
	for _, path in ipairs(listfiles(CONFIG_FOLDER)) do
		local name = path:match("([^/\\]+)%.json$")
		if name then table.insert(out, name) end
	end
	return out
end

function Config.Delete(name)
	if not fileApiAvailable() or type(delfile) ~= "function" then return false end
	local path = string.format("%s/%s.json", CONFIG_FOLDER, name)
	if isfile(path) then
		pcall(delfile, path)
		return true
	end
	return false
end

return Config
