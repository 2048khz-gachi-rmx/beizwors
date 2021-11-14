local META = FindMetaTable("Panel")

function META:SetInput(b)
	if b == nil then b = false end

	self:SetMouseInputEnabled(b)
	self:SetKeyboardInputEnabled(b)
end

function META:GetCenter(xfrac, yfrac)
	xfrac = xfrac or 0.5
	yfrac = yfrac or 0.5

	local w,h = self:GetParent():GetSize()

	local x = w * xfrac
	local y = h * yfrac

	local w, h = self:GetSize()

	x = x - w/2
	y = y - h/2

	return x, y
end

local dred = Color(160, 40, 40, 120)
function META:Debug()
	self.Paint = function(self, w, h) draw.RoundedBox(8, 0, 0, w, h, dred) end
end

function META:AddDockPadding(l, t, r, b)
	l, t, r, b = l or 0, t or 0, r or 0, b or 0

	local l1, t1, r1, b1 = self:GetDockPadding()
	self:DockPadding(l1 + l, t1 + t, r1 + r, b1 + b)
end

function META:AddDockMargin(l, t, r, b)
	l, t, r, b = l or 0, t or 0, r or 0, b or 0

	local l1, t1, r1, b1 = self:GetDockMargin()
	self:DockMargin(l1 + l, t1 + t, r1 + r, b1 + b)
end

function META:AddCloud(name, text)
	local cls = self.__Clouds or {}
	self.__Clouds = cls

	if IsValid(cls[name]) then
		cls[name]:Popup(true) --well if they requested to add it then they probably want it active
		return cls[name], false
	else
		local cl = vgui.Create("Cloud", self)

		cls[name] = cl

		cl:SetSize(self:GetSize())	--prevent cloud from disappearing when 0,0 of parent is not in view
		if text then cl:SetText(text) end
		cl.RemoveWhenDone = true
		cl:Popup(true)
		cl:Bond(self)

		return cl, true
	end
end

function META:RemoveCloud(name)
	local cls = self.__Clouds or {}
	self.__Clouds = cls

	if IsValid(cls[name]) then
		cls[name]:Popup(false)
	end
end

function META:GetCloud(name)
	local cls = self.__Clouds or {}
	self.__Clouds = cls

	return IsValid(cls[name]) and cls[name]
end

local specialKeys = {
	X = true,
	Y = true,
}

function META:Lerp(key, val, dur, del, ease, forceswap, changeDest)
	local self2 = specialKeys[key] and self or self:GetTable()

	if val ~= val then
		error("attempt to lerp to nan")
	end

	if isbool(val) then
		val = val and 1 or 0
	end

	if not self2 then
		print("!!! WTF META:Lerp called on", self, key, self2)
	end

	local anims = self2.__Animations or {}
	self2.__Animations = anims

	local anim

	if not self2[key] then self2[key] = self2[key] or 0 end
	local from = self2[key]

	if self2[key] == val then return false, false end

	if anims[key] then
		anim = anims[key]
		if anim.ToVal == val and not forceswap then return anim, false end --don't re-create animation if we're already lerping to that anyways
		anim.ToVal = val

		if not changeDest then
			anim:Swap(dur, del, ease)
		end

	else
		anim = self:NewAnimation(dur, del, ease)

		anim:SetSwappable(true)

		anim.ToVal = val
		anims[key] = anim
	end

	anim:On("Stop", "RemoveAnim", function()
		anims[key] = nil
	end)

	anim.Think = function(anim, self, fr)
		self2[key] = Lerp(fr, from, anim.ToVal)
	end

	return anim, true
end

META.To = META.Lerp

function META:GetTo(key)
	return self.__Animations and self.__Animations[key]
end

local format = string.format

local function hex(t)
	return format("%p", t)
end

function META:MemberLerp(tbl, key, val, dur, del, ease, forceswap)
	local anims = self.__Animations or {}
	self.__Animations = anims

	if val ~= val then
		error("attempt to lerp to nan")
	end

	local as_str = hex(tbl)

	local anim = anims[key .. as_str]

	local from = tbl[key]
	tbl[key] = from or 0

	if from == val then return end
	from = from or 0
	if anim then
		if anim.ToVal == val and not forceswap then return end

		anim.ToVal = val
		anim:Swap(dur, del, ease)

	else

		anim = self:NewAnimation(dur, del, ease)
		anim:SetSwappable(true)

		anim.ToVal = val
		anim.FromTable = tbl
		anims[key .. as_str] = anim
	end

	anim:On("Stop", "RemoveAnim", function()
		anims[key .. as_str] = nil
	end)

	anim.Think = function(anim, self, fr)
		tbl[key] = Lerp(fr, from, val)
	end

	return anim
end

function META:RemoveLerp(key)
	local anims = self.__Animations or {}

	if anims[key] then
		anims[key].Think = empty -- no thoughts head empty
		anims[key].OnEnd = empty

		for k,v in pairs(self.m_AnimList) do
			if v == anims[key] then
				self.m_AnimList[k] = nil
				break
			end
		end

	end

	anims[key] = nil
end

function META:RemoveMemberLerp(t, key)
	local as_str = hex(t)
	self:RemoveLerp(tostring(key) .. as_str)
end

--CW has its' own LerpColor which seems to work differently from this
--src will be the source color from which the lerp starts
local LerpColor

if not draw.LerpColor then
	function LerpColor(frac, col1, col2, src)

		col1.r = Lerp(frac, src.r, col2.r)
		col1.g = Lerp(frac, src.g, col2.g)
		col1.b = Lerp(frac, src.b, col2.b)

		local sA, c1A, c2A = src.a, col1.a, col2.a

		if sA ~= c2A or c1A ~= c2A then
			col1.a = Lerp(frac, sA, c2A)
		end

	end
else
	LerpColor = draw.LerpColor
end

-- the difference between this and LerpColor is that the result is written into col3 instead
local function LerpColorFrom(frac, col1, col2, col3)
	col3.r = Lerp(frac, col1.r, col2.r)
	col3.g = Lerp(frac, col1.g, col2.g)
	col3.b = Lerp(frac, col1.b, col2.b)

	if col1.a ~= col2.a then
		col3.a = Lerp(frac, col1.a, col2.a)
	end
end

local function eq(c, c2)
	return c.r == c2.r and c.g == c2.g and c.b == c2.b and c.a == c2.a
end

--[[
	Because colors are tables, instead of giving a key you can give LerpColor a color as the first arg,
	so the color structure will be changed instead
]]
function META:LerpColor(key, val, dur, del, ease, forceswap)
	local anims = self.__Animations or {}
	self.__Animations = anims

	local anim

	local iscol = IsColor(key)
	local from = (iscol and key) or self[key]
	if not from then errorf("Didn't find color when provided %s (%s)", key, type(key)) end
	if from == val and not anims[key] then return end

	if anims[key] then
		anim = anims[key]
		if anim.ToVal == val and eq(anim.ToVal, val) and not forceswap then
			return
		end --don't re-create animation if we're already lerping to that anyways

		anim.ToVal = val
		anim:Swap(dur, del, ease)

	else
		anim = self:NewAnimation(dur, del, ease)
		anim:SetSwappable(true)

		anim.ToVal = val:Copy()
		anims[key] = anim
	end

	local newfrom = from:Copy()

	anim:On("Stop", "RemoveAnim", function()
		anims[key] = nil
	end)

	anim.Think = function(anim, self, fr)
		if iscol then
			LerpColorFrom(fr, newfrom, val, from)
		else
			self[key] = (IsColor(self[key]) and self[key]) or from
			LerpColor(fr, from, val, newfrom)
		end
	end

	return anim
end


-- see: emitter.lua

--[[

function META:On(event, name, cb, ...)
	self.__Events = self.__Events or muldim:new()

	local events = self.__Events
	local vararg

	if isfunction(name) then
		vararg = cb
		cb = name
		name = #(events:GetOrSet(event)) + 1

		local t = {cb, vararg, ...}
		events:Set(t, event, name)
	else
		events:Set({cb, ...}, event, name)
	end

end

function META:Emit(event, ...)
	if not self.__Events then return end
	local events = self.__Events
	local evs = events:Get(event)

	if evs then
		for k,v in pairs(evs) do
			--if event name isn't a string, isn't a number and isn't valid then bail
			if not (isstring(k) or isnumber(k) or IsValid(k)) then evs[k] = nil continue end
			--v[1] is the callback function
			--every other key-value is what was passed by On

			if #v > 1 then --AHHAHAHAHAHAHAHAHAHAHHA AAAA
				local t = {unpack(v, 2)}
				table.InsertVararg(t, ...)

				local a, b, c, d, e, why = v[1](self, unpack(t))
				if a ~= nil then return a, b, c, d, e, why end --hook.Call intensifies
			else
				local a, b, c, d, e, why = v[1](self, ...)
				if a ~= nil then return a, b, c, d, e, why end
			end

		end
	end
end

]]

function META:RemoveHook(event, name)
	if not self.__Events then return end

	self.__Events:Set(nil, event, name)
end


function META:AddElement(name, pnl)
	self.Elements = self.Elements or muldim:new()
	table.insert(self.Elements:GetOrSet(name), pnl)
end

function META:GetElements(name)
	self.Elements = self.Elements or muldim:new()
	return self.Elements:GetOrSet(name)
end

function META:RemoveElements(name)
	self.Elements = self.Elements or muldim:new()
	for k,v in ipairs(self.Elements:GetOrSet(name)) do
		if not IsValid(v) then continue end
		if v.Disappear then
			v:Disappear()
		else
			print(v, "didn't implement a 'Disappear' method; popping out.")
			v:PopOut()
		end
	end
end


function META:PopIn(dur, del, func, noalpha)
	if not noalpha then self:SetAlpha(0) end

	local anim = self:AlphaTo(255, dur or 0.1, del or 0, (isfunction(func) and func) or BlankFunc)
	return anim
end

function META:PopOut(dur, del, rem)

	local func = rem or (rem ~= false and function(_, self)
		if IsValid(self) then self:Remove() end
	end)

	local anim = self:AlphaTo(0, dur or 0.1, del or 0, func)
	return anim
end

function META:PopInShow(dur, del, rem, noalpha)
	self:Show()
	return self:PopIn(dur or 0.1, del or 0, rem, noalpha)
end

function META:PopOutHide(dur, del, rem)
	return self:PopOut(dur or 0.1, del or 0, function(_, self)
		self:Hide()
		if rem then rem(_, self) end
	end)
end

-- yes this is ugly, shut up

local function xMove(fr)
	return math.cos(fr * math.pi / 2) - 1
end

local function xMoveRev(fr)
	return math.cos(fr * math.pi / 2 + math.pi / 2)
end

local function yMove(fr)
	return math.sin(fr * math.pi / 2)
end

local function yMoveRev(fr)
	return 1 + math.sin(fr * math.pi / 2 - math.pi / 2)
end


function META:CircleMoveTo(toX, toY, len, ease, rev)

	if self.__circleAnim then
		self.__circleAnim:Stop()
	end

	local anim = self:NewAnimation(len, 0, ease)
	self.__circleAnim = anim

	local fromX, fromY = self:GetPos()

	local f1, f2 = rev and xMoveRev or xMove, rev and yMoveRev or yMove

	local fx = (toX - fromX)
	local fy = (toY - fromY)
	anim.Think = function(self, pnl, fr)
		local x = fromX - fx * f1(fr)
		local y = fromY + fy * f2(fr)

		pnl:SetPos(x, y)
	end
end

--[[
	these are not good and are not backed up by any actual maths
]]

function META:SpringIn(accel, dist, x, y, len, ease, func)
	local anim = self:NewAnimation(len or 0.5, del or 0, ease or -1, func or function() end)
	if x == -1 then x = self.X end
	if y == -1 then y = self.Y end

	local px, py = self.X, self.Y
	local dx, dy = px - x, py - y

	accel = accel or 3
	dist = (dist and -dist) or -10


	anim.Think = function(self, pnl, frac)
		local t = frac
		local p = ( 2 * math.pi ) / 3;

		local mult = ( 2 ^ (dist * t) ) * math.sin( ( t * accel - 0.75 ) * p) + 1

		pnl:SetPos(px - dx*mult, py - dy*mult)
	end


end

function META:InElastic(dur, del, func, funcend, ease, int, dist)

	local anim = self:NewAnimation(dur or 0.5, del or 0, ease or -1, funcend or function() end)
	anim.func = func
	if not func then return end --k

	dist = dist or 1
	int = int or 1

	local from = math.pi*3/2
	local to = from/3

	anim.Think = function(self, pnl, frac)

		local var = math.sin(Lerp(frac^int * int, from, to)) * (dist-frac*(dist-1)) * frac --what the fuck

		func(self, pnl, var)
	end

end

local gu = Material("vgui/gradient-u")
local gd = Material("vgui/gradient-d")
local gr = Material("vgui/gradient-r")
local gl = Material("vgui/gradient-l")

function META:DrawGradientBorder(w, h, gw, gh)
	gw, gh = math.ceil(gw), math.ceil(gh)

	if gh > 0 then
		surface.SetMaterial(gu)
		surface.DrawTexturedRect(0, 0, w, gh)

		surface.SetMaterial(gd)
		surface.DrawTexturedRect(0, h - gh, w, gh)
	end

	if gw > 0 then
		surface.SetMaterial(gr)
		surface.DrawTexturedRect(w - gw, 0, gw, h)

		surface.SetMaterial(gl)
		surface.DrawTexturedRect(0, 0, gw, h)
	end
end

Animations = {}

local latest = 0
anims = {}

animmeta = {}

function animmeta:Stop()
	anims[self.AnimIndex] = nil
	self.Finished = true
end

function animmeta:Swap(len, del, ease, cb)

	del = del or self.Delay
	len = len or self.Length

	self.EndTime = SysTime() + del + len
	self.StartTime = SysTime() + del

	self.Ease = self.Ease or ease
	self.OnEnd = self.OnEnd or cb

	self.Finished = false

	if not anims[self.AnimIndex] then
		anims[self.AnimIndex] = self --back in town bby
	end
end

function animmeta:SetThinkManually(b)
	b = (b == nil and true) or b
	if b then
		anims[self.AnimIndex] = nil
		self.ThinkManually = true
	else
		anims[self.AnimIndex] = self
		self.ThinkManually = false
	end
end

animobj = {}
animobj.__index = animmeta

local pi2by3 = (2*math.pi)/3

--[[
	neither are these
]]

function Animations.SpringIn(accel, dist, len, ease, func, callback, delay)
	local anim = NewAnimation(len, delay, ease, callback)
	accel = accel or 5
	dist = (dist and -dist) or -10

	anim.Animate = function(frac)
		local t = frac

		local mult = ( 2 ^ (dist * t) ) * math.sin( ( t * accel - 0.5 ) * pi2by3) + 1

		func(mult)
	end

	return anim
end

function Animations.SpringOut(accel, strength, len, ease, func, callback)
	local anim = NewAnimation(len, 0, ease, callback)

	local p = math.pi * 3 / 2
	local p2 = math.pi * 2

	local lf = 0
	local lt = SysTime()
	anim.Animate = function(frac)
		--print("diff:", (lf-frac) / (SysTime() - lt))

		lf = frac
		lt = SysTime()

		local mult = math.sin( p2 - (p * frac^accel)) * frac^(1/strength)

		func(mult)
	end

	return anim
end

function Animations.InElastic(dur, del, func, funcend, ease, int, dist)
	local anim = NewAnimation(dur or 0.5, del or 0, ease or -1, funcend or function() end)

	dist = dist or 1
	int = int or 1

	local from = math.pi*3/2
	local to = from/3

	anim.Animate = function(frac)

		local var = math.sin(Lerp(frac^int*int, from, to)) * (dist-frac*(dist-1)) * frac

		func(var)
	end

	return anim
end

function NewAnimation(len, del, ease, callback)
	if ( del == nil ) then del = 0 end
	if ( ease == nil ) then ease = -1 end

	latest = latest + 1

	del = del + SysTime()


	local anim = {
		EndTime = del + len,
		StartTime = del,

		Length = len,
		Delay = del,

		Ease = ease,
		OnEnd = callback,

		ThinkManually = false,

		UneasedFrac = 0,
		Frac = 0
	}
	
	setmetatable(anim, animobj)

	anim.AnimIndex = latest
	anims[latest] = anim

	return anim
end

function Ease(num, how) --garry easing
	num = math.Clamp(num, 0, 1)
	local Frac = 0

	if ( how < 0 ) then
		Frac = num ^ ( 1.0 - ( num - 0.5 ) ) ^ -how
	elseif ( how > 0 and how < 1 ) then
		Frac = 1 - ( ( 1 - num ) ^ ( 1 / how ) )
	else --how > 1 = ease in
		Frac = num ^ how
	end

	return Frac
end

local two3 = 2 / 3

function ReverseEase(num, how) --garry easing
	num = math.Clamp(num, 0, 1)
	local Frac = 0

	if ( how < 0 ) then
		errorNHf("NYI")
		return num
	elseif ( how > 0 and how < 1 ) then
		Frac = 1 - ( ( 1 - num ) ^ how )
	else --how > 1 = ease in
		Frac = num ^ (1 / how)
	end

	return Frac
end

local function AnimationsThink()

	local systime = SysTime()

	for k, anim in pairs( anims ) do

		if ( systime >= anim.StartTime ) then

			local Fraction = math.TimeFraction( anim.StartTime, anim.EndTime, systime )
			Fraction = math.min( Fraction, 1 )
			anim.UneasedFrac = Fraction

			if ( anim.Animate ) then

				local Frac = Fraction ^ anim.Ease
				anim.Frac = Frac
				-- Ease of -1 == ease in out
				if ( anim.Ease < 0 ) then
					Frac = Fraction ^ ( 1.0 - (  Fraction - 0.5 ) ) ^ -anim.Ease
				elseif ( anim.Ease > 0 and anim.Ease < 1 ) then
					Frac = 1 - ( ( 1 - Fraction ) ^ ( 1 / anim.Ease ) )
				end

				anim.Animate( Frac, anim )
			end

			if ( Fraction == 1 ) then

				if ( anim.OnEnd ) then anim:OnEnd() end
				anims[k] = nil

			end

		end

	end

end

hook.Add("Think", "Animations", AnimationsThink)


-- Drag'n'drop callbacks
-- (Why are there none by default!?)
if not DetouredDragFuncs then
	local startDragging, stopDragging = META.OnStartDragging, META.OnStopDragging

	META.OnDragStart, META.OnDragStop = BlankFunc, BlankFunc

	function META:OnStartDragging()

		self.Dragging = true
		self:InvalidateLayout()

		if ( self:IsSelectable() ) then

			local canvas = self:GetSelectionCanvas()

			if ( !self:IsSelected() ) then
				canvas:UnselectAll()
			end

		end

		self:OnDragStart()
	end

	function META:OnStopDragging()
		self.Dragging = false
		self:OnDragStop()
	end

	DetouredDragFuncs = true
end


function META:Bond(to)
	--if not self.__HasBonded then
		local name = ("bondThink:%p:%p"):format(self, to) --ptrs

		hook.Add("Think", name, function()
			if not IsValid(self) then
				hook.Remove("Think", name)
			end

			if not IsValid(to) then
				if IsValid(self) then self:Remove() end
				hook.Remove("Think", name)
				return
			end
		end)

	-- why not!
	--elseif self.__HasBonded ~= to then
	--	error("Can't bond a panel to multiple objects.")
	--end

	--self.__HasBonded = to
end

function META:GetAutoCanvas(name, class)
	if not name then return end

	self.__Canvases = self.__Canvases or {}
	local cs = self.__Canvases

	if cs[name] and cs[name]:IsValid() then
		return cs[name], false
	end

	local cv = vgui.Create(class or "InvisPanel", self, "AutoCanvas - " .. name)
	cs[name] = cv

	return cv, true
end

function META:ShowAutoCanvas(name, class, duration, delay)
	if not name then return end

	self.__Canvases = self.__Canvases or {}
	local cs = self.__Canvases

	if not cs[name] or not cs[name]:IsValid() then
		return self:GetAutoCanvas(name, class)	-- returns true already
	end

	if isbool(insta) then
		cs[name]:Show()
		cs[name]:SetAlpha(255)
	else
		local dur = isnumber(duration) and duration or 0.1
		local del = isnumber(delay) and delay or 0
		cs[name]:PopInShow(dur, del)
	end

	return cs[name], false
end

function META:HideAutoCanvas(name, duration, delay)
	if not name then errorNHf("no name ritard") return false end

	self.__Canvases = self.__Canvases or {}
	local cs = self.__Canvases

	if not cs[name] or not cs[name]:IsValid() then print("not valid", name) return false end

	if isbool(insta) then
		cs[name]:SetAlpha(0)
		cs[name]:Hide()
	else
		local dur = isnumber(duration) and duration or 0.1
		local del = isnumber(delay) and delay or 0
		local anim = cs[name]:PopOutHide(dur, del)
	end

	return cs[name]
end

function META:CopiedColor(col, name)
	local t = self:GetTable()
	local k = "__" .. name .. "Color"
	if not t[k] then
		t[k] = col:Copy()
		t[k .. "Generated"] = col

		return t[k]
	else
		local gen = t[k .. "Generated"]
		if gen.r ~= col.r or gen.g ~= col.g or gen.b ~= col.b or gen.a ~= col.a then
			t[k]:Set(col)
			t[k .. "Generated"]:Set(col)
		end

		return t[k]
	end
end