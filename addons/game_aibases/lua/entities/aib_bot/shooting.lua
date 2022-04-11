--

function ENT:Give(class)
	if not weapons.GetStored(class) then errorNHf("tried to give non-gun %s", class) return end

	local wep = ents.Create(class)
	if IsValid(wep) then
		self:SetupWeapon(wep)
		wep:Spawn()
	end

	return wep
end

function ENT:SetupWeapon(wep)
	wep:SetPos(self:GetPos())
	wep:SetAngles(self:GetAngles())

	wep:SetOwner(self)
	wep:SetParent(self)
	wep:SetTransmitWithParent(true)

	wep:SetMoveType(MOVETYPE_NONE)
	wep:AddEffects(EF_BONEMERGE)
	wep:RemoveSolidFlags(FSOLID_TRIGGER)
	wep:RemoveEffects(EF_ITEM_BLINK) -- tha fuck is this valve
	wep:AddEFlags(EFL_USE_PARTITION_WHEN_NOT_SOLID)

	wep:PhysicsDestroy() -- fuck you
	wep.UsedByAI = self

	self:SetCurrentWeapon(wep)
end

hook.Add("PlayerCanPickupWeapon", "StopStealing", function(ply, wep)
	if IsValid(wep.UsedByAI) then
		return false
	end
end)

function ENT:DoShootBehavior()
	local wep = self:GetCurrentWeapon()
	if not IsValid(wep) then return end

	if not self:GetEnemy() then return end

	if not wep.CW20Weapon then
		print("Non-CW gun in hands. Fuck you")
		return
	end

	wep:Think()
	if self.TargetAligned or self.TrackingEnemy then
		if not self.TargetAligned then
			print("knowing miss")
		end
		self:DoShoot(wep)
	end
end

function ENT:GetAmmoCount()
	return 999
end

function ENT:RemoveAmmo() end

function ENT:KeyDown(key)
	if key == IN_ATTACK then
		return self.TargetAligned and self:GetEnemy()
	end

	print("Attempted to check KeyDown:", key)
	print(debug.traceback())

	return false
end

function ENT:KeyPressed(key)
	if key == IN_ATTACK then
		return self.TargetAligned and self:GetEnemy()
	end

	print("Attempted to check KeyDown:", key)
	print(debug.traceback())

	return false
end

function ENT:DoShoot(wep)
	local nextPrim = wep:GetNextPrimaryFire()
	if CurTime() < nextPrim then return end

	--do return end

	local mag = wep:Clip1()
	if mag == 0 then
		wep:Reload()
		return
	end

	wep:PrimaryAttack()
end

-- TODO: increased acc with cw
function ENT:Crouching()
	return false
end

