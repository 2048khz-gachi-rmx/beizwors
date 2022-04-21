local bw = BaseWars.Bases

local zNW = bw.NW.Zones
local bNW = bw.NW.Bases

local nw = bw.NW

LibItUp.OnInitEntity(function()
	nw.PlayerData = nw.PlayerData or Networkable("bw_bases_player" .. LocalPlayer():SteamID64())
	nw.PlayerData:Alias("CurrentZone", 1)
	nw.PlayerData:Alias("CurrentBase", 2)
end)

--[[-------------------------------------------------------------------------
	Networkable decoders
---------------------------------------------------------------------------]]

hook.Add("NetworkableInvalidate", "BW_Bases", function(sid, nw)
	if nw == bw.NW.Zones or nw == bw.NW.Bases then
		table.Empty(nw:GetNetworked())

		if nw == bw.NW.Zones then
			table.Empty(bw.Zones)
		else
			table.Empty(bw.Bases)
		end

		return false
	end
end)

zNW:On("ReadChangeValue", "DecodeZones", function(self, zID)

	local yiss = net.ReadBool()

	if not yiss then
		local z = bw.Zones[zID]
		if z then z:Remove() end
		return nil, true
	end

	self.Networked.Zones = self.Networked.Zones or {}

	local mins, maxs = net.ReadVector(), net.ReadVector()
	local name = net.ReadCompressedString(bw.MaxZoneNameLength)

	local zone = bw.GetZone(zID) or bw.Zone(zID, mins, maxs) -- don't recreate a zone if we knew about it; just update it instead
	self.Networked.Zones[zID] = zone

	zone:SetName(name)
	zone:SetBounds(mins, maxs)

	return zone
end)

zNW:On("NetworkedChanged", "DecodedAll", function(self)
	zNW:Emit("ReadZones", self.Networked.Zones)
	bw:Emit("ReadZones")
end)

bNW:On("ReadChangeValue", "DecodeBases", function(self, key)
	local yiss = net.ReadBool()

	if not yiss then
		local z = bw.Zones[key]
		if z then z:Remove() end
		return nil, true
	end

	local base = bw.GetBase(key) or bw.Base(key)

	base:ReadNetwork()

	return base
end)

bNW:On("NetworkedChanged", "DecodedAll", function(self)
	bw:Emit("ReadBases")
end)

hook.Add("NotifyShouldTransmit", "ReadyBase", function(e, add)
	if not add then return end
	if not bw.IsCore(e) then return end

	local ENT = scripted_ents.GetStored("bw_basecore").t
	local base = ENT.GetBase(e) -- fucking gmod is insane
	if not base then print(e, myBaseID, "didn't find base with that ID when entered PVS?") return end

	base:SetBaseCore(e)
	base:_Ready()
end)

function bw.Base:ReadNetwork()
	local name = net.ReadCompressedString(bw.MaxBaseNameLength)
	self:SetName(name)

	local amtZones = net.ReadUInt(8)

	for z=1, amtZones do
		local zID = net.ReadUInt(12)

		if not bw.Zones[zID] then

			local eid = ("wait:%d:%d"):format(self:GetID(), zID)
			bw.NW.Zones:On("ReadZones", eid, function(nw, zones)
				if zones[zID] then
					self:AddZone(zones[zID])
					bw.NW.Zones:RemoveListener("ReadZones", eid)
					self:_OnReady()
				end
			end)

		else
			self:AddZone(zID)
			self:_OnReady()
		end
	end

	local baseTier = net.ReadUInt(4)
	print("ai tier", baseTier)

	self.Data.AIBaseTier = baseTier > 0 and baseTier
end