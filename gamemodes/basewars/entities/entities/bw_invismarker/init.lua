AddCSLuaFile("cl_init.lua")

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Invisible marker"
ENT.DontCollide = true
ENT.Model = "models/hunter/blocks/cube025x025x025.mdl"

function ENT:Initialize()
	if self.Model then self:SetModel(self.Model) end

	local mins, maxs

	if self.CustomOBB then
		mins, maxs = unpack(self.CustomOBB)
	else
		mins, maxs = self:OBBMins(), self:OBBMaxs()
	end

	if not mins or not maxs then error("???") return end

	self:PhysicsInitBox(mins, maxs)
	self:GetPhysicsObject():EnableMotion(false)
	self:SetCustomCollisionCheck(true)
	self:EnableCustomCollisions(true)

	constraint.NoCollide(self, game.GetWorld(), 0, 0)
end

function ENT:UpdateTransmitState()
	return DEBUG_MARKERS and TRANSMIT_PVS or TRANSMIT_NEVER
end

function ENT:TestCollision(...)
	return false
end

hook.Add("ShouldCollide", "CollisionTest", function(a, b)
	if a.DontCollide or b.DontCollide then
		return false
	end
end)