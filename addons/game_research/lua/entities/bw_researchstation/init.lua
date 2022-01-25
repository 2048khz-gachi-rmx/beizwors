--soon:tm:
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/grp/computers/supercomputer_01.mdl"

util.AddNetworkString("ResearchComputer")


function ENT:Init()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self:DrawShadow(false)
	self:SetModelScale(1)
end

function ENT:Use(ply, a, b, c)
	if ply ~= a or not IsPlayer(ply) then return end

	net.Start("ResearchComputer")
		net.WriteEntity(self)
	net.Send(ply)
end

function ENT:QueueResearch(ply, perk, lv)
	self:SetRSPerk(perk.NumID)
	self:SetRSLevel(lv)
	self:SetRSTime(CurTime())
end