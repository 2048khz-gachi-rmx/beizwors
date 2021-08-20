
--[[
	DarkHUD:On("VitalsFramePainted")
	DarkHUD:On("VitalsBarsPainted")
	DarkHUD:On("VitalsEconomyPainted")
]]

local render = render
local surface = surface
local dh = DarkHUD
local fonts = DarkHUD.Fonts

fonts.NameFont = "Open Sans Semibold"
fonts.FactionFont = "Open Sans"
fonts.MoneyFont = "Open Sans"
fonts.VitalsNumberFont = "Open Sans"


local scale = DarkHUD.Scale

local log = Logger("DarkHUD Vitals", Color(150, 90, 90))

local function createFonts()
	local scale = Lerp(0.25, scale, 1)

	fonts.NameHeight = 40 * scale
	fonts.FactionHeight = 16 + 12 * scale
	fonts.MoneyHeight = 28 * scale
	fonts.VitalsNumberHeight = 12 + 16 * scale

	print(scale)

	surface.CreateFont("DarkHUD_Name", {
		font = fonts.NameFont,
		size = fonts.NameHeight
	})

	surface.CreateFont("DarkHUD_Faction", {
		font = fonts.FactionFont,
		size = fonts.FactionHeight
	})

	surface.CreateFont("DarkHUD_Money", {
		font = fonts.MoneyFont,
		size = fonts.MoneyHeight
	})

	surface.CreateFont("DarkHUD_VitalsNumber", {
		font = fonts.VitalsNumberFont,
		size = fonts.VitalsNumberHeight
	})
end

createFonts()

DarkHUD:On("Rescale", "VitalsResize", function(self, new)
	log("	Rescaling", DarkHUD.Vitals)

	scale = new
	createFonts()

	log("	New scale: %f", scale)
	local f = DarkHUD.Vitals
	if not IsValid(f) then log("Invalid panel.") return end

	f:ResizeElements()
end)

function DarkHUD.CreateVitals()
	if DarkHUD.Vitals then DarkHUD.Vitals:Remove() end
	DarkHUD.Vitals = vgui.Create("FFrame", nil, "DarkHUD - Vitals")

	local f = DarkHUD.Vitals
	if not IsValid(f) then log("Failed to create vitals frame?") return false end --?
	f:SetPaintedManually(true)
	f.HeaderSize = 18

	local hs = f.HeaderSize

	f:CacheShadow(2, 8, 1)

	local fw, fh

	f:SetCloseable(false, true)

	f.BackgroundColor.a = 255
	f.HeaderColor.a = 255

	f.Vitals = vgui.Create("InvisFrame", f)

	local vls = f.Vitals

	vls:SetSize(f:GetWide(), f:GetTall() - hs - 12 - 64*scale)
	vls:SetPos(0, f:GetTall() - hs + 12 + 64*scale)

	local barH
	local barPad = 8

	local function recalcBarH()
		barH = math.floor(16 * Lerp(0.5, scale, 1) / 2) * 2 --brings to multiple of 2

		if barH > 13 and barH < 21 then
			barH = 16
		end
	end

	f.Economy = vgui.Create("InvisFrame", f)
	local ecn = f.Economy

	-- ecn:SetSize(f:GetWide(), f:GetTall() - hs - 12 - 64*scale)
	-- ecn:SetPos(0, hs + 12 + 64*scale)

	ecn:MoveToBefore(vls)   --draw economy behind vitals so when you press C the EXP box doesn't show
							--it does some alpha trickery to look better
	ecn:SetAlpha(0)


	local av = vgui.Create("AvatarImage", f)
	f.Avatar = av

	-- av:SetSize(64 * scale, 64 * scale)
	-- av:SetPos(16, hs + 8)
	av:SetPlayer(LocalPlayer(), 64)

	av:SetPaintedManually(true)

	function f:ResizeElements()
		fw, fh = scale * 500, scale * 220

		recalcBarH()

		self:SetSize(fw, fh)
		self:SetPos(dh.PaddingX, ScrH() - fh - dh.PaddingY)

		local vlsH = math.max(barH, draw.GetFontHeight("DarkHUD_VitalsNumber")) * 2 + barPad
		vls:SetSize(fw, vlsH)
		vls:SetPos(0, fh - vls:GetTall())

		ecn:SetSize(fw, fh - hs - 12 - 64*scale)
		ecn:SetPos(0, hs + 12 + 64*scale)

		av:SetSize(64 * scale, 64 * scale)
		av:SetPos(16, hs + 8)
	end

	f:ResizeElements()

	local tcol = Color(100, 100, 100)

	f.Shadow = {spread = 0.9, intensity = 2}

	local pl, pm = LocalPlayer():GetLevel(), LocalPlayer():GetMoney()

	local pmd  = {} --differences

	local mCol = Color(250, 250, 250)
	local lvCol = Color(250, 250, 250)

	local boxcol = Color(50, 50, 50, 253)

	local me = LocalPlayer()

	function f:Think()
		local lvl = me:GetLevel()
		local mon = me:GetMoney()

		if pl ~= lvl then
			PopupLevel = CurTime()
			lvCol:Set(Colors.Green)
			pld = {amt = lvl - pl, y = 0, ct = CurTime(), boxcol = boxcol:Copy()}
		end

		-- track money changes for money popups

		if pm ~= mon then
			PopupMoney = CurTime()

			if pm < mon then -- + money
				mCol:Set(Colors.Green)
			else
				mCol:Set(Colors.Red)
			end

			if #pmd < 7 then
				pmd[#pmd + 1] = {amt = mon - pm, y = 0, ct = CurTime(), col = mCol:Copy(), boxcol = boxcol:Copy()}
			else
				local cur = pmd[1]

				cur.amt = cur.amt + (mon - pm)
				cur.ct = CurTime()

				if cur.amt < 0 then
					cur.col:Set(red)
				else
					cur.col:Set(green)
				end

			end

		end

		pl, pm = lvl, mon
	end

	local popups = Animatable:new("DarkHUD_Vitals")

	popups.MoneyFrac = 0
	popups.MoneyColor = color_white:Copy()

	popups.BounceMoney = 0

	popups.LevelFrac = 0

	popups.Money = {}
	popups.Levels = {}

	LocalPlayer():On("MoneyChanged", f, function(_, old, new)
		local diff = new - old

		local t = {
			amt = diff,
			ct = CurTime(),
			boxcol = boxcol:Copy(),
			y = 0,
			a = 0, --alpha, 0-1
			--col = green or red, depending on diff
		}

		if diff > 0 then
			t.col = Colors.Green:Copy()
			popups.MoneyColor:Set(Colors.Green)
		else
			t.col = Colors.DarkerRed:Copy()
			popups.MoneyColor:Set(Colors.Red)
		end

		popups:LerpColor(popups.MoneyColor, color_white, 0.4, 0.5, 0.3, true) --force swap the animation
		popups.BounceMoney = 1
		popups:RemoveLerp("BounceMoney")
		popups:To("BounceMoney", 0, 0.3, 0, 0.6)

		local key = table.insert(popups.Money, t)
		if diff > 0 then
			t.y = key * -28 - 36 - 4 - 64 -- + appears from above
		else
			t.y = -36 - 4 -- - appears from the wallet
		end
	end)

	function f:PrePaint(w,h)

		if #popups.Money > 0 then
			popups:To("MoneyFrac", 1, 0.3, 0, 0.3)
		else
			popups:To("MoneyFrac", 0, 0.3, 0.1, 0.3)
		end

		local mf = popups.MoneyFrac

		local ct = CurTime()

		DisableClipping(true)

			for k = #popups.Money, 1, -1 do--k,v in ipairs(popups.Money) do
				local v = popups.Money[k]
				local should_y = -36 - 4 - (28 * k)

				if ct - v.ct > 2 then --stayed for more than 2 seconds, gtfo now

					local anim, new = popups:LerpMember(v, "y", 0, 0.3, 0, 2)
					popups:LerpMember(v, "a", 0, 0.2, 0, 1.7)

					if v.a <= 0 then
						table.remove(popups.Money, k)
					end

				else --go up
					popups:LerpMember(v, "y", should_y, 0.3, 0, 0.3)
					popups:LerpMember(v, "a", 1, 0.2, 0, 0.3)
				end

				local y = v.y
				local difftxt = Language.Currency .. BaseWars.NumberFormat(math.abs(v.amt))

				surface.SetFont("OSB24")
				local tw, th = surface.GetTextSize(difftxt)

				v.boxcol.a = v.a * 240
				v.col.a = v.a * 255

				draw.RoundedBox(4, 12, y, tw + 8, th + 2, v.boxcol)
				surface.SetTextPos(16, y + 1)
				surface.SetTextColor(v.col:Unpack())
				surface.DrawText(difftxt)

			end
		DisableClipping(false)

		if mf > 0 then

			local mtxt = Language.Currency .. BaseWars.NumberFormat(me:GetMoney())

			surface.SetFont("OSB28")
			local mw, mh = surface.GetTextSize(mtxt)

			local boxY, boxH = -mf * 36, 32

			DisableClipping(true)
				draw.RoundedBox(8, 12, boxY, mw + 8 + 24 + 6 + 8, boxH, boxcol)

				surface.SetDrawColor(255, 255, 255)
				surface.DrawMaterial("https://i.imgur.com/8b0nZI7.png", "moneybag.png", 12 + 8, boxY + 4, 25, 24)

				surface.SetTextColor(popups.MoneyColor:Unpack())
				surface.SetTextPos(12 + 8 + 24 + 6, boxY + boxH / 2 - mh / 2)
				surface.DrawText(mtxt)
			DisableClipping(false)
			--draw.SimpleText(mtxt, "OSB28", 48, boxY + boxH / 2, col, 0, 1)
		end
	end

	local function Mask(av, x, y, w2, h2)
		draw.NoTexture()
		surface.SetDrawColor(0, 0, 0, 255)
		draw.DrawCircle(x+w2/2, y+h2/2, w2/2 + 2, 50)
	end

	local function Paint(av)
		av:SetAlpha(255)
		av:PaintManual()
	end

	local moneyIconCol = Color(200, 200, 200, 220)
	local defaultCol = Color(100, 100, 100)

	local curTeamCol = defaultCol:Copy()

	local ic1 = Icons.Money32:Copy()
	local ic2 = Icons.Money64:Copy()
	ic1:SetFilter(true)
	ic2:SetFilter(true)

	function f:PostPaint(w, h)
		local x, y = av:GetPos()
		local w2, h2 = av:GetSize()

		local nameY = y + h2 / 2
		local fh = draw.GetFontHeight("DarkHUD_Name")

		local tw, th = draw.SimpleText(me:Nick(), "DarkHUD_Name",
			x + w2 + 12, nameY + fh * 0.125 / 2, curTeamCol, 0, 4)

		local sz = 36 * scale
		local ic = ic2
		if sz <= 32 then
			ic = ic1
		end

		local moneyY = nameY + 6 - popups.BounceMoney * 6

		surface.SetDrawColor(moneyIconCol:Unpack())

		ic:Paint(x + w2 + 12, moneyY, sz, sz)

		moneyY = moneyY - popups.BounceMoney * 2
		draw.SimpleText2(Language.Price(LocalPlayer():GetMoney()), "DarkHUD_Money",
			x + w2 + 12 + sz + 4, moneyY + sz/2, popups.MoneyColor, 0, 1)

		local tm = me:Team()
		local col = tm ~= 0 and team.GetColor(tm) or defaultCol
		self:LerpColor(curTeamCol, col, 0.5, 0, 0.3)

		draw.Masked(Mask, Paint, nil, nil, av, x, y, w2, h2)


		surface.SetDrawColor(curTeamCol:Unpack())
		surface.DrawMaterial("https://i.imgur.com/VMZue2h.png", "circle_outline.png", x-3, y-3, w2+6, h2+6)

		DarkHUD:Emit("VitalsFramePainted", w, h)
	end

	vls.HPFrac = 0
	vls.ARFrac = 0

	local gray = Colors.LighterGray:Copy()
	local hpCol = Color(240, 70, 70)
	local arCol = Color(40, 120, 255)

	function vls:Paint(w, h)
		local x, y = 12, barPad

		--self:SetSize(f:GetWide(), f:GetTall() - hs)

		local hpto = math.Clamp( me:Health() / me:GetMaxHealth(), 0, 1)
		local arto = math.min(me:Armor() / 100, 1)

		self:To("HPFrac", hpto, 0.4, 0, 0.2)
		self:To("ARFrac", arto, 0.4, 0, 0.2)

		local hpfr, arfr = self.HPFrac, self.ARFrac


		local rndrad = barH/2

		if rndrad > 8 and rndrad < 11 then  --16 is perfect because gmod corners are 8x8
			rndrad = 8						--any more and they looked scuffed
		end

		local barsH = barH * 2 + barPad

		local hpText = tostring(LocalPlayer():Health())
		local arText = tostring(LocalPlayer():Armor())
		local font = "DarkHUD_VitalsNumber"

		surface.SetFont(font)
		local rightPad = surface.GetTextSize("999")

		local barX = w * 0.07
		local barW = w - barX * 2 - rightPad

		local barY = math.ceil(h / 2) - barsH / 2

		--[[
		surface.SetFont(font)
		local hpW, hpH = math.max(surface.GetTextSize(hpText), barX)
		local arW, arH = math.max(surface.GetTextSize(arText), barX)
		]]

		--surface.DrawOutlinedRect(avx, barY, w - avx*2 - 48, barsH)
		local sx, sy = self:LocalToScreen(avx, barY)

		--[[
			Health
		]]

			local round = (barW * hpfr > barH and math.Round(math.Clamp(barW*hpfr - rndrad, 0, rndrad)))

			draw.RoundedBox(rndrad, barX, barY, barW, barH, gray)

			if not round then
				--draw.RoundedBox(8, avx, avy, hpw, 16, Color(240, 70, 70))
				if barW * hpfr < barH then
					render.SetScissorRect(sx, sy - 2, sx + (barW * hpfr), sy + barH + 2, true)
						draw.RoundedBoxEx(rndrad, barX, barY, barH, barH, hpCol, true, false, true, false)
					render.SetScissorRect(0, 0, 0, 0, false)
				else

					draw.RoundedBox(rndrad, barX, barY, barW*hpfr, barH, hpCol)

				end

			elseif round then

				DarkHUD.RoundedBoxCorneredSize(rndrad, barX, barY,
					barW * hpfr, barH, hpCol, rndrad, round, rndrad, round)

			end

			draw.SimpleText(hpText, font,
				barX + barW + 4, barY + barH/2 - 1, color_white, 0, 1)


		--[[
			Armor
		]]

			barY = barY + barH + barPad
			local round = (barW*arfr > 16 and math.Round(math.Clamp(barW*arfr - rndrad, 0, rndrad)))

			draw.RoundedBox(rndrad, barX, barY, barW, barH, gray)

			if not round then
				if barW*arfr < 16 then
					render.SetScissorRect(sx, sy, sx + barW * arfr, sy + barH, true)
						draw.RoundedBox(rndrad, barX, barY, 16, barH, arCol)
					render.SetScissorRect(0, 0, 0, 0, false)
				else

					draw.RoundedBox(rndrad, barX, barY, barW*arfr, barH, arCol)

				end

			elseif round then

				DarkHUD.RoundedBoxCorneredSize(rndrad, barX, barY,
					barW * arfr, barH, arCol, rndrad, round, rndrad, round)

			end

			draw.SimpleText(arText, font,
				barX + barW + 4, barY + barH/2 - 1, color_white, 0, 1)

			DarkHUD:Emit("VitalsBarsPainted", w, h)
	end

	function ecn:Paint(w,h)

		local x, y = av:GetPos()

		local barH = math.floor(16 * Lerp(0.5, scale, 1) / 2) * 2 --brings to multiple of 2
		local rndrad = barH/2

		local barsH = barH * 2 + 8
		local barY = h/2 - barH/2

		local iconSize = 24 * Lerp(0.5, scale, 1)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawMaterial("https://i.imgur.com/8b0nZI7.png", "moneybag.png", x + 18, 4, iconSize, iconSize)

		draw.SimpleText(Language.Currency .. BaseWars.NumberFormat(LocalPlayer():GetMoney()), "DarkHUD_Money", x + 50, 4 + iconSize/2, color_white, 0, 1)


		local expBoxX = w - 180 * scale - 8
		local expBoxY = barY

		local expY = 4 + iconSize + 8*scale + iconSize/2
		local expw, exph = draw.SimpleText(LocalPlayer():GetLevel(), "DarkHUD_Money", expBoxX + 64, 4 + iconSize/2, color_white, 1, 1)
		expBoxY = 4 + iconSize/2 + exph/2 + 2

		surface.DrawMaterial("https://i.imgur.com/YYXglpb.png", "star.png", expBoxX + 64 - expw/2 - 4 - iconSize, 4, iconSize, iconSize)

		draw.RoundedBox(rndrad, expBoxX, expBoxY, 180*scale, barH, Color(75, 75, 75))
		draw.RoundedBox(rndrad, expBoxX, expBoxY, 180*scale * (LocalPlayer():GetXP() / LocalPlayer():GetXPNextLevel()), barH, Color(140, 80, 220))

		DarkHUD:Emit("VitalsEconomyPainted", w, h)
	end

end

local used = DarkHUD.Used

hook.Add("OnContextMenuOpen", "DarkHUD_Vitals", function()
	local f = DarkHUD.Vitals

	if not IsValid(f) then
		DarkHUD.Create()
		f = DarkHUD.Vitals
		if not IsValid(DarkHUD.Vitals) then return end
	end

	if not used.ContextMenu ~= 1 then
		DarkHUD.SetUsed("ContextMenu", 1)
	end

	if IsValid(f.Vitals) and IsValid(f.Economy) then
		f.Vitals:PopOut(nil, nil, function() end)
		f.Economy:PopIn()
	else

	end

end)

hook.Add("OnContextMenuClose", "DarkHUD_Vitals", function()
	local f = DarkHUD.Vitals
	if not IsValid(f) then return end

	if IsValid(f.Vitals) and IsValid(f.Economy) then
		f.Economy:PopOut(nil, nil, function() end)
		f.Vitals:PopIn()
	else

	end

end)

hook.Add("HUDPaint", "DarkHUD_Vitals", function()
	local f = DarkHUD.Vitals
	if not IsValid(f) then return end

	f:PaintManual()
end)

local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true
}

hook.Add("HUDShouldDraw", "HideHUD", function(name)	--wiki example copypasting gang rise up
	if hide[name] then return false end
end)

local wasvalid = false

if IsValid(DarkHUD.Vitals) then
	DarkHUD.Vitals:Remove()
	DarkHUD.Vitals = nil
	DarkHUD.CreateVitals()
end

DarkHUD:On("Ready", "CreateVitals", DarkHUD.CreateVitals)