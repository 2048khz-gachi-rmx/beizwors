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

ENT.Mood = "passive"

ENT.Moods = {
	"passive",
	"alert",
	"engaging", -- shooting at the target
	"covering",
	"chasing",
}

function ENT:SetMood(m)
	if not self.Moods[m] then errorNHf("not a mood: %s", m) return end
	self.Mood = m
end

function ENT:GetMood()
	return self.Mood
end

function ENT:Initialize()
	-- self:SetModel(self.Model)

	self.Moods = table.KeysToValues(self.Moods)

	self.LoseTargetDist = 1000
	self.Tier = self.Tier or 1

	self:InitializeTier(self.Tier)

	self.EnemyAwareness = {}
	self._curActs = {}
	self.DynCoros = {}
	self.headEmpty = true
	
	--self:MatchActivity()
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
	self:DoGestures()

	self.loco:SetMaxYawRate(99999)
	local aang = self:GetAimAngle():Forward()
	if self:GetAimingAt() then
		self.loco:FaceTowards(self:GetShootPos() + self:GetAimAngle():Forward() * 32)
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
include("gestures.lua")