--

function Scaler(desw, desh, floor)
	assert(isnumber(desw))
	assert(isnumber(desh))

	local scale, scaleW

	if floor then
		function scale(v)
			return math.floor(v * (ScrH() / desh))
		end

		function scaleW(v)
			return math.floor(v * (ScrW() / desw))
		end
	else
		function scale(v)
			return v * (ScrH() / desh)
		end

		function scaleW(v)
			return v * (ScrW() / desw)
		end
	end

	return scale, scaleW
end