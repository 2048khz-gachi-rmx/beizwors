AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.PrintName = "AI Base Bot"

ENT.Model = "models/Humans/Group01/Female_01.mdl"
ENT.Skin = 0
ENT.Spawnable = true

function ENT:SetupDataTables()

end

list.Set( "NPC", "aib_bot", {
	Name = "MoveToPos",
	Class = "aib_bot",
	Category = "NextBot Demos - NextBot Functions"
} )