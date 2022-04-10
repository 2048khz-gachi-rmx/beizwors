include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true

function ENT:Initialize()
	self:SetModel(self.Model)
end

function ENT:RunBehaviour()
	while true do
		coroutine.wait(0.2)
		local ply = player.GetAll()[1]
		if not ply then return end

		self.loco:SetDesiredSpeed(125)
		self:MoveToPos( ply:GetPos(), {draw = true} )

		coroutine.yield()
	end
end


list.Set( "NPC", "aib_bot", {
	Name = "MoveToPos",
	Class = "aib_bot",
	Category = "NextBot Demos - NextBot Functions"
} )