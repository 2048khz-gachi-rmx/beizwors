ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
include("shared.lua")
AddCSLuaFile("shared.lua")


local an
local noise = CreateMaterial("aib_noise6", "UnlitGeneric", {
	["$basetexture"] = "engine/noise-blur-256x256.vtf",
	["$alpha"] = 0.1
})

local scan = CreateMaterial("aib_scanline3", "UnlitGeneric", {
	["$basetexture"] = "dev/dev_scanline",
	["$alpha"] = 0.06
})

noise:SetInt("$flags", bit.bor(noise:GetInt("$flags"), 128))
scan:SetInt("$flags", bit.bor(scan:GetInt("$flags"), 128))

function ENT:Acq()
	an = an or Animatable("aibkey")
end

function ENT:QMOnOpen(qm, pnl)
	local canv = qm:GetCanvas()
	local hld = vgui.Create("FFrame", canv)
	-- local lay = vgui.Create("FIconLayout", canv)
	hld:SetCloseable(false, true)
	hld.HeaderSize = 28

	canv.Holder = hld
	hld.Color = Color(40, 40, 40, 250)

	hld:SetWide(canv:GetWide() * 0.25)
	hld:CenterHorizontal()

	hld.WantY = canv:GetTall() * 0.55
	hld.GoneY = canv:GetTall() * 0.58
	hld.Y = hld.GoneY

	hld:PopIn()
	hld:MoveTo(hld.X, hld.WantY, 0.3, 0, 0.3)

	hld:CacheShadow(4, {4, 8}, 4)

	function hld:PostPaint(w, h)
		draw.SimpleText("Your access cards", "EXSB24", w / 2, self.HeaderSize / 2, color_white, 1, 1)
	end

	-- generate card slots
end

function ENT:QMOnBeginClose(qm, pnl)
	local canv = qm:GetCanvas()
	local hld = canv.Holder

	hld:MoveTo(hld.X, hld.GoneY, qm:GetTime(), 0, 0.3)
end

function ENT:QMOnReopen(qm, pnl)
	local canv = qm:GetCanvas()
	local hld = canv.Holder

	hld:MoveTo(hld.X, hld.WantY, qm:GetTime(), 0, 0.3)
end


function ENT:Initialize()
	self:SetBodygroup(1, 1)

	local qm = self:SetQuickInteractable()

	qm:SetTime(0.2)
	qm.OnOpen = function(qm, _, pnl) self:QMOnOpen(qm, pnl) end
	qm.OnClose = function(qm, _, pnl) self:QMOnBeginClose(qm, pnl) end
	qm.OnReopen = function(qm, _, pnl) self:QMOnReopen(qm, pnl) end
end

function ENT:RenderScreen()
	local ep = EyePos()
	local dist = ep:Distance(self:GetPos())
	local ac = true
	local t = self:GetTable()
	local dfr = t.Dfr or 0

	if dist < 256 then
		an:MemberLerp(t, "Dfr", 0, 1.2, 0, 0.2)
	else
		an:MemberLerp(t, "Dfr", 1, 0.4, 0, 2.2)
		ac = false
	end

	t.Dfr = t.Dfr or 0


	local w, h = 598, 280
	local x, y = 0, 0

	local nh = h * (1 - math.ease.InBack(t.Dfr or 0))
	local a = Ease(1 - t.Dfr, 0.3)

	if ac then
		-- appear
		y = h - nh
		h = nh
	else
		y = h - nh
		h = nh
	end

	y = math.ceil(y)
	surface.SetDrawColor(220, 200, 100, 110 * a)
	surface.DrawRect(x, y, w, h)

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(noise)

	noise:SetFloat("$alpha", math.RemapClamp(dist, 128, 384, 0.02, 0.05))

	local ru = math.random()
	local rv = math.random()
	local noiseRes = dist * 2

	surface.DrawTexturedRectUV(x, y, w, h, ru, rv, w / noiseRes + ru, h / noiseRes + rv)

	surface.SetMaterial(scan)
	surface.SetDrawColor(0, 0, 0, 255)
	local tv = (t.tvt or 0) / -6
	t.tvt = (t.tvt or 0) + FrameTime() * (2.2 + 0.8 * math.random())

	surface.DrawTexturedRectUV(x, y, w, h, 0, tv, 1, h / 768 + tv)

	local bSz = 8
	surface.SetDrawColor(0, 0, 0, 215 * a)
	surface.DrawRect(x + bSz, y + bSz, w - bSz * 2, h - bSz)

	t.ic = t.ic or Icons.Arrow:Copy()
	local aW, aH = 28, 48
	local offsetToCardReader = 54

	for i=0, 2 do
		local aFr = ((CurTime() * 1 + i / 3) % 1.33) ^ 0.3 * 1
		local pa = (1 - aFr) * 255
		local aH = math.ceil(aH + (aH * (1 - aFr) * 0.5))
		local naW = math.ceil(aW * (0.8 + (1 - aFr) * 0.2))
		t.ic:GetColor().a = pa * a
		t.ic:Paint(x + w - offsetToCardReader,
			y + h - aW / 2 - i * aW * 0.66,
			naW, aH,
			-90)
	end

	local avW = w - bSz - offsetToCardReader - aH + 2
	local tx, ty = bSz, y + h - aW / 2

	local _, th = draw.SimpleText("Access Level: 1488", "EX40", tx + avW, ty, color_white:IAlpha(a * 255), 2, 4)
	ty = ty - th

	local _, hh = draw.SimpleText("Insert Keycard", "EXB64", tx + avW, ty + draw.GetFontHeight("OSB64") * 0.125,
		color_white:IAlpha(a * 255), 2, 4)
end

local off = Vector (0.28, -13.411619186401, 20 * 280 / 380)
local ang = Angle(0, 90, 90)

function ENT:Draw()
	self:Acq()
	self:SetBodygroup(1, 1) -- i hate this engine

	self:DrawModel()

	cam.Start3D2D(self:LocalToWorld(off), self:LocalToWorldAngles(ang), 0.05)
		xpcall(self.RenderScreen, GenerateErrorer("AIBKeyReader"), self)
	cam.End3D2D()
end