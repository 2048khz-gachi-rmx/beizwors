
util.AddNetworkString("BW_OwnershipChange")
util.AddNetworkString("BW_OwnershipChange_Mass")

local trackEnt
local bwe = BaseWars.Ents
	bwe.EntsArr = bwe.EntsArr or ValidSeqIterable() 	-- sequential table of all basewars entities
	bwe.EntsOwners = bwe.EntsOwners or {}				-- table of [sid64] = {ValidSeqIter}

hook.Add("CPPIAssignOwnership", "BWTrackOwner", function(ply, ent)
	if not ply:IsValid() then return end
	if ent.CPPI_OwnerSID == ply:SteamID() then return end

	local old = ent.CPPI_OwnerSID
	local id = ply:SteamID()
	ent.CPPI_OwnerSID = id

	trackEnt(ent, id)

	bwe.EntsArr:addExclusive(ent)

	net.Start("BW_OwnershipChange")
		net.WriteBoool(true)
		net.WriteUInt(ent:EntIndex(), 15)
		net.WriteSteamID(ply:SteamID())
	net.Broadcast()

	-- run a new hook because, again, fpp sucks
	hook.Run("EntityOwnershipChanged", ply, ent, old)
end)

function BaseWars.Ents.NetworkAll(ply)
	local props = {}
	local sids = {}

	for k,v in ipairs(ents.GetAll()) do
		local ow, id = v:CPPIGetOwner()
		if not id then continue end

		props[#props + 1] = v
		sids[id] = sids[id] or {}
		table.insert(sids[id], v)
	end


	net.Start("BW_OwnershipChange_Mass")

		local count = table.Count(sids)
		net.WriteUInt(count, 16)

		for k,v in pairs(sids) do
			net.WriteSteamID(k)
			net.WriteUInt(#v, 16)

			for _, ent in ipairs(v) do
				net.WriteUInt(ent:EntIndex(), 16)
			end
		end

	net.Send(ply)
end

hook.Add("PlayerFullyLoaded", "BW_NetworkOwnership", function(ply)
	BaseWars.Ents.NetworkAll(ply)
end)

local function getEntry(sid)
	if IsPlayer(sid) then
		sid = sid:SteamID()
	end

	local t = bwe.EntsOwners[sid]
	if t then
		t:clean()
		return t
	else
		t = ValidSeqIterable()
		bwe.EntsOwners[sid] = t
		return t
	end
end

local function untrackEnt(ent, owID)
	local entry = getEntry(owID)
	entry:remove(ent)
	bwe.EntsArr:remove(ent)
end

function trackEnt(ent, owID)
	local entry = getEntry(owID)
	entry:addExclusive(ent) -- just in case :ok_hand:
	bwe.EntsArr:addExclusive(ent)
end

function BaseWars.Ents.GetAll()
	-- return a copy
	local ret = {}
	for k,v in bwe.EntsArr:iter() do
		ret[k] = v
	end

	return ret
end

function BaseWars.Ents.GetOwnedBy(who)
	local pin = GetPlayerInfoGuarantee(who)
	local sid = pin:SteamID()

	if not sid then
		error("bad argument #1 to BaseWars.Ents.GetOwnedBy (steamid/steamid64/player expected," ..
				"got `" .. type(who) .. "` (" .. tostring(who) .. ")")
		return
	end

	local ret = {}
	for k,v in getEntry(sid):iter() do
		ret[k] = v
	end

	return ret
end


hook.NHAdd("EntityActuallyRemoved", "BWUntrackOwner", function(ent, entTable)
	local owID = ent.FPPOwnerID -- fpp exclusive
	if not owID then return end -- dafuq

	untrackEnt(ent, owID)

	net.Start("BW_OwnershipChange")
		net.WriteBoool(false)
		net.WriteUInt(ent:EntIndex(), 15)
	net.Broadcast()
end)