include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

ENT.Spread = 15
ENT.NextShot = 0

function ENT:Init()
	self:SetModel(self.Model)
end

local function IsTarget(ow, ply)
	if ow:IsEnemy(ply) then return true end -- duh
	if not ply:Alive() then return false end
	if ply:BW_GetBase() == ow:GetBase() and not ow:IsTeammate(ply) then return true end -- trespassing
end

local function IsFriend(ow, ply)
	if not ply:Alive() then return false end
	if ow == ply then return true end -- duh
	if ow:IsTeammate(ply) then return true end
end

function ENT:SpawnBullet(target, theirEyes)
	self:SetNextThink(CurTime() + self.ShootingDelay)
	self:SetNextScan(CurTime() + self.ShootingDelay)

	if not self:DrainPower(self.Drain or 10) then return end

	local Bullet = self:GetBulletInfo(target, theirEyes)

	self:FireBullets(Bullet)
	-- self:DrainPower(self.Drain)
	if self.PlaySound then
		self:PlaySound(Bullet)
	else
		local snd

		if istable(self.Sounds) then
			snd = table.SeqRandom(self.Sounds)
		else
			snd = self.Sound or self.Sounds
		end

		if snd then
			self:EmitSound(snd, 60)
		end
	end
end

local randVec = Vector()

function ENT:ModifyBullet(bullet, target) end

local moaToDeg = 10 / 180 / 60

function ENT:OnHit(who, trace, dmg)

end

function ENT:OnHitFriendly(who, trace, dmg)
	return true -- negate FF
end

function ENT:GetBulletInfo(target, pos)

	local dir = pos - self.ShootWorldOffset

	local ang = math.random() * math.pi * 2
	local x, y = math.cos(ang), math.sin(ang)

	local rad = self.Spread * moaToDeg * math.sqrt(math.random())
	randVec:SetUnpacked(
		0, x * rad, y * rad
	)

	dir:Normalize()

	randVec:Rotate(dir:Angle()) -- when shooting up/down, spread is fucked without this
	dir:Add(randVec)
	dir:Normalize()

	local bullet = {}
		bullet.Damage = self.Damage
		bullet.TracerName = "AR2Tracer"
		bullet.Src = self.ShootWorldOffset
		bullet.Dir = dir

		--bullet.IgnoreEntity = target
		bullet.Callback = function(e, tr, dmg)
			--debugoverlay.Cross(tr.HitPos, 1, 1, color_white)
			local vic = tr.Entity
			if vic ~= target then
				if not vic:IsPlayer() then dmg:ScaleDamage(0) return end

				local ow = self:BW_GetOwner()
				ow = ow and ow:GetPlayer()
				if ow and not IsTarget(ow, vic) then

					local should_neg = self:OnHitFriendly(vic, tr, dmg)
					if should_neg then
						dmg:ScaleDamage(0) -- it'd be funny if turrets could friendly-fire but EHHH
					end

					return
				end
			end

			self:OnHit(vic, tr, dmg)
		end

	--debugoverlay.Cross(pos, 2, 1, Colors.Red, true)
	self:ModifyBullet(bullet)

	return bullet
end

local b = bench("turret", math.huge)

function ENT:FinishScan(friend)
	-- finished scan; noone found

	self:SetNextScan(CurTime() + (friend and self.HiFreqScanDelay or self.ScanDelay))
	self:SetNextThink(self:GetNextScan())

	self:SetTarget(friend or NULL)

	if self:IsState("IDLE") and not friend then
		self:FoundFriend(friend)
		return
	end

	if not friend then
		self:SetState("IDLE")
		self:FoundFriend(friend)
		return
	end

	if friend and self:IsState("IDLE") then
		self:SetState("FRIENDLY")
	end

	self:FoundFriend(friend)
end

function ENT:FoundFriend(tgt)
	b:Close():print()
end

function ENT:FoundEnemy(tgt)
	self:SpawnBullet(tgt, self:GetPlayerShootPoint(tgt))
	self:SetTarget(tgt)
	self:SetState("FIRING")
	b:Close():print()
end

local cache -- ...really?

local priorityBones = {
	--"ValveBiped.Bip01_Spine2",
	"ValveBiped.Bip01_Spine1",
	"ValveBiped.Bip01_Spine",
}

function ENT:FindBone(ent)
	cache = cache or muldim:new()

	local mdl = ent:GetModel()
	local boneIdx = cache:Get(mdl)
	local curPrio = math.huge

	if boneIdx == false then
		return false -- already tried to find and failed
	end

	if boneIdx == nil then -- never tried to find; try to
		if priorityBones[1] then priorityBones = table.KeysToValues(priorityBones) end
		cache:Set(false, mdl) -- if we don't find anything, this'll remain

		for i=0, ent:GetBoneCount() - 1 do
			local prio = priorityBones[ent:GetBoneName(i)]
			if prio and curPrio > prio then
				cache:Set(i, mdl)
				boneIdx = i
				curPrio = prio
			end
		end
	end

	if not boneIdx then
		printf("!! turret: failed to find bone pos on model %s !!", ent:GetModel()) -- that ain't supposed ta happen
		return false
	end

	return ent:GetBonePosition(boneIdx)
end

local trOut = {}

local trIn = {
	output = trOut,
	mins = -Vector(0, 0, 0),
	maxs = Vector(0, 0, 0)
}

function ENT:IsInAim(point, offset, fwd, rad, ang, closest, ply)
	local dist = offset:DistToSqr(point)
	if dist > closest then return false end

	if not IsInCone(point, offset, fwd, rad, ang) then return false end

	-- well they're in cone and in dist; now we have to do the expensive check...
	trIn.start = offset
	trIn.endpos = point
	trIn.filter = self

	util.TraceHull(trIn)
	if trOut.Hit and trOut.Entity ~= ply then return false end

	return dist
end

function ENT:GetPlayerShootPoint(v)
	return self:FindBone(v) or v:LocalToWorld(v:OBBCenter())
end

function ENT:FindTargets(plys, owPly)
	local fwd = self:GetForward()
	local offset = self:LocalToWorld(self.ShootingOffset)
	self.ShootWorldOffset = offset

	local rad, ang = self.Radius, self.Angle / 2

	local target, targetEyes
	local closestTarget = self.Radius ^ 2

	for k, v in ipairs(plys) do
		-- we already acquired a target; we can just ignore friendlies and save performance
		local vPos = self:GetPlayerShootPoint(v)

		local dist = self:IsInAim(vPos, offset, fwd, rad, ang, closestTarget, v)
		if not dist then continue end

		-- found player closer than the current one (or just the first one)
		closestTarget = dist
		target = v
		targetEyes = vPos
	end

	return target, targetEyes
end

function ENT:GetAimParams(target)
	local offset = self:LocalToWorld(self.ShootingOffset)
	local fwd = self:GetForward()
	local rad, ang = self.Radius, self.Angle / 2
	local vPos = self:GetPlayerShootPoint(target)

	return vPos, offset, fwd, rad, ang
end

ENT.CurYaw = 0

function ENT:FrequentThink()

end

function ENT:SetNextThink(t)
	self.NextTurretThink = t
end

ENT.NextTurretThink = 0

function ENT:ThinkFunc()
	self:FrequentThink()
	self:NextThink(CurTime())
	if (self.NextTurretThink or 0) > CurTime() then return true end

	if not self:IsPowered() then
		self:SetState("IDLE")
		self:SetTarget(NULL)
		return
	end

	b:Open()

	-- determine what table do we search
	local ow = self:BW_GetOwner()
	local owPly = ow and ow:GetPlayer()
	local in_raid = ow and ow:GetRaid()
	local base = self:BW_GetBase()

	local usingBase = not in_raid and base and base:GetPlayers()
	local plys = usingBase or player.GetConstAll()

	if not owPly then
		self:FinishScan()
		return true
	end

	local target = self.LastTarget

	--[==================================[
		behavior:
			- check for cached enemy
			- if they're unavailable, scan for new enemies
			- if no new enemies, check cached friendly
			- no friendly => scan
	--]==================================]

	-- check for cached enemy
	if target and target:IsValid() then
		local acqTime = CurTime() - self.AcquiredWhen
		if acqTime < 0.5 then -- cache only lasts 0.5s since last rescan
			-- we still remember a target; see if we can still aim at them

			local a, bb, c, d, e = self:GetAimParams(target)
			local canAim = self:IsInAim(a, bb, c, d, e, self.Radius ^ 2, target)

			if canAim then
				-- we can still aim at them; just shoot at them and don't try to search
				self:FoundEnemy(target)
				return true
			end
		end

		target = nil -- we're here because either we need to recache or target isn't accessible
	end


	self.LastTarget = nil

	-- scan baddies; construct search arrays
	local baddies, friends = {}, {}

	for k,v in pairs(plys) do
		local ply = usingBase and k or v

		if IsTarget(owPly, ply) then
			baddies[#baddies + 1] = ply
		elseif IsFriend(owPly, ply) then
			-- a player can be neither friend nor foe
			friends[#friends + 1] = ply
		end
	end

	do
		if #baddies > 0 then
			target, targetEyes = self:FindTargets(baddies, owPly)
			self.LastTarget = target
			self.AcquiredWhen = CurTime()
		end

		-- found hostile; shoot and bail
		if target then
			self:FoundEnemy(target)
			return true
		end
	end

	-- find cached friend
	local friend = self.LastFriend

	if friend and friend:IsValid() then
		self:SetState("FRIENDLY")
		local a, bb, c, d, e = self:GetAimParams(friend)
		local canAim = self:IsInAim(a, bb, c, d, e, self.Radius ^ 2, friend)
		if canAim then
			self:SetTarget(friend)
			self:FoundFriend(friend)
			return true -- we have friendo :):):)
		end
	end

	friend = nil

	-- no cached friends; find someone,,, :(
	if not target and #friends > 0 then
		friend = self:FindTargets(friends, owPly)
		self.LastFriend = friend
	end

	self:FinishScan(friend)
	self:SetState("SCANNING")

	return true
end