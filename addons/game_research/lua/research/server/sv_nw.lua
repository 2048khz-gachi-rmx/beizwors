--
local PIN = LibItUp.PlayerInfo



hook.Add("Research_PerksFetched", "Network", function(ply, perks)
	local nw = ply:GetPrivateNW()

	for k,v in pairs(nw:GetNetworked()) do
		if isstring(k) and k:match("^rs_") then
			nw:Set(k, nil)
		end
	end

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