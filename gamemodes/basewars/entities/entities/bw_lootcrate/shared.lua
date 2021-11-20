AddCSLuaFile()

ENT.Base = "bw_base_template"
ENT.Type = "anim"
ENT.PrintName = "Loot Crate"

ENT.Skin = 0

ENT.CanTakeDamage = true
ENT.NoHUD = true
ENT.Model = false


ENT.SizeInfo = {
	"small", "medium", "big", "large"
}

ENT.TypeInfo = {
	weapon = {
		models = {
			medium = {
				"models/props/de_prodigy/ammo_can_02.mdl",
			}
		},
	},

	scraps = {
		models = {
			small = {
				"models/props_c17/BriefCase001a.mdl",
				"models/props_c17/SuitCase_Passenger_Physics.mdl",
				"models/props/cs_office/Cardboard_box03.mdl",
				"models/props_junk/cardboard_box004a.mdl",
			},

			medium = {
				"models/props_junk/cardboard_box001a.mdl",
				"models/props_c17/suitcase001a.mdl",
				"models/Items/item_item_crate.mdl",
			}
		},
	},
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


function ENT:SetSpawnInfo(typ, size)
	if not self.TypeInfo[typ] then
		errorf("no such type: %s", typ)
		return
	end

	if not self.TypeInfo[typ].models[size] then
		errorf("no such size for type %s: %s", typ, size)
		return
	end

	self.CrateType = typ
	self.Size = size
end

function ENT:GetTypeInfo()
	local typ = self.CrateType or "scraps"

	return self.TypeInfo[typ]
end

function ENT:PreInit()
	if not self.Inventory and SERVER then
		error("forgot to create inventory :skull:")
		return
	end


	self.CrateType = self.CrateType or "scraps"
	self.Size = self.Size or "small"


	if not self.Model then
		local mTbl = self:GetTypeInfo().models[self.Size]
		self.Model = mTbl[math.random(#mTbl)]
	end
end

function ENT:UpdateTransmitState()
	return self.Ready and TRANSMIT_PVS or TRANSMIT_NEVER
end

function ENT:SHInit()

end