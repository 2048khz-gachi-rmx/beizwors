AddCSLuaFile()

local bwbase = BaseWars.Bases.Base

function bwbase:IsAI()
	return self:GetData().AIBase
end
