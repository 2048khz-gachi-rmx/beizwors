do -- give weapon
	
	local prefixes = {
		"",
		"weapon_",
		"weapon_fwp_",
		"weapon_cs_",
		"tf_weapon_",
		"tfa_cso_",
		"cw_gau_",
		"cw_",
		"cw_g4p_",
	}

	local weapons_engine = {
		weapon_357 = true,
		weapon_ar2 = true,
		weapon_bugbait = true,
		weapon_crossbow = true,
		weapon_crowbar = true,
		weapon_frag = true,
		weapon_physcannon = true,
		weapon_pistol = true,
		weapon_rpg = true,
		weapon_shotgun = true,
		weapon_slam = true,
		weapon_smg1 = true,
		weapon_stunstick = true,
		weapon_physgun = true
	}

	aowl.AddCommand("give", function(ply, line, target, weapon, ammo1, ammo2)

		local ent = ((isstring(target) and isstring(weapon)) and easylua.FindEntity(target)) or ply

		if not isstring(weapon) and ent==ply then weapon = target end

		if not ent:IsPlayer() then return false, aowl.TargetNotFound(target) end

		if not isstring(weapon) or weapon == "#wep" then
			local wep = ply:GetActiveWeapon()
			if IsValid(wep) then
				weapon = wep:GetClass()
			else
				return false,"Invalid weapon"
			end
		end

		ammo1 = tonumber(ammo1) or 0
		ammo2 = tonumber(ammo2) or 0
		for _,prefix in ipairs(prefixes) do
			local class = prefix .. weapon
			if weapons.GetStored(class) == nil and not weapons_engine[class] then continue end
			if ent:HasWeapon(class) then ent:StripWeapon(class) end
			local wep = ent:Give(class)
			if IsValid(wep) then
				wep.Owner = wep.Owner or ent
				ent:SelectWeapon(class)
				if wep.GetPrimaryAmmoType then
					ent:GiveAmmo(ammo1,wep:GetPrimaryAmmoType())
				end
				if wep.GetSecondaryAmmoType then
					ent:GiveAmmo(ammo2,wep:GetSecondaryAmmoType())
				end
				return
			end
	end
	local matches = {}

	    for k, v in pairs(weapons.GetList()) do
	        if string.find(string.lower(v.PrintName or ""), string.lower(weapon)) or string.find(string.lower(v.ClassName or ""), string.lower(weapon)) then
	            matches[#matches+1] = v.ClassName or ""
	        end
        end
    local errtxt = "Multiple matches found: "

	    if #matches>=1 then 
	        ent:Give(matches[1])
	        ply:ChatPrint('Giving ' .. matches[1] .. ' to ' .. ent:Nick())
	        return true
	    end

		return false, "Couldn't find " .. weapon
	end, "superadmin")
end

aowl.AddCommand("ammo", function(ply, line,ammo,ammotype)
	if !ply:Alive() and !IsValid(ply:GetActiveWeapon()) then return end
	local amt = tonumber(ammo) or 500
	local wep = ply:GetActiveWeapon()
	if not ammotype or ammotype:len() <= 0 then
		if wep.GetPrimaryAmmoType and wep:GetPrimaryAmmoType() != none then
			ply:GiveAmmo(amt,wep:GetPrimaryAmmoType())
		end
	else
		ply:GiveAmmo(amt,ammotype)
	end
end, "admin")