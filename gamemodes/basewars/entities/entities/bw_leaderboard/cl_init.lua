include("shared.lua")
AddCSLuaFile("shared.lua")

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()

end

local b = bench("Scoreboard", 600)

local bgBord = Color(0, 0, 0)
local bordSz = 8
local bg = Color(30, 30, 30)
local scontr = Color(170, 170, 170)

function ENT:PaintPlayer(x, y, rw, rh, dat, is_me)
	draw.RoundedBox(16, x, y, rw, rh, is_me and Colors.Sky or Colors.Gray)
end

function ENT:PaintPlayers(y, w, h, off)
	local nw = self:GetNW()
	if not nw then return end

	local inY = y
	local col = w * 0.07
	local colSz = (w - col * 2.2) / 2

	local wantRows = 6
	local pad = 16
	local needH = math.floor( (h - inY - off) / wantRows ) - pad

	local mySid = CachedLocalPlayer():SteamID64()
	local have_me = false

	for k,v in ipairs(nw:GetNetworked()) do
		local is_me = v.sid == mySid
		self:PaintPlayer(col, y, colSz, needH, v, is_me)
		y = y + needH + pad

		if y > h - off - needH then
			col = w - col - colSz
			y = inY
		end

		have_me = have_me or is_me
	end

	if have_me then return end

	local dotFont = "EXB128"
	local th = draw.GetFontHeight(dotFont)
	draw.SimpleText("...", dotFont, col + colSz / 2, y + needH / 2 - th * 0.125, color_white, 1, 1)
end

function ENT:DrawDisplay()
	local st = SysTime()

	bgBord:SetHSV(st * 75, 0.7, 1)
	local w, h = 1423, 711

	draw.SetRainbowGradient(true)

	local v0, v1 = (st * 0.2) % 1; v1 = v0 + 0.5
	local u0, u1 = (st * 0.2 + 0.5) % 1; u1 = u0 + 0.5

	surface.SetDrawColor(255, 255, 255)
	surface.DrawTexturedRectUV(0, 0, w / 2, h, 0, v1, 1, v0)
	surface.DrawTexturedRectUV(w / 2, 0, w / 2, h, 0, v0, 1, v1)

	draw.SetRainbowGradient()
	surface.DrawTexturedRectUV(bordSz, 0, w - bordSz * 2, h / 2, u0, 0, u1, 1)
	surface.DrawTexturedRectUV(bordSz, h - bordSz, w - bordSz * 2, bordSz, u1, 0, u0, 1)

	surface.SetDrawColor(bg:Unpack())
	surface.DrawRect(bordSz, bordSz, w - bordSz * 2, h - bordSz * 2)

	local tw, th = draw.SimpleText("Leaderboard", "EXSB96", w / 2, 0, color_white, 1)

	local xpad = w * 0.2

	surface.SetDrawColor(scontr:Unpack())
	surface.DrawRect(xpad, th, w - xpad * 2, 4)

	local ypad = th * 0.25
	self:PaintPlayers(th + 4 + ypad, w, h, ypad)
end

local depth = 1.6
local depthFar = 3
local farDist = 512

local off = Vector(71, 142.3, depth)


local temp = Vector()

function ENT:Draw()
	--self:DrawModel()

	b:Open()
	local pos = self:LocalToWorld(off)
	local ang = self:GetAngles()

	ang:RotateAroundAxis(ang:ToUp(temp), -90)

	cam.Start3D2D(pos, ang, 0.2)
		xpcall(self.DrawDisplay, GenerateErrorer("LeaderboardDisplay"), self)
	cam.End3D2D()
	b:Close():print()
end