local META = {}

local function hex(p)
	return ("%p"):format(p)
end

function META:Timer(name, sec, reps, func, ...)
	local args = {...} -- luwa

	-- i don't like writing these out manually but eh..
	if isfunction(sec) then
		func = sec
		if reps ~= nil then table.insert(args, 1, reps) end
		sec = 0
		reps = 1
	end

	if isfunction(reps) then
		if func ~= nil then table.insert(args, 1, func) end
		func = reps
		reps = 1
	end

	if not func then error("Nice function") return end --ya idiot

	name = name or uniq.Seq("__Timerified:" .. hex(self))
	local id = "__Timerified:" .. hex(self) .. ":" .. tostring(name)

	if reps == 0 then
		errorNHf("created a 0 rep timer (use a string '0' to stop this) @ %s", debug.traceback())
	end

	reps = tonumber(reps)

	sec = sec or 0
	sec = sec --+ (CurTime() - UnPredictedCurTime()) -- brb finna kms

	self.__timerifiedTimers = self.__timerifiedTimers or {}
	self.__timerifiedTimers[name] = true

	timer.Create(id, sec, reps or 1, function()
		if self.IsValid and not self:IsValid() then return end
		func(self, unpack(args))
	end)

	return id
end

function META:RemoveTimer(name)
	if not name then error("Nice ID") return false end
	local fullID = "__Timerified:" .. hex(self) .. ":" .. tostring(name)
	local ex = timer.Exists(fullID)
	timer.Remove(fullID)

	if self.__timerifiedTimers then self.__timerifiedTimers[tostring(name)] = nil end

	return ex
end

function META:TimerExists(name)
	return timer.Exists("__Timerified:" .. hex(self) .. ":" .. tostring(name))
end

function META:KillAllTimers()
	local tmr = self.__timerifiedTimers
	if not tmr then return end

	for k,v in pairs(tmr) do
		timer.Remove(k)
	end
end

local metas = {
	FindMetaTable("Entity"),
	FindMetaTable("Panel"),
}

for k,v in pairs(metas) do
	for name, fn in pairs(META) do
		v[name] = fn
	end
end

function Timerify(what)
	for name, fn in pairs(META) do
		what[name] = fn
	end
end

local PLAYER = FindMetaTable("Player")

function PLAYER:LiveTimer(id, ...)
	self._timers = self._timers or {}
	self._timers[id] = self:Timer(id, ...)
end

function PLAYER:ResetLiveTimers()
	if not self._timers then return end

	for k,v in pairs(self._timers) do
		timer.Remove(v)
	end

	self._timers = {}
end

hook.Add("PlayerDeath", "ResetTimers", PLAYER.ResetLiveTimers)

if CLIENT then
	gameevent.Listen("entity_killed")
	hook.Add("entity_killed", "ResetTimers", function(dat)
		local eid = dat.entindex_killed
		local ent = Entity(eid)
		if not ent:IsPlayer() then return end

		ent:ResetLiveTimers()
	end)
end
