
--[[
	DarkHUD:On("AmmoPainted")
]]

local scale = DarkHUD.Scale
local dh = DarkHUD

local ammoColor = Color(225, 205, 15)
local firedAmmoColor = Color(85, 75, 5, 190)

local fonts = DarkHUD.Fonts

fonts.WeaponNameFont = "Open Sans SemiBold"
fonts.WeaponMagFont = "Open Sans"
fonts.WeaponReserveFont = "Open Sans"
fonts.WeaponFiremodeFont = "Open Sans"

local function createFonts()
	fonts.WeaponNameHeight = 48 * scale

	fonts.WeaponMagHeight = 16 + 48 * scale
	fonts.WeaponDivHeight = 32 + 48 * scale
	fonts.WeaponReserveHeight = 48 * scale

	fonts.WeaponFiremodeHeight = 27 * scale

	--[[
		the font size is picked dynamically, but
		fonts.WeaponNameHeight is the maximum possible size
	]]

	surface.CreateFont("DarkHUD_WeaponName", {
		font = fonts.WeaponNameFont,
		size = fonts.WeaponNameHeight
	})


	surface.CreateFont("DarkHUD_AmmoMagazine", {
		font = fonts.WeaponMagFont,
		size = fonts.WeaponMagHeight
	})

	surface.CreateFont("DarkHUD_AmmoDivide", {
		font = fonts.WeaponMagFont,
		size = fonts.WeaponDivHeight
	})

	surface.CreateFont("DarkHUD_AmmoReserve", {
		font = fonts.WeaponReserveFont,
		size = fonts.WeaponReserveHeight
	})

	surface.CreateFont("DarkHUD_Firemode", {
		font = fonts.WeaponFiremodeFont,
		size = fonts.WeaponFiremodeHeight
	})

	surface.SetFont("DarkHUD_AmmoDivide")
	fonts.WeaponDivWidth = surface.GetTextSize("/")
end

createFonts()

local log = Logger("DarkHUD Ammo", Color(190, 175, 10))

DarkHUD:On("Rescale", "AmmoResize", function(self, new)
	log("Rescaling %s", DarkHUD.Ammo)
	scale = new
	log("	New scale: %f", scale)
	local f = DarkHUD.Ammo

	if not IsValid(f) then
		DarkHUD.CreateAmmo()
	else
		f:ResizeElements()
	end

	createFonts()
end)

local hl2_recs = {
	["weapon_smg1"] = 0.01,
	["weapon_shotgun"] = 0.8,
	["weapon_ar2"] = 0.025,
	["weapon_357"] = 3,
	["weapon_pistol"] = 0.02,
}

function DarkHUD.Ammo_GetRecoil(wep)
	if wep.ArcCW then
		local rec = wep.Recoil * wep:GetBuff_Mult("Mult_Recoil") * 3
		return rec
	end

	if wep.CW20Weapon or wep.IsFAS2Weapon then
		return wep.Recoil * 3
	end


	return hl2_recs[wep:GetClass()] or 0.05 -- default
end

function DarkHUD.CreateAmmo()
	DarkHUD.HideHUDs.CHudAmmo = true
	DarkHUD.HideHUDs.CHudSecondaryAmmo = true

	if DarkHUD.Ammo then DarkHUD.Ammo:Remove() end

	local me = LocalPlayer()

	DarkHUD.Ammo = vgui.Create("FFrame", nil, "DarkHUD - Ammo")
	local f = DarkHUD.Ammo
	f:SetCloseable(false, true)
	f.Shadow = {spread = 0.9, intensity = 2}
	f:SetSize(scale * 500, scale * 120)
	f:SetPos(ScrW() - f:GetWide() - dh.PaddingX, ScrH() - f:GetTall() - dh.PaddingY)
	f.HeaderSize = scale * 32
	f:SetPaintedManually(true)
	f:CacheShadow(4, 8, 2)

	local rad = f.RBRadius or 8
	local fX, fY = f:GetPos()

	function f:ResizeElements()
		log("	ResizeElements %f", scale)
		f:SetSize(scale * 500, scale * 120)
		f:SetPos(ScrW() - f:GetWide() - dh.PaddingX, ScrH() - f:GetTall() - dh.PaddingY)
		log("	Setpos: %d - %d - %d = %d (%d)", ScrW(), f:GetWide(), dh.PaddingX, ScrW() - f:GetWide() - dh.PaddingX, f.X)
		log("	Setpos: %d - %d - %d = %d (%d)", ScrH(), f:GetTall(), dh.PaddingY, ScrH() - f:GetTall() - dh.PaddingY, f.Y)
		fX, fY = f:GetPos()
		f.HeaderSize = scale * 32
	end

	f.AmmoFrac = 0
	f.AmmoMissingFrac = 0
	f.AmmoGrad = 0

	f.ChamberedFrac = 0
	f.LineGap = 0

	f.Lines = 0

	f.Recoil = 0

	f.ShakeX, f.ShakeY = 0, 0

	local lastVars = {}

	local lastAmmoFrac

	function f:ShakeLogic()

		if self.Recoil > 0 then
			local shk = self.Recoil
			local shkX, shkY = math.random(-shk, shk), math.random(-shk, shk)
			self.ShakeX, self.ShakeY = shkX, shkY
			self:SetPos(fX + shkX, fY + shkY)

			local subRecoil = math.max(self.Recoil * 4 * FrameTime(), FrameTime() * 5)
			self.Recoil = math.max(self.Recoil - subRecoil, 0)
		end

	end

	local fired = FrameNumber()

	function f.OnFire(wep, self)
		local recoil = DarkHUD.Ammo_GetRecoil(wep)
		if fired == FrameNumber() then return end -- deal with shotguns 'n shit

		if f.RecoilAnim then f.RecoilAnim:Stop() end

		f.Recoil = f.Recoil + (recoil * 20) ^ 0.4 * scale
		--f.RecoilAnim = f:To("Recoil", 0, (recoil * 0.4)^0.1, 0, 0.3, true)

		fired = FrameNumber()
	end

	function f:IsWeaponValid(wep)
		return wep and wep:IsValid()
	end

	function f:ShouldDrawAmmo(wep)
		return self:IsWeaponValid(wep) and
			(wep.DrawAmmo or wep:IsEngine() or
				wep.IsFAS2Weapon or wep.CW20Weapon)
			and wep:GetMaxClip1() > 0
	end

	f:On("Think", "Recoil", function(self)
		local wep = me:GetActiveWeapon()
		local valid = f:ShouldDrawAmmo(wep)

		if valid then

			if not wep:GetListener("FiredBullet", self) then
				wep:On("FiredBullet", self, f.OnFire, f)
			end

			self.Gone = false
			self.GoingAway = false

			if self.Y ~= fY and self.Recoil == 0 then
				local anim, new = self:To("Y", fY, 0.4, 0, 0.3)
				if new then anim:On("Think", function() self.WasGone = false end) end
			else
				f:ShakeLogic()
			end
		else
			local anim, new = self:To("Y", ScrH() - 1, 0.15, 0, 4)
			self.GoingAway = true
			if new then
				anim:Then(function()
					self.Gone = true
					self.GoingAway = false
					self.WasGone = true
				end)
			end
		end

	end)

	function f:MaskHeader(w, h)
		--render.SetStencilCompareFunction(STENCIL_ALWAYS)
		draw.RoundedStencilBox(rad, 0, 0, w, self.HeaderSize, color_white, true, true, false, false)
	end

	function f:PrePaint(w, h)
		self.NoDraw = self.Gone
	end

	function f:PostPaint(w, h)
		self.NoDraw = self.Gone

		if self.Gone then
			goto emit
		end

		do
			rad = f.RBRadius or 8

			local wep = me:GetActiveWeapon()
			local valid = f:ShouldDrawAmmo(wep)

			local x, y = self:LocalToScreen(0, 0)

			local clip = valid and wep:Clip1() or lastVars.clip or 0
			lastVars.clip = clip

			local maxclip = (valid and (wep.ArcCW and wep:GetCapacity() or wep:GetMaxClip1())) or lastVars.maxclip or 0
			lastVars.maxclip = maxclip

			local reserve = (valid and me:GetAmmoCount(wep:GetPrimaryAmmoType())) or lastVars.reserve or -1
			lastVars.reserve = reserve

			local weaponName = (valid and wep:GetPrintName()) or lastVars.weaponName or "-"
			if valid and wep:IsEngine() then
				weaponName = language.GetPhrase(weaponName) or weaponName
			end
			lastVars.weaponName = weaponName

			local frW = math.min(clip / maxclip, 1)
			local dist = math.abs(self.AmmoFrac - frW)

			local anim, new = self:To("AmmoFrac", frW, (dist ^ 0.1) * 0.3, 0, 0.3)

			if frW ~= lastAmmoFrac and self.LastChangedWeapon ~= wep and new and valid then
				anim:Then(function()
					self.LastChangedWeapon = wep
				end)

				self.AmmoMissingFrac = 0 -- don't add the 'missing' bar when switching between guns (and lerping clips)
				self.ReserveAmmo = reserve
			elseif self.LastChangedWeapon == wep and valid then
				self.AmmoMissingFrac = math.max(self.AmmoFrac, self.AmmoMissingFrac)
			end

			if self.Gone then
				-- if the frame was gone, don't animate anything cuz it just looks weird
				if anim then anim:Stop() end
				self.AmmoFrac = frW
			end

			local total_lines = math.max(maxclip, 1)

			if total_lines > 10 then

				if total_lines % 10 == 0 then
					if total_lines >= 60 then
						total_lines = total_lines / 20
					elseif total_lines > 30 then
						total_lines = total_lines / 10
					else
						total_lines = total_lines / 5
					end
				elseif total_lines % 5 == 0 then
					total_lines = total_lines / 5
				else
					total_lines = 4
				end

			end


			local line_gap = math.max(w / total_lines, 2)

			local anim, new = f:To("LineGap", line_gap, 0.3, 0, 0.3)

			if self.Gone then
				if anim then anim:Stop() end
				self.LineGap = line_gap
			end

			if frW < self.AmmoFrac and self.LastChangedWeapon == wep and valid then
				self:To("AmmoGrad", 1.5, 0.1, 0, 0.3)
				local anim, new = self:To("AmmoMissingFrac", frW, (dist ^ 0.1) * 0.2, 0.2, 0.2)

				if new then
					anim:Then(function()
						self:To("AmmoGrad", 0, 0.6, 0.2, 0.3)
					end)
				end
			end

			draw.BeginMask(f.MaskHeader, f, w, h)
			draw.DrawOp()

			render.SetScissorRect(x, y, x + w * self.AmmoMissingFrac, y + self.HeaderSize, true)
					DarkHUD.RoundedBoxCorneredSize(8, 0, 0, w, self.HeaderSize, firedAmmoColor, 8, 8, 0, 0)

				render.SetScissorRect(x, y, x + w * self.AmmoFrac, y + self.HeaderSize, true)
					DarkHUD.RoundedBoxCorneredSize(8, 0, 0, w, self.HeaderSize, ammoColor, 8, 8, 0, 0)
					surface.SetDrawColor(color_black)
					surface.DrawLine(-5, self.HeaderSize - 1, w, self.HeaderSize - 1)

					local lines = math.min(math.ceil(w / self.LineGap), w)
					lastLines = lines
					for i=1, lines do
						surface.DrawLine(self.LineGap * i, 0, self.LineGap * i, h)
					end


					-- todo: chambered indicator
					--[[
						local chambered = wep.ArcCW and math.max(clip - maxclip, 0) or 0
						local maxChamber = wep.ArcCW and wep:GetChamberSize() or 0
						local chamberFrac = (chambered ~= 0 and maxChamber ~= 0 and chambered / maxChamber) or 0
						local dist = math.abs(self.ChamberedFrac - chamberFrac)

						f:To("ChamberedFrac", chamberFrac, (dist ^ 0.1) * 0.1, 0, 0.2)
					]]
					if total_lines >= 20 then
						total_lines = math.min(math.floor(total_lines / 6), 10)
					end

					surface.SetDrawColor(color_white)
					surface.SetMaterial(MoarPanelsMats.gr)
					local gW = math.floor(4 * self.AmmoGrad)
					surface.DrawTexturedRect(w * self.AmmoFrac - gW, 0, gW, self.HeaderSize)

				render.SetScissorRect(0, 0, 0, 0, false)

			draw.FinishMask()

			lastWeapon = wep
			lastAmmoFrac = frW

			--[[------------------------------]]
			--	  		Weapon info
			--[[------------------------------]]


			------------------------------
			-- 	Weapon name

			local hdH = self.HeaderSize

			local font, sz = Fonts.PickFont("OSB", weaponName, w * 0.4, h - hdH - fonts.WeaponFiremodeHeight)

			if sz > fonts.WeaponNameHeight then
				font = "DarkHUD_WeaponName"
				sz = math.Round(fonts.WeaponNameHeight)
			end

			local iHateFonts = 1 - 0.25 -- 25% of space is wasted for letter extensions or whatever the fuck like `p , q l`

					-- main
			local tH = sz + fonts.WeaponFiremodeHeight
			local tY = hdH + (h - hdH) / 2 - tH / 2

			local wNameW, wNameH = draw.SimpleText(weaponName, font, 8, tY, color_white)
			wNameH = wNameH * iHateFonts

			local nameW = 0	-- full name section width (weapon + firemode)

			local firemode = valid and
								((wep.ArcCW and wep:GetFiremodeName())
									or (wep.Primary and wep.Primary.Automatic and "AUTO" or "SEMI")
								)
			if not valid then firemode = lastVars.firemode end
			lastVars.firemode = firemode

			if firemode then
				surface.SetFont("DarkHUD_Firemode")
				local fW = surface.GetTextSize(firemode)
				nameW = fW
				local fX = math.max(8, 8 + wNameW / 2 - fW / 2)
				surface.SetTextPos(fX, tY + wNameH + 2)
				surface.SetTextColor( lazy.Get("DHFM") or lazy.Set("DHFM", Color(130, 130, 130)) )
				surface.DrawText(firemode)
			end

			nameW = math.max(nameW, wNameW)

			------------------------------
			--	Mag/reserve counters

			local ammoW = 0
			local magW = 0
			local resW = 0
			surface.SetFont("DarkHUD_AmmoMagazine")
			magW = surface.GetTextSize(clip)
			ammoW = ammoW + magW

			if not self.ReserveAmmo or self.Gone then
				self.ReserveAmmo = reserve
			else
				self:To("ReserveAmmo", reserve, 0.5, 0, 0.3)
			end

			reserve = math.floor(self.ReserveAmmo)

			surface.SetFont("DarkHUD_AmmoReserve")
			resW = surface.GetTextSize(reserve)
			ammoW = ammoW + resW

			local ammoX = 8 + nameW + 8 + 8*scale
			local ammoY = tY + tH / 2

			if not self.AmmoX or self.Gone then
				self.AmmoX = ammoX
			else
				self:To("AmmoX", ammoX, 0.3, 0, 0.2)
			end

			ammoX = self.AmmoX

			local magH = fonts.WeaponMagHeight
			local resH = fonts.WeaponReserveHeight


			-- first draw reserve because we already have the font set
			surface.SetTextColor( lazy.Get("DHReserve") or lazy.Set("DHReserve", Color(100, 100, 100)) )
			surface.SetTextPos(ammoX + magW + fonts.WeaponDivWidth, ammoY - magH / 2 + (magH - resH) * iHateFonts)
			surface.DrawText(reserve)

			-- then draw the mag
			surface.SetTextColor( lazy.Get("DHCurAmmo") or lazy.Set("DHCurAmmo", Color(130, 130, 130)) )
			surface.SetFont("DarkHUD_AmmoMagazine")
			surface.SetTextPos(ammoX, ammoY - magH / 2)
			surface.DrawText(clip)

			surface.SetTextColor( lazy.Get("DHReserve") )

			surface.SetFont("DarkHUD_AmmoDivide")
			surface.SetTextPos(ammoX + magW, ammoY - magH / 2 - 8)
			surface.DrawText("/")
		end

		--self.Gone = false -- if the panel is being painted that means it ain't gone

		::emit::
		DarkHUD:Emit("AmmoPainted", self, w, h) -- ;)
	end

end


if DarkHUD.Vitals then
	DarkHUD.CreateAmmo()
end

hook.Add("HUDPaint", "DarkHUD_Ammo", function()
	local f = DarkHUD.Ammo
	if not IsValid(f) then return end

	DarkHUD:Emit("PrePaintAmmo", f)
	f.NoDraw = not DarkHUD.SettingFrame:GetValue()
	f:PaintManual()
	DarkHUD:Emit("PostPaintAmmo", f)
end)

DarkHUD:On("Ready", "CreateAmmo", DarkHUD.CreateAmmo)