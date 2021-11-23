--
setfenv(1, _G)
local CD = LibItUp.Cooldown or Emitter:callable()
LibItUp.Cooldown = CD
LibItUp.Cooldowns = LibItUp.Cooldowns or {}

function CD:Initialize(id, timeMethod)
	if id and LibItUp.Cooldowns[id] then
		return LibItUp.Cooldowns[id]
	end

	self.TimeMethod = timeMethod or CurTime
	self.Data = {}

	if id then
		LibItUp.Cooldowns[id] = self
	end
end

function CD:Put(key, t)
	t = t or 1

	local c = self.Data
	local TM = self.TimeMethod

	if not c[key] or TM() - c[key] > 0 then
		c[key] = TM() + t
		return true
	end

	return false
end

function CD:Set(key, t)
	t = t or 1

	local c = self.Data
	local TM = self.TimeMethod

	c[key] = TM() + t
end

function CD:IsOn(key)
	local c = self.Data
	local TM = self.TimeMethod

	if not c[key] or TM() - c[key] > 0 then
		return true
	end

	return false
end
