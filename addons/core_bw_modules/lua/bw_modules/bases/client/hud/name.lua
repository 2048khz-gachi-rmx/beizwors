local bw = BaseWars.Bases
local nw = bw.NW
local hud = bw.HUD

local titleFont = "EXM36"

function hud:GetNameDT()
	if self._NameDT then return self._NameDT end

	local zone = LocalPlayer():BW_GetZone()
	local zname = zone and zone:GetName() ~= "" and zone:GetName()

	local dt = DeltaText()
		:SetFont("EXM24")

	local piece, key = dt:AddText("")
	dt._zonelesspiece = piece

	local piece, key = dt:AddText("")
	dt._zonepiece = piece

	dt.AlignY = -2 --use paint's Y as bottom

	piece:SetFont("EX18")
	piece:SetColor(Color(150, 150, 150))
	dt.BaseStarter = piece:AddFragment("(", 1)
	dt.BaseName = piece:AddFragment(zname or "", 2)
	dt.BaseEnder = piece:AddFragment(")", 3)

	if zname then
		dt:ActivateElement(dt._zonepiece)
	else
		dt:ActivateElement(dt._zonelesspiece)
	end

	self._NameDT = dt
	return dt
end

function hud:UpdateNameDT()
	-- dont remove zone if we're leaving out cuz it doesnt look good
	if self.Disappearing then return end

	local dt = self._NameDT
	local zone = LocalPlayer():BW_GetZone()
	-- make sure the zone actually belongs to this base
	local name = zone and zone:GetBase() == self:GetBase() and
		zone:GetName() ~= "" and zone:GetName()

	if name then
		dt._zonepiece:ReplaceText(2, name)
		dt:ActivateElement(dt._zonepiece)
	else
		dt:ActivateElement(dt._zonelesspiece)
	end
end

function hud:PaintName(cury)
	local base = self:GetBase()
	local bs = hud.BorderSize

	local th = draw.GetFontHeight(titleFont)
	local tx, ty = bs + 8, cury - th * 0.25 + 4

	hud.NameX = tx

	local tw, _th = draw.SimpleText(base:GetName(), titleFont,
		tx, ty, color_white, 0, 5)

	local dt = hud.GetNameDT(self)
	local dth = dt._zonepiece:GetFontHeight()
	local dty = ty + th - dth * 0.25

	hud.UpdateNameDT(self)

	dt:Paint(tx + tw + 4, dty + dth * 0.125 / 2)
	local w = dt:GetWide()

	local wantW = tw + w + tx * 2 + 4

	if self:GetWide() < wantW then
		self:SetWide(wantW)
	end

	return math.max(th * 0.875, dth)
end

hud.AddPaintOp(9998, "PaintName", hud)