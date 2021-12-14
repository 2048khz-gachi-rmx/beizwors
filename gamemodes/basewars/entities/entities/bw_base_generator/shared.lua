AddCSLuaFile()
ENT.Base = "bw_base_upgradable"
ENT.Type = "anim"
ENT.PrintName = "Base Generator"

ENT.Model = "models/props_wasteland/laundry_washer003.mdl"
ENT.Skin = 0

ENT.IsGenerator = true
ENT.IsElectronic = false
ENT.PowerType = "Generator"
ENT.MaxLevel = 3

ENT.PowerGenerated = 15
ENT.PowerCapacity = 1000
ENT.TransmitRadius = 600
ENT.TransmitRate = 20
ENT.ConnectDistance = 600

ENT.Cableable = true


Generators = Generators or {}
ENT._UsesNetDTNotify = true

function ENT:DerivedGenDataTables()

end

function ENT:DerivedDataTables()
	self:DerivedGenDataTables()
end

function ENT:OnFinalUpgrade()
	local base = scripted_ents.GetStored(self:GetClass()).t.PowerGenerated
	self.PowerGenerated = base * self:GetLevel()
	self:EmitSound("replay/rendercomplete.wav")

	if SERVER and self:GetPowerGrid() then
		self:GetPowerGrid():UpdatePowerIn()
	end
end

function ENT:GetUpgradeCost(lv)
	lv = lv or self:GetLevel()
	local cost = self:GetBoughtPrice() or 1000
	return cost * (2 ^ lv)
end

function ENT:IsPowered()
	return true
end

ENT.GetPower = ENT.IsPowered