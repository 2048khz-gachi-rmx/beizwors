--

local gen = Inventory.GetClass("item_meta", "generic_item")
local eq = Inventory.ItemObjects.Equippable or gen:Extend("Equippable")

eq.IsEquippable = true

-- give these functions to generic so all the other items
-- also have this method (to return nil)

BaseItemAccessor(gen, "IsEquippable", "Equippable")
BaseItemAccessor(eq, "EquipSlot", "EquipSlot")

ChainAccessor(eq, "Equipped", "Equipped")
eq.IsEquipped = eq.GetEquipped

function eq:Unequip(ply, slot, intoInv)
	local char = Inventory.GetEquippableInventory(ply)
	if not char then errorf("What the fuck can't equip on %s cuz no character inventory", ply) end

	local mem = char:Unequip(self, slot, intoInv)

	mem:Then(function()
		self:SetEquipped(false)
	end)

	return mem
end

function eq:Equip(ply, slot)
	local char = Inventory.GetEquippableInventory(ply)
	if not char then errorf("What the fuck can't equip on %s cuz no character inventory", ply) end

	local mem = char:Equip(self, slot)
	mem:Then(function()
		self:SetSlot(slot)
		self:SetEquipped(true)
	end)

	return mem
end


eq:Register()