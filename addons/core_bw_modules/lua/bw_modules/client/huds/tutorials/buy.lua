--
setfenv(1, _G)

local tut = BaseWars.Tutorial
local ptr = tut.AddStep(2, "Buy")

local col = Color(230, 230, 230)

function ptr:PaintBuy(cury)
	local w, h = self:GetSize()
	local py = cury
	local tw, th = draw.SimpleText("Purchasing", "BSSB24",
		6 * DarkHUD.Scale, cury, col)
	cury = cury + th

	self:CompletePoint(1, spawnmenu.BaseWarsOpened)
	return cury + self:PaintPoints(cury) - py
end

ptr:AddPaint(999, "PaintFrame", ptr)
ptr:AddPaint(998, "PaintBuy", ptr)

ptr:AddPoint(1, "Check the BaseWars tab in your spawnmenu")
ptr:AddPoint(2, "Buy a Manual Generator from the Entities tab")
ptr:AddPoint(3, "Buy a Manual Printer from the Printers tab")

hook.Add("EntityOwnershipChanged", "TrackBuyTutorial", function(ply, ent)
	if ply ~= LocalPlayer() then return end

	if ent.IsManualGen then
		ptr:CompletePoint(2, true)
	elseif ent.IsManualPrinter then
		ptr:CompletePoint(3, true)
	end
end)