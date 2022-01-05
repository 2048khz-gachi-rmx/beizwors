if CLIENT then
	hook.Add("HUDShouldDraw", "NoRed", function(h)
		if h == "CHudDamageIndicator" then return false end
	end)
end

hook.Add("EntityTakeDamage", "NoViewpunch", function(ent, dmg)
	if not ent:IsPlayer() then return end

	ent._preVP = ent:GetViewPunchAngles()
	ent._preVPV = ent:GetViewPunchVelocity()
end)

hook.Add("PostEntityTakeDamage", "NoViewpunch", function(ent, dmg)
	if not ent:IsPlayer() then return end
	if not ent._preVP then return end

	ent:SetViewPunchAngles(ent._preVP)
	ent:SetViewPunchVelocity(ent._preVPV)

	ent._preVP = nil
	ent._preVPV = nil
end)

hook.Add("PlayerSpawn", "NoForce", function(ply)
	ply:AddEFlags(EFL_NO_DAMAGE_FORCES)
	ply:Timer("EForce", 1, 1, function()
		ply:AddEFlags(EFL_NO_DAMAGE_FORCES)
	end)
end)