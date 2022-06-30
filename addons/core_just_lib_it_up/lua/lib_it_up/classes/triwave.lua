setfenv(1, _G)

TriWave = TriWave or Object:callable() -- an odd object the math for which started cropping up way too frequently

function TriWave:Initialize(t)
	self.timer = isfunction(t) and t or CurTime

	self.changed = self.timer()
	self.changedWith = 0

	self.fr = 0

	self.down = -1
	self.up = 1

	self.dir = self.down
	self.state = false
	self.floor = 0
	self.ceil = 1
end

function TriWave:SetBounds(f, c)
	self.floor = f
	self.ceil = c

	return self
end

function TriWave:SetSpeeds(down, up)
	self.down, self.up = down, up

	if self.state then
		self.dir = self.up
	else
		self.dir = self.down
	end

	return self
end

function TriWave:SetDirection(up)
	if self.state == up then return end

	self.changedWith = self:Get()
	self.changed = self.timer()

	self.state = up
	self.dir = up and self.up or self.down

	return self
end

function TriWave:GetCurrentBound()
	return self.state and self.ceil or self.floor
end

function TriWave:GetBounds()
	return self.floor, self.ceil
end

function TriWave:GetDirection()
	return self.state, self.dir
end

function TriWave:Set(v)
	self.changedWith = v
	self.changed = self.timer()
end

function TriWave:Get()
	local cur = self.timer()
	local dt = cur - self.changed

	return math.Clamp(self.changedWith + dt * self.dir, self.floor, self.ceil)
end

function TriWave:GetTimeSinceSwitch()
	return self.timer() - self.changed
end

local TESTING = false
if not TESTING then return end

if IsValid(_F) then _F:Remove() end

local f = vgui.Create("FFrame")
_F = f

f:SetSize(400, 300)
f:Center()
f:MakePopup()

local tri = TriWave:new()

function f:PostPaint(w, h)
	local dir = input.IsMouseDown(MOUSE_LEFT)
	tri:SetDirection(dir)

	White()
	surface.DrawRect(w / 2 - 2,
		Lerp(tri:Get(), h / 2 - 100, h / 2 + 100),
		4, 4)

	surface.DrawLine(4, h / 2 - 100, w - 8, h / 2 - 100)
	surface.DrawLine(4, h / 2 + 100, w - 8, h / 2 + 100)

	Colors.Sky:SetDraw()
	surface.DrawRect(w / 2 - 2,
		Lerp(math.ease.InOutCubic(tri:Get()), h / 2 - 100, h / 2 + 100),
		4, 4)
end