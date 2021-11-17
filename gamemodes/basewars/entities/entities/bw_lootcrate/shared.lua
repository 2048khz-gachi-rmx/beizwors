AddCSLuaFile()

ENT.Base = "bw_base_template"
ENT.Type = "anim"
ENT.PrintName = "Loot Crate"

ENT.Skin = 0

ENT.CanTakeDamage = true
ENT.NoHUD = true
ENT.Model = false

ENT.SmallModels = {
	"models/props_junk/cardboard_box004a.mdl",
	"models/props_junk/cardboard_box003a.mdl",
}

ENT.MediumModels = {
	"models/props_junk/cardboard_box003a.mdl", -- overlap intentional
	"models/props_junk/cardboard_box001a.mdl",
	"models/props_junk/cardboard_box002a.mdl",
}

ENT.SpecialModels = {
	weapon = "models/props/de_prodigy/ammo_can_02.mdl",

	scraps = {
		"models/props_c17/BriefCase001a.mdl",
		"models/props_c17/SuitCase_Passenger_Physics.mdl",
	}
	-- nuclear = "models/props/de_train/barrel.mdl",

}

-- todo: models/props/de_train/processor.mdl

function ENT:CreateInventory()
	self.Inventory = {Inventory.Inventories.Entity:new(self)}

	self.Storage = self.Inventory[1]
	self.Storage.DisallowAllActions = true
	self.Storage.MaxItems = 10
	self.Storage.UseOwnership = false
end

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "LockLevel")
end

function ENT:Ready()
	self.Ready = true
end

function ENT:PreInit()
	if not self.Inventory and SERVER then
		error("forgot to create inventory :skull:")
		return
	end

	self.Model = self.SmallModels[math.random(#self.SmallModels)]
end

function ENT:UpdateTransmitState()
	return self.Ready and TRANSMIT_PVS or TRANSMIT_NEVER
end

function ENT:SHInit()

end