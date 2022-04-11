include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:Draw()
	self:DrawModel()

	if IsValid(self:GetCurrentWeapon()) then
		self:GetCurrentWeapon():SetRenderBounds(self:OBBMins(), self:OBBMaxs())
	end
end