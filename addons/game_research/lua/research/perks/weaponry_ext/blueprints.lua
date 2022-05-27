--

local bPerk = Research.Perk:new("blueprints")
Research.BlueprintPerk = bPerk

bPerk:SetName("Blueprints")
bPerk:SetTreeName("Weaponry")
bPerk:SetColor(Color(80, 150, 250))


local reqs = {
	{ Items = {
		blank_bp = 25,
		weaponparts = 1,
	} },

	{ Items = {
		blank_bp = 200,
		weaponparts = 5,
		wepkit = 2,
	} },
}

for i=1, #reqs do
	local n = i - 1
	local t = i + 1
	local lv = bPerk:AddLevel(i)
	--lv:AddRequirement( reqs[i] or reqs[#reqs] )
	lv:SetNameFragments({
		"Tier " .. t .. " Blueprint Unlock"
	})

	lv:SetPos(0, -2 - n * 2)
	lv:SetRequirements(reqs[i])

	lv:SetDescription(function()
		local ret = ("Unlocks the creation of Tier %d weapon blueprints.\n"):format(t)

		return ret
	end)

	local mx = Matrix()

	lv:On("PostPaint", "BP", function(_, btn, w, h)
		if not Inventory.BlueprintPaints[t] then return end

		mx:Reset()

		local sx, sy = btn:LocalToScreen(0, 0)

		-- pain
		mx:TranslateNumber(sx + 2, sy + 2)
		mx:ScaleNumber((w - 4) / 128, (h - 4) / 128)
		mx:TranslateNumber(-sx - 2, -sy - 2)

		-- the GOOD scaling
		btn:NoClipping(true)

		cam.PushModelMatrix(mx)
			Inventory.BlueprintPaints[t] (btn, 0, 0, 128, 128)
		cam.PopModelMatrix()
	end)
end