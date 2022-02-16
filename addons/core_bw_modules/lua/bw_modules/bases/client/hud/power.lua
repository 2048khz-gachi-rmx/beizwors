local bw = BaseWars.Bases
local nw = bw.NW
local hud = bw.HUD

local titleFont = "MR36"

local icon = Icons.Electricity:Copy()
icon:SetPreserveRatio(true)
icon:SetFilter(true)

local lossColor = Colors.Reddish
local gainColor = Colors.Money
local neutralColor = Color(150, 150, 150)

function hud:GetPowerDT()
	if self._PowerDT then return self._PowerDT end

	local base = self:GetBase()

	local dt = DeltaText()
		:SetFont("MRM24")

	dt.AlignY = -1
	self._PowerDT = dt

	local piece, key = dt:AddText("")
	dt._acpiece = piece
	dt:CycleNext()

	piece:SetFont("EXSB20")
	piece:SetColor(neutralColor)
	piece:SetLiftStrength(-8)
	piece:SetDropStrength(8)

	local i = 0

	local tbl = {}
	dt.IDs = tbl

	local function make(tx)
		i = i + 1
		tbl[i] = piece:AddFragment(tx or "", i)
	end

	make() make(" / ") make() make(" ") make()

	local piece, key = dt:AddText("")
	dt._deacpiece = piece

	hud.UpdatePowerDT(self)
	return dt
end

function hud:UpdatePowerDT()
	local dt = self._PowerDT
	local base = self:GetBase()
	local grid = base and base:GetPowerGrid()

	if not base or not grid or not base:IsOwner(LocalPlayer()) then
		dt:ActivateElement(dt._deacpiece)
		return false
	end --idk

	dt:ActivateElement(dt._acpiece)

	local fcur, fmax, fgain = dt.IDs[1], dt.IDs[3], dt.IDs[5]
	local pc = dt._acpiece

	local cur, max = grid:GetPower(), grid:GetCapacity()
	local gain = grid:GetPowerIn() - grid:GetPowerOut()

	pc:ReplaceText(fcur, tostring(cur))
	pc:ReplaceText(fmax, tostring(max))

	local gainStr = ("(%s%d)"):format(
		gain > 0 and "+" or gain <= 0 and "", -- <0 doesnt need a "-" as it already has it
		gain)

	pc:ReplaceText(fgain, gainStr)

	local an = hud.Anims
	an:LerpColor(pc:GetColor(),
		gain > 0 and gainColor or
		gain < 0 and lossColor or neutralColor,
		0.3, 0, 0.3)

	return true
end

function hud:PaintPower(cury)
	local dt = hud.GetPowerDT(self)
	local should = hud.UpdatePowerDT(self)

	if not should then
		hud.Anims:MemberLerp(self, "_PowerFrac", 0, 0.3, 0, 0.3)
	else
		hud.Anims:MemberLerp(self, "_PowerFrac", 1, 0.3, 0, 0.3)
	end

	local fr = self._PowerFrac or 0
	local foff = - 12 + fr * 12

	local x = hud.NameX + 12

	local amult = surface.GetAlphaMultiplier()
	surface.SetAlphaMultiplier(fr * amult)

	local fw, fh = icon:Paint(x, cury + foff, nil, 20)

	x = x + fw + 4

	dt:Paint(x, cury + fh / 2 + foff)
	surface.SetAlphaMultiplier(amult)
	--[[local w = dt:GetWide()

	local wantW = tw + w + tx * 2 + 4

	if self:GetWide() < wantW then
		self:SetWide(wantW)
	end]]

	return (math.max(fh, dt._acpiece:GetFontHeight()) + 4) * (should and 1 or 0)
end

hud.AddPaintOp(9996, "PaintPower", hud)
hud.RestartPainters()