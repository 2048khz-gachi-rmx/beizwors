include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true
ENT.IsAIBaseBot = true

AccessorFunc(ENT, "Enemy", "Enemy")

function ENT:Initialize()
	self:SetModel(self.Model)

	self.LoseTargetDist = 1000
end

function ENT:RunBehaviour()
	while ( true ) do
		self:StartActivity( ACT_IDLE )

		if ( self:HaveEnemy() ) then
			self.loco:FaceTowards(self:GetEnemy():EyePos())
		elseif not self.StopWandering then
			self:DoWander()
		end

		coroutine.wait(2)
	end
end

function ENT:BehaveUpdate(time)
	self.BehaveTime = time

	if not self.BehaveThread then return end

	local ok, err = coroutine.resume(self.BehaveThread)

	if not ok then
		errorNHf("AIBaseBot `%s` error: %s.", self:GetClass(), err)
	end

	--self:DoAimAdjustment(time)
end

function ENT:Think()
	local period = CurTime() - (self._lastThink or CurTime() - engine.TickInterval())
	self._lastThink = CurTime()

	self:DoAimTarget(period)
	self:DoAimAdjustment(period)
	self:DoShootBehavior(period)
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