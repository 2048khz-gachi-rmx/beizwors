--LibItUp.SetIncluded()

if not Promise then include('promise.lua') end
if not LibItUp.Emitter then include('emitter.lua') end
setfenv(1, _G)
Animatable = Animatable or LibItUp.Emitter:callable()
LibItUp.Animatable = Animatable

Animetable = Animatable

AnimatableObjects = AnimatableObjects or setmetatable({}, {__mode = "v"}) -- dont keep references to prevent leaking
AnimatableIDs = AnimatableIDs or setmetatable({}, {__mode = "v"})


function AnimatableObjectsResetAll()
	table.Empty(AnimatableObjects)
	table.Empty(AnimatableIDs)
end


local objs = AnimatableObjects


AnimMeta = Promise:extend()

-- if SERVER then return end --bruh

local systime = SysTime()

hook.Add("Think", "AnimatableThink", function()
	systime = SysTime()

	for k,v in pairs(objs) do
		v:AnimationThink()
	end
end)

function AnimMeta:Remove()
	local ans = self.Parent.m_AnimList
	if ans[self.Key] == self then
		ans[self.Key] = nil
	end

	self.Valid = false
end

function AnimMeta:IsValid()
	return self.Valid ~= false
end

function AnimMeta:Stop()
	self:Remove()
	self:Emit("Stop")
end

function AnimMeta:End()
	self:Stop()
	self:Emit("End")
end

function AnimMeta:SetSwappable(b)
	self.Swappable = (b==nil and true) or b
	return self
end

function AnimMeta:Swap(length, delay, ease, callback)
	self:Reset() --reset promise

	self.StartTime = delay + SysTime()
	self.EndTime = delay + length + SysTime()
	self.Ease = ease
	self.OnEnd = callback

	self.Ended = false
	self._Started = false

	self:Emit("Swap")

	return self
end

function Animatable:Initialize(auto_think)
	self.__Animations = {}	-- this stores only :Lerp or :MemberLerp or :LerpColor
							-- as [key] = anim

	self.m_AnimList = {}	-- this is pretty much just a list of animations

	if auto_think ~= false and self.__instance.NoAutoThink ~= true then
		local id = auto_think ~= true and auto_think -- if auto_think isn't a bool consider it an ID
		local ud = (id and AnimatableIDs[id]) or self --GCProxy(self)
		--self.__gcHandle = ud

		if id then
			ud:StopAnimations()
			ud.__NameID = id
			AnimatableIDs[id] = ud
			local found = false
			for k,v in pairs(objs) do
				if v == ud then return v end
			end
		end

		objs[#objs + 1] = ud
	end

end

function Animatable:StopAnimations()
	for k,anim in pairs(self.m_AnimList) do
		if anim.Ended then continue end
		if anim.OnEnd then anim:OnEnd( self ) end
		anim:End()
		anim:Exec() -- start promise :Then's
		anim.Ended = true
	end

	self.__Animations = {}
	self.m_AnimList = {}
end
Animatable.Stop = Animatable.StopAnimations

function Animatable:AnimationThink()
	self:Emit("AnimationPreThink", self.m_AnimList)

	for k, anim in pairs( self.m_AnimList ) do
		if anim.Ended then continue end

		if ( systime >= anim.StartTime ) then
			if not anim._Started then
				anim._Started = true
				anim:Emit("Start")
			end
			
			local Fraction = math.TimeFraction( anim.StartTime, anim.EndTime, systime )
			Fraction = math.Clamp( Fraction, 0, 1 )
			anim.UneasedFrac = Fraction
			
			if ( anim.Think ) then

				local Frac
				if anim.EaseFn then
					Frac = anim.EaseFn(Fraction)
				else
					Frac = Fraction ^ anim.Ease

					-- Ease of -1 == ease in out
					if ( anim.Ease < 0 ) then
						Frac = Fraction ^ ( 1.0 - ( ( Fraction - 0.5 ) ) )
					elseif ( anim.Ease > 0 && anim.Ease < 1 ) then
						Frac = 1 - ( ( 1 - Fraction ) ^ ( 1 / anim.Ease ) )
					end
				end

				anim.Frac = Frac
				anim:Think( self, Frac )
				anim:Emit("Think", Frac)
			end

			if ( Fraction == 1 ) then

				if not anim.Ended then
					anim.Ended = true
					if anim.OnEnd then anim:OnEnd( self ) end
					anim:End()

					anim:Resolve() -- start promise :Then's
				end

				if anim.Swappable then continue end

				self.m_AnimList[k] = nil
				anim.Valid = false
				anim.Key = 0	--this animation isn't "valid" anymore; zero out the key so stopping the animation actually does nothing
			end

		end

	end

	self:Emit("AnimationPostThink", self.m_AnimList)
end

function Animatable:NewAnimation( length, delay, ease, callback )

	if ( delay == nil ) then delay = 0 end
	if ( ease == nil ) then ease = -1 end

	delay = delay + SysTime()

	local anim = AnimMeta:new()

	table.Merge(anim, {
		EndTime = delay + length,
		StartTime = delay,
		Ease = ease,
		EaseFn = isfunction(ease) and ease or nil,
		OnEnd = callback,
		Parent = self,
		Valid = true,
		UneasedFrac = 0,
		Frac = 0
	})

	if ( self.m_AnimList == nil ) then self.m_AnimList = {} end

	local key = table.insert( self.m_AnimList, anim )
	anim.Key = key

	return anim

end

--everything below has been pretty much lifted from panellib meta.lua


local format = string.format

local function hex(t)
	return format("%p", t)
end

function Animatable:Lerp(key, val, dur, del, ease, forceswap)
	if not isnumber(val) then errorf("Animation:Lerp : expected number as arg #2, got %s instead", type(val)) return end

	if val ~= val then
		error("attempt to lerp to nan")
	end

	local anims = self.__Animations or {}
	self.__Animations = anims

	local anim
	local from = self[key] or 0

	local oldAnim = anims[key]

	if self[key] == val then
		if not oldAnim or oldAnim.ToVal == val then
			return false, false
		end
	end

	if oldAnim then
		anim = oldAnim
		if anim.ToVal == val and not forceswap then return anim, false end --don't re-create animation if we're already lerping to that anyways

		anim.ToVal = val
		anim:Swap(dur, del, ease)
	else
		anim = self:NewAnimation(dur, del, ease)
		anim:SetSwappable(true)

		anim.ToVal = val
		anims[key] = anim
	end

	anim:On("Stop", "RemoveAnim", function()
		anims[key] = nil
		anim:Remove()
	end)

	anim.Think = function(anim, self, fr)
		self[key] = UnboundedLerp(fr, from, val)
	end

	self:Emit("NewAnimation", anim, self, key, val)

	return anim, true
end

Animatable.To = Animatable.Lerp

function Animatable:MemberLerp(tbl, key, val, dur, del, ease, forceswap)
	if not isnumber(val) then errorf("Animation:MemberLerp : expected number as arg #3, got %s instead", type(val)) return end
	local anims = self.__Animations or {}
	self.__Animations = anims

	local as_str = hex(tbl)
	local ankey = tostring(key) .. as_str

	local anim = anims[ankey]
	local from = tbl[key] or 0

	if tbl[key] == val then
		if not anim or anim.ToVal == val then
			return false, false
		end
	end

	if anim then
		if anim.ToVal == val and not forceswap then
			return anim, false
		end

		anim.ToVal = val
		anim:Swap(dur, del, ease)
	else
		anim = self:NewAnimation(dur, del, ease)
		anim:SetSwappable(true)

		anim.ToVal = val
		anim.FromTable = tbl
		anims[ankey] = anim
	end

	anim:On("Stop", "RemoveAnim", function()
		anims[ankey] = nil
		anim:Remove()
	end)

	anim.Think = function(anim, self, fr)
		tbl[key] = UnboundedLerp(fr, from, val)
	end

	self:Emit("NewAnimation", anim, tbl, key, val)

	return anim, true
end

Animatable.LerpMember = Animatable.MemberLerp

--CW has its' own LerpColor which seems to work differently from this
--src will be the source color from which the lerp starts
local function LerpColor(frac, col1, col2, src)

	col1.r = UnboundedLerp(frac, src.r, col2.r)
	col1.g = UnboundedLerp(frac, src.g, col2.g)
	col1.b = UnboundedLerp(frac, src.b, col2.b)

	if src.a ~= col2.a then
		col1.a = UnboundedLerp(frac, src.a, col2.a)
	end

end

local function LerpColorFrom(frac, col1, col2, col3) --the difference is that the result is written into col3 instead, acting like classic lerp
	col3.r = UnboundedLerp(frac, col1.r, col2.r)
	col3.g = UnboundedLerp(frac, col1.g, col2.g)
	col3.b = UnboundedLerp(frac, col1.b, col2.b)

	if col1.a ~= col2.a then
		col3.a = UnboundedLerp(frac, col1.a, col2.a)
	end
end

--[[
	Because colors are tables, instead of giving a key you can give LerpColor a color as the first arg,
	so the color structure will be changed instead
]]
function Animatable:LerpColor(key, val, dur, del, ease, forceswap)
	if val ~= val then
		error("attempt to lerp to nan")
	end

	local anims = self.__Animations or {}
	self.__Animations = anims

	local anim

	local iscol = IsColor(key)
	local from = (iscol and key) or self[key]
	if not from then errorf("Didn't find color when provided %s (%s)", key, type(key)) end
	if from == val and not anims[key] then return end

	if anims[key] then
		anim = anims[key]
		if anim.ToVal == val and not forceswap then return end --don't re-create animation if we're already lerping to that anyways

		anim.ToVal = val
		anim:Swap(dur, del, ease)

	else
		anim = self:NewAnimation(dur, del, ease)
		anim:SetSwappable(true)

		anim.ToVal = val
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

end

function Animatable:RemoveLerp(key)
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

function Animatable:RemoveMemberLerp(t, key)
	local as_str = hex(t)
	self:RemoveLerp(tostring(key) .. as_str)
end

_G.GlobalAnimatable = Animatable:new("Global")