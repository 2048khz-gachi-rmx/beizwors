--soon:tm:

ENT.Base = "bw_base_electronics"
ENT.Type = "anim"

ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.PrintName = "Research Computer"

ENT.Model = "models/grp/computers/supercomputer_01.mdl"
ENT.Skin = 0
ENT.ResearchComputer = true



function ENT:DerivedDataTables()
	self:NetworkVar("Int", 5, "RSPerk")
	self:NetworkVar("Int", 6, "RSLevel")
	self:NetworkVar("Float", 1, "RSTime")
end