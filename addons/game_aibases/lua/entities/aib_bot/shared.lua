AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.PrintName = "AI Base Bot"

ENT.Model = "models/player/ct_gign.mdl"
ENT.Skin = 0
ENT.Spawnable = true
ENT.IsAIBaseBot = true

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "CurrentWeapon")
end

function ENT:GetActiveWeapon()
	return self:GetCurrentWeapon()
end

list.Set( "NPC", "aib_bot", {
	Name = "MoveToPos",
	Class = "aib_bot",
	Category = "NextBot Demos - NextBot Functions"
} )


local PLAYER = FindMetaTable("Player")
PLAYER._aibAimVector = PLAYER._aibAimVector or PLAYER.GetAimVector

function PLAYER:GetAimVector()
	if self.IsAIBaseBot then
		return self:GetAngles():Forward()
	end

	return self._aibAimVector(self)
end