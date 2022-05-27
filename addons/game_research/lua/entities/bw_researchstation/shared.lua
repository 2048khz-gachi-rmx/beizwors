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
	self:NetworkVar("String", 0, "RSPerk")
	self:NetworkVar("Int", 2, "RSLevel")

	--[[
		if halted due to no power, RSTime will contain halted time
			and RSProgress will contain halted progress

		if not halted, RSProgress will contain starting progress
			and RSTime will contain ending time

		if halted,
			frac = RSProgress
		else
			frac = RSProgress + (
			math.Remap(CurTime, RSTime - ResearchTime * (1 - RSProgress), RSTime,
				1 - RSProgress, 1)
			)
	]]

	self:NetworkVar("Bool", 1, "RSHalted")
	self:NetworkVar("Float", 1, "RSTime")
	self:NetworkVar("Float", 2, "RSProgress")
end

function ENT:IsResearching()
	if self:GetRSPerk() == "" then return false end
	return not self:FinishedResearching()
end

function ENT:FinishedResearching()
	if CLIENT then
		return self:GetResearchFrac() == 1
	end

	return self.Finished
end