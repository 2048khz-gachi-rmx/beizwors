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
		Rate = 350,
	}, {
		Cost = 5e6,
		Rate = 700,
	}, {
		Cost = 50e6,
		Rate = 1250,
	}, {
		Cost = 300e6,
		Rate = 2000,
	}, {
		Cost = 1.5e9,
		Rate = 3000,
	}
}

function ENT:DerivedDataTables()

end

function ENT:GetTransferRate()
	return self:GetLevelData().Rate
end

function ENT:CanFromBuf(ply, itm, toInv)
	if toInv.IsBackpack then return true end
	if toInv.IsVault and self.Status:Get(itm:GetSlot(), 0) >= itm:GetTotalTransferCost() then
		return true
	end

	return false
end

function ENT:CanToBuf(ply, itm, fromInv)
	if not fromInv then
		errorNHf("something's wrong - no inv passed to ActionCanCrossInventoryTo(%s, %s, %s)", ply, itm, fromInv)
		return
	end

	if fromInv and not fromInv.IsBackpack then return false end
	-- if SERVER and not self._Allow then return false end

	return true
end

function ENT:AllowInteract(inv, ply, act, ...)
	if not self:BW_IsOwner(ply) then return false end
	if ply:Distance(self) > 192 then return false end
	if not ply:Alive() then return false end

	return true
end

-- for override
function ENT:InVaultNewItem(slot, fromInv, itm, ply) end

function ENT:CreateInventories()
	self.Inventory = {
		Inventory.Inventories.Entity:new(self)
	}

	self.InVault = self.Inventory[1]
	self.InVault.MaxItems = self.MaxQueues
	self.InVault.SupportsSplit = false
	self.InVault.ActionCanMove = false

	self.InVault.ActionCanCrossInventoryFrom = function(inv, ply, ...)
		return self:CanFromBuf(ply, ...)
	end

	self.InVault.ActionCanCrossInventoryTo = function(inv, ply, ...)
		return self:CanToBuf(ply, ...)
	end

	self.InVault:On("AllowInteract", "Distance", function(...)
		return self:AllowInteract(...)
	end)

	self.InVault:On("CrossInventoryMovedTo", "Hook", function(...)
		self:InVaultNewItem(...)
	end)

	self.Status = Networkable("MDig:" .. self:EntIndex())
	self.Status:Bind(self)
end