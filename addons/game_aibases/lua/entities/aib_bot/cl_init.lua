include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:Draw()
	self:DrawModel()

	--[[local att = self:GetAttachment(5)
	if att then
		render.SetColorMaterialIgnoreZ()
		render.DrawSphere(att.Pos, 4, 4, 4, color_white)
	end]]



	if IsValid(self:GetCurrentWeapon()) then
		self:GetCurrentWeapon():SetRenderBounds(self:OBBMins(), self:OBBMaxs())
	end
end