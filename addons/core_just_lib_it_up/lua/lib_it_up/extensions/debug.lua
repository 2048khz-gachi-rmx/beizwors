LibItUp.SetIncluded()

local modules = {}

local logger = Object:extend()

ChainAccessor(logger, "_ShouldNewline", "ShouldNewline")
ChainAccessor(logger, "_Name", "Name")
ChainAccessor(logger, "_Color", "Color")

function LogModule(name, col)
	name = name or "[Unnamed]"

	if modules[name] then
		modules[name].col = col or modules[name].col
		return modules[name]
	end

	local ret = logger:new()
		ret:SetName(name)
		ret:SetColor(col or Color(255, 0, 0))
		ret:SetShouldNewline(true)

	modules[name] = ret
	return ret
end


-- you may use '[col = 255, 0, 0]' (ambigous spaces) to color up the logs
local function Log(mod, str, ...)
	if not mod then error("Can't log without a logger object.") return end

	local n = mod:GetName()
	local col = mod:GetColor()

	str = isstring(str) and str:format(...) or table.concat({...}, "	")

	local tbl = {
		col,
		("[%s] "):format(n),
		Color(255, 255, 255)
	}

	local str2 = str

	local tags = str:match("%b[]")

	if tags then
		local lastsub = 0

		for s in str:gmatch("%[(.-)%]") do --match color tags
			local r, g, b = s:match("col[%s]*=[%s]*(%d+),[%s]*(%d+),[%s]*(%d+)")

			if r or g or b then

				local where, ends = string.find(str2, s, 1, true)
				str2 = str2:gsub(s, "")

				tbl[#tbl + 1] = string.sub(str2, lastsub+1, where-2)

				tbl[#tbl + 1] = Color(r, g or 0, b or 0)
				lastsub = where
			end
		end

		tbl[#tbl + 1] = string.sub(str2, lastsub+1, #str2)
	else
		tbl[#tbl + 1] = str
	end

	tbl[#tbl + 1] = color_white:Copy()

	if mod:GetShouldNewline() then
		tbl[#tbl + 1] = "\n"
	end


	MsgC(unpack(tbl))
end

logger.__call = Log

Logger = LogModule
LibItUp.Log = Logger("LBU", Color(210, 255, 99))

function Realm(lower, side)
	local s = (CLIENT and "Client" or "Server") .. (side and "side" or "")
	if lower then return s:lower() end
	return s
end

function Rlm(lower)
	if lower then
		return CLIENT and "cl" or "sv"
	else
		return CLIENT and "CL" or "SV"
	end
end

local svcol = Color( 137, 222, 255 )
local clcol = Color( 255, 222, 102 )
local realmcol = SERVER and svcol or clcol

function RealmColor()
	return realmcol
end

function clPrint(...)
	if CLIENT then print(...) end
end
clprint = clPrint

function svPrint(...)
	if SERVER then print(...) end
end
svprint = svPrint

function clPrintf(...)
	if CLIENT then printf(...) end
end
clprintf = clPrintf

function svPrintf(...)
	if SERVER then printf(...) end
end
svprintf = svPrintf

if not CheckArg then LibItUp.IncludeIfNeeded("extensions/lua.lua") end

LibItUp.LogIDs = LibItUp.LogIDs or {}
function CreateLogID(id, str, types)
	CheckArg(1, id, "string")
	CheckArg(2, str, "string")
	CheckArg(3, types, {})

	local m = LogModule(id, Colors.Warning)
	m.FormatStr = str
	m.Types = types

	LibItUp.LogIDs[id] = m
end

CreateLogID("log-idless", "Attempted to log a string with non-existent ID: %s", {""})

if CLIENT then
	-- todo: this will send the stuff to the server
	function clLog(id, ...)
		if not LibItUp.LogIDs[id] then
			clLog("log-idless", id)
			return
		end

		-- todo: typecheck ... here

		Log(LibItUp.LogIDs[id], LibItUp.LogIDs[id].FormatStr, ...)
	end
end