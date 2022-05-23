local tree = Research.Trees.Machines

local perk = Research.Perk:new("turrets_tier")
perk:SetName("Turret Unlock")
perk:SetTreeName("Machines")
perk:SetColor(Color(90, 230, 180))

local reqs = {
	{ Items = {
		wire = 15,
		circuit_board = 10,
		laserdiode = 5,
		lube = 3,
		weaponparts = 3,
	} },

	{ Items = {
		laserdiode = 20,
		cpu = 3,
		tgt_finder = 3,
		wepkit = 3,
	} },
}

local names = {
	"Rifle",
	"Sniper",
}

for i=1, #names do
	local n = i - 1
	local lv = perk:AddLevel(i)
	lv:AddRequirement( reqs[i] or reqs[#reqs] )
	lv:SetNameFragments({
		names[i] .. " Turret Unlock"
	})

	lv:SetPos(-2, -2 - n * 2)
	lv:SetIcon(CLIENT and Icon("https://i.imgur.com/iB2uxxG.png", "sentry64.png")
		:SetPreserveRatio(true)
		:SetRatioSize(64, 56)
	)

	lv:SetDescription(function()
		local ret = ("Unlocks the %s turret.\n"):format(names[i])

		return ret
	end)
end