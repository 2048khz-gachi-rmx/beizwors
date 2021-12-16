AddCSLuaFile()

ENT.Base = "bw_base_electronics"
ENT.Type = "anim"
ENT.PrintName = "Blueprint Constructor"

ENT.Model = "models/grp/bpmachine/bpmachine.mdl"
ENT.Skin = 0

ENT.Connectable = true
ENT.Cableable = true
ENT.BlueprintConstructor = true

function ENT:DerivedDataTables()
	self:NetworkVar("Float", 1, "BPDur")
	self:NetworkVar("Float", 2, "BPStart")
	self:NetworkVar("Float", 3, "TimeLeft")

	self:NetworkVar("Bool", 2, "Active")
	self:NetworkVar("Bool", 3, "HasBP") -- use DTs to not make race conditions (inv nw vs. active)

	self:NetworkVar("Int", 2, "BPTier")
	self:NetworkVar("String", 0, "BPType")
end

function ENT:SHInit()
	self.Inventory = {Inventory.Inventories.Entity:new(self)}

	self.Storage = self.Inventory[1]
	self.Storage.MaxItems = self.Slots
	self.Storage.UseOwnership = true

	self.Storage:On("CanAddItem", "NoMoving", function(self, it)
		return it._CtorPrinted ~= nil
	end)

	self.Storage:On("CanMoveItem", "NoMoving", function(self, it)
		return false
	end)

	self.Storage:On("CrossInventoryMovedFrom", "ResetStates", function(str, itm, inv)
		self:SetActive(false)
		self:SetHasBP(false)
	end)

	self.Storage.ActionCanCrossInventoryFrom = true
	self.Storage.ActionCanCrossInventoryTo = false
	self.Storage.SupportsSplit = false
end

function ENT:TimeForTier(t)
	return 0 * (2 * t)
end

local cl = {
	"cl_creation",
	"cl_claim"
}

for k,v in pairs(cl) do
	AddCSLuaFile(v .. ".lua")
	if CLIENT then include(v .. ".lua") end
end