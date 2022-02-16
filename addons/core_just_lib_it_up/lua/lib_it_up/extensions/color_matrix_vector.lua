LibItUp.SetIncluded()

local COLOR = FindMetaTable("Color")
local MATRIX = FindMetaTable("VMatrix")
local VECTOR = FindMetaTable("Vector")
local ANGLE = FindMetaTable("Angle")

Colors = Colors or {}

Colors.Green = Color(60, 235, 60)
Colors.Red = Color(255, 70, 70)

Colors.DarkerRed = Color(205, 40, 40)

-- shit
Colors.LighterGray = Color(110, 110, 110)
Colors.MediumGray = Color(85, 85, 85)
Colors.LightGray = Color(65, 65, 65)
Colors.Gray = Color(50, 50, 50)
Colors.DarkGray = Color(35, 35, 35)
Colors.DarkerGray = Color(20, 20, 20)

Colors.White = Color(255, 255, 255)
Colors.DarkWhite = Color(220, 220, 220)
Colors.DarkerWhite = Color(182, 182, 182)

Colors.Sky = Color(50, 150, 250)

Colors.Money = Color(100, 220, 100)
Colors.Level = Color(110, 110, 250)

Colors.Golden = Color(205, 160, 50)
Colors.Yellowish = Color(250, 210, 120)

Colors.Blue = Color(60, 140, 200)

Colors.Warning = Color(255, 210, 65)
Colors.Error = Color(230, 75, 75)

-- better for buttons
Colors.Greenish = Color(88, 188, 88)
Colors.Reddish = Color(175, 68, 68)
Colors.Purpleish = Color(230, 110, 255)

-- THANK U BASED GigsD4X
-- https://gist.github.com/GigsD4X/8513963

local rets = {
	function(v, p, q, t) return v, t, p end,
	function(v, p, q, t) return q, v, p end,
	function(v, p, q, t) return p, v, t end,
	function(v, p, q, t) return p, q, v end,
	function(v, p, q, t) return t, p, v end,
	function(v, p, q, t) return v, p, q end
}

local function HSVToColorRGB(hue, saturation, value)
	value = math.Clamp(value, 0, 1)
	saturation = math.Clamp(saturation, 0, 1)

	if saturation == 0 then
		return value * 255, value * 255, value * 255
	end

	hue = hue % 360

	local hue_sector, hue_sector_offset = math.modf(hue / 60)

	-- in the gist, hue_sector_offset is a negative value, so to use modf
	-- and compensate for it, i changed the signs in maths below

	-- also  *255 because gmod

	local p = value * ( 1 - saturation ) * 255
	local q = value * ( 1 - saturation * hue_sector_offset ) * 255
	local t = value * ( 1 - saturation * ( 1 - hue_sector_offset ) ) * 255

	value = value * 255
	--also utilize a jump table here

	return rets[hue_sector + 1] (value, p, q, t)
end

local function ColorModHSV(col, h, s, v)
	col.r, col.g, col.b = HSVToColorRGB(h, s, v)
	return col
end

local function ColorMulHSV(col, h, s, v)
	local ch, cs, cv = col:ToHSV()
	col.r, col.g, col.b = HSVToColorRGB(ch * h, cs * s, cv * v)
	return col
end

local function ColorChangeHSV(col, h, s, v)
	local ch, cs, cv = col:ToHSV()

	col.r, col.g, col.b = HSVToColorRGB(ch + (h or 0), cs + (s or 0), cv + (v or 0))
	return col
end

if CLIENT then
	draw.ColorMulHSV = ColorMulHSV
	draw.ColorModHSV = ColorModHSV
	draw.ColorChangeHSV = ColorChangeHSV
end

function COLOR:Set(col, g, b, a)
	if IsColor(col) then
		self.r = col.r
		self.g = col.g
		self.b = col.b
		self.a = col.a
	else
		self.r = col or self.r
		self.g = g or self.g
		self.b = b or self.b
		self.a = a or self.a
	end

end

function COLOR:Copy()
	return Color(self.r, self.g, self.b, self.a)
end

function COLOR:SetHSV(h, s, v)
	return ColorModHSV(self, h, s, v)
end

function COLOR:ModHSV(h, s, v)
	return ColorChangeHSV(self, h, s, v)
end

function COLOR:MulHSV(h, s, v)
	return ColorMulHSV(self, h, s, v)
end

COLOR.HSVMod = COLOR.ModHSV

function COLOR:SetDraw()
	surface.SetDrawColor(self.r, self.g, self.b, self.a or 255)
end

function COLOR:SetText()
	surface.SetTextColor(self.r, self.g, self.b, self.a or 255)
end

function COLOR:Lerp(fr, from, to)
	draw.LerpColor(fr, self, to, from)
end

function IsMaterial(m)
	return type(m) == "IMaterial"	--we can't really compare m.MetaName because m might not even be a table
end

MATRIX.Reset = MATRIX.Identity -- bruh

local vec = Vector()
local ang = Angle()

local mtrx_methods = {
	"Translate", 		vec,
	"Scale", 			vec,

	"SetTranslation", 	vec,
	"SetScale", 		vec,

	"Rotate", 			ang,
	"SetAngles", 		ang
}

for i=1, #mtrx_methods, 2 do
	local fn = mtrx_methods[i]
	local typ = mtrx_methods[i + 1]

	MATRIX[fn .. "Number"] = function(self, x, y, z)
		typ:SetUnpacked(x or 0, y or 0, z or 0)
		MATRIX[fn] (self, typ)
	end
end

local cos, sin, rad = math.cos, math.sin, math.rad

function ANGLE:ToForward(inVec)
	local p, y = self:Unpack()
	p, y = rad(p), rad(y)

	local sy, cy = sin(y), cos(y)
	local sp, cp = sin(p), cos(p)

	inVec:SetUnpacked(
		cy * cp,
		sy * cp,
		-sp
	)

	return inVec
end

function ANGLE:ToRight(inVec)
	local p, y, r = self:Unpack()
	p, y, r = rad(p), rad(y), rad(r)

	local sy, cy = sin(y), cos(y)
	local sp, cp = sin(p), cos(p)
	local sr, cr = sin(r), cos(r)

	inVec:SetUnpacked(
		-cy * sp * sr + sy * cr,
		-sy * sp * sr - cy * cr,
		-cp * sr
	)

	return inVec
end

function ANGLE:ToUp(inVec)
	local p, y, r = self:Unpack()
	p, y, r = rad(p), rad(y), rad(r)

	local sy, cy = sin(y), cos(y)
	local sp, cp = sin(p), cos(p)
	local sr, cr = sin(r), cos(r)

	inVec:SetUnpacked(
		cr * sp * cy + sr * sy,
		cr * sp * sy - sr * cy,
		cp * cr
	)

	return inVec
end

local toChain = {
	"Add", "Sub", "Mul", "Div"
}

for k,v in pairs(toChain) do
	VECTOR["C" .. v] = function(self, ...)
		self[v](self, ...)
		return self
	end
end

local lerp = Lerp

function LerpSource(dlt, from, to)
	from[1] = Lerp(dlt, from[1], to[1])
	from[2] = Lerp(dlt, from[2], to[2])
	from[3] = Lerp(dlt, from[3], to[3])
end

function LerpInto(dlt, from, to, into)
	into[1] = Lerp(dlt, from[1], to[1])
	into[2] = Lerp(dlt, from[2], to[2])
	into[3] = Lerp(dlt, from[3], to[3])

	return into
end