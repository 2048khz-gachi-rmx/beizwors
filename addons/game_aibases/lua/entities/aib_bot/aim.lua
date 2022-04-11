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

	if self.TrackingEnemy then
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

function ENT:DoAimAdjustment(dlt)
	if not self:GetAimingAt() then return end
	local pos = self:EyePos()
	tVec:Set(self:GetAimingAt())
	tVec:Sub(pos)

	local wantAngle = tVec:Angle()
	wantAngle:Normalize()

	local ang = self:GetAngles()

	local spdMult, inacc = self:GetAimSpeed(tVec)

	wantAngle[1] = wantAngle[1] + inacc * math.Rand(-1, 1)
	wantAngle[2] = wantAngle[2] + inacc * math.Rand(-1, 1)

	-- if tracking enemy, slowdown on fast moving targets
	-- otherwise, relaxed turning
	local speedup = self.TrackingEnemy and 3 or 1
	local slowdown = self.TrackingEnemy and 1 or 0.075
	local degAt = self.TrackingEnemy and 140 or 30

	local dp = math.AngleDifference(self._aimPitch, wantAngle[1])
	local speedMult = math.RemapClamp(math.abs(dp), 0, degAt, slowdown, speedup)
	local speed = speedMult * dlt * spdMult

	local np = math.ApproachAngle(self._aimPitch, wantAngle[1], speed)
	self._aimPitch = np
	self:SetPoseParameter("aim_pitch", np)

	local dy = math.AngleDifference(ang[2], wantAngle[2])
	speedMult = math.RemapClamp(math.abs(dy), 0, degAt, slowdown, speedup)

	speed = speedMult * dlt * spdMult

	local ny = math.NormalizeAngle(math.ApproachAngle(ang[2], wantAngle[2], speed))

	ang[2] = ny
	self:SetAngles(ang)
	self:SetPoseParameter("aim_yaw", ny)

	local dist = tVec:Length()
	debugoverlay.Line(pos, pos + wantAngle:Forward() * dist, 0.1, color_white)
	-- why
	self.TargetAligned = math.abs((np - wantAngle[1]) + (ny - wantAngle[2])) < EPS

	if self.TargetAligned then
		self.TrackingEnemy = true
	end
end

local cache -- ...really?

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

	local pos = self:FindBonePos(self:GetEnemy())

	if not pos then
		pos = self:GetEnemy():GetPos() + self:GetEnemy():OBBCenter()
	end

	debugoverlay.Sphere(pos, 4, 0.2, color_white, true)
	self:SetAimingAt(pos)
end

function ENT:GetAimDir()
	if self.AimOverride then
		local dir = (self.AimOverride - self:EyePos())
		dir:Normalize()
		return dir
	end

	local ang = self:EyeAngles()
	ang.p = self._aimPitch

	return ang:Forward()
end

hook.Add("CW_GetAimDirection", "AIB_AimDir", function(wep, ow)
	if not ow.IsAIBaseBot then return end

	return ow:GetAimDir()
end)