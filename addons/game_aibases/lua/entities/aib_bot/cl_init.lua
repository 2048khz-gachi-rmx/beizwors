include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:Draw()
	self:DrawModel()

	if IsValid(self:GetCurrentWeapon()) then
		self:GetCurrentWeapon():SetRenderBounds(self:OBBMins(), self:OBBMaxs())
	end
end

hook.Add("CreateClientsideRagdoll", "AIB_Cleanup", function(ent, rag)
	if not ent.IsAIBaseBot then return end

	timer.Simple(30, function()
		if not IsValid(rag) then return end
		rag:SetSaveValue("m_bFadingOut", true)
	end)
end)