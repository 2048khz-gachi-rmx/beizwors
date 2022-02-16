--

local hp = Research.GetPerk("hp")

function Research.ApplyPhysPerks(ply)
	if ply:GetDeathVar("PhysPerksApplied") then return end
	ply:SetDeathVar("PhysPerksApplied", true)

	local perks = ply:GetResearchedPerks()

	if perks.hp then
		ply:SetMaxHealth(ply:GetMaxHealth() + hp:GetLevel(perks.hp).TotalHP)
		ply:AddHealth( hp:GetLevel(perks.hp).TotalHP )
	end

end

hook.Add("PlayerLoadout", "PhysPerks", Research.ApplyPhysPerks)
hook.Add("Reserach_PerksFetched", "Physperks", Research.ApplyPhysPerks)