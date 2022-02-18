AddCSLuaFile()
include('shared.lua')
ENT.Base = "base_gmodentity"
ENT.Type = "anim"

ENT.Model 		= "models/hunter/blocks/cube025x025x025.mdl"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local function LC(col, dest, vel)
	local v = 10
	if not IsColor(col) or not IsColor(dest) then return end
	if isnumber(vel) then v = vel end
	local r = Lerp(FrameTime()*v, col.r, dest.r)
	local g = Lerp(FrameTime()*v, col.g, dest.g)
	local b = Lerp(FrameTime()*v, col.b, dest.b)
	local a = Lerp(FrameTime()*v, col.a or 255, dest.a or 255)
	return Color(r,g,b,a)
end

local function L(s,d,v)
	if not v then v = 5 end
	if not s then s = 0 end
	return Lerp(FrameTime()*v, s, d)
end

function ENT:Initialize()
	self:SetModel(self.Model)

	local min = self:GetMinsZone()
	local max = self:GetMaxsZone()

	self:SetRenderBoundsWS(min, max, Vector(2,2,2))

	self.min = min
	self.max = max

	self.BoxCol = Color(25,225,25,0)
end

local ba = 0
local exp = Vector(2, 2, 0)
local drawDist = 2048

local colInac = Color(5, 5, 5)
local colAc = Color(25, 225, 25)
local useCol = Color(0, 0, 0)

function ENT:Draw()		--shhhh sneaky workaround
	self.A = self.A or 0
	local pos = self:GetPos()
	local in_sz = CachedLocalPlayer():GetNWInt("Safezone", 0) ~= 0

	local min = self:GetMinsZone()
	local max = self:GetMaxsZone()
	local mepos = EyePos()

	local bmin = min - pos
	local bmax = max - pos

	bmin.z = -512
	--bmax.z = 512

	self:SetRenderBoundsWS(min, max, Vector(2, 2, 2))

	render.SetColorMaterial()

	render.DrawBox(pos, angle_zero, bmin, bmax, self.BoxCol)	--render outwards
	bmin:Sub(exp)
	bmax:Sub(exp)
	render.DrawBox(pos, angle_zero, bmax, bmin, self.BoxCol)	--render inwards

	local desCol = colInac

	if mepos:WithinAABox(min, max) then
		ba = math.min(L(ba, 20, 15), 20)
		desCol = colAc
		self.BoxCol:Lerp(FrameTime() * 15, self.BoxCol, desCol)
		self.BoxCol.a = ba

		return
	end

	-- cba to do proper anim
	self.BoxCol:Lerp(FrameTime() * 15, self.BoxCol, desCol)
	self.BoxCol.a = ba * 2

	if not in_sz then
		local vec, dir, frac = 	util.IntersectRayWithOBB(mepos, LocalPlayer():EyeAngles():Forward() * drawDist,
			pos, angle_zero, bmin, bmax )

		if vec then
			ba = L(ba, 60, 15)
			local ang = dir:Angle()

			ang.p = 0
			ang:RotateAroundAxis(ang:Up(), 90)
			ang:RotateAroundAxis(ang:Forward(), 90)

			cam.Start3D2D(vec, ang, 0.2)
				local dist = frac * 2048

				if dist < 512 and dist > 192 then
					self.A = math.max(frac*50, L(self.A, 255, 15))
				else
					self.A = math.min(frac*1000, L(self.A, 0, 25))
				end
				--surface.SetDrawColor(20, 20, 20, 50)
				--surface.DrawRect(0,0,64,64)
				surface.SetTextColor(255, 255, 255, self.A)
				draw.SimpleText2("SAFEZONE", "OSB128", 0, 0, nil, 1, 1)
			cam.End3D2D()

		 else

		 	ba = L(ba, 0, 2)

		 end
	end
end
