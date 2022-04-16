--

function Scaler(desw, desh)
	assert(isnumber(desw))
	assert(isnumber(desh))

	local function scale(v)
		return v * (ScrH() / desh)
	end

	local function scaleW(v)
		return v * (ScrW() / desw)
	end

	return scale, scaleW
end