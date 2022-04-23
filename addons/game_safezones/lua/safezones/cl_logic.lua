--

function Safezones.IsIn(ent)
	return ent:GetNWBool("InSafezone", false)
end

function Safezones.IsLingering(ent)
	local till = ent:GetNWFloat("LingerStart", 0)
	local ct = CurTime()

	return ct - till < Safezones.ProtectionLinger, Safezones.ProtectionLinger - (ct - till)
end

function Safezones.TimeSinceIn(ent)
	if not Safezones.IsIn(ent) then return 0, 0 end

	local ct = CurTime()
	return ct - ent:GetNWFloat("Safezone", ct)
end