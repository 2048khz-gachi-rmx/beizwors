local hud = BaseWars.HUD
local sin = hud.StructureInfo
local anim = sin.Anims

local col = Color(100, 80, 80)

function sin:PaintLevel(cury)
	local scale = DarkHUD.Scale

	local ent = self:GetEntity():IsValid() and self:GetEntity()
	local w, h = self:GetSize()

	local shouldnt = ent and not ent.GetLevel
	if shouldnt then return end

	local lv = ent and ent:GetLevel()
	local mx = ent and ent.GetMaxLevel and ent:GetMaxLevel()
	local uc = ent and ent.GetUpgradeCost

	self.EntLevel = lv or self.EntLevel
	self.EntMaxLevel = mx or self.EntMaxLevel
	if uc then
		self.EntUpgCost = ent:GetUpgradeCost()
	end

	if not self.EntLevel then return end

	local offy = cury

	local lvText = Language("Level", self.EntLevel, self.EntMaxLevel)
	local lvFont, sz = Fonts.PickFont("EXSB", lvText, w,
		DarkHUD.Scale * 36, nil, "16")

	local pad = 6

	local lvW, lvH = draw.SimpleText(lvText, lvFont,
		pad, offy - sz * 0.25, color_white, 0, 5)

	if self.EntUpgCost then
		local str = Language("UpgCost", self.EntUpgCost)

		-- whats upfont
		local upFont, sz = Fonts.PickFont("EX", str, w,
			scale * 32, nil, 16)

		local tw = surface.GetTextSizeQuick(str, upFont)
		local maxW = math.max(lvW + tw + pad * 2 + scale * 16, w)

		self:SetWide(math.max(self:GetWide(), maxW))
		local _, th = draw.SimpleText(str,
			upFont, maxW - tw - pad, offy + lvH / 2 - sz * 0.25, color_white, 0, 1)

		lvH = math.max(lvH, th)
		lvW = lvW + tw + pad
	end

	offy = offy - sz * 0.25 + lvH
	self:SetWide(math.max(self:GetWide(), lvW))

	--surface.DrawLine(0, offy, 124, offy)
	return offy - cury
end

sin.AddPaintOp(8999, "PaintLevel", sin)