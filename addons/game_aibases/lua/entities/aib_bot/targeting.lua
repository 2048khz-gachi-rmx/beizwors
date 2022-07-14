--
local trIn, trOut = {}, {}
trIn.output = trOut

function ENT:HaveEnemy()
	local enemy = self:GetEnemy()
	if not enemy then return self:FindEnemy() end

	--if self:GetRangeTo(enemy:GetPos()) > self.LoseTargetDist then return self:FindEnemy() end
	if enemy:IsPlayer() and not enemy:Alive() then return self:FindEnemy() end

	local can, passed = self:CanSeeTarget()

	-- current enemy not visible; try to reaggro on someone else
	if not can then
		local ret = self:FindEnemy(true)
		if ret then return ret end
	end

	-- we found no new enemy; stay on the old one
	if not can and passed > 0.7 then
		if self.TrackingEnemy then
			self.PrevTrackTime = self.TrackingTime
			self.TrackingTime = CurTime()
		end
		self.TrackingEnemy = false
	end

	return true
end

function ENT:CanTarget(ply, ignorebase)
	if ply.NoTarget or self.NoTarget then return false end
	if not ignorebase and not self:BW_GetBase() then return false end -- wtf
	if not ignorebase and ply:BW_GetBase() ~= self:BW_GetBase() then return false end
	if ply.InDevMode then return false end

	return true
end

function ENT:UpdateLastAwarePos(pos)
	self.TargetVisPos = pos
end

-- pos is optional
-- vis means updating via sight (more info such as velocity can be gathered)
function ENT:UpdateLastAware(ent, pos, vis)
	local aws = self.EnemyAwareness
	local aw = aws[ent] or {}
	aws[ent] = aw

	aw.pos = isvector(pos) and pos or ent:EyePos()
	aw.vel = vis and ent:GetVelocity()
	self:UpdateLastAwarePos(aw.pos)
end

-- return the awareness of an ent (or current enemy)
function ENT:GetTargetAwareness(e)
	return self.EnemyAwareness[e or self:GetEnemy() or false]
end

function ENT:CanSeeTarget()
	local ct = CurTime()

	return self.HaveTargetLOS, ct - (self.LOSLastChange or ct),
		self.TargetVisPos
end

local b = bench("targetlos", 600)

function ENT:_changeLOS(b)
	if self.HaveTargetLOS ~= b then
		self:Emit("LOSChanged", b)
		hook.Run("AIB_LOSChanged", self, b)

		self.LOSLastChange = CurTime()
		self[b and "_acqTime" or "_lostTime"] = CurTime()
	end

	self.HaveTargetLOS = b
end

function ENT:UpdateTargetLOS()
	--b:Open()
	local en = self:GetEnemy()
	if not en then
		self:_changeLOS(false)
		--b:Close():print()
		return
	end

	local can_tgt, visPos = self:InView(en)

	if not can_tgt then
		self:_changeLOS(false)
		--self.TargetVisPos = nil
		--b:Close():print()
		return
	end

	self:_changeLOS(true)
	self:MakeAwareOf(en, visPos)
	--b:Close():print()
end

function ENT:MakeAwareOf(ent, vis)
	self:UpdateLastAware(ent, vis or ent:OBBCenter() + ent:GetPos(), not not vis)
end

local tracePoses = {
	--function(self, ply) return ply:GetShootPos() end,
	function(self, ply) return ply:OBBCenter() end,
}

local traceBones = {
	"ValveBiped.Bip01_Spine1",
	"ValveBiped.Bip01_Head1", -- TODO: disable headshots
	"ValveBiped.Bip01_R_Forearm",
	"ValveBiped.Bip01_L_Forearm",
	"ValveBiped.Bip01_R_Calf",
	"ValveBiped.Bip01_L_Calf",
}

for k,v in pairs(traceBones) do
	tracePoses[#tracePoses + 1] = function(self, ply)
		local ind = ply:BoneToIndex(v)
		if ind then
			return ply:GetBonePosition(ind)
		end

		return false
	end
end


-- this is souper expensive
function ENT:InView(ply, reuse)
	if not reuse then
		trIn.start = self:GetShootPos()
		trIn.filter = self
	end

	for k,v in pairs(tracePoses) do
		local ep = v(self, ply)
		if ep then
			trIn.endpos = ep
			util.TraceLine(trIn)

			local ent = trOut.Entity

			-- didnt hit when aiming straight for the eyes; means no obstacles means ur so fucked homie

			if not trOut.Hit then
				self:UpdateLastAware(ply, ep, true)
				return ply, ep
			end

			if ent:IsPlayer() then
				if ent == ply then
					self:UpdateLastAware(ent, ep, true)
					return ent, ep
				end
				if self:CanTarget(ent) then -- eh this'll do
					self:UpdateLastAware(ent, ep, true)
					return ent, ep
				end
			end
		end
	end

	return false
end

function ENT:OnTakeDamage(dmg)
	local atk = dmg:GetAttacker()
	if not IsValid(atk) or not self:CanTarget(atk, true) then
		self:Emit("OnTakeDamage", dmg)
		return
	end

	if not self:GetEnemy() then
		self:SetEnemy(atk)
		self:MakeAwareOf(atk)
		self:SetAimingAt(atk:EyePos())
	end

	self:Emit("OnTakeDamage", dmg)
end

local b = bench("targetacq", 600)

function ENT:FindEnemy(noWriteLoss)
	local plys = player.GetConstAll()
	trIn.start = self:GetShootPos()
	trIn.filter = self

	--b:Open()
	for k,v in ipairs(plys) do
		if not self:CanTarget(v) then
			continue
		end

		local tgt = self:InView(v, true)
		if not tgt then
			continue
		end

		self:SetEnemy(tgt)
		self:MakeAwareOf(tgt)
		self:_changeLOS(true)

		self.headEmpty = false
		--b:Close():print()
		return true
	end

	if self:GetEnemy() then
		self:OnEnemyLost()
	end

	if not noWriteLoss then
		self:LoseEnemy()
	end
	--b:Close():print()
	return false
end

function ENT:ValidateEnemy()
	if not self.Enemy or not self.Enemy:IsValid() then
		self:LoseEnemy()
	end

	return self.Enemy
end

function ENT:OnEnemyLost()
	self:Emit("EnemyLost", self:GetEnemy())
	self:SetMood("alert")
	self.headEmpty = true
end

function ENT:LoseEnemy()
	if self:GetEnemy() then
		self:OnEnemyLost()
	end

	self.TrackingEnemy = false
	self:SetEnemy(nil)
end