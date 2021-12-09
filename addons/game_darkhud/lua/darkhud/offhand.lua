
local dh = DarkHUD
local col = Colors.LighterGray

local icon = {"https://i.imgur.com/6se0gFC.png", "none64_gray.png"}

local handle = BSHADOWS.GenerateCache("DarkHUD_OffhandNothing", 64, 64)
handle.rendered = false
handle:SetGenerator(function(self, w, h)
	surface.SetDrawColor(255, 255, 255)
	surface.DrawMaterial(icon[1], icon[2],
		0, 0, w, h)
end)


local function paintNothing(pnl, x, y, w)
	local sz = w * 0.65
	local diff = w - sz

	local x, y = math.floor(x + diff / 2),
		math.floor(y + diff / 2)

	surface.SetDrawColor(255, 255, 255)
	handle:Paint(x, y, sz, sz)

	surface.SetDrawColor(col:Unpack())
	surface.DrawMaterial(icon[1], icon[2],
		x, y, sz, sz)
end

local fmt = "[%s]"

local rectCol = Color(0, 0, 0, 240)
local gradCol = Color(180, 180, 180, 250)
local outlineCol = Color(120, 120, 120)

local pad = 16
local rectSz = 4
local gradH = 0.95
local gradStart = 0.2

DarkHUD.OffhandYPad = 8

surface.CreateFont("Darkhud_OffhandTip", {
	font = "BreezeSans",
	size = DarkHUD.Scale * 28,
	weight = 600,
})

surface.CreateFont("Darkhud_OffhandTipSmall", {
	font = "BreezeSans",
	size = DarkHUD.Scale * 24,
	weight = 600,
})

surface.CreateFont("Darkhud_OffhandTipSmallShadow", {
	font = "BreezeSans",
	size = DarkHUD.Scale * 24,
	weight = 600,
	blursize = 3,
})

surface.CreateFont("Darkhud_OffhandTipShadow", {
	font = "BreezeSans",
	size = DarkHUD.Scale * 28,
	weight = 600,
	blursize = 3,
})

DarkHUD.OffhandKeyFontSize = math.ceil(DarkHUD.Scale * 28)

dh:On("Rescale", "OffhandFonts", function(_, sc)
	surface.CreateFont("Darkhud_OffhandTip", {
		font = "BreezeSans",
		size = sc * 28,
		weight = 600,
	})

	surface.CreateFont("Darkhud_OffhandTipShadow", {
		font = "BreezeSans",
		size = sc * 28,
		weight = 600,
		blursize = 3,
	})

	surface.CreateFont("Darkhud_OffhandTipSmall", {
		font = "BreezeSans",
		size = DarkHUD.Scale * 24,
		weight = 600,
	})

	DarkHUD.OffhandKeyFontSize = math.ceil(sc * 28)
end)

local holdTip = "(hold)"

dh:On("AmmoPainted", "PaintOffhand", function(_, pnl, fw, h)
	local x = pnl.OffhandX or 8
	local w = math.max(48, 48 * DarkHUD.Scale)
	pnl.OffhandFr = pnl.OffhandFr or 0
	local y = -w - DarkHUD.OffhandYPad - (1 - pnl.OffhandFr) * h

	local mat, has = draw.GetMaterial(unpack(icon))

	if has and not handle.rendered then
		handle:CacheShadow(3, 8, 4)
		handle.rendered = true
	end

	pnl:To("OffhandX", pnl.Gone and fw - #Offhand.Binds * w or 8, 0.3, 0, 0.3)
	pnl:To("OffhandFr", (pnl.Gone or pnl.GoingAway) and 0 or 1, 0.3, 0, 0.3)

	DisableClipping(true)

	-- counteract the shaking a bit
	-- unshaken is used in painting icons and keys, not rects

	for i, bind in ipairs(Offhand.Binds) do
		local ux = math.floor(x - pnl.ShakeX * 0.6)
		local uy = math.floor(y - pnl.ShakeY * 0.6)

		local act = Offhand.GetBindAction(bind)
		local tbl = Offhand.GetAction(act)

		local left = x - rectSz
		local uleft = ux - rectSz

		local top = y - rectSz
		local utop = uy - rectSz

		local rsz = w + rectSz * 2

		--[[surface.SetDrawColor(rectCol:Unpack())
		surface.DrawRect(left, top, rsz, rsz)

		surface.SetDrawColor(gradCol:Unpack())
		surface.SetMaterial(MoarPanelsMats.gd)
		surface.DrawTexturedRectUV(left,
			-w * gradH - DarkHUD.OffhandYPad + rectSz - (1 - pnl.OffhandFr) * h,
			rsz, w * gradH,
			0, 0, 1, gradStart)]]

		local ok, add

		if not tbl or not tbl.Paint then
			paintNothing(pnl, ux, uy, w)
			add = w
			goto postpaint
		end

		ok, add = xpcall(tbl.Paint, GenerateErrorer("PaintAction_" .. act),
			pnl, ux, uy, w)

		::postpaint::

		--[[surface.SetDrawColor(outlineCol:Unpack())
		surface.DrawOutlinedRect(left, top,
			rsz, rsz)]]

		if pnl.OffhandFr > 0 then
			local txt = fmt:format(input.GetKeyName(bind.Key)):upper()

			surface.SetFont("Darkhud_OffhandTipShadow")

			local txW, txH = surface.GetTextSize(txt)
			local txX, txY = math.floor(uleft + rsz / 2 - txW / 2),
				math.floor(utop - 4 - txH)

			if act:match("nothing") then
				local font = "Darkhud_OffhandTipSmall"
				surface.SetFont(font .. "Shadow")
				surface.SetTextColor(0, 0, 0, (pnl.OffhandFr or 0) * 200)
				local tipW, tipH = surface.GetTextSize(holdTip)
				local tipX = uleft + rsz / 2 - tipW / 2

				for i=1, 3 do
					surface.SetTextPos(tipX, txY - tipH)
					surface.DrawText(holdTip)
				end

				surface.SetFont(font)
				surface.SetTextColor(160, 160, 160, (pnl.OffhandFr or 0) * 200)
				surface.SetTextPos(tipX, txY - draw.GetFontHeight(font))
				surface.DrawText(holdTip)
			end

			surface.SetFont("Darkhud_OffhandTipShadow")
			surface.SetTextColor(0, 0, 0, (pnl.OffhandFr or 0) * 255)

			for i=1, 5 do
				surface.SetTextPos(txX, txY)
				surface.DrawText(txt)
			end

			surface.SetFont("Darkhud_OffhandTip")
			surface.SetTextPos(txX, txY)
			surface.SetTextColor(255, 255, 255, (pnl.OffhandFr or 0) * 255)
			surface.DrawText(txt)
		end

		x = x + (add or w) + pad
	end
	DisableClipping(false)
end)
