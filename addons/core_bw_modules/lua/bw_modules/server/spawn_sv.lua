--
BaseWars.Spawn = BaseWars.Spawn or {}

function BaseWars.Spawn.UseAmmoDispensers(ply)
	local ammo = BaseWars.GetPurchased(ply, "bw_dispenser_ammo")
	if not ammo or not ammo[1] then return end

	local weps = ply:GetWeapons()
	local wantAmmo = {}
	local addedAmmo = {}

	for k,v in pairs(weps) do
		local typ = v:GetPrimaryAmmoType()
		if typ ~= -1 and not addedAmmo[typ] then
			wantAmmo[#wantAmmo + 1] = typ
		end
	end

	for k,v in pairs(ammo) do
		if not IsEntity(v) then continue end

		for charge=1, v:GetCharge() do
			local ammoInd = 1 + ((charge - 1) % #wantAmmo)
			local typ = wantAmmo[ammoInd]
			local ok = v:DoDispense(ply, typ)

			if not ok then wantAmmo[ammoInd] = nil end
		end
	end
end

hook.Add("SpawnpointUsed", "RS_UseDispensers", function(ply, sp)
	if sp:GetLevel() >= 2 then
		BaseWars.Spawn.UseAmmoDispensers(ply)
	end


end)