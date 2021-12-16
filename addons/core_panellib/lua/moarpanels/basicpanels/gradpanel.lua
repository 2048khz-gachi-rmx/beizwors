
local PANEL = {}

function PANEL:Init()
	self.GradColor = Color(10, 10, 10, 250)
	self.Color = Color(200, 200, 200)
	self.GradSize = 4
end

function PANEL:SetColor(col, g, b, a)
	if IsColor(col) then
		self.Color = col
		return
	end

	local c = self.Color
	c.r = col or 70
	c.g = g or 70
	c.b = b or 70
	c.a = a or 255
end

vgui.ToPrePostPaint(PANEL)

function PANEL:Draw(w, h)
	if self.NoDraw or self.NoDrawBG then return end

	surface.SetDrawColor(self.Color:Unpack())
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(self.GradColor:Unpack())
	self:DrawGradientBorder(w, h, self.GradSize, self.GradSize)
end

vgui.Register("GradPanel", PANEL, "Panel")