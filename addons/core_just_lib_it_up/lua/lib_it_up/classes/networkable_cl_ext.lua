local nw = Networkable
local idData = _NetworkableData

local SZ = Networkable._Sizes

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
local _CurrentNWKey = nil
local encoderIDLength = nw.EncoderLength

local decoders = {
	["string"] = {0, net.ReadString},
	["entity"] = {1, function()
		local entID = net.ReadUInt(16)
		if IsValid(Entity(entID)) then return Entity(entID) end
		errorf("Reading '%s' : Entity[%d] isn't valid. Consider networking something else...?", _CurrentNWKey, entID)
	end},
	["vector"] = {2, net.ReadVector},

	["table"] = {3, function(t)
		--if t.Networkable_Decoder then return t:Networkable_Decoder() end

		local len = net.ReadUInt(16)
		local von_data = net.ReadData(len)

		local de_vonned = von.deserialize(von_data)

		return de_vonned
	end},

	["boolean"] = {4, net.ReadBool},
	["angle"] = {5, net.ReadAngle},
	["color"] = {6, net.ReadColor},

	["uint"] = {7, net.ReadUInt, 32},
	["ushort"] = {8, net.ReadUInt, 16},

	["int"] = {9, net.ReadInt, 32},
	["float"] = {10, net.ReadDouble, 32},
	["nil"] = {11, BlankFunc}
}

local decoderByID = {}

for typ,v in pairs(decoders) do
	decoderByID[v[1]] = v
end

local function IDToNumber(id)
	return IDToNum[id]
end

local function NumberToID(id)
	return numToID[id]
end

local function ReadNWID()
	local enc_id = net.ReadUInt(encoderIDLength)

	local dec = decoderByID[enc_id]
	local name = dec[2](dec[3])

	return name
end

local function ReadChange(obj)
	local k_encID = net.ReadUInt(encoderIDLength)

	local k_dec = decoderByID[k_encID]

	if not k_dec then errorf("Failed to read key decoder ID from %s properly (@ %d)", obj or "NWLess", k_encID) return end

	local decoded_key = k_dec[2](k_dec[3])
	printf("decoded key: %s (dealiased: %s)", decoded_key, obj and (obj.__AliasesBack[decoded_key] or "no alias") or "no obj")
	if obj and obj.__AliasesBack[decoded_key] then decoded_key = obj.__AliasesBack[decoded_key] end

	if obj then
		-- try to emit for this key's decoder specifically first
		local customValue, setNil = obj:Emit("ReadChange" .. tostring(decoded_key))
		if customValue ~= nil or setNil then return decoded_key, customValue end

		-- try to emit for generic custom decoder
		customValue, setNil = obj:Emit("ReadChangeValue", decoded_key)
		if customValue ~= nil or setNil then return decoded_key, customValue end
	end

	local v_encID = net.ReadUInt(encoderIDLength)

	local v_dec = decoderByID[v_encID]
	if not v_dec then errorf("Failed to read value decoder ID from %s properly (@ %d)", obj or "NWLess", v_encID) return end

	local decoded_val = v_dec[2](v_dec[3])

	print("	decoded key, val:", decoded_key, decoded_val)
	return decoded_key, decoded_val
end

function Networkable.ReadByDecoder(encid)
	if not encid then
		encid = net.ReadUInt(encoderIDLength)
	end

	local dec = decoderByID[encid]

	if not dec then
		errorf("Failed to read key decoder ID properly (@ %d)", encid)
		return
	end

	return dec[2](dec[3])
end

net.Receive("NetworkableSync", function(len)
	local lBytes = len / 8

	printf("received Networkable sync: %d bytes", lBytes)

	local is_new = net.ReadBool()
	local num_id = net.ReadUInt(SZ.NUMBERID)
	local nwID

	if is_new then
		printf("new networkable sync, reading NWID for numid %d", num_id)
		nwID = ReadNWID(num_id)
	else
		nwID = NumberToID(num_id)
		printf("we're supposed to know the pair for %d [think its %s]", num_id, nwID)
	end

	if lBytes > Networkable.BytesWarn then
		warnf("	quite a long Networkable update for `%s` (%d bytes)", nwID or ("[numID: %d]"):format(num_id), lBytes)
	end

	if not nwID then
		warnf("Something went wrong while reading networkable: failed to grab NWID for numID %d.", num_id)
		return
	end

	_CurrentNWKey = nwID

	-- write entry into profiler
	local ct = math.floor(CurTime())
	local instances = nw.Profiling._NWDataInstances[ct] or {}
	nw.Profiling._NWDataInstances[ct] = instances

	local instBytes = instances[nwID] or 0
	instances[nwID] = instBytes + lBytes

	local obj = cache[nwID]

	if not obj then
		printf("object for %s <-> %d didn't exist, creating ID pair", nwID, num_id)
		Networkable.CreateIDPair(nwID, num_id)
	else
		printf("object for %s <-> %d existed, just setting numid", nwID, num_id)
		obj:SetNetworkableNumberID(num_id)
	end

	if not obj then
		local added = hook.Run("NetworkableAttemptCreate", nwID)

		if not added then
			obj = cache[nwID]
			if obj then
				warnf("Some hook created a networkable for `%s`, but didn't return success.", nwID)
			end

			if not obj then
				warnf("Networkable with the name `%s` (%d) didn't exist clientside.", nwID, num_id)
			end

		elseif added then
			obj = cache[nwID]
			if not obj then
				warnf("Some hook returned success, but didn't create a networkable for `%s`.", nwID)
			end
		end

		if obj then
			printf("post-creation: %s <-> %s", obj:GetID(), obj:GetNumberID())
		end
	end

	if obj and obj:Emit("CustomReadChanges") ~= nil then
		printf("	networkable %s(%d) had custom reader", nwID or "nil", num_id)
		return
	end

	local cng_amt = net.ReadUInt(SZ.CHANGES_COUNT)
	printf("	amt of changed keys for %s(id: %s): %d", obj, nwID:Quote(), cng_amt)

	local changes = {}
	for i=1, cng_amt do

		printf("	reading change #%d", i)

		if not obj then warnf("Reading an object-less change #%d", i) end
		local k, v = ReadChange(obj)

		if obj then
			changes[k] = {obj.Networked[k], v}
			obj.Networked[k] = v
			obj:Emit("NetworkedVarChanged", k, changes[k][1], v) -- key, old, new
			hook.Run("NetworkableVarChanged", obj, k, changes[k][1], v)
		else

			idData:Set(v, NumberToID(num_id), k)
			warnf("	Couldn't find object with numID %d; stashing change...", num_id)
		end

	end

	if obj then
		obj:Emit("NetworkedChanged", changes)
		hook.Run("NetworkableChanged", obj, changes)
	end
end)

net.Receive("NetworkableInvalidated", function()
	local num_id = net.ReadUInt(SZ.NUMBERID)
	print("invalidated nwable with numID", num_id)
	local id = NumberToID(num_id)
	print("that's ID", id)

	if not id then print("we dont know that") return end

	local can, can_id = hook.Run("NetworkableInvalidate", id, _NetworkableCache[id])
	if can ~= false then
		_NetworkableData[id] = nil

		if _NetworkableCache[id] then
			_NetworkableCache[id].InvalidatedCuz = "ServerSaidSo"
			_NetworkableCache[id]:Invalidate()
		end
	end

	if can_id ~= false then
		_NetworkableNumberToID[num_id] = nil
		_NetworkableIDToNumber[id] = nil
	end
end)

function nw:AddDependency() end
nw.AddDepend = nw.AddDependency