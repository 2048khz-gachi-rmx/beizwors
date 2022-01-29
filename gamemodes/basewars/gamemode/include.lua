
AddCSLuaFile()

BaseWars = BaseWars or {}
BW = BaseWars
Basewars = BW

local rlm = Realm(true, true)

local includes = {
	[_CL] = function(name, should)
		-- always add to CSLua,
		-- don't include clientside if should = false

		if SERVER then
			AddCSLuaFile(name)
		else
			if should == false then return end
			return include(name)
		end
	end,

	[_SH] = function(name, cl, sv)
		--cl = false : file doesn't get AddCSLua'd + not included clientside
		--cl = 1     : file gets only AddCSLua'd but not included
		--sv = false : file is not loaded but can be AddCSLua'd

		if cl ~= false then AddCSLuaFile(name) end
		if (sv ~= false and SERVER) or (cl ~= false and cl ~= 1 and CLIENT) then return include(name) end
	end,


	[_SV] = function(name, should)
		if not SERVER or should == false then return end
		return include(name)
	end,

}

local function Realm()
	return CLIENT and 1 or 2
end

local needToInclude = {
	[1] = {[_CL] = true, [_SH] = true, [_SV] = false},
	[2] = {[_CL] = true, [_SH] = true, [_SV] = true} 	--even though server's _CL should be false it's actually true because the server needs to AddCSLua
}

local function NeedToInclude(realm)
	return needToInclude[Realm()][realm]
end

FInc.IncludeRealms = includes

local BlankFunc = function() end

local inlinedFIncRecursive

function inlinedFIncRecursive(name, realm, nofold, callback)	--even though with "nofold" it's not really recursive
	if not NeedToInclude(realm) then return end
	callback = callback or BlankFunc

	local file, folder = file.Find( name, "LUA" )

	local path = name:match("(.+/).+$") or ""
	local wildcard = name:match(".+/(.+)$")

	for k,v in pairs(file) do
		if not v:match(".+%.lua$") then continue end --if file doesn't end with .lua, ignore it
		if v:match("^_[^/]+%.lua$") then continue end -- prefixed with _ dont get included

		local inc_name = path .. v
		if inc_name:match("extensions/includes%.lua") then continue end --don't include yourself

		if loading then files = files + 1 end

		if includes[realm] then
			local cl, sv = callback (inc_name)
			includes[realm] (inc_name, cl, sv)

		else
			ErrorNoHalt("Could not include file " .. inc_name .. "; fucked up realm?\n")
			continue
		end

	end

	if not nofold then
		for k,v in pairs(folder) do

			-- path/ .. found_folder  .. /  .. wildcard_used
			-- muhaddon/newfolder/*.lua

			inlinedFIncRecursive(path .. v .. "/" .. wildcard, realm, nil, callback)
		end
	end

end

local function includeCS(File)
	include(File)
	if SERVER then
		AddCSLuaFile(File)
	end
end

BaseWars.LoadLog = Logger("BW-Load", Color(220, 100, 100))

MsgC("\n")
BaseWars.LoadLog("Beginning inclusion %s%s",
	("[col=%d,%d,%d]"):format(RealmColor():Copy():ModHSV(0, -0.1, -0.2):Unpack()),
	rlm)

local stageStart, stageEnd

local function printFinish()
	local took = stageEnd - stageStart
	local warn = 0.3
	local col = Colors.Greenish

	if took > warn then
		col = Colors.Warning
	end

	MsgC( col, ("	| took %.2fs.\n"):format(stageEnd - stageStart) )
end

local t1 = SysTime()


BaseWars.LoadLog:SetShouldNewline(false)

	-- derivation takes a long time
	BaseWars.LoadLog("	Deriving...")
		-- FProfiler.start()
		stageStart = SysTime()
			DeriveGamemode("sandbox")
		stageEnd = SysTime()
		-- FProfiler.stop()
		printFinish()


	BaseWars.LoadLog("	Including shared...")

		stageStart = SysTime()
			includeCS("shared.lua")
			-- includeCS("language.lua")
			includeCS("config.lua")

			if ulib or ulx then
				includeCS("integration/bw_admin_ulx.lua")
			end
		stageEnd = SysTime()

		printFinish()


	local path = "basewars/gamemode/"

	local function shouldInclude(fn)
		if fn:match("_ext") then return false, false end
	end


	BaseWars.LoadLog("	Including realm folders...")

	stageStart = SysTime()
		inlinedFIncRecursive(path .. "shared/*", _SH, nil, shouldInclude)
		inlinedFIncRecursive(path .. "client/*", _CL, nil, shouldInclude)
		inlinedFIncRecursive(path .. "server/*", _SV, nil, shouldInclude)
	stageEnd = SysTime()

	printFinish()

BaseWars.LoadLog:SetShouldNewline(true)


BaseWars.LoadLog("	Running module includer.")

if not IncludeBasewarsModules then
	BaseWars.LoadLog("!!!  Module includer does not exist! !!!")
	BaseWars.LoadLog("!!! `IncludeBasewarsModules` is nil! !!!\n")
else
	IncludeBasewarsModules()
end

local t2 = SysTime()

BaseWars.LoadLog("Included all %s in %.3fs!", rlm, t2 - t1)
MsgC("\n")

BaseWars.Loaded = true