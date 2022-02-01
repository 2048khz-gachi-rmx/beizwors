--
local PIN = LibItUp.PlayerInfo



hook.Add("Reserach_PerksFetched", "Network", function(ply, perks)
	local nw = ply:GetPrivateNW()

	for perk, lv in pairs(perks) do
		nw:Set("rs_" .. perk, lv)
	end
end)

hook.Add("PlayerResearched", "Network", function(pin, perk, lv)
	local nw = pin:GetPrivateNW()
	nw:Set("rs_" .. lv:GetPerk():GetID(), lv:GetLevel())
end)


function PIN:GetResearchedPerks()
	self._perks = self._perks or {}
	return self._perks
end

function PIN:SetResearchedPerks(t)
	self._perks = t
	return self
end

PInfoAccessor("ResearchedPerks")