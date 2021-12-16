
AddCSLuaFile()


local _CL = 1
local _SH = 2
local _SV = 3

CUM = CUM or {}

CUM.Log = Logger("CUM", Color(151, 148, 3))

CUM.cmds = CUM.cmds or {}
CUM.Cats = CUM.Cats or {}

local function IncludeFolder(name, realm)
	local file, folder = file.Find( name, "LUA" )
	local tbl = string.Explode("/", name)
	tbl[#tbl] = ""
	local fname = table.concat(tbl,"/")
	if not realm then realm=_SH end

	for k,v in SortedPairs(file) do
		local name = ""
		if realm==_CL then

			if SERVER then
				AddCSLuaFile(fname..v)
			end

			if CLIENT then
				include(fname..v)
			end

		elseif realm == _SH then

			include(fname..v)
			AddCSLuaFile(fname..v)

		elseif realm == _SV and SERVER then

			include(fname..v)
		else
			ErrorNoHalt("Could not include file " .. fname .. "; fucked up realm?")
			continue
		end

		local rstr = (realm==_CL and "Client") or (realm==_SH and 'Shared') or (realm==_SV and 'Server') or "WHAT THE FUCK?"

	end

	for k,v in pairs(folder) do
		IncludeFolder(name..v, realm)
	end

end

local function IncludeCommands()

	local file, folder = file.Find( "CUM/commands/*", "LUA" )

	local fname = "CUM/commands/"

	for k,v in SortedPairs(file) do
		local catname = v:gsub(".lua", "")
		CUM.CurCat = catname
		include(fname .. v)
	end

	CUM.CurCat = nil
end

hook.Add("OnMySQLReady", "CUM", function()
	IncludeFolder("CUM/server/*.lua", _SV)
	IncludeFolder("CUM/client/*.lua", _CL)
	IncludeFolder("CUM/*.lua", _SH)

	IncludeFolder("CUM/misc/client/*.lua", _CL)
	IncludeFolder("CUM/misc/server/*.lua", _SV)
	IncludeFolder("CUM/misc/*.lua", _SH)

	IncludeCommands()

	for k,v in pairs(CUM.cmds) do
		aowl.cmds[k] = nil
	end
end)

hook.Add("AowlCommandAdded", "CUM_Aowl", function(name)
	if CUM.cmds[name] then aowl.cmds[name] = nil end
end)

for k,v in pairs(CUM.cmds) do
	aowl.cmds[k] = nil
end
--IncludeFolder("CUM/commands/*", _SV)