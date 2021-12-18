local ENTITY = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")

local bw = BaseWars.Bases
local nw = bw.NW

local lp

function PLAYER:BW_GetBase()
	lp = lp or LocalPlayerG
	if not lp then return end

	if self ~= LocalPlayerG then
		errorf("You can only get base of LocalPlayer! (tried to get %s's base)", self)
		return
	end

	local nw = nw.PlayerData
	if not nw then return end --???

	return bw.GetBaseNumber( nw:Get("CurrentBase") )
end

function PLAYER:BW_GetZone()
	if not lp then return end

	if self ~= LocalPlayerG then
		errorf("You can only get zone of LocalPlayer! (tried to get %s's zone)", self)
		return
	end

	local nw = nw.PlayerData
	if not nw then return end --???

	return bw.GetZone( nw:Get("CurrentZone") )
end

function ENTITY:BW_GetBase()
	return BaseWars.Bases.EntIDToBase[self:EntIndex()]
end