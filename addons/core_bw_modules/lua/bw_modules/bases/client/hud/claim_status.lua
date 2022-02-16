local bw = BaseWars.Bases
local nw = bw.NW
local hud = bw.HUD

local titleFont = "MR36"

local flag = Icons.Flag128:Copy()
flag:SetPreserveRatio(true)
flag:SetFilter(true)

function hud:GetClaimDT()
	if self._ClaimDT then return self._ClaimDT end

	local base = self:GetBase()

	local dt = DeltaText()
		:SetFont("MRM24")

	dt.AlignY = -1
	self._ClaimDT = dt

	local piece, key = dt:AddText("")
	dt._piece = piece
	dt:CycleNext()

	piece:SetFont("MR20")
	piece:SetColor(Color(150, 150, 150))

	-- `Owned by: ` or `Not owned!`
	dt.BaseStarterID, dt.BaseStarter = piece:AddFragment("", 1)

	-- faction/player name or ""
	dt.BaseNameID, dt.BaseName = piece:AddFragment(zname or "", 2)

	hud.UpdateClaimDT(self)


	return dt
end

function hud:UpdateClaimDT()
	local dt = self._ClaimDT
	local base = self:GetBase()

	local pc = dt._piece
	pc:SetLiftStrength(-18)

	if base:GetClaimed() then
		local fac, owners = base:GetOwner()

		local name = fac and fac:GetName()
		if not fac then
			name = owners[1] and owners[1]:GetNick() or "???"
		end

		pc:ReplaceText(dt.BaseStarterID, "Owned by: ")
		local _, new = pc:ReplaceText(dt.BaseNameID, name or "[what]")
		if new then
			new.Color = (fac and fac:GetColor() or color_white):Copy()
		end
	else
		pc:ReplaceText(dt.BaseStarterID, "Not owned!")
		pc:ReplaceText(dt.BaseNameID, "")
	end
end

function hud:PaintOwner(cury)
	local x = hud.NameX + 12

	local dt = hud.GetClaimDT(self)
	local dth = dt._piece:GetFontHeight()

	local fw, fh = flag:Paint(x, cury, nil, 24)

	x = x + fw + 4

	hud.UpdateClaimDT(self)

	dt:Paint(x, cury + fh / 2)


	local w = dt:GetWide()

	local wantW = hud.NameX + 12 + fw + w + 4 * 2

	if self:GetWide() < wantW then
		self:SetWide(wantW)
	end

	--[[local w = dt:GetWide()

	local wantW = tw + w + tx * 2 + 4

	if self:GetWide() < wantW then
		self:SetWide(wantW)
	end]]

	return math.max(fh, dt._piece:GetFontHeight()) + 8
end

hud.AddPaintOp(9997, "PaintOwner", hud)
hud.RestartPainters()