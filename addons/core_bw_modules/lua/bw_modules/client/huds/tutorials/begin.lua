--

local tut = BaseWars.Tutorial
local ptr = tut.AddStep(1, "Begin")

local col = Color(230, 230, 230)

function ptr:PaintBegin(cury)
	local w, h = self:GetSize()
	local py = cury
	local tw, th = draw.SimpleText("The Basics", "BSSB24", 6 * DarkHUD.Scale, cury, col)
	cury = cury + th

	self:CompletePoint(1, not not LocalPlayer():BW_GetBase())
	return cury + self:PaintPoints(cury) - py
end

ptr:AddPaint(999, "PaintFrame", ptr)
ptr:AddPaint(998, "PaintBegin", ptr)

ptr:AddPoint(1, "Find a base")
ptr:AddPoint(2, "Claim the core")

--[[ptr:AddPoint(3, "Can i put my balls in your jaws? Can i put my balls in your jaws? " ..
	"Can i? (Can i?) Can i? (Can i?)")]]

ptr:CompletePoint(1, not not LocalPlayer():BW_GetBase())
ptr:CompletePoint(2, not not LocalPlayer():GetBase())

hook.Add("BaseClaimed", "TutorialTrack", function(base)
	if base:IsOwner(LocalPlayer()) then
		ptr:CompletePoint(2, true)
	end
end)

hook.Add("BaseUnclaimed", "TutorialTrack", function(base)
	if not LocalPlayer():GetBase() then
		ptr:CompletePoint(2, false)
	end
end)