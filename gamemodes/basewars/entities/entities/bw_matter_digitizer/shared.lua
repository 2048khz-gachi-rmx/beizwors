AddCSLuaFile()

ENT.Base = "bw_base_upgradable"
ENT.Type = "anim"
ENT.PrintName = "Matter Digitizer"

ENT.Model = "models/props_combine/combine_mortar01b.mdl"
ENT.Skin = 0

ENT.CanTakeDamage = true
ENT.IsMatterDigitizer = true
ENT.MaxQueues = 3
ENT.IdleRate = 10

ENT.SubModels = {
	{
		Ang      = Angle (  0.047310583293438, -89.875785827637   , - 0.21090526878834 ),
		Material = "",
		Model    = "models/props_combine/breenconsole.mdl",
		Pos      = Vector (-32.690765380859   ,   1.6189754009247  , - 0.94484406709671 )
	}, {
		Ang      = Angle (  89.980911254883  , -179.87663269043   ,    0               ),
		Material = "",
		Model    = "models/props_combine/combinebutton.mdl",
		Pos      = Vector (-  0.28220677375793,    2.2998285293579 ,   42.15901184082   )
	}
}

ENT.Levels = {
	{
		Cost = 0,
		Rate = 200,
	}, {
		Cost = 5e6,
		Rate = 500,
	}, {
		Cost = 50e6,
		Rate = 850,
	}, {
		Cost = 300e6,
		Rate = 1200,
	}, {
		Cost = 1.5e9,
		Rate = 1750,
	}
}

function ENT:DerivedDataTables()

end

function ENT:GetTransferRate()
	return self:GetLevelData().Rate
end

function ENT:CanFromBuf(inv, ply, itm, toInv)
	if toInv.IsBackpack then return true end
	if toInv.IsVault and self.Status:Get(itm:GetSlot(), 0) >= itm:GetTotalTransferCost() then
		return true
	end

	return false
end

function ENT:CanToBuf(inv, ply, itm, toInv)
	if toInv and not toInv.IsBackpack then return false end
end

function ENT:CreateInventories()
	self.Inventory = {
		Inventory.Inventories.Entity:new(self)
	}

	self.InVault = self.Inventory[1]
	self.InVault.MaxItems = self.MaxQueues
	self.InVault.SupportsSplit = false

	self.InVault.ActionCanCrossInventoryFrom = function(...)
		return self:CanFromBuf(...)
	end

	self.InVault.ActionCanCrossInventoryTo = function(inv, ply, ...)
		return self:CanToBuf(...)
	end

	self.want = {}

	self.Status = Networkable("MDig:" .. self:EntIndex())
	self.Status:Bind(self)
end