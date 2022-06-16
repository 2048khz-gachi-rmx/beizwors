include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:Draw()
	self:DrawModel()

	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), -90)

	cam.Start3D2D(self:GetPos() + ang:Right() * -8, ang, 0.1)
	xpcall(function()
		local fr, wrk = self:GetFrac()
		draw.SimpleText(("%.1f%% (%s)"):format(fr * 100, wrk), "OSB36", 0, 0, color_white, 1, 1)
	end, GenerateErrorer("overrideme"))
	cam.End3D2D()
end