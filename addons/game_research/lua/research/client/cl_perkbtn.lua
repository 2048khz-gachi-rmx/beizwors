--

local PERK = {}
local bg = Color(255, 0, 0)

function PERK:Init()
	self:SetText("")
	self.DownFracTime = 0.3
	self.SelFrac = 0

	self.bgColor = bg -- do not use self:GetColor(), worst mistake of my life
end


local hov = Color(60, 160, 250, 60)
local sel = Color(60, 160, 250):MulHSV(1, 0.7, 1)

local tcol = Color(0, 0, 0)

local mx = Matrix()

function PERK:Paint(w, h)
	self:HoverLogic(self:GetDisabled(), w, h)

	local hf = math.max(self.SelFrac, self.HoverFrac)
	local df = self.DownFrac

	if hf > 0 or df > 0 or self.Selected then
		if self.Selected then df = 1 end

		tcol:Set(hov)
		draw.LerpColor(df, tcol, sel, hov)

		local fr = hf + self.SelFrac * 0.5 - self.DownFrac
		if self.Selected then
			fr = 1 + self.SelFrac * 0.5 + (self.DownFrac ^ 0.4) * 0.5
		end

		local sx, sy = self:LocalToScreen(w / 2, h / 2)
		mx:Reset()
		mx:TranslateNumber(sx, sy)
		mx:ScaleNumber(0.95 + fr * 0.125, 0.95 + fr * 0.125, 1)
		mx:TranslateNumber(-sx, -sy)

		cam.PushModelMatrix(mx)
			tcol:SetDraw()
			draw.DrawMaterialCircle(w / 2, h / 2, h)
		cam.PopModelMatrix()
	end

	self.bgColor:SetDraw()
	draw.DrawMaterialCircle(w / 2, h / 2, h)

	if self.Icon then
		local iw, ih = self.Icon:GetSize()

		self.Icon:Paint(w / 2, h / 2, w * iw, h * ih)
	end
end

function PERK:SetLevel(level)
	local ic = level:GetIcon()
	if ic then
		self.Icon = ic:Copy()
		self.Icon:SetAlignment(5)
	end

	self.Perk = level
	self.Level = level
end

function PERK:Deselect(another)
	if not self.Selected then print("already deselected") return end

	self.Selected = false
	self:Emit("Deselect", self.Perk, another)
	self:To("SelFrac", 0, 0.3, 0, 0.3)
end

function PERK:Select()
	if self.Selected then return end

	self.Selected = true
	self:Emit("Select", self.Perk)
	self:To("SelFrac", 1, 0.3, 0, 0.3)
end

function PERK:DoClick()
	if not self.Selected then
		self:Select()
	else
		self:Deselect()
	end
end

vgui.Register("ResearchPerk", PERK, "FButton")