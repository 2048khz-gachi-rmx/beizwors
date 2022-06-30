Agriculture = Agriculture or {}



-- this is not the best way to do this stuff...
-- keep in mind numIDs are used in storage; changing them will change all stored items too

Agriculture.CocaineTypes = {}
local coc = Agriculture.CocaineTypes

coc[1] = {
	Name = "Thorny", -- rage
	Result = "Roid Rage",
	Description = "Increases damage. Beebis pebis bebis benib bibbababab. Bebibab.",
	Color = Color(255, 160, 160),
	TextColor = Color(210, 80, 80),
}

coc[2] = {
	Name = "Remedial", -- regen
	Result = "Mending",
	Color = Color(200, 255, 200)
}

coc[3] = {
	Name = "Vigorous", -- steroid
	Result = "Steroid",
	Color = Color(190, 240, 255),
}

coc[4] = {
	Name = "Stout", -- adrenaline
	Result = "Adrenaline",
	Color = Color(250, 250, 215),
	TextColor = Color(255, 255, 120),
}

coc[5] = {
	Name = "Numbing", -- painkiller
	Result = "Methadone",
	Color = Color(120, 180, 215),
}

for k,v in ipairs(coc) do
	coc[v.Name] = v
	coc[v.Result] = v
	v.ID = k
end



-- Thorny (=> Roid Rage)
do
	local key = "Thorny"
	local DRUG = coc[key]

	function DRUG.GetStrength(n)
		return 0.3 * n
	end

	function DRUG.Markup(mup, desc, str)
		local numCol, notNumCol, textCol = unpack(Inventory.Modifiers.DescColors)

		desc.Font = "OS18"
		desc:SetColor(textCol)

		local tx = desc:AddText("Increases your damage dealt by ")

		local tx2 = desc:AddText(math.Round(DRUG.GetStrength(str) * 100, 1))
		tx2.color = DRUG.TextColor or DRUG.Color
		desc.pt = tx2

		desc:AddText("%.")
	end

	function DRUG.UpdateMarkup(mup, desc, str)
		desc.pt.text = tostring(math.Round(DRUG.GetStrength(str) * 100, 1))
		desc:Recalculate()
	end
end

-- Remedial (=> Mending)
do
	local key = "Remedial"
	local DRUG = coc[key]
	DRUG.Description = "regens hp (add desc later)"

	function DRUG.GetStrength()

	end

	--[[function DRUG.Markup(mup, desc, str)

	end]]

	function DRUG.UpdateMarkup(mup, desc, str)

	end
end

-- Vigorous (=> Steroid)
do
	local key = "Vigorous"
	local DRUG = coc[key]

	function DRUG.GetStrength()

	end

	function DRUG.Markup(mup, desc, str)

	end

	function DRUG.UpdateMarkup(mup, desc, str)

	end
end

-- Stout (=> Adrenaline)
do
	local key = "Stout"
	local DRUG = coc[key]

	function DRUG.GetStrength(n)
		return math.Round(50 * n)
	end

	function DRUG.Markup(mup, desc, str)
		local numCol, notNumCol, textCol = unpack(Inventory.Modifiers.DescColors)

		desc.Font = "OS18"
		desc:SetColor(textCol)

		local tx = desc:AddText("Increases maximum health by ")

		local tx2 = desc:AddText(DRUG.GetStrength(str))
		tx2.color = DRUG.TextColor or DRUG.Color
		desc.pt = tx2

		desc:AddText(".")
	end

	function DRUG.UpdateMarkup(mup, desc, str)
		desc.pt.text = tostring(DRUG.GetStrength(str))
		desc:Recalculate()
	end
end

-- Numbing (=> Methadone)
do
	local key = "Numbing"
	local DRUG = coc[key]

	function DRUG.GetStrength(n)
		return 0.333 * n
	end

	function DRUG.Markup(mup, desc, str)
		local numCol, notNumCol, textCol = unpack(Inventory.Modifiers.DescColors)

		desc.Font = "OS18"
		desc:SetColor(textCol)

		local tx = desc:AddText("Decreases damage taken by ")

		local tx2 = desc:AddText(math.Round(DRUG.GetStrength(str) * 100, 1))
		tx2.color = DRUG.TextColor or DRUG.Color
		desc.pt = tx2

		desc:AddText("%.")
	end

	function DRUG.UpdateMarkup(mup, desc, str)
		desc.pt.text = tostring(math.Round(DRUG.GetStrength(str) * 100, 1))
		desc:Recalculate()
	end
end

function Agriculture.CocaineIDToName(id)
	return coc[id] and coc[id].Result
end

function Agriculture.CocaineIDToLeaf(id)
	return coc[id] and coc[id].Name
end

function Agriculture.CocaineNameToID(name)
	return coc[name] and coc[name].ID
end

function Agriculture.GetDrug(by)
	return coc[by]
end

do return end

local s = [[
-- %s (=> %s)
do
	local key = "%s"
	local DRUG = coc[key]

	function DRUG:GetStrength()

	end

	function DRUG:Markup(mup, desc, str)

	end
end
]]

for k,v in ipairs(coc) do
	print(s:format(v.Name, v.Result, v.Name))
end