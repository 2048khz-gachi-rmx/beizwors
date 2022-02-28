--

function Scaler(desw, desh)
	if not des then
		print("current res", ScrH(), ScrW())
	end

	local function scale(v)
		return v * (ScrH() / desh)
	end

	local function scaleW(v)
		return v * (ScrW() / desw)
	end

	return scale, scaleW
end