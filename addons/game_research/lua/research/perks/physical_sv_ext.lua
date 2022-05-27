--

local hp = Research.GetPerk("hp")

function Research.ApplyPhysPerks(ply)
	if ply:GetDeathVar("PhysPerksApplied") then return end
	ply:SetDeathVar("PhysPerksApplied", true)

	local perks = ply:GetResearchedPerks()

	if perks.hp then
		ply:SetMaxHealth(ply:GetMaxHealth() + hp:GetLevel(perks.hp).TotalHP)
		ply:AddHealth( hp:GetLevel(perks.hp).TotalHP )
		ply:SetDeathVar("ResearchHPApply", hp:GetLevel(perks.hp).TotalHP)
	end
end

function Research.ApplyNewPhysPerk(pin, perk, lv)
	if lv.TotalHP then
		local ply = pin:GetPlayer()
		if ply then
			local ap = ply:GetDeathVar("ResearchHPApply", 0)
			ply:SetDeathVar("ResearchHPApply", lv.TotalHP)
			ply:SetMaxHealth(ply:GetMaxHealth() - ap + lv.TotalHP)
			ply:AddHealth(-ap + lv.TotalHP)
		end
	end
end

hook.Add("PlayerLoadout", "PhysPerks", Research.ApplyPhysPerks)
hook.Add("Reserach_PerksFetched", "Physperks", Research.ApplyPhysPerks)
hook.Add("PlayerResearched", "Physperks", Research.ApplyNewPhysPerk)