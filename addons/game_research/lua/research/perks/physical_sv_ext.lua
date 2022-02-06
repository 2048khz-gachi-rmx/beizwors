--

local hp = Research.GetPerk("hp")

hook.Add("PlayerLoadout", "PhysPerks", function(ply)
	local perks = ply:GetResearchedPerks()

	if perks.hp then
		ply:SetMaxHealth(ply:GetMaxHealth() + hp:GetLevel(perks.hp).TotalHP)
		ply:AddHealth( hp:GetLevel(perks.hp).TotalHP )
	end
end)