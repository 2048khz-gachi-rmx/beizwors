setfenv(1, _G)

local tut = BaseWars.Tutorial
local ptr = tut.AddStep(3, "Cope")

local col = Color(230, 230, 230)

function ptr:PaintBuy(cury)
	local w, h = self:GetSize()
	local py = cury
	local tw, th = draw.SimpleText("cope & mald", "BSSB24",
		6 * DarkHUD.Scale, cury, col)
	cury = cury + th

	return cury + self:PaintPoints(cury) - py
end

ptr:AddPaint(999, "PaintFrame", ptr)
ptr:AddPaint(998, "PaintBuy", ptr)

ptr:AddPoint(1, "Delete Garry's Mod")
--ptr:CompletePoint(1, true)