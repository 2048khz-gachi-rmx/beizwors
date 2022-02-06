--
local tree = Research.Tree:new("Machines")
tree:SetDescription("Upgrades, but better")

local spoint = Research.Perk:new("spoint")
spoint:SetName("Spawnpoint Upgrade")
spoint:SetTreeName("Machines")
spoint:SetColor(Color(90, 230, 180))

local also = {
	"Automatically *refills *your #ammo using the ammo dispenser on respawn.",
	"Automatically *refills *your ^armor *and $stims using your dispensers on respawn."
}

local reqs = {
	{ Items = {
		copper_bar = 15,
		emitter = 1,
		gold_bar = 5,
	} },

	{ Items = {
		tgt_finder = 2,
		emitter = 3,
		gold_bar = 10,
	} },
}

for i=1, 2 do
	local n = i - 1
	local lv = spoint:AddLevel(i)
	--lv:AddRequirement( reqs[i] or reqs[#reqs] )

	lv:SetPos(2 + n * 2, 0)
	lv:SetIcon(CLIENT and Icons.Plus)

	if i > 3 then
		lv:AddRequirement( { Computer = 2 } )
	end

	lv:SetDescription(function()
		local sp = scripted_ents.GetStored("bw_spawnpoint").t
		local st = sp.Levels[i + 1].SpawnTime
		st = st and st * 100 or "what"

		local ret = ("Unlocks Spawnpoint Lv. %d\n" ..
			"Respawn time: ^%s%%"):format(i + 1, st)

		if also[i] then
			ret = ret .. "\n\n" .. also[i]
		end

		return ret
	end)
end

local dcharge = Research.Perk:new("dispcharge")
dcharge:SetName("Dispenser Charge Rate")
dcharge:SetTreeName("Machines")
dcharge:SetColor(Color(230, 210, 180))

local total = 0
local reqs = {
	{ Items = {
		copper_bar = 10,
		gold_bar = 3,
	} },

	{ Items = {
		capacitor = 5,
		gold_bar = 5,
	} },

	{ Items = {
		capacitor = 10,
		emitter = 3,
		gold_bar = 5,
	} },
}

for i=1, 3 do
	local n = i - 1
	local lv = dcharge:AddLevel(i)
	--lv:AddRequirement( reqs[i] or reqs[#reqs] )

	lv:SetPos(0, 2 + n * 1.5)
	lv:SetIcon(CLIENT and Icons.Plus)

	if i > 3 then
		lv:AddRequirement( { Computer = 2 } )
	end

	local ch = 20 + 15 * i
	lv.TotalRate = 1 + (total + ch) / 100
	total = total + ch

	lv:SetDescription( ("Increase dispenser charge rate by ^%d%% (total: *%d%%)")
		:format(ch, lv.TotalRate * 100) )
end
