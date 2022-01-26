local hp = Research.Perk:new("hp")
hp:SetName("Health Up")
hp:SetTreeName("Physical")
hp:SetColor(Color(250, 130, 130))

local hps = {
	5, 10, 15, 20, 25, 25
}

local totalHP = 100

for i=1, 6 do
	local lv = hp:AddLevel(i)
	lv:AddRequirement( { Items = { iron_bar = i * 5, gold_bar = i * 3 } } )

	lv:SetPos((i - 1) * 1.5, 0)
	lv:SetIcon(CLIENT and Icons.Plus)

	local add = hps[i]
	totalHP = totalHP + add

	lv:SetDescription( ("Increase your maximum HP by $%d (total: *%d)"):format(
		math.floor(add),
		math.floor(totalHP)
	) )
end

local cap = Research.Perk:new("cap")
cap:SetName("Capacity Up")
cap:SetTreeName("Physical")
cap:SetColor( Colors.Sky:Copy():MulHSV(1, 0.6, 2) )

for i=1, 3 do
	local lv = cap:AddLevel(i)
	lv:AddRequirement( { Items = { iron_bar = i * 5, gold_bar = i * 3 } } )
	lv:AddRequirement( { Items = { zased = i } } )

	lv:SetPos(i * 3, 1)
	lv:SetIcon(CLIENT and Icons.Plus)
end