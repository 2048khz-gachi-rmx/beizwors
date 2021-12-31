LibItUp.SetIncluded()
setfenv(0, _G)

if CLIENT then
	for i=1, 100 do
		ErrorNoHalt("WTF? Networkable_sv included clientside\n")
	end
end

if not muldim then include("multidim.lua") end
if not netstack then include("netstack.lua") end

local nw = LibItUp.Networkable
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

		SV: "WriteChange" : key, value, players
			If you return false from this, the change key/value won't be written
			Should be primarily used to encode both the key AND the value in your own way

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

_NetworkableChanges = _NetworkableChanges or muldim:new()
_NetworkableAwareness = _NetworkableAwareness or muldim:new() --[ply] = {'NameID', 'NameID'}
_NetworkableQueue = _NetworkableQueue or {}				-- [seq_id] = [name] ; FIFO

local update_freq = Networkable._UpdateFrequency
local SZ = Networkable._Sizes

SZ.INTERVAL_UPDATE = 1024 * 64 * Networkable._UpdateFrequency 	-- Networkable._UpdateFrequency = kb/nw frame
SZ.FULL_UPDATE = 1024 * 96										-- kb/s

Networkable.CurrentWritten = Networkable.CurrentWritten or 0
Networkable.WrittenWhen = Networkable.WrittenWhen or 0

SZ.WRITTEN_DECAY = 1024 * 64 -- 64kb becomes available each second

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

local encoderIDLength = 5 --5 bits fit 16 (0-15) encoders

local _vONCache = {}

local fakeNil = nw.FakeNil
--[[
	encoders
]]

-- make sure you up encoderIDLength if you go above encoder ID of 15
local ns = netstack:new()

-- write hijacked versions of net.*
ns:Hijack(true)

local encoders = {
	["string"] = {0, net.WriteString},
	["entity"] = {1, net.WriteEntity},
	["vector"] = {2, net.WriteVector},

	["table"] = {3, function(t, _, key)
		--if t.Networkable_Encoder then return t:Networkable_Encoder() end
		local vonned = (key and _vONCache[key]) or von.serialize(t)
		if key then _vONCache[key] = nil end

		net.WriteUInt(#vonned, 16)
		net.WriteData(vonned, #vonned)
	end},

	["boolean"] = {4, net.WriteBool},	--please don't use bools as keys for ID's lmao
	["angle"] = {5, net.WriteAngle},
	["color"] = {6, net.WriteColor},

	--7 to 11 are used!!!!!! do not use them!
}

ns:Hijack(false)
ns = nil

local function determineEncoder(typ, val)
	if val == fakeNil or val == nil then --lol
		return BlankFunc, 11
	end

	if typ == "number" then --numbers are a bit more complicated
		if math.ceil(val) == val and math.abs(val) < 2^32 - 1 then
			if val >= 0 then

				if val > 65535 then
					return net.WriteUInt, 7, 32 -- uint
				else
					return net.WriteUInt, 8, 16 -- ushort
				end
			elseif val < 0 then
				return net.WriteInt, 9, 32		-- int
			end
		else
			return net.WriteDouble, 10
		end
	end

	if typ == "player" or typ == "weapon" then typ = "entity" end
	if typ == "table" and IsColor(val) then
		return net.WriteColor, 6
	end

	local enc = encoders[typ]
	if not enc then errorf("Failed to find Encoder function for type %s! Value is %s", typ, val) return end

	return enc[2], enc[1], enc[3]
end

function nw.GetEncoder(val)
	return determineEncoder(type(val), val)
end

function nw.WriteEncoder(val)
	local enc, id, arg = determineEncoder(type(val), val)
	net.WriteUInt(id, encoderIDLength)

	return enc(val, arg)
end

--[[
	server-only methods used in shared
]]

function nw:_SVSetTable(k, v)
	-- like :Set() but does vON checking
	-- this is intended to be used with arrays/lists with von encodable shit

	-- setting objects will proc a networkablechange regardless of whether or not they're exact von-wise
	-- as we have no way of tracking it for custom objects
	-- they aren't intended to be serialized and are expected to be encoded in an emit ( and via an :Encode method when i get around to doing it :) )

	-- for tables, however, we can check if the data is exact

	local last_von = self.__LastSerialized[v]

	local err, new_von = pcall(von.serialize, v)

	if err then
		errorf("%s: Attempted to serialize a non-vON'able table! %s = %s\n%s", self, k, v, new_von)
	else
		if last_von == new_von then --[[ adios ]] return self end
		self.__LastSerialized[v] = new_von
	end
end

function nw:_SVBroadcastInvalidate()
	printf("-- BROADCASTING INVALIDATE FOR %s --", self.NetworkableID)
	_NetworkableChanges[self.NetworkableID] = nil
	self:_Dequeue()
	for ply, ids in pairs(_NetworkableAwareness) do
		print("	invalidating awareness for", self.NetworkableID, ply,
			ids[self.NetworkableID])
		ids[self.NetworkableID] = nil
	end

	-- TODO: Awareness check here
	net.Start("NetworkableInvalidated")
		net.WriteUInt(self.NumberID, 24)
	net.Broadcast()
end

function nw:_SVSetNWID(id, replace)
	local typ = type(id):lower()
	local before = (replace and cache[id])

	local encoder, encoderID, additionalArg = determineEncoder(typ, id)

	self.NetworkableIDEncoder = {
		Func = encoder, --function which will encode the ID
		ID = encoderID, --ID of the encoder function so the client knows how to figure it out
		IDArg = additionalArg, --additional arg for the encoder function, for cases like UInt and whatnot which require a second arg
	}

	local key = (replace and before and before.NumberID) or #numToID + 1
	assert(not numToID[key]) -- just in case, since luajit has issues with gapped tables iinm

	if key > bit.lshift(1, SZ.NUMBERID) then
		errorf("Networkable: NumberID's overflowed! (tried to write NWnumID %d, whereas max is %d)",
			key, bit.lshift(1, SZ.NUMBERID))
		return
	end

	local b4NumID = self.NumberID
	self:SetNetworkableNumberID(key)

	if b4NumID and b4NumID ~= key then
		for ply, nws in pairs(_NetworkableAwareness) do
			nws[id] = nil
		end
	end

end

--[[
	actual networking:
]]

local function WriteNWID(obj)
	net.WriteUInt(obj.NetworkableIDEncoder.ID, encoderIDLength).Description = "Encoder ID"
	obj.NetworkableIDEncoder.Func(obj.NetworkableID, obj.NetworkableIDEncoder.IDArg)
end

local function WriteChange(key, val, obj, ...)
	key = obj.__Aliases[key] ~= nil and obj.__Aliases[key] or key

	local key_typ = type(key):lower()
	local val_typ = type(val):lower()

	obj.__LastNetworked[key] = val
	if val == fakeNil then val = nil end

	local unAliased = obj.__AliasesBack[key] or key

	print("WriteChange", key, val, obj)

	local res = obj:Emit("WriteChange", unAliased, val, ...)
	if res == false then printf("WriteChangeValue asked to not write key/value (%s = %s)", unAliased, val) return end

	local k_encoder, k_encoderID, k_additionalArg = determineEncoder(key_typ, key)
	local v_encoder, v_encoderID, v_additionalArg = determineEncoder(val_typ, val)

	-- write key encoderID and the encoded key
	local op = net.WriteUInt(k_encoderID, encoderIDLength)
	k_encoder(key, k_additionalArg, val)

	if net.ActiveNetstack then
		op.Description = "Changed key encoder ID"
	end
	-- write val encoderID and the encoded val
	--print("WriteChange called", key, val)

	local res = obj:Emit("WriteChangeValue", unAliased, val, ...)

	if res == false then printf("WriteChangeValue asked to not write change (%s = %s)", unAliased, val) return end

	op = net.WriteUInt(v_encoderID, encoderIDLength)
	v_encoder(val, v_additionalArg, key)

	if net.ActiveNetstack then
		op.Description = "Changed value encoder ID"
	end
end

util.AddNetworkString("NetworkableSync")
util.AddNetworkString("NetworkableInvalidated")

function nw:_SendNet(who, full, budget)
	if self:Emit("ShouldNetwork", who) == false then return false end

	budget = math.min(budget or 32 * 1024, 63 * 1024) -- don't write more than 63kb in one net message

	local numID, nameID = self.NumberID, self.NetworkableID
	local unaware = not not full


	-- full is either a bool (use _all_ networked data) or a table (use only that networked data)
	-- done like this because if the network wasn't complete, you can pass the incomplete networked data back

	local changes

	if not full then
		-- _NetworkableChanges is intended to be nilled as the changes happen, so don't copy it
		changes = _NetworkableChanges[nameID]
		from_glob = true
	else
		-- `changes` will be modified, so copy the networked table if its a full update
		if istable(full) then
			changes = full
		else
			changes = table.Copy(self:GetNetworked())
		end
	end

	if not changes then return false end --/shrug

	-- we're networking something for sure at this point; start writing stuff

	-- write ID awareness
	if full ~= true then -- fullupdate ignores nw awareness
		for _, ply in ipairs(who) do
			-- if some player didn't know about this NWID, network the ID as well
			print("awareness for", nameID, ply, _NetworkableAwareness[ply], _NetworkableAwareness[ply] and _NetworkableAwareness[ply][nameID])
			if not _NetworkableAwareness[ply] or not _NetworkableAwareness[ply][nameID] then
				unaware = true
				_NetworkableAwareness:Set(true, ply, nameID)
				printf("%s unware of %s[%d], networking.", ply, nameID, numID)
			end
		end
	end

	local changes_count = table.Count(changes)

	local written = 0
	local needRerun = false -- if we haven't networked everything we had, we'll need a rerun next nw frame

	net.Start("NetworkableSync")
		local ns = netstack:new()
		ns:Hijack()

		-- write numberID + NWID if there are any unaware people
		net.WriteBool(unaware)
		net.WriteUInt(numID, SZ.NUMBERID).Description = "NumberID for `" .. nameID .. "`"

		if unaware then
			WriteNWID(self)
			printf("writing NWID (%s[%d]).", nameID, numID)
		end

		self:Emit("StartWritingChanges", changes)

		local actuallyWritten = 0
		local nsCursor = 0

		if self:Emit("CustomWriteChanges", changes) == nil then
			net.WriteUInt(changes_count, SZ.CHANGES_COUNT).IsChangesCount = true
			nsCursor = ns:GetCursor() - 1

			for k,v in pairs(changes) do
				WriteChange(k, v, self, who)
				changes[k] = nil
				actuallyWritten = actuallyWritten + 1

				if ns:BytesWritten() > budget then
					if next(changes, k) then
						needRerun = true -- we're yeeting but we have more changes
					end

					goto send -- YEET IT
				end
			end
		end

		::send::
		written = ns:BytesWritten()

		ns:Hijack(false)

		ns:SetCursor(nsCursor)
		ns:WriteUInt(actuallyWritten, SZ.CHANGES_COUNT)

		for k,v in pairs(who) do
			print(k, v)
		end

		local ct = math.floor(CurTime())
		local instances = nw.Profiling._NWDataInstances[ct] or {}
		nw.Profiling._NWDataInstances[ct] = instances

		local instBytes = instances[nameID] or 0

		print(ns)
		net.WriteNetStack(ns)
		instances[nameID] = instBytes + (net.BytesWritten())
		print("sending ", net.BytesWritten(), " bytes")
	net.Send(who)

	return ns, written, needRerun and changes
end

function Networkable:_Queue()
	local q = _NetworkableQueue
	for k,v in ipairs(q) do
		if v == self.NetworkableID then return end
	end

	local inj = {}
	local injLkup = self:_InjectDeps(inj, injLkup)

	for k, obj in pairs(inj) do
		injLkup = obj:_InjectDeps(inj, injLkup)
	end

	for k,v in ipairs(inj) do
		v:_Queue()
	end

	q[#q + 1] = self.NetworkableID
end

function Networkable:_Dequeue()
	local q = _NetworkableQueue
	for i=#q, 1, -1 do
		if v == self.NetworkableID then table.remove(q, i) end
	end
end

-- networks all networkables to all players
local function NetworkAll()
	Networkable.OverBudget = false
	if not next(_NetworkableChanges) then return end

	for nwID, changes in pairs(_NetworkableChanges) do
		if cache[nwID] then
			cache[nwID]:_Queue()
		end
	end

	local all = player.GetAll()
	local nwTo = {}

	local total_written = 0
	local ct = CurTime()
	local budget = Networkable.GetAvailableBudget(false)

	-- every NW that needs networking will be in this queue
	-- so we pop the first one and network it
	for i=1, #_NetworkableQueue do
		if total_written > budget then
			Networkable._OnOverBudget()
			Networkable.CurrentWritten = Networkable.CurrentWritten + total_written
			Networkable.WrittenWhen = ct
			return
		end

		local name = _NetworkableQueue[1]

		local obj = _NetworkableCache[name]
		local shouldFull = false

		if not obj or not obj:IsValid() then continue end

		if obj.Filter then
			nwTo = {}

			for k,v in ipairs(all) do
				if obj:Filter(v) ~= false then
					nwTo[#nwTo + 1] = v
				end
			end
		else
			nwTo = all
		end

		local ns, written, remaining = obj:_SendNet(nwTo, shouldFull, SZ.INTERVAL_UPDATE - total_written)
		if ns then
			total_written = total_written + written
		end

		-- technically, the _NetworkableChanges queue-r should handle this
		-- but this would be the "proper" way i think
		if not remaining then
			table.remove(_NetworkableQueue, 1)
			_NetworkableChanges[obj:GetID()] = nil
		end

		--[[
		printf("NetworkAll #%d: `%s`, total written: %.1fkb. / %.1fkb., remaining: %s [%s entries]",
			i, obj.NetworkableID, total_written / 1024, budget / 1024, remaining, remaining and table.Count(remaining) or "none")
		]]
	end

	Networkable.CurrentWritten = Networkable.CurrentWritten + total_written
	Networkable.WrittenWhen = ct
end

_G.NWAll = NetworkAll

local nwErr = Curry(warnf, "NetworkableNetwork error: %s")
local nwAll = function()
	xpcall(NetworkAll, nwErr)
	timer.Adjust("NetworkableNetwork", update_freq, 0, nwAll)
	hook.NHRun("NetworkableNetworkFrame")
end

function Networkable._DoDecay()
	local passed = CurTime() - Networkable.WrittenWhen
	local decayed = passed * SZ.WRITTEN_DECAY			-- how much data became available since last write

	Networkable.CurrentWritten = math.max(Networkable.CurrentWritten - decayed, 0)

	printf("%.2fs. passed:\n	decay: %.1fkb. / %.1fkb.",
		passed, decayed / 1024, Networkable.CurrentWritten / 1024)
end

function Networkable.GetAvailableBudget(full)
	local total_available = (isnumber(full) and full) or
		(full and SZ.FULL_UPDATE or SZ.INTERVAL_UPDATE)

	Networkable._DoDecay()

	local budget = total_available - Networkable.CurrentWritten

	printf("budget: %.1fkb. / %.1fkb. [%s]",
		budget / 1024, total_available / 1024, full)

	return budget
end

function Networkable._OnOverBudget()
	-- called when budget gets exceeded during networking
	-- set a flag and force us to wait until the next networking frame
	Networkable.OverBudget = true
	timer.Adjust("NetworkableNetwork", update_freq, 0, nwAll)
end

-- Updates every player in `who` table on every networkable
-- in `what` table, regardless of their awareness

local b = bench("a")


function Networkable.UpdateFull(who, what, frag)
	if not what then
		what = _NetworkableCache
	end

	if istable(who) then
		Filter(who, true):Filter("IsValid", true)
	else
		who = {who}
	end

	local nwTo = {} -- table of players to network to
	local nwObjs
	local startIter = 1


	if not isnumber(frag) then
		-- not a fragmented update; copy `what`
		nwObjs = {}

		local inj = {}
		local injLkup

		for k, obj in pairs(what) do
			injLkup = obj:_InjectDeps(inj, injLkup)
			if not injLkup[obj] then
				inj[#inj + 1] = obj
				injLkup[obj] = true
			end
		end

		for k,v in ipairs(inj) do
			nwObjs[#nwObjs + 1] = {v, true} -- [1] = nwObj, [2] = changesToTransmit
			-- if [2] is a boolean, transmit all
		end

	else
		-- fragmented update; `what` already has the format we need
		nwObjs = what
		startIter = frag - (what[frag - 1] and 1 or 0)
	end

	local budget = Networkable.GetAvailableBudget(true)

	local total_written = 0

	for i=startIter, table.maxn(nwObjs) do
		if total_written > budget then
			Networkable._OnOverBudget()
			-- if we go over budget, wait till the next networking frame and
			-- call the function again with what we couldn't network this time
			hook.Once("NetworkableNetworkFrame", function()
				Networkable.UpdateFull(who, nwObjs, i)
			end)

			Networkable.CurrentWritten = Networkable.CurrentWritten + total_written
			Networkable.WrittenWhen = CurTime()

			return
		end

		local dat = nwObjs[i]
		local obj = dat[1]
		if obj.Filter then
			nwTo = {}

			for k,v in ipairs(who) do
				if obj:Filter(v) ~= false then
					nwTo[#nwTo + 1] = v
				end
			end
		else
			nwTo = who
		end

		local _, written, remaining = obj:_SendNet(nwTo, dat[2], budget - total_written)
		if written then
			total_written = total_written + written
		end

		if not remaining then
			nwObjs[i] = nil
		else
			nwObjs[i][2] = remaining
		end

		--[[printf("UpdateFull #%d: `%s`, total written: %.1fkb. / %.1fkb., remaining: %s",
			i, obj.NetworkableID, total_written / 1024, budget / 1024, remaining)]]
	end

	Networkable.CurrentWritten = Networkable.CurrentWritten + total_written
	Networkable.WrittenWhen = CurTime()
end

Networkable.FullUpdate = Networkable.UpdateFull

timer.Create("NetworkableNetwork", update_freq, 0, nwAll)

hook.Add("PlayerFullyLoaded", "NetworkableUpdate", function(ply)
	Networkable.UpdateFull(ply, _NetworkableCache)
end)

function nw:Network(full)
	local to = player.GetAll()
	local copy = {}

	if self.Filter then
		copy = {}

		for k,v in ipairs(to) do
			if self:Filter(v) ~= false then
				copy[#copy + 1] = v
			end
		end

	else
		copy = to
	end

	self:_SendNet(copy, not not full)
end

function nw:_NWNextTick()
	-- network all the next tick
	if not Networkable.OverBudget then
		timer.Adjust("NetworkableNetwork", 0, 0, nwAll)
	end
end

function nw:_ServerSet(k, v)
	if self.Networked[k] == v and not istable(v) then --[[adios]] return end

	if (v ~= nil and self.__LastNetworked[k] == v) or (v == nil and self.__LastNetworked[k] == fakeNil) then
		self.Networked[k] = v

		-- last networked is what we just set;
		-- set the var like normal but dont network it (cuz everyone already knows)
		_NetworkableChanges:Set(nil, self.NetworkableID, k) -- clear this change

		local ch = _NetworkableChanges:Get(self.NetworkableID)
		if table.IsEmpty(ch) then -- no changes left; remove us from changes entirely
			_NetworkableChanges:Set(nil, self.NetworkableID)
		end

		return
	end

	self.Networked[k] = v
	if v == nil then v = fakeNil end

	_NetworkableChanges:Set(v, self.NetworkableID, k)
end

-- injects the deps of an nw into the table before this nw

--[[
	nwable1,					nwable1,
	nwable2,					nwable2,
 -> depending_nw3,		-->		depended_nw5,
	nwable4,					depending_nw3,
	depended_nw5,				nwable4,
]]

function nw:_InjectDeps(tbl, injected)
	injected = injected or {[self] = true}

	if self.Dependencies then

		for k,v in ipairs(self.Dependencies) do
			if not v:IsValid() then continue end

			if not injected[v] then
				injected[v] = true
				-- inject the deps' deps recursively
				v:_InjectDeps(tbl, injected)
				-- then inject the dep itself
				table.insert(tbl, v)
			end
		end

	end

	return injected
end

function nw:AddDepend(nw2)
	assert(IsNetworkable(nw2))
	self.Dependencies = self.Dependencies or {}
	table.insert(self.Dependencies, nw2)
end

nw.AddDependency = nw.AddDepend