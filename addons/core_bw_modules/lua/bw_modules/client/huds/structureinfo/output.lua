local hud = BaseWars.HUD
local sin = hud.StructureInfo
local anim = sin.Anims

local col = Color(100, 80, 80)


--[[function sin:PaintGeneratorOutput(ent, cury)

	local w, h = self:GetSize()
	local offy = cury

	local _, th = draw.SimpleText(
			"+1000pw lol",
			"OS20", w / 2, offy, color_white, 1, 5)

	offy = offy + th

	return offy - cury
end

function sin:PaintPrinterOutput(ent, cury)
	local w, h = self:GetSize()
	local offy = cury

	local _, th = draw.SimpleText(
			"$420/s lol",
			"OS20", w / 2, offy, color_white, 1, 5)
	offy = offy + th

	offy = offy + th * 0.875

	return offy - cury
end]]

local ic = Icons.Money32:Copy()
ic:SetSize(24, 24)

function sin:PaintPrinterOutput(ent, cury)
	local scale = DarkHUD.Scale
	local w, h = self:GetSize()
	local offy = cury

	local amt = ent and ent:GetPrintAmount() or self._PrintAmt or 0
	self._PrintAmt = self._PrintAmt or amt
	anim:MemberLerp(self, "_PrintAmt", amt, 0.3, 0, 0.3)
	amt = self._PrintAmt

	local tx = ("%s%s/s."):format(Language.Currency,
		BaseWars.NumberFormat(amt or -1))

	local fnt, sz = Fonts.PickFont("BS", tx, w * 0.5, DarkHUD.Scale * 32, nil, "16")

	local icSz = math.Multiple(sz, 4)
	ic:SetSize(icSz, icSz)

	local total = ic:GetWide() + 6 * scale + surface.GetTextSizeQuick(tx, fnt)
	local x = w / 2 - total / 2
	ic:Paint(x, offy)
	x = x + ic:GetWide() + 6 * scale

	local _, th = draw.SimpleText(tx, fnt, x,
		offy, Colors.Money, 0, 5)

	offy = offy + math.max(th * 0.875, icSz)

	return offy - cury
end

function sin:PaintOutput(cury)
	local ent = self:GetEntity():IsValid() and self:GetEntity()

	self._EntType = self._EntType or ent and
		(	ent.IsGenerator and "Generator" or
			ent.IsPrinter and "Printer")

	if self._EntType and
		sin["Paint" .. self._EntType .. "Output"] then

		return sin["Paint" .. self._EntType .. "Output"](self, ent, cury)
	end

end

sin.AddPaintOp(8998, "PaintOutput", sin)