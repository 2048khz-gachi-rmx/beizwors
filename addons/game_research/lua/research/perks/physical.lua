local tree = Research.Tree:new("Physical")
tree:SetDescription("Harder, Better, Faster, Stronger")

local hp = Research.Perk:new("hp")
hp:SetName("Health Up")
hp:SetTreeName("Physical")
hp:SetColor(Color(250, 130, 130))

local hps = {
	115, 130, 145, 165, 185, 200
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

for i=1, #hps do
	local lv = hp:AddLevel(i)
	local n = i - 1
	lv:AddRequirement( reqs[i] or reqs[#reqs] )

	local tier = math.floor(n / 3)
	lv:SetPos(1 + (n * 1 + tier), 0)
	lv:SetIcon(CLIENT and Icon("https://i.imgur.com/8rDmfy5.png", "hp_up.png"))

	if n >= 3 then
		lv:AddRequirement( { Computer = 2 } )
	end

	local add = hps[i] - (hps[i - 1] or 100)
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

for i=1, 2 do
	local lv = cap:AddLevel(i)
	lv:AddRequirement( { Items = { iron_bar = i * 5, gold_bar = i * 3 } } )
	lv:AddRequirement( { Items = { zased = i } } )

	lv:SetPos(hp:GetLevel(i * 3):GetPos(), 1)
	lv:SetIcon(CLIENT and Icons.Plus)
	lv:AddPrerequisite(hp:GetLevel(i * 3))
end


if SERVER then
	include("physical_sv_ext.lua")
end