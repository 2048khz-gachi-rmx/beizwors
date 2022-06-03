LibItUp.SetIncluded()

__HookID = __HookID or 0

local function newID()
	__HookID = __HookID + 1
	return __HookID
end
-- difference between hook.Object and hook.Add(event, object) is that
-- you are guaranteed a unique hook which won't overwrite other hooks
-- with the same object and name (or get overwritten)

-- oh and also, the first arg to the callback is not the object you used for the ID
-- so if you used a player as the ID, it won't be provided as the first arg to the callback like with hook.Add

function hook.Object(hookname, hookobj, cb)
	local id = "hookObject" .. newID()

	hook.Add(hookname, id, function(...)
		if not hookobj:IsValid() then hook.Remove(hookname, id) return end
		cb(hookobj, ...)
	end)

	return id
end

-- only runs for the designated object once, then removes itself
-- useful for one-call on specific objects, e.g. Move on only 1 player

function hook.ObjectOnce(hookname, hookobj, num, cb)
	local id
	num = num or 1
	local func = function(...)
		if select(num, ...) ~= hookobj then return end
		hook.Remove(hookname, id)
		cb(...)
	end

	id = hook.Object(hookname, hookobj, func)
	return id
end

function hook.Once(hookname, hookid, cb)

	if isfunction(hookid) then
		cb = hookid
		hookid = "hookOnce" .. newID()
	end

	local canIndex = isentity(hookid) or ispanel(hookid) or istable(hookid)

	if canIndex and hookid.IsValid then -- if we were given an object, create a unique object hook

		local id
		local func = function(self, ...)
			hook.Remove(hookname, id)
			cb(self, ...)
		end

		id = hook.Object(hookname, hookid, func)

		return
	end

	hook.Add(hookname, hookid, function(...)
		hook.Remove(hookname, hookid)
		cb(...)
	end)

end


function hook.OnceRet(hookname, hookid, cb)

	if isfunction(hookid) then
		cb = hookid
		hookid = "hookOnceRet" .. newID()
	end

	local canIndex = isentity(hookid) or ispanel(hookid) or istable(hookid)

	if canIndex and hookid.IsValid then

		local id
		local func = function(self, ...)
			local ok, ret = pcall(cb, self, ...)

			if ret ~= false then
				hook.Remove(hookname, id)
				if not ok then
					error(ret, 2)
				end
			end
		end

		id = hook.Object(hookname, hookid, func)

		return
	end

	hook.Add(hookname, hookid, function(...)
		local ok, ret = pcall(cb, ...)

		if not ok or ret ~= false then
			hook.Remove(hookname, hookid)
			if not ok then
				error(ret, 2)
			end
		end

	end)

end


-- nohalt run: will throw an ErrorNoHalt
local function errPHook(err)
	local str = ("ProtectedHook error: %s\n%s"):format(err, debug.traceback("", 2))
	ErrorNoHalt(str)
end

function hook.PAdd(ev, name, func, ...)
	hook.Add(ev, name, function(...)
		local ok, a, b, c, d, e, f = xpcall(func, errPHook, ...)
		if ok then
			return a, b, c, d, e, f
		end
	end, ...)
end

hook.NHAdd = hook.PAdd

function hook.PRun(ev, ...)
	local ok, a, b, c, d, e, f = pcall(hook.Run, ev, ...)

	if not ok then
		return false, a
	else
		return true, a, b, c, d, e, f
	end
end


-- nohalt run: will throw an ErrorNoHalt
local function errNH(err)
	local str = ("hook.NHRun error: %s\n%s"):format(err, debug.traceback("", 2))
	ErrorNoHalt(str)
end

function hook.NHRun(ev, ...)
	local ok, a, b, c, d, e, f = xpcall(hook.Run, errNH, ev, ...)

	if not ok then
		return false, a
	else
		return true, a, b, c, d, e, f
	end
end


function hook.NHAllRun(ev, ...)
	local evs = hook.GetTable()[ev]
	if not evs then return end

	for id, fn in pairs(evs) do
		local ok, a, b, c, d, e, f = xpcall(fn, errNH, ...)

		if ok and a ~= nil then
			return a, b, c, d, e, f
		end
	end
end