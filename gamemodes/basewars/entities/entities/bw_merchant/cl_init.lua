include("shared.lua")
AddCSLuaFile("shared.lua")


-- this is what broke me
-- freezing the breath layer on the idle sequence is impossible

function ENT:Initialize()

end

function ENT:Draw()
	self:SetupBones()
	self:DrawModel()
end

function ENT:ClientUse()

end