hook.Add("BaseWars_PlayerEmptyPrinter", "XPRewards", function(ply, ent, money)
	--[[if ent:GetClass() == "bw_printer_manual" then
		ply:AwardEXPForMoney(money * 2, true)
	else
		ply:AwardEXPForMoney(money)
	end]]
end)


Basewars.GenEntsOwners = Basewars.GenEntsOwners or {}

hook.NHAdd("EntityOwnershipChanged", "BW_GenLimit", function(ply, ent, oldID)
	if not ent.Bought or not ent.IsGenerator then return end

	local old = oldID and GetPlayerInfo(oldID)
	local new = ent:BW_GetOwner()

	if old then
		old._Gens = (old._Gens or 1) - 1
	end

	if new then
		new._Gens = (new._Gens or 0) + 1
	end

	ent._genHooked = new
end)

hook.NHAdd("EntityRemoved", "BW_GenLimit", function(ent)
	if not ent._genHooked then return end
	local pin = ent._genHooked
	pin._Gens = pin._Gens - 1
end)


Basewars.GeneratorsAllowed = 4

hook.Add("BaseWars_PlayerCanBuyEntity", "Gennies", function(ply, ent)
	if scripted_ents.IsBasedOn(ent, "bw_base_generator") then
		local gens = GetPlayerInfo(ply)._Gens
		if gens and gens >= Basewars.GeneratorsAllowed then
			return false, "You can't have more than " .. Basewars.GeneratorsAllowed .. " generators active!"
		end
	end
end)

hook.Add("CPPIAssignedOwnership", "UpdateSID64", function(ply, ent)
	if IsPlayer(ply) then
		ent.FPPSteamID64 = ply:SteamID64()
	end
end)

hook.Add("BaseWars_PlayerBuyEntity", "Gennies", function(ply, ent)
	local sid64 = ply:SteamID64()

	if ent.IsGenerator then

		ent:CallOnRemove("dec_gen_limit", function()
			BaseWars.Generators[sid64] = (BaseWars.Generators[sid64] or 1) - 1
		end)

	end

end)