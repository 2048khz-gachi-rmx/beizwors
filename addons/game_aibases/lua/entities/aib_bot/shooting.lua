--

function ENT:Give(class)
	if not weapons.GetStored(class) then errorNHf("tried to give non-gun %s", class) return end

	local wep = ents.Create(class)
	if IsValid(wep) then
		self:SetupWeapon(wep)
	end

	return wep
end

function ENT:SetupWeapon(wep)

	local att = self:LookupAttachment("anim_attachment_RH")

	--wep:SetMoveType(MOVETYPE_NONE)


	wep:SetTransmitWithParent(true)

	wep.UsedByAI = self

	wep:Spawn()

	--wep:RemoveSolidFlags(FSOLID_TRIGGER)
	--wep:RemoveEffects(EF_ITEM_BLINK) -- tha fuck is this valve
	--wep:AddEFlags(EFL_USE_PARTITION_WHEN_NOT_SOLID)
	wep:SetOwner(self)

	wep:SetParent(self)

	wep:SetLocalPos(vector_origin)
	wep:SetLocalAngles(angle_zero)

	wep:SetMoveType(MOVETYPE_NONE)
	wep:PhysicsDestroy()
	wep:AddEffects(EF_BONEMERGE)

	wep:DrawShadow(false)

	self:SetCurrentWeapon(wep)
end

hook.Add("PlayerCanPickupWeapon", "StopStealing", function(ply, wep)
	if IsValid(wep.UsedByAI) then
		return false
	end
end)

ENT.InaccuracyFrom = 6
ENT.InaccuracyTo = 1
ENT.InaccuracyTime = 2
ENT.InaccuracyStartLosing = 2

hook.Add("CW2_ConeModifiers", "AIInacc", function(wep, spr)
	local ow = wep:GetOwner()
	if not ow.IsAIBaseBot or not ow:GetEnemy() then return end

	local t = ow:GetAccuracyLength()
	local fr = math.RemapClamp(t, 0, ow.InaccuracyTime, 0, 1)

	spr[1] = Lerp(fr, ow.InaccuracyFrom, ow.InaccuracyTo)
	spr[2] = spr[1]
	spr[3] = spr[1]
end)

hook.Add("AIB_LOSChanged", "AIInacc", function(bot, new)
	local max = bot.InaccuracyTime
	local len = bot.LOSLastChange or CurTime()

	if new then
		local lostFor = math.max(0, CurTime() - len - bot.InaccuracyStartLosing)

		bot.accumAccuracy = math.max(0, (bot.accumAccuracy or 0) - lostFor)
		bot.lostTime = CurTime()
	else
		-- lost; track how long we kept them in sights
		local acqFor = CurTime() - len
		bot.accumAccuracy = math.min(max, (bot.accumAccuracy or 0) + acqFor)
		bot.acqTime = CurTime()
	end
end)

function ENT:GetAccuracyLength()
	local trk, time, prev = self:CanSeeTarget()
	if trk then
		local acqFor = CurTime() - (self.lostTime or CurTime())
		return math.min(self.InaccuracyTime, (self.accumAccuracy or 0) + acqFor)
	else
		local lostFor = CurTime() - (self.acqTime or CurTime())
		return math.min(self.InaccuracyTime, (self.accumAccuracy or 0) + lostFor)
	end
end


function ENT:CanShoot()
	local wep = self:GetCurrentWeapon()

	local can_atk = wep:GetNextPrimaryFire() < CurTime()
	if not can_atk then return false end

	return true
end

function ENT:DoReload()
	if self:HasActivity("Reload") then
		errorNHf("trying to reload twice")
		return
	end

	self:AddActivity("Reload", "Reloading")
	self:AddCoro("Reload", function()
		self:AddActivity("Reload", "Reloading")
		self:WaitForReload()

		self:AddActivity("Reload", nil)
	end)
end

function ENT:RequestReload(now)
	if self:HasActivity("Reload") then return end

	if not now and not self:HasActivity("Reload") then
		local pr = self:TakeCover()
		if not pr then return end

		self:AddActivity("Covering", "Reload")

		-- if we dont see the target in cover for 2s, do reload
		local can, time = self:CanSeeTarget()
		while can or time < 2 do
			coroutine.yield()
			can, time = self:CanSeeTarget()
		end

		pr:Then(function()
			if not self:HasActivity("Reload") then
				self:DoReload()
			end
		end, function()
			self:AddActivity("Reload", nil)
		end)
		return
	end

	--for _, spot in pairs(spots) do
		-- debugoverlay.Line(self:GetShootPos(), spot, 0.05, color_white, true)
	--end

	self:DoReload()
end

function ENT:WaitForReload()
	assert(coroutine.running())

	local wep = self:GetCurrentWeapon()
	wep:Reload()
	self:AddGesture(ACT_HL2MP_GESTURE_RELOAD_AR2)

	while
		(wep.CW20Weapon and wep.ReloadDelay and wep.ReloadDelay > CurTime()) or
		(wep.ArcCW and wep:GetReloading()) do

		coroutine.yield()
	end
end

ENT.LockedShootTime = 0.3
ENT.LockedRequiredLostDelay = 2.2

function ENT:DoShootThink()
	local wep = self:GetCurrentWeapon()
	if not IsValid(wep) then return false end

	--[[if not wep.CW20Weapon then
		return
	end]]

	wep:Think()

	if not self:GetEnemy() then return end
	if not self:CanShoot() then return end

	local trk, time, prev = self:GetTrackedEnemy()
	local fr = math.RemapClamp(prev, 0, self.LockedRequiredLostDelay, 0, 1)

	if trk and (time > self.LockedShootTime * fr) then
		local can = self:CanSeeTarget()
		if not can then return end

		self:DoShoot()
	end
end

local trOut = {}
local trIn = {output = trOut}

function ENT:GetEyeTrace()
	trIn.start = self:GetShootPos()
	trIn.endpos = self:GetAimAngle():Forward()
		:CMul(32768)
		:CAdd(trIn.start)

	return util.TraceLine(trIn)
end

function ENT:GetAimVector()
	return self:GetAimAngle():Forward()
end

function ENT:GetAmmoCount()
	return 999
end

function ENT:SetAmmo() end
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

function ENT:DoShoot()
	local wep = self:GetCurrentWeapon()

	local nextPrim = wep:GetNextPrimaryFire()
	if CurTime() < nextPrim then return end

	local mag = wep:Clip1()

	if mag == 0 then
		self:RequestReload(true)
		return
	end
	--do return end

	wep:PrimaryAttack()
end

-- TODO: increased acc
function ENT:Crouching()
	return false
end

function ENT:IsScoped()
	return false
end

hook.Add("ScalePlayerDamage", "AIBDamage", function(ply, hg, dmg)
	local atk = dmg:GetAttacker()
	if not atk.IsAIBaseBot then return end

	local mult = atk.DamageMult or 0.4
	dmg:ScaleDamage(mult)
end)