--

hook.Add("Reserach_PerksFetched", "Network", function(ply, perks)
	local nw = ply:GetPrivateNW()

	for perk, _ in pairs(perks) do
		nw:Set("rs_" .. perk, true)
	end
end)

hook.Add("PlayerResearched", "Network", function(ply, perk, lv)
	local nw = ply:GetPrivateNW()
	nw:Set("rs_" .. lv:GetPerk():GetID(), lv:GetLevel())
end)
