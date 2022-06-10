local seed = Inventory.ItemObjects.Seed
local bseed = Inventory.BaseItemObjects.Seed

Agriculture.Seed:NetworkVar("NetStack", function(it, write)
	local ns = netstack:new()

	local res = it:GetResultBase() and it:GetResultBase():GetItemID() or 0

	if Inventory.Util.GetBase(res).ItemName == "coca" then
		ns:WriteBool(true)
	else
		ns:WriteBool(false)
		ns:WriteUInt(res, 15)
	end

	-- hp
	ns:WriteUInt(it:GetHealth(), 8)

	return ns
end, "EncodeSeed")


function seed:CreateResult()
	local smIt = Inventory.NewItem(self:GetResult())
	if not smIt then return end

	smIt:SetAmount(1) -- ?
	smIt:SetTypeID(self:GetTypeID())

	return smIt
end

function seed:DrainHealth()
	self:SetHealth(self:GetHealth() - 1)

	if self:GetHealth() <= 0 then
		self:Delete()
	end
end