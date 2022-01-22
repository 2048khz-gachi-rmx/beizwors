--

Dash.Icon = Icon("https://i.imgur.com/mClnf6i.png", "ffw_64.png")
	:SetAlignment(5)

local handle = BSHADOWS.GenerateCache("DarkHUD_Dash", 128, 128)

handle:SetGenerator(function(self, w, h)
	if not Dash.Icon:GetMaterial() then return false end

	surface.SetDrawColor(255, 255, 255)
	Dash.Icon:Paint(w / 2, h / 2, w, w * 0.75)

	return true
end)

local spr = {16, 8}

function Dash.PaintAbility(fr, x, y, sz)
	handle:CacheRet(4, spr, 4)
	handle:Paint(x, y, sz, sz)
	Dash.Icon:Paint(x + sz / 2, y + sz / 2, sz, sz * 0.75)
end