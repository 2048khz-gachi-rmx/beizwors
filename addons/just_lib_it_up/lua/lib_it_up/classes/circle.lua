-- YOU MAY HAVE DA STENCILS, BUT I HAVE DA ANIMATIONS

if not LibItUp.Animatable then include("animatable.lua") end
setfenv(0, _G)
LibItUp.Circle = LibItUp.Circle or LibItUp.Animatable:callable()

local sin = math.sin
local cos = math.cos
local mrad = math.rad

local circ = LibItUp.Circle
circ.AutoInitialize = false

local animakeys = {
	"StartAngle",
	"EndAngle",
	"Radius"
}

function circ:Initialize()
	self._Polies = {}
	self._Template = nil	-- new templates generated whenever the segment count changes

	self._SegmentCount = 60 -- 60 usually suffices

	-- intentionally not marked as `internal` so you can use :To on these mfers
	self.StartAngle = 0
	self.EndAngle = 360
	self.Radius = 0

	self.OutlineStartAngle = 0
	self.OutlineEndAngle = 360
	self.OutlineRadius = 0

	self.__parent.Initialize(self, false)
end

function circ:_GenerateSubPoly(ang, x, y, rad, frac)
	local s, c = cos( mrad(ang) - math.pi / 2 ), sin( mrad(ang) - math.pi / 2 )

	local ret = {
		x = x + s * rad,
		y = y + c * rad,
		u = s/2 + 0.5,
		v = c/2 + 0.5
	}

	return ret
end


function circ:_GenerateTemplate()
	local circ = {}
	self._Template = circ

	local seg = self._SegmentCount

	local segAngle = 360 / seg 	-- how many deg 1 poly covers
	local segRad = mrad(segAngle)

	for i=1, seg+1 do
		local ang = segRad * (i-1) - math.pi/2 -- in radians
		local s = cos(ang)
		local c = sin(ang)

		local p = {
			x = s,
			y = c,
			u = s/2 + 0.5,
			v = c/2 + 0.5
		}

		circ[i] = p
	end

end

function circ:_RegeneratePolies(x, y, startAngle, endAngle, rad, reusePolies)

	--[[

	local startAngle = self.StartAngle
	local endAngle = self.EndAngle

	local rad = self.Radius

	]]

	local seg = self._SegmentCount
	local segAngle = 360 / seg

	local sa = math.min(endAngle, startAngle)
	local ea = math.max(endAngle, startAngle)

	local poly = reusePolies or {}

	poly[1] = {
		x = x,
		y = y,
		u = 0.5,
		v = 0.5
	}

	local curPoly = 2

	local skipFirst = math.ceil(sa / segAngle)
	local useSegs = math.abs(ea - sa) / segAngle

	if useSegs % 1 ~= 0 then
		poly[curPoly] = self:_GenerateSubPoly(sa, x, y, rad)
		curPoly = curPoly + 1
		useSegs = math.floor(useSegs)
	end
	

	for i=0, useSegs-1 do
		local t = self._Template[skipFirst + i + 1]

		poly[curPoly + i] = {
			x = t.x * rad + x,
			y = t.y * rad + y,
			u = t.u,
			v = t.v
		}

	end
	
	poly[curPoly + useSegs] = self:_GenerateSubPoly(ea, x, y, rad)
	poly[curPoly + useSegs + 1] = nil

	return poly
end

function circ:SetOutlined(b)
	b = (b == nil and true) or b

	if b then
		self._Outlined = true
	end
end

function circ:Paint(x, y)
	self:AnimationThink()

	for k,v in ipairs(animakeys) do
		if self[v] ~= self["_Last" .. v] then
			self._SettingsChanged = true
			self["_Last" .. v] = self[v]
		end

		if self["Outline" .. v] ~= self["_LastOutline" .. v] then
			self._OutlineSettingsChanged = true
			self["_LastOutline" .. v] = self[v]
		end
	end

	if not self._Template then self:_GenerateTemplate() end

	local startAngle = self.StartAngle
	local endAngle = self.EndAngle
	local rad = self.Radius

	if self._Outlined then

		if not self._OutlinePolies or self._LastX ~= x or self._LastY ~= y then
			self._OutlinePolies = self._OutlinePolies or {}
			local poly = self:_RegeneratePolies(x, y, startAngle, endAngle, rad, self._OutlinePolies)
		end

	end

	if self._LastX ~= x or self._LastY ~= y or self._SettingsChanged then
		self:_RegeneratePolies(x, y, startAngle, endAngle, rad, self._Polies)
		self._LastX = x
		self._LastY = y
		self._SettingsChanged = false
	end

	surface.DrawPoly(self._Polies)
end

local function ChangeAccessor(k)
	circ["Get" .. k] = function(s)
		return s[k]
	end

	circ["Set" .. k] = function(s, v)
		CheckArg(1, v, isnumber, "number")

		if s[k] ~= v then
			s[k] = v
			s._SettingsChanged = true
		end

		return s
	end
end

local function ChangeOutlineAccessor(k)

	circ["GetOutline" .. k] = function(s)
		return s["Outline" .. k]
	end

	circ["SetOutline" .. k] = function(s, v)
		CheckArg(1, v, isnumber, "number")

		if s["Outline" .. k] ~= v then
			s["Outline" .. k] = v
			s._OutlineSettingsChanged = true
		end

		return s
	end

end

ChangeOutlineAccessor("Radius")
ChangeOutlineAccessor("EndAngle")
ChangeOutlineAccessor("StartAngle")
-- outline reuses outer segments amt

ChangeAccessor("Radius")
ChangeAccessor("EndAngle")
ChangeAccessor("StartAngle")

function circ:SetSegments(amt)
	CheckArg(1, amt, isnumber, "number")

	if self._SegmentCount ~= amt then
		self._SegmentCount = amt
		self._SettingsChanged = true
		self._Template = nil
	end
end