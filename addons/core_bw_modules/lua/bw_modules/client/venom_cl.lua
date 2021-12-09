hook.Add("CanForceStimpak", "Venom", function(ply)
	if ply:GetNWInt("Venom", 0) > 0 then return true end
end)