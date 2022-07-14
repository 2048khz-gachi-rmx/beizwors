include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true

function ENT:GetEnemy()
	return self.Enemy and self.Enemy:IsValid() and self.Enemy
end

function ENT:SetEnemy(ent)
	if IsValid(ent) then
		self:SetMood("engaging")
		self:Emit("EnemyFound", ent)
	end

	self.Enemy = ent
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
	self.RestartCoros = {}
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

ENT.BackBehavior = {}

for k,v in pairs(ENT.BehaviorOrder) do
	ENT.BackBehavior[v] = k
end

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

function ENT:ResumeCoro(coro, k)
	local stat = coroutine.status(coro)

	if stat == "dead" then
		if not self.Warned[k] then
			printf("!! coroutine BH_%s is dead !!", self.BehaviorOrder[k])
			self.Warned[k] = true
		end
		return
	end

	if stat == "suspended" then

		while true do
			local ok, err = coroutine.resume(coro, self)

			if not ok then
				errorNHf("AIBaseBot `%s` error in BH_%s: %s.", self:GetClass(), self.BehaviorOrder[k], err)
			else
				if err then print("yield out:", err) end
			end

			local runAgain = self.RestartCoros and self.RestartCoros[coro]

			if runAgain and runAgain > 0 then
				self.RestartCoros[coro] = self.RestartCoros[coro] - 1
			else
				break
			end
		end

	end

	if stat == "normal" then
		-- Requested to resume during execution => restart after we're done
		self.RestartCoros = self.RestartCoros or {}
		self.RestartCoros[coro] = (self.RestartCoros[coro] or 0) + 1
	end
end

function ENT:BehaveUpdate(time)
	self.BehaveTime = time

	for k,v in pairs(self.Behaviors) do
		self:ResumeCoro(v, k)
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

	if self:GetAimingAt() then
		self.loco:FaceTowards(self:GetShootPos() + self:GetAimAngle():Forward() * 32)
	end

	self:SlowThink()
	--self:DoAimAdjustment(time)
end

function ENT:RestartCoro(name)
	local num = self.BackBehavior[name]
	if not num then
		errorNHf("Unknown behavior name %s", name)
		return
	end

	self:ResumeCoro(self.Behaviors[num], num)
end

function ENT:SlowThink()
	self:UpdateTargetLOS()
end

-- very frequent think here
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