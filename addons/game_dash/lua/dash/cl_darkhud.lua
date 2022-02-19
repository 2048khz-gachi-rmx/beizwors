--

Dash.Icon = Icon("https://i.imgur.com/mClnf6i.png", "ffw_64.png")
	:SetAlignment(5)

local handle = BSHADOWS.GenerateCache("DarkHUD_Dash", 128, 128)

handle:SetGenerator(function(self, w, h)
	if not Dash.Icon:GetMaterial() then return false end

	surface.SetDrawColor(255, 255, 255)
	Dash.Icon:Paint(w / 2, h / 2, w, w * 0.75)

	return true
end)

local spr = {16, 8}

local flash = CreateMaterial("dashflash4", "UnlitGeneric", {
	["$basetexture"] = "sprites/light_glow02.vtf",
	["$additive"] = "1",
	["$translucent"] = "1",
	["$vertexcolor"] = "1",
	["$vertexalpha"] = "1",
})

flash:SetInt("$flags", bit.bor(flash:GetInt("$flags"), 128, 2097152))
flash:Recompute()

local an = Animatable("dash")

function Dash.OnReady(ply)
	if not IsFirstTimePredicted() then return end
	an.ReadyFlash = 0.06
	an:To("ReadyFlash", 1, 0.3, 0, 0.2, true)

	an.ReadyAlpha = 1
	an:To("ReadyAlpha", 0, 0.3, 0.1, 0.3, true)
end

function Dash.PaintAbility(self, x, y, sz)
	local me = CachedLocalPlayer()
	local cd, till = Offhand.GetCooldown("Dash", me)
	cd = math.max(0, till - PredTime())

	local frac = 1 - math.TimeFraction(0, Dash.DashCooldown, cd)

	local ac = frac == 1 and me:GetNW2Bool("DashReady", true)
	self:To("DashRdyFr", ac and 1 or 0, ac and 0.3 or 0, 0, 0.3)

	draw.LerpColor(self.DashRdyFr or 0, Dash.Icon:GetColor(),
		color_white, Colors.LightGray)

	if ac and not DarkHUD.Setting3D:GetValue() then -- additive doesnt work on RTs !?
		local fr = an.ReadyFlash or 0
		local a =  an.ReadyAlpha or 0
		local fH = ScrH() * 1.4 * fr

		local fsz = sz * 3 + 200 * math.max(0, 0.7 - fr) -- wtf

		flash:SetFloat("$alpha", a)
			surface.SetMaterial(flash)

			local f1H, f1sz = fH * 0.95, fsz * 0.9
			surface.SetDrawColor(Colors.Money)
			surface.DrawTexturedRect(x - f1sz / 2 + sz / 2, y + sz / 2 - f1H / 2, f1sz, f1H)

			f1H, f1sz = fH * 1.25, fsz * 1.25
			surface.SetDrawColor(Colors.Sky)
			surface.DrawTexturedRect(x - f1sz / 2 + sz / 2, y + sz / 2 - f1H / 2, f1sz, f1H)

			surface.SetDrawColor(255, 255, 255)
			surface.DrawTexturedRect(x - fsz / 2 + sz / 2, y + sz / 2 - fH / 2, fsz, fH)
		flash:SetFloat("$alpha", 1)
	end

	handle:CacheRet(4, spr, 4)
	handle:Paint(x, y, sz, sz)

	draw.BeginMask()
		surface.SetDrawColor(255, 255, 255)
		surface.DrawRect(x + math.ceil(sz * (1 - frac)), y, sz * frac, sz)
	draw.DrawOp()
		Dash.Icon:Paint(x + sz / 2, y + sz / 2, sz, sz * 0.75)
	draw.FinishMask()
end