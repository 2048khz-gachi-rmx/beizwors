include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

function ENT:Initialize(me)
	self:SetModel("models/playermodels/cr302_robot_pm.mdl")

	self:PhysicsInit(SOLID_BBOX)
	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_NONE)
end

function ENT:Think()
	self:SetPlaybackRate(0)

end

function ENT:Use(ply)

end
