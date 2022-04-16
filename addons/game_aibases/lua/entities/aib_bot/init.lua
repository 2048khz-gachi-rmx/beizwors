include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true

AccessorFunc(ENT, "Enemy", "Enemy")

function ENT:GetEnemy()
	return self.Enemy and self.Enemy:IsValid() and self.Enemy
end

function ENT:Initialize()
	self:SetModel(self.Model)

	self.LoseTargetDist = 1000
	self.Tier = self.Tier or 1

	self:InitializeTier(self.Tier)

	self._curActs = {}
	self.DynCoros = {}

	self:MatchActivity()
	self:SetLagCompensated(true)
end

function ENT:AddActivity(str, b)
	self._curActs[str] = b
end

function ENT:FinishActivity(str)
	self._curActs[str] = nil
end

function ENT:HasActivity(str)
	return self._curActs[str]
end

function ENT:AddCoro(name, cor)
	self.DynCoros[name] = isfunction(cor) and coroutine.create(cor) or cor
end

function ENT:HasCoro(name)
	return self.DynCoros[name]
end

ENT.AnimActivities = {
	ar = {
		aggro = ACT_MP_WALK,
		aggro_run = ACT_MP_RUN,

		reload = ACT_HL2MP_WALK_CROUCH_AR2,
		passive = ACT_HL2MP_WALK_PASSIVE,
	}
}

ENT.EquippedType = "ar"

function ENT:_getAc(base, pfx, sfx)
	local ac = self.AnimActivities[self.EquippedType]
	if not ac then print("no activities!") return ACT_HL2MP_WALK_PASSIVE end

	return 	ac[pfx .. base .. sfx] or
			ac[pfx .. base 		 ] or
			ac[		  base .. sfx] or
			ac[		  base		 ]
end

function ENT:GetDesiredActivity()

	local acts = self.AnimActivities[self.EquippedType]
	if not acts then return ACT_HL2MP_WALK_PASSIVE end

	local sfx = self.loco:GetVelocity():Length() > 100 and "_run" or ""
	local pfx = ""

	if self:HasActivity("Reload") then
		return self:_getAc("reload", pfx, sfx)
	end

	if self:GetEnemy() then
		return self:_getAc("aggro", pfx, sfx)
	end

	return self:_getAc("passive", pfx, sfx)
end

function ENT:MatchActivity()
	local wep = self:GetCurrentWeapon()
	local want = self:GetDesiredActivity()
	--print("want:", want, wep:TranslateActivity(want))
	if IsValid(wep) then
		local tr = wep:TranslateActivity(want)
		want = tr ~= -1 and tr or want
	end

	--print("want:", want)

	if want ~= self:GetActivity() then
		self:StartActivity(want)
	end
end

function ENT:BodyUpdate()
	self:BodyMoveXY()
end

function ENT:BH_Activity()

	while true do

		--if ( self:HaveEnemy() ) then
			--self.loco:FaceTowards(self:GetEnemy():EyePos())
		--elseif not self.StopWandering then
			--self:DoWander()
		--end

		coroutine.wait(2)
	end
end

function ENT:BH_Targeting()
	while true do
		self:HaveEnemy()
		coroutine.yield()
	end
end

function ENT:BH_DecideMovement()
	while true do
		self:DecideMovement()
		coroutine.yield()
	end
end

function ENT:BH_Movement()
	while true do
		self:DoQueuedMove()

		coroutine.yield()
	end
end

function ENT:BH_Shooting()
	while true do
		coroutine.wait(1)
	end
end

ENT.BehaviorOrder = {
	"Targeting",
	"DecideMovement",
	"Movement",
	"Shooting",
	"Activity"
}

function ENT:BehaveStart()
	self.Behaviors = {}
	self.Warned = {}

	for k,v in pairs(self.BehaviorOrder) do
		if not isfunction(self["BH_" .. v]) then
			errorNHf("No ENT:BH_%s defined.", v)
			continue
		end

		self.Behaviors[k] = coroutine.create(self["BH_" .. v])
	end
end

function ENT:BehaveUpdate(time)
	self.BehaveTime = time

	for k,v in pairs(self.Behaviors) do
		if coroutine.status(v) == "dead" then
			if not self.Warned[k] then
				printf("!! coroutine BH_%s is dead !!", self.BehaviorOrder[k])
				self.Warned[k] = true
			end
			continue
		end

		local ok, err = coroutine.resume(v, self)

		if not ok then
			errorNHf("AIBaseBot `%s` error in BH_%s: %s.", self:GetClass(), self.BehaviorOrder[k], err)
		end
	end

	for k,v in pairs(self.DynCoros) do
		local ok, err = coroutine.resume(v)
		if coroutine.status(v) == "dead" then
			self.DynCoros[k] = nil

			if not ok then
				errorNHf("AIBaseBot `%s` error in DynCor %s: %s.", self:GetClass(), k, err)
			end
		end
	end

	self:MatchActivity()

	self.loco:SetMaxYawRate(99999)
	if self:GetAimingAt() then
		self.loco:FaceTowards(self:GetAimingAt())
	end

	self:SlowThink()
	--self:DoAimAdjustment(time)
end

function ENT:SlowThink()
	self:UpdateTargetLOS()
end

function ENT:Think()
	local period = CurTime() - (self._lastThink or CurTime() - engine.TickInterval())
	self._lastThink = CurTime()

	self:DoAimTarget(period)
	self:DoAimAdjustment(period)
	self:DoShootThink(period) -- shoot in Think so we shoot a lot

	--[[self:NextThink(CurTime())
	return true]]
end

list.Set( "NPC", "aib_bot", {
	Name = "MoveToPos",
	Class = "aib_bot",
	Category = "NextBot Demos - NextBot Functions"
} )

include("shooting.lua")
include("targeting.lua")
include("movement.lua")
include("aim.lua")
include("tiers.lua")