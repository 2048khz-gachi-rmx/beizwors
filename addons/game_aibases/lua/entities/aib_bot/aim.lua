--

ENT.AimSpeed = 240
ENT._aimPitch = 0

function ENT:SetAimingAt(pos)
	self.AimingAt = pos
	self:SetEyeTarget(pos)
end

function ENT:GetAimingAt()
	return self.AimingAt
end

function ENT:AimAt(pos, raw) -- setting as raw allows modifying the same vector later
	self:SetAimingAt(raw and pos or Vector(pos))
end

local tVec = Vector()
local EPS = 0.1

function ENT:GetAimSpeed(diff)
	local base = 1 -- self.AimSpeed
	local inacc = 1

	if self:GetTrackedEnemy() then
		local en = self:GetEnemy()
		local velLen = en:GetVelocity():Length()
		local dist = diff:Length()

		local distMult = math.RemapClamp(dist, 256, 512, 1, 0.4)
		base = base * distMult

		-- velocity affects aimspeed a lot more the further you are
		local velMult = math.RemapClamp(velLen / distMult, 500, 900, 1, 0.6)
		base = base * velMult

		local velInacc = math.RemapClamp(velLen / distMult, 350, 900, 0, 1)
		local distInacc = math.RemapClamp(dist, 400, 720, 0, 0.2 + velInacc)

		inacc = velInacc + distInacc
	end

	return base * self.AimSpeed, inacc
end

function ENT:GetAimAngles()
	self._angs = self._angs or {0, 0, 0}
	return unpack(self._angs)
end

function ENT:SetAimAngles(p, y, r)
	local a = self._angs or {p, y, r}
	self._angs = a

	a[1] = p or a[1]
	a[2] = y or a[2]
	a[3] = r or a[3]
end

local aang = Angle()

function ENT:GetAimAngle()
	aang:SetUnpacked(self:GetAimAngles())
	return aang
end

local tAng = Angle()

function ENT:DoAimAdjustment(dlt)
	if not self:GetAimingAt() then return end
	local pos = self:GetShootPos()

	tVec:Set(self:GetAimingAt())
	tVec:Sub(pos)

	local wantAngle = tVec:Angle()
	wantAngle:Normalize()

	local cp, cy, cr = self:GetAimAngles()

	local spdMult, inacc = self:GetAimSpeed(tVec)

	wantAngle[1] = wantAngle[1] + inacc * math.Rand(-1, 1)
	wantAngle[2] = wantAngle[2] + inacc * math.Rand(-1, 1)

	-- if tracking enemy, slowdown on fast moving targets
	-- otherwise, relaxed turning
	local trk = self:GetTrackedEnemy()
	local speedup = trk and 3 or 1
	local slowdown = trk and 1 or 0.2
	local degAt = trk and 140 or 30

	local dp = math.AngleDifference(self._aimPitch, wantAngle[1])
	local speedMult = math.RemapClamp(math.abs(dp), 0, degAt, slowdown, speedup)
	local speed = speedMult * dlt * spdMult

	local np = math.ApproachAngle(self._aimPitch, wantAngle[1], speed)
	self._aimPitch = np

	local dy = math.AngleDifference(cy, wantAngle[2])
	speedMult = math.RemapClamp(math.abs(dy), 0, degAt, slowdown, speedup)

	speed = speedMult * dlt * spdMult

	local ny = math.NormalizeAngle(math.ApproachAngle(cy, wantAngle[2], speed))

	tAng:SetUnpacked(np, ny, 0)
	self:SetAimAngles(np, ny)

	local dist = tVec:Length()
	debugoverlay.Line(pos, pos + wantAngle:Forward() * dist, 0.02, color_white)
	debugoverlay.Line(pos, pos + tAng:Forward() * dist, 0.02, Colors.Sky)
	-- why
	self.TargetAligned = math.abs((np - wantAngle[1]) + (ny - wantAngle[2])) < EPS

	if self.TargetAligned and self:CanSeeTarget() then
		if not self.TrackingEnemy then
			self.PrevTrackTime = self.TrackingTime
			self.TrackingTime = CurTime()
		end
		self.TrackingEnemy = self:GetEnemy()
	end
end

function ENT:GetTrackedEnemy()
	local ct = CurTime()
	
	return self.TrackingEnemy, ct - (self.TrackingTime or 0), ct - (self.PrevTrackTime or 0)
end

local priorityBones = {
	--"ValveBiped.Bip01_Spine2",
	"ValveBiped.Bip01_Spine1",
	"ValveBiped.Bip01_Spine",
}

function ENT:FindBonePos(ent)
	for k,v in ipairs(priorityBones) do
		local ind = ent:BoneToIndex(v)
		if ind then
			return ent:GetBonePosition(ind)
		end
	end

	return false
end

-- if we have an enemy, set our aim pos to their dome (or elsewhere)
function ENT:DoAimTarget(dlt)
	if not self:GetEnemy() then return end -- oh well

	local can, when, pos = self:CanSeeTarget()
	if not can then return end

	if not pos then
		pos = self:GetEnemy():GetPos() + self:GetEnemy():OBBCenter()
	end

	self:SetAimingAt(pos)
end

local aimAng = Angle()

function ENT:GetAimDir()
	if self.AimOverride then
		local dir = (self.AimOverride - self:GetShootPos())
		dir:Normalize()
		return dir
	end

	local p, y, r = self:GetAimAngles()
	aimAng:SetUnpacked(p, y, r)

	return aimAng:Forward()
end

function ENT:GetShootPos()
	local ind = self:BoneToIndex("ValveBiped.Bip01_Head1")
	if not ind then return self:GetPos() + self:OBBCenter() end

	return self:GetBonePosition(ind)
end

hook.Add("CW_GetAimDirection", "AIB_AimDir", function(wep, ow)
	if not ow.IsAIBaseBot then return end

	return ow:GetAimDir()
end)