setfenv(1, _G)

local eidToOwner = BaseWars.Ents.EIDToOwner or {}
BaseWars.Ents.EIDToOwner = eidToOwner

local prs = BaseWars.Ents.Promises or {}
BaseWars.Ents.Promises = prs

function BaseWars.Ents.AssignOwner(eid, sid)
	if IsEntity(eid) then eid = eid:EntIndex() end
	if IsPlayer(sid) then sid = sid:SteamID() end

	--print("recv assignowner", eid, sid)

	assert(isnumber(eid))
	assert(isstring(sid))

	eidToOwner[eid] = sid

	prs[eid] = EventualEntity(eid):Then(function(self)
		--[[print("eventual recv", eid, Entity(eid), self.nvm,
			player.GetBySteamID(sid), Entity(eid), sid)]]
		if self.nvm then return end -- ???

		hook.Run("EntityOwnershipChanged",
			player.GetBySteamID(sid), Entity(eid), sid)
	end)
end

function BaseWars.Ents.UnassignOwner(eid)
	if IsEntity(eid) then eid = eid:EntIndex() end
	assert(isnumber(eid))

	eidToOwner[eid] = nil

	if prs[eid] then
		-- dont run the hook anymore if it didnt run yet
		prs[eid].nvm = true
	end
end

function BaseWars.Ents.EntityToSteamID(eid)
	if IsEntity(eid) then
		eid = eid:EntIndex()
	end
	assert(isnumber(eid))

	return eidToOwner[eid]
end

hook.Add("EntityActuallyRemoved", "BW_OwnershipYeet", function(ent, tbl, eid)
	if eid == -1 then return end
	BaseWars.Ents.UnassignOwner(eid)
end)

net.Receive("BW_OwnershipChange", function()
	local add = net.ReadBool()
	local eid = net.ReadUInt(15)
	if not add then
		BaseWars.Ents.UnassignOwner(eid)
		return
	end

	local sid = net.ReadSteamID()
	BaseWars.Ents.AssignOwner(eid, sid)
end)

net.Receive("BW_OwnershipChange_Mass", function()
	local sids = net.ReadUInt(16)

	for i=1, sids do
		local sid = net.ReadSteamID()
		local entCnt = net.ReadUInt(16)
		for e = 1, entCnt do
			local eid = net.ReadUInt(16)
			BaseWars.Ents.AssignOwner(eid, sid)
		end
	end
end)