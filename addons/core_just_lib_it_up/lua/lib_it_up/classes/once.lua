Once = Once or Object:callable() -- i love objects i love objects

function Once:Initialize(fn)
	CheckArg(1, fn, isfunction)
	self._fn = fn
	self._ran = false
end

function Once:__call(...)
	if self._ran then return end
	self._fn(...)
	self._ran = true
end

function Once:Ran()
	return self._ran
end

function Once:GetRan()
	return self._ran
end

function Once:StopRun()
	self._ran = true
end