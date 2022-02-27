AddCSLuaFile()

ENT.Base = "bw_base"
ENT.Type = "anim"
ENT.PrintName = "Bruh moment"

ENT.Model = "models/maver1k_xvii/stalker/props/devices/dev_merger.mdl"
ENT.Skin = 0

ENT.CanTakeDamage = false
ENT.NoHUD = true
ENT.WantBlink = false
ENT.InteractDistance = 192

function ENT:DerivedDataTables()
	self:NetworkVar("String", 0, "PlayerName")
end

function ENT:Init()
	self.Inventory = {Inventory.Inventories.Entity:new(self)}

	self.Storage = self.Inventory[1]
	self.Storage.MaxItems = Inventory.Inventories.Backpack.MaxItems
	self.Storage.UseOwnership = false
	self.Storage.VerbosePermissions = true

	self.Storage.ActionCanCrossInventoryFrom = true
	self.Storage.ActionCanCrossInventoryTo = false

	self[Rlm() .. "_Init"] (self)

	local ent = self
	local dist = ent.InteractDistance ^ 2

	self.Storage:On("AllowInteract", "Distance", function(self, ply, act)
		local cd = ent:GetPos():DistToSqr(ply:GetPos())
		if cd > dist then return false end

		if not ply:Alive() then return end
	end)

	self.Storage:On("CanInteract", "Default", function(self, ply, act)
		print("can interact:", act, Realm())
		return true
	end)

	self.Storage.ActionCanInteract = true
end
