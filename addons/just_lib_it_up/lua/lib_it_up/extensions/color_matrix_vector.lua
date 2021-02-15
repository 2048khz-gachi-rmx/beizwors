LibItUp.SetIncluded()

local COLOR = FindMetaTable("Color")
local MATRIX = FindMetaTable("VMatrix")
local VECTOR = FindMetaTable("Vector")

Colors = Colors or {}

Colors.Green = Color(60, 235, 60)
Colors.Red = Color(255, 70, 70)

Colors.DarkerRed = Color(205, 40, 40)

Colors.LighterGray = Color(75, 75, 75)
Colors.LightGray = Color(65, 65, 65)
Colors.Gray = Color(50, 50, 50)
Colors.DarkGray = Color(35, 35, 35)
Colors.DarkerGray = Color(20, 20, 20)

-- i used gray's too much already and they're all quite dark
-- i need a light-gray color palette now but all `light + gray` are already taken
-- this is my shitty solution :v

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

local function ColorChangeHSV(col, h, s, v)
	local ch, cs, cv = col:ToHSV()

	col.r, col.g, col.b = HSVToColorRGB(ch + (h or 0), cs + (s or 0), cv + (v or 0))
	return col
end

if CLIENT then
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

COLOR.HSVMod = COLOR.ModHSV
function IsMaterial(m)
	return type(m) == "IMaterial"	--we can't really compare m.MetaName because m might not even be a table
end

local mx = Matrix()
function MATRIX:Reset()
	self:Set(mx)
end

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