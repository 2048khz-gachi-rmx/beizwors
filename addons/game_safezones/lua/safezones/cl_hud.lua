--

local st = 0

local mata = 0
local txta = 0


local gu = Material("vgui/gradient-u")
local gd = Material("vgui/gradient-d")
local gr = Material("vgui/gradient-r")
local gl = Material("vgui/gradient-l")

local icona = 0

local unsafeCol = Color(230, 200, 30)
local safeCol = Color(70, 230, 70)

local warncol = Color(230, 200, 30)
local lasttxt = ""
local txsz = 1

local txCol = Color(255, 255, 255)
local anim

hook.Add("HUDPaint", "SafeZone", function()
	anim = anim or Animatable("safezones")
	anim.Safe = anim.Safe or 0

	local me = LocalPlayer()

	local isIn = me:GetNWBool("InSafezone", false)
	local safe = me:GetNWFloat("Safezone", 0)

	if isIn and safe > 0 then
		anim:To("Fr", 1, 0.3, 0, 0.3)
	else
		anim:To("Fr", 0, 0.2, 0, 0.3)
	end

	local fr = anim.Fr or 0
	local mata = fr * 250

	if fr == 0 then return end

	local y = 36 - 16 * (1 - fr)
	local x = ScrW() / 2 - 300

	local w, h = 500, 60

	surface.SetDrawColor(50, 50, 50, mata)
	surface.DrawRect(x, y, w, h)

	surface.SetDrawColor(0, 0, 0, mata)
	surface.SetMaterial(gl)
	surface.DrawTexturedRect(x, y, 16, h)

	surface.SetMaterial(gr)
	surface.DrawTexturedRect(x + w - 16, y, 16, h)

	local txt = "??? forsenE"

	-- in process
	local ttp = Safezones.TimeTillProtection
	local in_safe = isIn and CurTime() - safe < ttp and CurTime() - safe > 0
	local is_safe = isIn and CurTime() - safe > ttp and safe ~= 0

	if in_safe then
		anim:To("Safe", 0, 0.3, 0, 0.3)

		icona = 200 + math.sin(CurTime()*25)*100
		txt = ("You will be safe in %s seconds."):format(ttp - math.floor(CurTime() - safe))
		txsz = 1
	elseif is_safe then
		anim:To("Safe", 1, 0.3, 0, 0.3)
		icona = L(icona, 0, 25, true)
		txt = "You are under protection."
		txsz = 0
	else
		-- left or something
		icona = L(icona, 0, 25, true)
		txt = lasttxt
	end

	warncol:Lerp(anim.Safe, unsafeCol, safeCol)
	warncol.a = mata

	local stripeH = 8
	local sz = 40

	lasttxt = txt

	local font = "EXM32"
	local tw = surface.GetTextSizeQuick(txt, font)
	surface.SetDrawColor(255, 255, 255, icona)

	surface.DrawMaterial("https://i.imgur.com/Xq0xmuF.png", "unsafe.png",
		x + w / 2 - tw / 2 - sz / 2 - 4,
		y + h / 2 - sz / 2,
		sz, sz)

	txCol.a = mata
	local icW = (sz + 4) * txsz
	draw.SimpleText(txt, font, x + w / 2 - (tw + icW) / 2 + icW, y + h/2, txCol, 0, 1)

	local sV = 0.75 * (stripeH / w)

	local u = (CurTime() * 0.05) % 1


	surface.SetDrawColor(warncol)
	surface.DrawRect(x, y - stripeH, w, stripeH)
	surface.DrawRect(x, y + h, w, stripeH)

	surface.SetDrawColor(255, 255, 255, (fr ^ 0.4) * 250)
	surface.DrawUVMaterial("https://i.imgur.com/GBGbyCn.png", "stripes.png", x, y - stripeH, w, stripeH,
		u, 0, 1 + u, sV)

	surface.DrawUVMaterial("https://i.imgur.com/GBGbyCn.png", "stripes.png", x, y + h, w, stripeH,
		-u, 0, 1 - u, sV)
end)