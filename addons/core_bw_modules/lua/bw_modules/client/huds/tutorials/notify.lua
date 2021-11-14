local tut = BaseWars.Tutorial
local ptr = tut.AddStep(0, "Notify")

local col = Color(230, 230, 230)

function ptr:PaintNag(cury)
	local w, h = self:GetSize()
	local py = cury
	local tw, th = draw.SimpleText("Tutorial available!", "BSSB24", 6 * DarkHUD.Scale, cury, col)
	cury = cury + th

	return cury + self:PaintPoints(cury) - py
end

ptr:AddPaint(999, "PaintFrame", ptr)
ptr:AddPaint(998, "PaintNag", ptr)

ptr:AddPoint(1, "Check out the tutorial tab in F3.")

hook.Add("BW_TutorialBegin", "MarkTutorial", function()
	ptr:CompletePoint(1, true)
end)

hook.Add("BW_TutorialSkip", "MarkTutorial", function()
	ptr:CompletePoint(1, true)
end)