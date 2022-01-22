SWEP.Author			= "grmx"
SWEP.Contact			= ""
SWEP.Purpose			= ""


SWEP.Spawnable			= true

SWEP.ViewModel			= "models/weapons/c_pistol.mdl"
SWEP.WorldModel		= "models/weapons/w_pistol.mdl"
SWEP.DrawAmmo = false
SWEP.UseHands = true

SWEP.IsDash = true
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""

local dashDur = 0.3
SWEP.DashTime = dashDur

function SWEP:SetupDataTables()

	self:NetworkVar("Int", 0, "DashCharges")

	self:NetworkVar("Bool", 0, "Dashing")
	self:NetworkVar("Bool", 1, "SuperMoving")
	self:NetworkVar("Bool", 2, "PostSuperMove")
	self:NetworkVar("Bool", 3, "PostDash")

	self:NetworkVar("Float", 0, "DashEndTime")

	self:NetworkVar("Float", 1, "DashCooldown")
	self:NetworkVar("Float", 2, "DashCooldownEnd")
end


--[[function SWEP:GetDashCooldownEnd()
	local ret, when = self.PredNW:Get("DashCooldownEnd")
	return ret or 0, when or 0
end

function SWEP:SetDashCooldownEnd(v)
	return self.PredNW:Set("DashCooldownEnd", v)
end


function SWEP:GetDashCooldown()
	local ret, when = self.PredNW:Get("DashCooldown")
	return ret or 0, when or 0
end

function SWEP:SetDashCooldown(v)
	return self.PredNW:Set("DashCooldown", v)
end]]

DashTable = DashTable or {}

function SWEP:Initialize()
	if CLIENT then
		hdl.DownloadFile("http://vaati.net/Gachi/shared/whoosh.ogg", "whoosh.dat")
		self:SetPredictable(true)
		self.Dashed = false
	end

	self.CooldownEndsWhen = 0	-- for the HUD; don't use for pred!
	self.CooldownDuration = 0	-- since the HUD hooks can't wind CurTime() forward, we hafta track these separately
								-- as unpredicted curtimes

	--[[self.PredNW = PredNetworkable()

	self.PredNW:Alias("DashCooldownEnd", 0)
	self.PredNW:Alias("DashCooldown", 1)


	self.PredNW:SetNetworkableID("Dash" .. self:EntIndex())

	self.PredNW:Bind(self)
	self.PredNW.Filter = function(nw, p)
        return p == self:GetOwner()
    end]]
end

hook.Add("GetFallDamage", "DashFall", function(ply)
	if ply:GetActiveWeapon():GetClass() == "dash" then
		return 0
	end
end)

function SWEP:RechargeLogic(ply, force)
	local dashing = (SERVER and DashTable[ply]) or (CLIENT and self:GetDashing())

	if (ply:IsOnGround() or ply:WaterLevel() >= 2) and
		self:GetDashCharges() ~= 1 and not dashing then
		self:SetPostDash(false)

		if self:GetDashCooldown() > 0 and self:GetDashCooldownEnd() == 0 then
			self:SetDashCooldownEnd(CurTime() + self:GetDashCooldown())

			if IsFirstTimePredicted() then
				self.CooldownDuration = self:GetDashCooldown()
				self.CooldownEndsWhen = UnPredictedCurTime() + self:GetDashCooldown()
				clprintf("FirstPred - unpred: %.2f, pred: %.2f", UnPredictedCurTime(), CurTime())
			end

		end

		if self:GetDashCooldownEnd() > CurTime() then return end


		self:SetDashCooldownEnd(0)

		self:SetDashCooldown(0)

		self.CooldownDuration = 0
		self.CooldownEndsWhen = 0

		self:SetDashCharges(1)
		if CLIENT then
			self.Dashed = false
			self:CL_OnRecharge()
		end
	end

end

function SWEP:Think()
	self:RechargeLogic(self:GetOwner())
end

hook.Add("OnPlayerHitGround", "RechargeDash", function(ply, water, floater, speed)
	local dash = ply:GetWeapon("dash")
	if not dash or not dash:IsValid() or not dash.IsDash then return end

	dash:RechargeLogic(ply)
	local nxt = dash:GetDashCooldown()
end)

local OverrideDashEnd

function SWEP:CheckMoves(owner, mv, dir)

	local dt = DashTable[owner]
	if not dt then return end --ok?

	local jumping = mv:KeyDown(IN_JUMP) -- or dt.Jumped
	local ducked = 	mv:KeyDown(IN_DUCK)  -- or dt.Ducked

	--if not IsFirstTimePredicted() and self.SuperMovingVelocity then self:StopDash() return end

	if not self:GetDashing() then return end

	if not jumping or OverrideDashEnd then return end

	local pos = mv:GetOrigin()

	if dt.ground then

		if dt.jump or dt.down then return end

		local tr = util.TraceHull({
			start = pos + Vector(0, 0, 8),
			endpos = pos - Vector(0, 0, 16),
			filter = owner,
			mins = Vector( -16, -16, -4 ),
			maxs = Vector( 16, 16, 4 ),
			mask = bit.bor(MASK_SOLID, MASK_WATER)
		})

		if tr.Hit then

			local vel

			self:SetDashCooldown(1.5)

			if IsFirstTimePredicted() then
				self.CooldownDuration = self:GetDashCooldown()
			end

			if ducked then

				vel = dir * 2350
				vel.z = 300
				self:SetDashCooldown(3)
			else
				vel = dir * 1500
				vel.z = 400
			end


			--self.SuperMoving = true

			

			if SERVER then
				self:StopDash()
				self:SetSuperMoving(true)
				self:SetPostSuperMove(true)
				self.SuperMovingVelocity = vel
				owner:GetCurrentCommand():RemoveKey(IN_JUMP)
				return
			else
				self:SetSuperMoving(true)
				self:SetPostSuperMove(true)
				self.SuperMovingVelocity = vel
				self:SetDashing(false)
				return
			end

		end

	else --Dash started in mid-air

		if dt.jump or not dt.down then return end --Player must've dashed without space and dashed downwards

		local tr = util.TraceHull({
			start = pos + Vector(0, 0, 12),
			endpos = pos - Vector(0, 0, 24),
			filter = owner,
			mins = Vector( -24, -24, -4 ),
			maxs = Vector( 24, 24, 8 ),
			mask = bit.bor(MASK_SOLID, MASK_WATER)
		})

		if tr.Hit then

			local vel

			local dir = Vector()
			dir:Set(dt.dir)
			dir.z = math.min(-dir.z, 0.9) -- dt.down implies dir.z is < -0.15
										  -- the lower dir.z was, the bigger the bounce

			local mul = 2000 * (1 - dir.z) -- and the bigger the bounce, the less velocity you have

			vel = dir * mul
			vel.z = math.max(vel.z * (dir.z > 0.6 and (0.77 / (1 - dir.z)) or 1), 400)

			if SERVER then
				self:StopDash()
				self:SetSuperMoving(true)
				self:SetPostSuperMove(true)
				self.SuperMovingVelocity = vel
				owner:GetCurrentCommand():RemoveKey(IN_JUMP)
				return
			else
				self:SetDashing(false)
				self:SetSuperMoving(true)
				self:SetPostSuperMove(true)
				self.SuperMovingVelocity = vel
				return
			end

		end

	end

end

function SWEP:PrimaryAttack()
	local owner = self:GetOwner()

	if self:GetDashCharges() <= 0 then return end

	if not IsFirstTimePredicted() then
		self:SetDashing(true)
		self:SetDashCharges(self:GetDashCharges() - 1)
		self:SetDashCooldown(1)

		return
	end

	self:SetDashCharges(self:GetDashCharges() - 1)

	

	if CLIENT then
		self.Dashed = true
		--self:EmitSound("dash/whoosh.ogg", 45)
		sound.PlayFile("data/hdl/whoosh.dat", "", function() end)
	end

	if SERVER then self:SetDashEndTime(CurTime() + self.DashTime) end

	self:SetDashing(true)
	self:SetPostDash(true)
	local dir = owner:EyeAngles():Forward()
	local z = dir.z

	self:SetDashCooldown(1)
	self.CooldownDuration = self:GetDashCooldown()

	if z > -0.15 and z < 0.20 then
		dir.z = 0.1
	end

	DashTable[owner] = {
		t = CurTime(),
		dir = dir,
		wep = self,
		ground = owner:IsOnGround() or owner:WaterLevel() >= 1,
	}

	local dt = DashTable[owner]

	dt.jump = owner:KeyDown(IN_JUMP)
	dt.down = dir.z < -0.15

	self:SetNextPrimaryFire(CurTime() + 0.4)
	if CLIENT then
		self:CL_OnDash()
	end
end

hook.Add("FinishMove", "Dash", function(ply, mv, cmd)
	local dash = ply:GetActiveWeapon()

	if not dash or not dash:IsValid() or not dash.IsDash then return end

	if dash.EndSuperMove and SERVER then
		if mv:GetVelocity():Length() < 600 or ply:IsOnGround() or ply:WaterLevel() >= 1 then
			dash:SetSuperMoving(false)
			dash:SetPostSuperMove(false)
			dash:SetPostDash(false)
			dash.EndSuperMove = nil
			dash.Dashed = false
		end
	end

	if not DashTable[ply] then return end

	if CLIENT and ply ~= LocalPlayer() then
		return
	end

	local t = DashTable[ply]

	local self = t.wep

	if not IsValid(self) then
		DashTable[ply] = nil
		return
	end

	local time = t.t

	local curt = CurTime()
	local d = t.dir

	local newvel = t.newvel or d * 800

	self:CheckMoves(ply, mv, d)

	if self:GetSuperMoving() then

		mv:SetMaxSpeed(10e9)
		mv:SetVelocity(self.SuperMovingVelocity)

		self:SetSuperMoving(false)
		return
	end

	local endtime = OverrideDashEnd or time + self.DashTime

	if curt > endtime and self:GetDashing() then

		if SERVER then
			self:StopDash()
		else
			self:SetDashing(false)
		end

	end

	if curt < endtime and self:GetDashing() then
		mv:SetVelocity(newvel)
	end

end)

local trails = {}

local st = 0
local two = math.pi/2
local fin = math.pi

local trail = Material("models/props_combine/stasisshield_sheet")
trail:SetFloat("$refractamount", 0.05)

trail:SetFloat("$alpha", 1)

hook.Add("PostPlayerDraw", "Dash", function(ply)
	local t = trails[ply]
	local dash = ply:GetActiveWeapon()
	local dasht = (IsValid(dash) and dash.IsDash and dash:GetTable())
	if not dasht then return end

	local dt = DashTable[ply]

	if dt then

		if not dt.wep:IsValid() or CurTime() - dt.t > dashDur then
			DashTable[ply] = nil
			dt = nil
		end

	end

	if ( dash:GetPostDash() or dash:GetPostSuperMove() ) or dt then
		local widmul = (dash:GetDashing() or dt) and 15 or 8

		local wid = math.min(ply:GetVelocity():Length() / 50, widmul)

		t = t or {}

		trails[ply] = t

		local pos = ply:GetPos()
		local cent = ply:OBBCenter()
		cent:Mul(1.5)
		pos:Add(cent)

		t[#t + 1] = {pos, CurTime(), wid}
	elseif t then
		if #t == 0 or CurTime() - t[#t][2] > 1 then trails[ply] = nil return end
	end

	if not t then return end


	render.StartBeam(#t)

		for i=1, #t do
			local time = (CurTime() - t[i][2])

			local one = Lerp(time, two, fin)
			local two = Lerp((time - 0.3)*2, fin, two)


			local sin = math.sin(two)
			local wid = math.abs(1 - sin) * t[i][3]

			render.SetMaterial(trail)

			render.AddBeam(t[i][1], wid, 1/i, Color(255, 255, 255))
		end

	render.EndBeam()

	for i=#t, 1, -1 do
		if t[i][3] < 0.5 then
			table.remove(t, i)
		end
	end

end)

function SWEP:Holster(wep)

	if wep.CW20Weapon then
		local oldMult = wep.DrawSpeedMult
		wep.DrawSpeedMult = wep.DrawSpeedMult * 3
		wep.GlobalDelay = 0
		wep:recalculateDeployTime()

		timer.Simple(0.2, function()
			if not IsValid(wep) then return end
			wep.DrawSpeedMult = wep.DrawSpeedMult / 3
			wep.GlobalDelay = 0
			wep:recalculateDeployTime()
		end)

	end

	return true
end

function SWEP:StopDash()
	local owner = self:GetOwner()

	self:SetDashing(false)
	self.Dashed = false

	self:SetDashEndTime(0)
	self:SetDashing(false)
	self:SetSuperMoving(false)
	self.SuperMovingVelocity = nil

	self.Moved = false
	self.EndSuperMove = true
	self.StoppedDash = nil

	DashTable[owner] = nil

end



function SWEP:SecondaryAttack()

	if DashTable[self:GetOwner()] then
		self:StopDash(false)
	end

end