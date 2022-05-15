local hud = BaseWars.HUD
local sin = hud.StructureInfo
local anim = sin.Anims

local lvCol = Color(200, 200, 200)
local upgCol = Color(200, 200, 200)

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

	if lv == 1 and mx == 1 then return end

	if uc then
		self.EntUpgCost = ent:GetUpgradeCost() or self.EntUpgCost
	end

	if not self.EntLevel then return end

	local offy = cury

	local lvText = Language("Level", self.EntLevel, self.EntMaxLevel)
	local lvFont, sz, lvW = Fonts.PickFont("EXSB", lvText, w,
		DarkHUD.Scale * 36, nil, "16")

	local pad = 6

	if lv == mx and lv and mx then
		anim:MemberLerp(self, "_lvCenter", 1, 0.3, 0, 0.3)
	elseif lv and mx then
		anim:MemberLerp(self, "_lvCenter", 0, 0.3, 0, 0.3)
	end

	local lvc = self._lvCenter or 0
	local lvpad = Lerp(lvc, 6, w / 2 - lvW / 2)
	lvCol:Lerp(lvc, color_white, Colors.Yellowish)
	upgCol:Lerp(lvc, Colors.DarkerWhite, Colors.Money)

	local lvW, lvH = draw.SimpleText(lvText, lvFont,
		lvpad, offy - sz * 0.25, lvCol, 0, 5)

	if self.EntUpgCost and lvc < 1 then
		upgCol.a = upgCol.a * (1 - lvc)
		local str = Language("UpgCost", self.EntUpgCost)

		-- whats upfont
		local upFont, sz = Fonts.PickFont("EX", str, w,
			scale * 32, nil, 16)

		local tw = surface.GetTextSizeQuick(str, upFont)
		local maxW = math.max(lvW + tw + pad * 2 + scale * 16, w)

		self:SetWide(math.max(self:GetWide(), maxW))
		local _, th = draw.SimpleText(str,
			upFont, maxW - tw - pad, offy + lvH / 2 - sz * 0.25, upgCol, 0, 1)

		lvH = math.max(lvH, th)
		lvW = lvW + tw + pad
	end

	offy = offy - sz * 0.25 + lvH
	self:SetWide(math.max(self:GetWide(), lvW))

	--surface.DrawLine(0, offy, 124, offy)
	return offy - cury
end

sin.AddPaintOp(8999, "PaintLevel", sin)