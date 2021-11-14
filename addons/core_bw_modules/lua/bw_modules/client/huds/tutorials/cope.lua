--
local tut = BaseWars.Tutorial
local ptr = tut.AddStep(3, "Upgrading")


function ptr:PaintUpgrade(cury)
	self:CompletePoint(1, BaseWars.EverUpgraded())
	return self:PaintPoints(cury)
end

ptr:AddPaint(999, "PaintFrame", ptr)
ptr:AddPaint(998, "PaintName", ptr)
ptr:AddPaint(997, "PaintUpgrade", ptr)

ptr:AddPoint(1, "Upgrade your printer by typing /upg in chat while looking at it.")