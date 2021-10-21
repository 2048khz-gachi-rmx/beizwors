local hud = BaseWars.HUD
local sin = hud.StructureInfo

local frCol = Color(25, 25, 25)
local bgCol = Color(15, 15, 15, 220)
local anim = sin.Anims

function sin:PaintFrame(cury)
	local hd = 18

	BSHADOWS.BeginShadow()
	cam.PushModelMatrix(self.Matrix) -- why
	self:SetWide(math.max(self:GetWide(), ScrW() * 0.15))

	draw.RoundedBoxEx(8, 0, cury, self:GetWide(), hd, Colors.FrameHeader, true, true)
	draw.RoundedBoxEx(8, 0, cury + hd, self:GetWide(), self:GetTall() - hd, Colors.FrameBody,
		false, false, true, true)

	BSHADOWS.EndShadow(2, 1, 1)
	cam.PopModelMatrix(self.Matrix)

	return hd + 2
end

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
	local ent = self:GetEntity():IsValid() and self:GetEntity()
	local w, h = self:GetSize()

	self._EntName = ent and (ent.PrintName or ent:GetClass()) or self._EntName

	local offy = cury

	local tw, th = draw.SimpleText(self._EntName, "OSB24",
		self:GetWide() / 2, cury, color_white, 1, 5)

	offy = offy + th + 4

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
	local barH = 16

	local tx = Language("Health",
		math.floor(self.HP), math.floor(self.MaxHP))

	txt.Text = tx

	DarkHUD.PaintBar(rounding, barX, offy, barW, barH, hpFr,
		HPBG, hpBorderCol, hpCol, txt)

	offy = offy + barH + 4

	self:SizeTo(math.max(self:GetWide(), tw), -1, 0.3, 0, 0.3)
	return offy - cury
end

sin.AddPaintOp(9999, "PaintFrame", sin)
sin.AddPaintOp(9998, "PaintName", sin)