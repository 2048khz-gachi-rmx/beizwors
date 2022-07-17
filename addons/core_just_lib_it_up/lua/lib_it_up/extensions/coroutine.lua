LibItUp.SetIncluded()
function coroutine.Resumer()
	local cor = coroutine.running()

	return function(...)
		local ok, err = coroutine.resume(cor, ...)
		if not ok then
			errorNHf("coroutine.Resumer error: %s", err)
		end
	end
end

function coroutine.ResumeIn(s, ...)
	local cor = coroutine.running()
	local lua_is_dumb = Carry(...)

	timer.Simple(s, function()
		coroutine.resume(cor, lua_is_dumb())
	end)
end

function coroutine.YieldResumeIn(s)
	local cor = coroutine.running()

	timer.Simple(s, function()
		coroutine.resume(cor)
	end)

	return coroutine.yield()
end

function coroutine.Creator(f)
	return function(...)
		return coroutine.wrap(f)(...)
	end
end