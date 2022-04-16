util.AddNetworkString("BWBases")

local bw = BaseWars.Bases
local nw = bw.NW

local zNW = bw.NW.Zones
local bNW = bw.NW.Bases

zNW:On("WriteChangeValue", "EncodeZones", function(self, key, zone, plys)

	if bw.IsZone(zone) then
		net.WriteBool(true)
		local mins, maxs = zone:GetBounds()
		net.WriteVector(mins)
		net.WriteVector(maxs)
		net.WriteCompressedString(zone:GetName(), bw.MaxZoneNameLength)
	else
		net.WriteBool(false)
	end

	return false
end)

bNW:On("WriteChangeValue", "EncodeZones", function(self, key, base, plys) -- changes, ...)

	if bw.IsBase(base) then
		net.WriteBool(true)

		net.WriteCompressedString(base:GetName(), bw.MaxBaseNameLength + 1)
		net.WriteUInt(#base:GetZones(), 8)

		for k,v in ipairs(base:GetZones()) do
			net.WriteUInt(v:GetID(), 12)
		end
		net.WriteUInt(self:GetData().AIBaseTier or 0, 4)
	else
		net.WriteBool(false)
	end

	return false
end)

function bw.Base:UpdateNW()
	local plys, nws = {}, {self.OwnerNW, self.EntsNW}
	local _, infos = self:GetOwner()

	for k,v in ipairs(infos) do
		local ply = v:GetPlayer()
		if ply then plys[#plys + 1] = ply end
	end

	-- do a full update to keep new players up to speed on the current values
	for k,v in ipairs(nws) do
		v:Network(true)
	end

	self:GetPowerGrid():UpdateNW(plys)
end

-- adding to NW will proc a networkable update automatically

function bw.Base:AddToNW()
	bw.NW.Bases:Set(self:GetID(), self)
end

function bw.Zone:AddToNW()
	bw.NW.Zones:Set(self:GetID(), self)
end

-- TODO: this doesnt get invalidated
local function initNW(ply)
	if bw.NW.PlayerData[ply] then return end

	bw.NW.PlayerData[ply] = Networkable("bw_bases_player" .. ply:SteamID64())
	local nw = bw.NW.PlayerData[ply]
	nw:Alias("CurrentZone", 1)
	nw:Alias("CurrentBase", 2)
	nw:AddDependency(bw.NW.Bases)
	nw:AddDependency(bw.NW.Zones)
	nw.Filter = function(self, p2)
		return ply == p2
	end
end

hook.NHAdd("PlayerDisconnected", "BasesPlayerNWYeet", function(ply)
	if bw.NW.PlayerData[ply] then
		bw.NW.PlayerData[ply]:Invalidate()
		bw.NW.PlayerData[ply] = nil
	end
end)

nw.InitPlayerNW = initNW

function bw.GetPlayerNW(ply)
	local nw = bw.NW.PlayerData[ply]
	if not nw or not nw:IsValid() then initNW(ply) end
	return bw.NW.PlayerData[ply]
end

hook.NHAdd("PlayerInitialSpawn", "InitBaseNWPlayerData", function(ply)
	initNW(GetPlayerInfoGuarantee(ply))
end)

for k,v in ipairs(player.GetAll()) do
	initNW(v)
end