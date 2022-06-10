local seed = Inventory.ItemObjects.Seed
local bseed = Inventory.BaseItemObjects.Seed

Agriculture.Seed:NetworkVar("NetStack", function(it, write)
	local iid = net.ReadBool() and Inventory.Util.GetBase("coca").ItemID or net.ReadUInt(15)
	it.Data.Result = iid

	-- hp
	local hp = net.ReadUInt(8)
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

seed.AutoSepNum = 1

function seed:PostGenerateText(cloud, markup)
	local typ = self:GetType()

	if typ then
		cloud.FontShit = 0.2 -- squish the label and type together
		cloud:AddFormattedText(("Strain: %s"):format(typ.Name), Colors.LighterGray, "BSSB16", 16, nil, 1)
	end

	local hp = self:GetHealth()
	local hpt

	if hp then
		local hpFr = math.Clamp(hp / 100, 0, 1)
		local col = blend(Color(0, 0, 0), hpFr)

		local _, tbl = cloud:AddFormattedText(hp .. "% health", col, "EXSB20", nil, nil, 1)
		hpt = tbl
	end

	cloud:On("Think", "SeedUpdate", function()
		local nhp = self:GetHealth()

		if nhp ~= hp and hpt then
			local hpFr = math.Clamp(nhp / 100, 0, 1)
			hpt.Text = nhp .. "% health"
			blend(hpt.Color, hpFr)

			hp = nhp
		end
	end)
end

