local seed = Inventory.ItemObjects.Seed
local bseed = Inventory.BaseItemObjects.Seed

Agriculture.Seed:NetworkVar("NetStack", function(it, write)
	print("encoding seed")
	local ns = netstack:new()

	-- result
	ns:WriteUInt(it:GetResultBase() and it:GetResultBase():GetItemID() or 0, 32)

	-- hp
	ns:WriteUInt(it:GetHealth(), 8)

	return ns
end, "EncodeSeed")