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
	lv:SetIcon(CLIENT and Icon(Material("entities/acwatt_perk_fastreload.png")):SetSize(0.9, 0.9))

	if i > 3 then
		lv:AddRequirement( { Computer = 2 } )
	end

	local ch = 20 + 15 * i
	lv.TotalRate = 1 + (total + ch) / 100
	total = total + ch

	lv:SetDescription( ("Increase dispenser charge rate by ^%d%% (total: *%d%%)")
		:format(ch, lv.TotalRate * 100) )
end
