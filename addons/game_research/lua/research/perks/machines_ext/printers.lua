local tree = Research.Trees.Machines

local perk = Research.Perk:new("printer_tier")
perk:SetName("Printer Tier Unlock")
perk:SetTreeName("Machines")
perk:SetColor(Color(90, 230, 180))

local reqs = {
	{ Items = {
		capacitor = 25,
		wire = 25,
		circuit_board = 10,
		radiator = 5,
	} },

	{ Items = {
		nanotubes = 20,
		cpu = 3,
		ionbat = 3,
	} },
}

for i=1, 2 do
	local n = i - 1
	local lv = perk:AddLevel(i)
	lv:AddRequirement( reqs[i] or reqs[#reqs] )
	lv:SetNameFragments({
		"Printer Tier ", i+1, " Unlock"
	})

	lv:SetPos(0, -2 - n * 2)
	lv:SetIcon(CLIENT and Icons.CoinAdd)

	lv:SetDescription(function()
		local ret = ("Unlocks Tier %d printers.\n"):format(i + 1)

		return ret
	end)
end