local PLAYER = debug.getregistry().Player

local PInfo = LibItUp.PlayerInfo
BaseWars.Prestige = BaseWars.Prestige or {}
BaseWars.Prestige.NWKey = "Prestige"

local MODULE = BaseWars.Prestige

MODULE.Log = Logger("BW-Prestige", Color(0, 230, 250))
MODULE.Functions = {}

function PInfo:GetPrestige()
	if SERVER then
		return self._prestige
	else
		return self:GetPublicNW():Get(BaseWars.Prestige.NWKey, 0)
	end
end

function PLAYER:GetPrestige()
	return GetPlayerInfoGuarantee(self):GetPrestige()
end