local hud = BaseWars.HUD
local sin = hud.StructureInfo

local anim = sin.Anims

local HPBG = Color(75, 75, 75)
local hpCol = Color(240, 70, 70)
local hpBorderCol = Color(150, 30, 30)

local txt = {
	Filled = color_white,
	Unfilled = color_black,
	Text = "?",
	Font = "OSB18",
}

function sin:PaintName(cury)
	local scale = DarkHUD.Scale

	local ent = self:GetEntity():IsValid() and self:GetEntity()
	local w, h = self:GetSize()

	self._EntName = ent and (ent.PrintName or ent:GetClass()) or self._EntName

	local offy = cury

	local font, sz = Fonts.PickFont("OSB", self._EntName, w * 0.8,
		DarkHUD.Scale * 40, nil, 24)

	local tw, th = draw.SimpleText(self._EntName, font,
		self:GetWide() / 2, cury, color_white, 1, 5)

	offy = math.floor(offy + th + 2 * scale)

	-- health
	local hpFr = ent and math.min(ent:Health() / ent:GetMaxHealth(), 1) or self.HPFrac
	local hp = ent and ent:Health() or self.HP
	local maxHP = ent and ent:GetMaxHealth() or self.MaxHP

	self.HPFrac = self.HPFrac or hpFr
	self.HP = self.HP or hp
	self.MaxHP = self.MaxHP or maxHP

	anim:MemberLerp(self, "HPFrac", hpFr, 0.3, 0, 0.3)
	anim:MemberLerp(self, "HP", hp, 0.3, 0, 0.3)
	anim:MemberLerp(self, "MaxHP", maxHP, 0.3, 0, 0.3)

	hpFr = self.HPFrac

	local rounding = 8
	local barX = 8
	local barW = w - (barX * 2)

	local barH = math.ceil(28 * scale)

	local tx = Language("Health",
		math.floor(self.HP), math.floor(self.MaxHP))

	font, sz = Fonts.PickFont("OSB", self._EntName, barW * 0.8,
		barH, nil, 18)
	txt.Font = font

	txt.Text = tx


	DarkHUD.PaintBar(rounding, barX, offy, barW, barH, hpFr,
		HPBG, hpBorderCol, hpCol, txt)

	offy = offy + barH + 4

	self:SizeTo(math.max(self:GetWide(), tw), -1, 0.3, 0, 0.3)

	return offy - cury
end

sin.AddPaintOp(9999, "PaintFrame", ptr)
sin.AddPaintOp(9998, "PaintName", sin)