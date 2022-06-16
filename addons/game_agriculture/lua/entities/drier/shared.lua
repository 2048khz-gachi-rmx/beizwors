AddCSLuaFile()

local base = "bw_gtbase"
ENT.Base = base
ENT.Type = "anim"
ENT.PrintName = "Cocaine Drier"

ENT.Model = "models/craphead_scripts/the_cocaine_factory/drying_rack/drying_rack.mdl"
ENT.Skin = 0

ENT.CanTakeDamage = true
ENT.NoHUD = false
ENT.WantBlink = false

ENT.IngredientTakes = "cocaine"
ENT.CocaineDrier = true

ENT.Levels = {
	{
		Cost = 0,
	}--[[, {
		Cost = 25e6,
	}, {
		Cost = 250e6,
	}]]
}

function ENT:DerivedDataTables()
	self:BaseRecurseCall("DerivedDataTables")
	self:NetworkVar("Bool", 3, "LightsOn")
end

function ENT:CanFrom(ply, itm, toInv)
	if not toInv.IsBackpack then return false end

	return true
end

function ENT:CanTo(ply, itm, fromInv)
	if not fromInv.IsBackpack then return false end
	if itm:GetItemName() ~= self.IngredientTakes then return false end
	if itm:GetProcessed() then return false end

	return true
end

function ENT:AllowInteract(invWith, ply, itm, invFrom)
	if not ply:Alive() then return false end
	if ply:Distance(self) > 192 then return false end

	return true
end

function ENT:InNewItem(inv, itm, fromInv, slot, fromSlot, ply) end
function ENT:InTakeItem(inv, itm, toInv, slot, fromSlot, ply) end
function ENT:InMovedItem(inv, it, slot, it2, b4slot, ply) end

function ENT:CreateInventories()
	self.Inventory = {
		Inventory.Inventories.Entity:new(self)
	}

	self.Buf = self.Inventory[1]
	self.Buf.MaxItems = self.Levels[#self.Levels].Slots
	self.Buf.SupportsSplit = false
	self.Buf.ActionCanMove = true

	self.Buf.ActionCanCrossInventoryFrom = function(inv, ply, ...)
		return self:CanFrom(ply, ...)
	end

	self.Buf.ActionCanCrossInventoryTo = function(inv, ply, ...)
		return self:CanTo(ply, ...)
	end

	self.Buf:On("AllowInteract", "Distance", function(...)
		return self:AllowInteract(...)
	end)

	self.Buf:On("CrossInventoryMovedTo", "Hook", function(...)
		self:InNewItem(...)
	end)

	self.Buf:On("CrossInventoryMovedFrom", "Hook", function(...)
		self:InTakeItem(...)
	end)
end

function ENT:SHInit()
	self:CreateInventories()
end

function ENT:GetWorkTime()
	return 5
end

function ENT:ShouldHalt()
	if not self:IsPowered() then return true end
	if not self.Buf:GetItemInSlot(1) then return true end
	if not self:GetLightsOn() then return true end
	if self.Buf:GetItemInSlot(1):GetProcessed() then return true end

	return false
end