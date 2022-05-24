local seed = Inventory.ItemObjects.Seed
local bseed = Inventory.BaseItemObjects.Seed

Agriculture.Seed:NetworkVar("NetStack", function(it, write)
	print("reading sneed")
	local iid = net.ReadUInt(32)
	print("iid is", iid)
	it.Data.Result = iid

	-- hp
	local hp = net.ReadUInt(8)
	print("health is", hp)
	it.Data.Health = hp
end, "EncodeSeed")


local function blend(col, fr) -- blend color to health-colors (red -> yellow -> green)
	if fr < 0.5 then
		col:Lerp(math.Remap(fr, 0, 0.5, 0, 1), Colors.Red, Colors.Yellowish)
	else
		col:Lerp(math.Remap(fr, 0.5, 1, 0, 1), Colors.Yellowish, Colors.Money)
	end

	return col
end

function seed:PostGenerateText(cloud, markup)
	local hp = self:GetHealth()

	if hp then
		local hpFr = math.Clamp(hp / 100, 0, 1)
		local col = blend(Color(0, 0, 0), hpFr)

		cloud:AddFormattedText(hp .. "% health", col, "OSB18", nil, nil, 1)
	end
end

