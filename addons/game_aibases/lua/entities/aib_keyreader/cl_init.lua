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

function ENT:Initialize()
	self:GetRT()
	self:SetBodygroup(1, 1)
end

function ENT:RenderScreen()
	local ep = EyePos()
	local dist = ep:Distance(self:GetPos())
	local ac = true
	local dfr = self.Dfr or 0

	if dist < 256 then
		an:MemberLerp(self, "Dfr", 0, 1.2, 0, 0.2)
	else
		an:MemberLerp(self, "Dfr", 1, 0.4, 0, 2.2)
		ac = false
	end

	local w, h = 598, 280
	local x, y = 0, 0

	local nh = h * (1 - math.ease.InBack(self.Dfr))
	local a = 1

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
	local tv = (self.tvt or 0) / -6
	self.tvt = (self.tvt or 0) + FrameTime() * (2.2 + 0.8 * math.random())

	surface.DrawTexturedRectUV(x, y, w, h, 0, tv, 1, h / 768 + tv)

	local bSz = 8
	surface.SetDrawColor(0, 0, 0, 215 * a)
	surface.DrawRect(x + bSz, y + bSz, w - bSz * 2, h - bSz)

	self.ic = self.ic or Icons.Arrow:Copy()
	local aW, aH = 28, 48
	local offsetToCardReader = 54

	for i=0, 2 do
		local aFr = ((CurTime() * 1 + i / 3) % 1.33) ^ 0.3 * 1
		local a = (1 - aFr) * 255
		local aH = math.ceil(aH + (aH * (1 - aFr) * 0.5))
		local naW = math.ceil(aW * (0.8 + (1 - aFr) * 0.2))
		self.ic:GetColor().a = a
		self.ic:Paint(x + w - offsetToCardReader,
			y + h - aW / 2 - i * aW * 0.66,
			naW, aH,
			-90)
	end

	local avW = w - bSz - offsetToCardReader - aH + 2
	local tx, ty = bSz, h - aW / 2

	
	local _, th = draw.SimpleText("Access Level: 1488", "EX40", tx + avW, ty, color_white, 2, 4)
	ty = ty - th

	local _, hh = draw.SimpleText("Insert Keycard", "EXB64", tx + avW, ty + draw.GetFontHeight("OSB64") * 0.125, color_white, 2, 4)
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