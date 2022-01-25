local hp = Research.Perk:new("hp")
hp:SetName("Health Up")
hp:SetTreeName("Physical")

for i=1, 5 do
	local lv = hp:AddLevel(i)
	lv:AddRequirement( { Items = { iron_bar = i * 5, gold_bar = i * 3 } } )
	lv:AddRequirement( { Items = { zased = i } } )
end