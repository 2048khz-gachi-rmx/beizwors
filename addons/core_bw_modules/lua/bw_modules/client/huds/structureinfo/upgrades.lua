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
	local uc = ent and ent.GetUpgradeCost and ent:GetUpgradeCost()

	self.EntLevel = lv or self.EntLevel
	self.EntMaxLevel = mx or self.EntMaxLevel
	self.EntUpgCost = uc or self.EntUpgCost

	if not self.EntLevel then return end

	local offy = cury

	local _, th = draw.SimpleText(
		Language("Level", self.EntLevel, self.EntMaxLevel),
		"OS20", w / 2, offy, color_white, 1, 5)

	offy = offy + th

	if self.EntUpgCost then
		local _, th = draw.SimpleText(
			Language("UpgCost", self.EntUpgCost),
			"OS20", w / 2, offy, color_white, 1, 5)

		offy = offy + th
	end

	local lvText = Language("Level", self.EntLevel, self.EntMaxLevel)
	local lvFont = Fonts.PickFont("BSB", lvText, w,
		DarkHUD.Scale * 32, nil, "16")

	local pad = 6

	local lvW, lvH = draw.SimpleText(lvText, lvFont,
		pad, offy, color_white, 0, 5)

	if self.EntUpgCost then
		local str = Language("UpgCost", self.EntUpgCost)

		-- whats upfont
		local upFont = Fonts.PickFont("BS", str, w,
			scale * 28, nil, 16)

		local tw = surface.GetTextSizeQuick(str, upFont)
		local maxW = math.max(lvW + tw + pad * 2 + scale * 16, w)

		self:SetWide(math.max(self:GetWide(), maxW))
		local _, th = draw.SimpleText(str,
			upFont, maxW - tw - pad, offy + lvH / 2, color_white, 0, 1)

		lvH = math.max(lvH, th)
		lvW = lvW + tw + pad
	end

	offy = offy + lvH
	self:SetWide(math.max(self:GetWide(), lvW))

	return offy - cury
end

sin.AddPaintOp(8999, "PaintLevel", sin)