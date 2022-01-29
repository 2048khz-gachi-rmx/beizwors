local hp = Research.Perk:new("hp")
hp:SetName("Health Up")
hp:SetTreeName("Physical")
hp:SetColor(Color(250, 130, 130))

local hps = {
	5, 10, 15, 20, 25, 25
}

local totalHP = 100

local reqs = {
	{ Items = {
		iron_bar = 10,
		gold_bar = 3
	} },

	{ Items = {
		copper_bar = 15,
		gold_bar = 5,
		stem_cells = 2
	} },

	{ Items = {
		gold_bar = 10,
		stem_cells = 5
	} },

	{ Items = {
		stem_cells = 15,
		blood_nanobots = 3,
		tgt_finder = 1
	} },

	{ Items = {
		stem_cells = 30,
		blood_nanobots = 10,
		tgt_finder = 3
	} },
}

for i=1, 6 do
	local lv = hp:AddLevel(i)
	lv:AddRequirement( reqs[i] or reqs[#reqs] )

	lv:SetPos((i - 1) * 1.5, 0)
	lv:SetIcon(CLIENT and Icons.Plus)

	if i > 3 then
		lv:AddRequirement( { Computer = 2 } )
	end

	local add = hps[i]
	totalHP = totalHP + add

	lv:SetDescription( ("Increase your maximum HP by $%d (total: *%d)"):format(
		math.floor(add),
		math.floor(totalHP)
	) )

	lv.TotalHP = totalHP - 100
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


if SERVER then
	include("physical_sv_ext.lua")
end