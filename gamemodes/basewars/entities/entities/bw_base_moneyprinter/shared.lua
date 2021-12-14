AddCSLuaFile()
ENT.Base = "bw_base_upgradable"

ENT.Model = "models/grp/printers/printer.mdl"
ENT.Skin = 0

ENT.Capacity 		= 10000
ENT.Money 			= 0
ENT.PrintInterval 	= 1
ENT.PrintAmount		= 20
ENT.MaxLevel 		= 5
ENT.UpgradeCost 	= 1000

ENT.PrintName 		= "Basic Printer"

ENT.IsPrinter 		= true
ENT.IsValidRaidable = false

ENT.RebootTime = 10
ENT.PowerRequired = 6

local slot = 2

function ENT:MakeFloat(name)
	self:NetworkVar("Float", slot, name)
	slot = slot + 1
end

function ENT:DerivedDataTables()
	slot = 2

	self:MakeFloat("Capacity")
	self:SetCapacity(self.Capacity)

	self:MakeFloat("NWMoney")

	self:MakeFloat("Level")
	self:SetLevel(1)

	self:MakeFloat("Multiplier")
	self:SetMultiplier(1)

	self:MakeFloat("PrintAmount")

	self:NetworkVar("Entity", 1, "PrinterRack") --ew

	slot = 2
end

function ENT:GetUpgradeCost(lv)
	lv = lv or self:GetLevel()
	local cost = self:GetBoughtPrice() or 1000
	return cost * lv
end

local mults = {
	[1] = 1.5,
	[2] = 1.3,
	[3] = 1.15
}

function OverclockGetMult(var)
	return mults[var] or 1
end
