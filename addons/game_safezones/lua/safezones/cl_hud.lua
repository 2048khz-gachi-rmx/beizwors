local gu = Material("vgui/gradient-u")
local gd = Material("vgui/gradient-d")
local gr = Material("vgui/gradient-r")
local gl = Material("vgui/gradient-l")

local anim = Animatable("safezones")

local unsafeCol = Color(230, 200, 30)
local lingerTop = Color(50, 150, 250)
local lingerBot = Color(20, 90, 160)
local safeCol = Color(70, 230, 70)

local lasttxt, lastAltTxt = "", ""
local txCol = Color(255, 255, 255)
local bordCol = Color(230, 200, 30)
local icona = 0

hook.Add("HUDPaint", "SafeZone", function()
	anim.Safe = anim.Safe or 0

	local me = LocalPlayer()

	local safe = me:GetNWFloat("Safezone", 0)

	local ttp = Safezones.TimeTillProtection

	local is_safe = Safezones.IsProtected(me, true)
	local in_safe = not is_safe and Safezones.IsIn(me)
	local _l, linLeft = Safezones.IsLingering(me)
	local is_lin = not (is_safe or in_safe) and _l

	if is_safe or in_safe or is_lin then
		anim:To("Fr", 1, 0.3, 0, 0.3)
	else
		anim:To("Fr", 0, 0.2, 0, 0.3)
	end

	local fr = anim.Fr or 0
	local mata = fr * 250

	if fr == 0 then return end

	local txt = lasttxt or "???"
	local altTxt = lastAltTxt or "???"
	local font = "EXM32"
	local altFont = "EX28"

	if in_safe then
		anim:To("WarnFr", 1, 0.3, 0, 0.3)
		anim:To("Safe", 0, 0.3, 0, 0.3)
		anim:To("TxSz", 1, 0.3, 0, 0.3)

		icona = 200 + math.sin(CurTime()*25)*100
		txt = ("You will be safe in %s seconds."):format(ttp - math.floor(CurTime() - safe))
	elseif is_safe then
		anim:To("Safe", 1, 0.3, 0, 0.3)

		txt = "You are under protection."
	elseif is_lin then
		altTxt = ("You are protected for %.1fs."):format(linLeft)
		anim:To("Safe", 0, 0.3, 0, 0.3)
	end

	anim:To("Linger", is_lin and 1 or 0, 0.3, 0, 0.4)

	if is_safe or is_lin then
		anim:To("WarnFr", 0, 0.3, 0, 0.3)
		anim:To("TxSz", 0, 0.3, 0, 0.3)
	end

	local wfr = anim.WarnFr or 0
	local sfr = anim.Safe or 0
	local lin = anim.Linger or 0
	local txA = 1 - math.RemapClamp(anim.Linger or 0, 0, 0.5, 0, 1)
	local altA = math.RemapClamp(anim.Linger or 0, 0.5, 1, 0, 1)
	local txsz = anim.TxSz or 0

	local linLeftFr = not is_lin and 1 or math.max(0, math.TimeFraction(0, Safezones.ProtectionLinger, linLeft))
	local y = math.ceil(Lerp(lin, 36, 24) - 16 * (1 - fr))
	local x = ScrW() / 2 - 300

	local w, h = 500, math.ceil(Lerp(lin, 60, 40))

	local stripeH = math.ceil(Lerp(lin, 8, 4))
	local sz = 40
	local tw = Lerp(altA, surface.GetTextSizeQuick(txt, font), surface.GetTextSizeQuick(altTxt, altFont))


	surface.SetDrawColor(50, 50, 50, mata)
	surface.DrawRect(x, y, w, h)

	render.SetScissorRect(x + w * linLeftFr, y - stripeH, x + w, y + h + stripeH * 2, true)
		surface.SetDrawColor(20, 20, 20, mata)
		surface.DrawRect(x, y, w, h)
	render.SetScissorRect(0, 0, 0, 0, false)

	surface.SetDrawColor(0, 0, 0, mata)
	surface.SetMaterial(gl)
	surface.DrawTexturedRect(x, y, 16, h)

	surface.SetMaterial(gr)
	surface.DrawTexturedRect(x + w - 16, y, 16, h)

	bordCol:Lerp(sfr, unsafeCol, safeCol)
	bordCol:Lerp(lin, bordCol, lingerTop)

	bordCol.a = mata

	surface.SetDrawColor(255, 255, 255, icona * wfr * fr)
	surface.DrawMaterial("https://i.imgur.com/Xq0xmuF.png", "unsafe.png",
		x + w / 2 - tw / 2 - (sz / 2 - 4) * (1 + (1 - txsz) * 2),
		y + h / 2 - sz / 2,
		sz, sz)

	local icW = (sz + 4) * txsz

	if altA > 0 then
		txCol.a = mata * altA
		draw.SimpleText(altTxt, altFont, x + w / 2 - (tw + icW) / 2 + icW, y + h/2, txCol, 0, 1)
	end

	if txA > 0 then
		txCol.a = mata * txA
		draw.SimpleText(txt, font, x + w / 2 - (tw + icW) / 2 + icW, y + h/2, txCol, 0, 1)
	end

	local sV = 0.75 * (stripeH / w)

	local u = (CurTime() * 0.05) % 1


	surface.SetDrawColor(bordCol)
	surface.DrawRect(x, y - stripeH, w, stripeH)
	surface.DrawRect(x, y + h, w, stripeH)

	surface.SetDrawColor(255, 255, 255, (fr ^ 0.4) * 250)
	surface.DrawUVMaterial("https://i.imgur.com/GBGbyCn.png", "stripes.png", x, y - stripeH, w, stripeH,
		u, 0, 1 + u, sV)

	surface.DrawUVMaterial("https://i.imgur.com/GBGbyCn.png", "stripes.png", x, y + h, w, stripeH,
		-u, 0, 1 - u, sV)

	render.SetScissorRect(x + w * linLeftFr, y - stripeH, x + w, y + h + stripeH * 2, true)

	surface.SetDrawColor(lingerBot)
	surface.DrawRect(x, y - stripeH, w, stripeH)
	surface.DrawRect(x, y + h, w, stripeH)

	surface.SetDrawColor(255, 255, 255, (fr ^ 0.4) * 250)
	surface.DrawUVMaterial("https://i.imgur.com/GBGbyCn.png", "stripes.png", x, y - stripeH, w, stripeH,
		u, 0, 1 + u, sV)

	surface.DrawUVMaterial("https://i.imgur.com/GBGbyCn.png", "stripes.png", x, y + h, w, stripeH,
		-u, 0, 1 - u, sV)

	render.SetScissorRect(0, 0, 0, 0, false)


	lasttxt = txt
	lastAltTxt = altTxt
end)