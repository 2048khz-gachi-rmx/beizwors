--

local TAB = {}
local inacCol = Color(90, 90, 90)
local hovCol = Color(135, 135, 135)
local acCol = Color(50, 180, 250)

function TAB:Init()
	self.TextCol = inacCol:Copy()
	self.Active = false
	self.BaseClass.SetText(self, "")

	self:SetFont("OSB72")
end

ChainAccessor(TAB, "Text", "Text")

function TAB:Paint(w, h)
	self:HoverAnim()

	if not self.Active then
		self.TextCol:Lerp(self.HovFrac, inacCol, hovCol)
	end

	self:LerpColor(self.TextCol, self.Active and acCol or inacCol, 0.3, 0, 0.3)

	draw.SimpleText(self:GetText(), self:GetFont(), 0, 0, self.TextCol)
end

function TAB:SizeToContents()
	self:SetWide(surface.GetTextSizeQuick(self:GetText(), self:GetFont()))
end

function TAB:IsHovered()
	return self.Hovered
end

vgui.Register("BW_LeaderboardTab", TAB, "DButton")

function TAB:SetActive(b)
	if self.Active == b then return end
	self.Active = b

	self:Emit(b and "Activate" or "Deactivate")
end

function TAB:DoClick()
	self:SetActive(true)
end

local CANV = {}

function CANV:Init()
	self.AvPool = {}
	self.NamePool = {}
end

function CANV:GetPlayerName(sid, fnt, w)
	if not self.NamePool[sid] then
		self.NamePool[sid] = "loading..."

		steamworks.RequestPlayerInfo(sid, function(name)
			if #name == 0 then
				name = "<" .. sid .. ">"
			end

			name = util.FilterText(name, TEXT_FILTER_NAME)
			self.NamePool[sid] = string.MaxFits(name, w, fnt)
		end)

		return self.NamePool[sid]
	end

	return self.NamePool[sid]
end

function CANV:GetAvatar(k, sid)
	local cache = self.AvPool[k]
	if cache then
		local prev = cache[2]
		if prev ~= sid then
			cache[1]:SetSteamID(sid, 128)
			cache[2] = sid
		end
		return cache[1]
	end

	local av = vgui.Create("CircularAvatar", self)
	self.AvPool[k] = {av, sid}

	av:SetSteamID(sid, 128)

	av.Corners[2] = false
	av.Corners[4] = false

	av:SetPaintedManually(true)
	av:Hide()

	return av
end

local moneyCol = Color(150, 200, 150)

function CANV:PaintPlayer(k, x, y, rw, rh, dat, is_me)
	self:To("pmon" .. k, dat.money, 1.2, 0, 0.2)
	local money = self["pmon" .. k] or 0

	local av = self:GetAvatar(k, dat.sid)
	local asz = rh
	local apad = 0

	av:SetSize(asz, asz)
	av:SetPos(x + apad, y + apad)

	if is_me then
		local bsz = 4
		draw.RoundedBox(16, x, y, rw, rh, Colors.Sky)
		draw.RoundedBox(16, x + bsz, y + bsz, rw - bsz * 2, rh - bsz * 2, Colors.Gray)
	else
		draw.RoundedBox(16, x, y, rw, rh, is_me and Colors.Sky or Colors.Gray)
	end

	av:PaintAt(x + apad, y + apad)

	local nameFont = "EXM40"
	local th = draw.GetFontHeight(nameFont)

	local moneyFont = "EXSB36"
	local mth = draw.GetFontHeight(moneyFont)

	local ty = y + rh / 2 - (th + mth) / 2

	draw.SimpleText(self:GetPlayerName(dat.sid, nameFont, rw - asz - 24), nameFont, x + asz + 12, ty, color_white)
	draw.SimpleText(Language("Money", money), moneyFont, x + asz + 12, ty + th * 0.875, moneyCol)
end

function CANV:PaintRT(w, h)
	local nw = BW.Leaderboard.NW
	if not nw then return end

	local y = math.floor(h * 0.05)
	local inY = y
	local off = h * 0.05
	local col = math.floor(w * 0.07)
	local colSz = (w - col * 2.2) / 2

	local wantRows = 5
	local pad = 16
	local needH = math.floor( (h - inY - off) / wantRows ) - pad

	local mySid = CachedLocalPlayer():SteamID64()
	local have_me = false

	for k,v in ipairs(nw:GetNetworked()) do
		local is_me = v.sid == mySid
		if is_me then have_me = k break end
	end

	--[[if have_me then
		wantRows = 5
		needH = math.floor( (h - inY - off) / wantRows ) - pad
	end]]

	for k,v in ipairs(nw:GetNetworked()) do
		local is_me = k == have_me

		self:PaintPlayer(k, col, y, colSz, needH, v, is_me)
		y = y + needH + pad

		if y > h - off - needH then
			col = w - col - colSz
			y = inY
		end
	end
end

BW.Leaderboard.LastUpdate = 0

function CANV:Paint(w, h)
	self.LastPaint = self.LastPaint or 0
	local passed = CurTime() - self.LastPaint

	local rt, mat = draw.GetRTMat("Leaderboard", w, h, "UnlitGeneric")

	local should_render =
		passed > 2.5 or
		self:HasAnimations() or
		self.LastPaint < BW.Leaderboard.LastUpdate

	if should_render then
		self.LastPaint = CurTime()

		surface.PushAlphaMult(1)
		render.PushRenderTarget(rt)
		cam.Start2D()
		render.Clear(0, 0, 0, 0, true)
		render.OverrideAlphaWriteEnable(true, true)
			xpcall(self.PaintRT, GenerateErrorer("LeaderboardPanel"), self, w, h)
		render.OverrideAlphaWriteEnable(false, true)
		cam.End2D()
		render.PopRenderTarget()
		surface.PopAlphaMult()
	end

	surface.SetMaterial(mat)
	surface.SetDrawColor(255, 255, 255)
	surface.DrawTexturedRect(0, 0, w, h)
end

vgui.Register("BW_LeaderboardCanvas", CANV, "DPanel")