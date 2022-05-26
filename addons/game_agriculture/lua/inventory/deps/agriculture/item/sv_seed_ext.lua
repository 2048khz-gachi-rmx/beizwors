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


function seed:CreateResult()
	local smIt = Inventory.NewItem(self:GetResult())
	if not smIt then return end

	smIt:SetAmount(1) -- ?

	return smIt
end

function seed:DrainHealth()
	self:SetHealth(self:GetHealth() - 1)

	if self:GetHealth() <= 0 then
		self:Delete()
	end
end