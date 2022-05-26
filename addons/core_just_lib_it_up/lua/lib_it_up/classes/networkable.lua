LibItUp.SetIncluded()
setfenv(0, _G)

if not muldim then include("multidim.lua") end
if not netstack then include("netstack.lua") end

--[[
	Emits:

		SV: "CustomWriteChanges" : changes_table
			If you have a custom encoder for the whole object, use this event and return anything from it

		SV: "ShouldNetwork"
			Returning false from this will prevent networking
			Changes won't be lost to networking, meaning it might attempt to network in the future

		SV: REMOVED || 	"ShouldEncode" : change_key, change_value
						If you return false from this, the change won't be written (but will be lost to networking!)
						Should be primarily used for equality checks

		SV: "WriteChangeValue" : key, value, players
			If you return false from this, the change value won't be written
			Should be primarily used to encode a value your own way


		CL: "CustomReadChanges"
			If you have a custom encoder for the whole object, use this event and return anything from it

		CL: "ReadChangeValue" : key
			If you had a custom encoder for the value in WriteChangeValue, this is the hook to read it from
			Return your value from it, and if it's nil, return the 2nd arg as "true"

		CL: "NetworkedVarChanged" : key, old_var, new_var
			Kinda like NetworkVarNotify

		CL: "NetworkedChanged" : changes_table
			Kinda like NetworkVarNotify, except after _everything_ was updated
]]

LibItUp.Networkable = LibItUp.Networkable or Emitter:callable()
Networkable = LibItUp.Networkable
local nw = Networkable

nw.IsNetworkable = true
nw._UpdateFrequency = 0.1

nw._Sizes = {
	NUMBERID = 16, -- if you need more than 65535 networkables, its likely there's a leak
	CHANGES_COUNT = 14,
}

_NetworkableCache = _NetworkableCache or {}

_NetworkableNumberToID = _NetworkableNumberToID or {} 	-- [num] = name
_NetworkableIDToNumber = _NetworkableIDToNumber or {} 	-- [name] = num

_NetworkableData = _NetworkableData or muldim:new() 	-- stores networkable data as [num_id] = {bunch of key-values}
local idData = _NetworkableData							-- only used clientside for handling net races for primitive nw's
														-- (no custom decoders)

nw.Verbose = nw.Verbose or (nw.Verbose == nil and false)
nw.Warnings = true
nw.BytesWarn = nw.BytesWarn or 500


nw.Profiling = {}
nw.Profiling._NWDataInstances = {}
nw.Profiling.CleanTime = 900

nw.FakeNil = nw.FakeNil or newproxy() --lul
local fakeNil = nw.FakeNil

local decoders = {
	"String",	"Entity",	"Vector",	"Table",	"Boolean",
	"Angle",	"Color",	"UInt",		"UShort",	"Int",
	"Double",	"Nil",		"Float",
}

nw.Types = {}
nw.TypesBack = {}
for k,v in ipairs(decoders) do
	nw.Types[v] = k - 1
end

nw.Types.Bool = nw.Types.Boolean

for k,v in pairs(nw.Types) do nw.TypesBack[v] = k end
nw.TypesBack[nw.Types.Bool] = "Boolean"

-- { [CurTime] = { [nameID] = amt_bytes, ... }

timer.Create("NetworkableCleanProfiler", nw.Profiling.CleanTime, 0, function()
	local ct = CurTime()

	for time, data in pairs(nw.Profiling._NWDataInstances) do
		if time < ct - nw.Profiling.CleanTime then
			nw.Profiling._NWDataInstances[time] = nil
		end
	end

end)

local realPrint = print
local print = function(...)
	if not nw.Verbose then return end
	realPrint(...)
end

local realPrintf = printf
local printf = function(...)
	if not nw.Verbose then return end
	realPrintf(...)
end

local warnf = function(s, ...)
	if not nw.Warnings then return end
	MsgC(Colors.Warning, "[NWble] ", color_white, s:format(...), "\n")
end

local cache = _NetworkableCache
local numToID = _NetworkableNumberToID -- these tables are not sequential!!!
local IDToNum = _NetworkableIDToNumber

function nw.ResetAll()
	table.Empty(cache)

	table.Empty(numToID)
	_NetworkableNumberToID = numToID

	table.Empty(IDToNum)
	_NetworkableIDToNumber = IDToNum

	if SERVER then
		table.Empty(_NetworkableChanges)
		table.Empty(_NetworkableAwareness)
		table.Empty(_NetworkableQueue)
	end
end

function nw.CreateIDPair(id, numid)
	if CLIENT then
		printf("Creating ID pair: %d <-> %s", numid, id)
	end
	numToID[numid] = id
	IDToNum[id] = numid
end

local _vONCache = {}
local _CurrentNWKey -- used for debug

-- make sure you up encoderIDLength if you go above encoder ID of 15
local ns = netstack:new()

nw.AutoAssignID = true
nw.EncoderLength = 5

function IsNetworkable(what)
	return istable(what) and what.IsNetworkable
end

function nw:Initialize(id, ...)
	self.Networked = {}
	
	self.__LastNetworked = {}
	self.__Aliases = {}			-- [name] = alias
	self.__AliasesBack = {}		-- [alias] = name
	self.__AliasesTypes = {}	-- [name] = type

	self.__LastSerialized = {} -- purely for networked tables
	self.__Aware = muldim:new()

	self.Valid = true
	--[[
	self:On("ShouldEncode", "TablesvONCheck", function(self, k, v)
		if istable(v) and not v.__isobject then
			local vonData = "bruh"--von.serialize(v)
			if self.__LastSerialized[k] == vonData then return end
			_vONCache[k] = vonData
		end
	end)
	]]

	if not rawget(self.__instance, "AutoAssignID") then return end 	-- if this object is constructed from an Networkable extension,
																	-- ignore the fact we don't have an ID

	assert(id, "Networkable creation requires an ID!")

	if cache[id] then return cache[id] end

	self:SetNetworkableID(id)
end

function nw:__tostring()
	return ("[Networkable][%d][`%s`]"):format(self.NumberID or -1, self.NetworkableID or "[no ID]")
end

function nw:SetNetworkableID(id, replace)
	self.NetworkableID = id

	if cache[id] and cache[id] ~= self and not replace then
		errorf("This isn't supposed to happen -- setting NWID with a networkable already existing! NWID: %s", id)
		return
	end
	cache[id] = self

	--printf("SetNetworkableID called %s %s %s", Realm(true, true), id, idData[id])

	if CLIENT and idData[id] then
		printf("stashed data for %s existed; merging", id)
		for k, v in pairs(idData[id]) do
			if self.__Aliases[k] then k = self.__Aliases[k] end
			printf("pulling cached change: %s = %s", k, v)
			self:Set(k, v)
		end
	end

	if SERVER then
		self:_SVSetNWID(id, replace)
	end

	return self
end

function nw:SetNetworkableNumberID(numid)
	assert(self.NetworkableID, "Networkable must have an ID before setting a number ID!")
	assert(isnumber(numid))

	numToID[numid] = self.NetworkableID
	IDToNum[self.NetworkableID] = numid

	self.NumberID = numid
end

function nw:IsValid()
	return self.Valid ~= false
end

function nw:_ValidateNW(k, v)
	assert(self.Valid, "Attempted to set a networked var on an invalid Networkable!")
	assert(self.NetworkableID, "Networkable must have an ID!")

	if not _NetworkableCache[self.NetworkableID] then
		printf("didn't find self with nwid?... %s", self.NetworkableID)
		self:SetNetworkableID(self.NetworkableID)
	end -- maybe resetall happened

end

function nw:SetTable(k, v)
	self:_ValidateNW(k, v)

	if not istable(v) then
		errorf("Calling SetTable on a non-table value! (%s = %s `%s`)", k, v, type(v))
		return
	end

	if v.__isobject then
		errorf("Calling SetTable on an object! (%s = %s `%s`)", k, v, type(v))
		return
	end

	if SERVER then
		self:_SVSetTable(k, v)
	end

	return self:Set(k, v)
end

function nw:Set(k, v)
	assert(k ~= nil, "key is nil")
	-- if you're using a table or an object as `v`, it's assumed you have a custom encoder for it
	-- if you don't, well, expect issues...
	self:_ValidateNW(k, v)

	if CLIENT then -- don't bother
		self.Networked[k] = v
		return self
	end

	self:_ServerSet(k, v)
	return self
end

function nw:Get(k, default)
	--if self.__Aliases[k] ~= nil then k = self.__Aliases[k] end

	local ret = self.Networked[k]
	if ret == fakeNil then return default end
	if ret == nil then return default end

	return ret
end

function nw:GetID()
	return self.NetworkableID
end

function nw:GetNumID()
	return _NetworkableIDToNumber[self:GetID()]
end
nw.GetNumberID = nw.GetNumID

-- self:Alias("__ct", 255, "Float")
function nw:Alias(k, k2, typ)
	if self.__Aliases[k] then
		self.__AliasesBack[k2] = nil
	end

	self.__Aliases[k] = k2
	self.__AliasesBack[k2] = k

	if typ and not Networkable.Types[typ] then
		errorNHf("unknown alias type: %s", typ)
		return
	end

	self.__AliasesTypes[k] = typ and Networkable.Types[typ]
end

function nw:GetNetworked() --shrug
	return self.Networked
end


function nw:Invalidate()
	if self.Valid == false then return end

	self.Valid = false

	if self.NetworkableID then
		cache[self.NetworkableID] = nil
		idData[self.NetworkableID] = nil

		if self.NumberID and numToID[self.NumberID] == self.NetworkableID then numToID[self.NumberID] = nil end

		IDToNum[self.NetworkableID] = nil
	end

	self:Emit("Invalidated")

	if SERVER then
		self:_SVBroadcastInvalidate()
	end

end


function nw:Bind(what)

	if IsPlayer(what) then
		local origUID = what:UserID()

		gameevent.Listen("player_disconnect")
		hook.OnceRet("player_disconnect", ("Networkable.Bind:%p"):format(what), function(data)
			local uid = data.userid
			if uid ~= origUID then return false end

			self:Invalidate()
		end)
	elseif isentity(what) then

		hook.OnceRet("EntityRemoved", ("Networkable.Bind:%p"):format(what), function(ent)
			if ent ~= what then return false end

			if CLIENT then
				--[[timer.Simple(0.1, function()
					if IsValid(ent) then self:Bind(ent) return end --fullupdates :v
					self:Invalidate()
					self.InvalidatedCuz = ("EntRemoved:%s,%s,%s"):format(ent, ent:EntIndex(), ent:IsValid())
				end)]]
			else
				self:Invalidate()
			end

		end)
	else
		errorf("Can't bind to %q (%s)!", type(what), what)
	end

	return self
end
nw.Bond = nw.Bind


function Networkable.Profiling.Print()
	local entries = {}
	for ct, dat in pairs(Networkable.Profiling._NWDataInstances) do
		entries[#entries + 1] = {ct, dat}
	end

	table.sort(entries, function(a, b) return a[1] < b[1] end)

	for _, t in ipairs(entries) do
		local ct, dat = unpack(t)
		local first = true

		for k,v in SortedPairs(dat) do
			if v > 200 then
				if first then
					MsgC(Colors.Red, ("%ds.:\n"):format(ct))
					first = false
				end

				MsgC(Colors.Sky, ("	%s: "):format(k), color_white, ("%d bytes\n"):format(v))
			end
		end
	end
end

if CLIENT then
	include("networkable_cl_ext.lua")
else
	include("networkable_sv_ext.lua")
end