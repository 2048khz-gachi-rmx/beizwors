LibItUp.SetIncluded()

function math.Percent(num, perc)	--stfu
	perc = perc / 100
	return num * perc
end

--two if's are faster than math sqrt addition multiplication bullshit, dont @ me
--(its not for rotated shit)

function math.PointIn2DBox(px, py, rx, ry, rw, rh)


	local cond1 = (rx < px) and (px < rx + rw)	--X
	if not cond1 then return false end

	local cond2 = (ry < py) and (py < ry + rh)	--Y
	if not cond2 then return false end

	return true
end

local sin = function(d) return math.sin(math.rad(d)) end
local cos = function(d) return math.cos(math.rad(d)) end

function math.AARectSize(w, h, deg)
	local nh = h * math.abs(cos(deg)) + w * math.abs(sin(deg))
	local nw = h * math.abs(sin(deg)) + w * math.abs(cos(deg))

	return nw, nh
end

function math.Length(num) --length of number in base 10, kind of works for retarded numbers (> 14 in len)
	if num == 0 then return 0 end
	local ret = math.floor(
			math.log10(
				math.abs( num )
			)
		)

	return (ret > 14 and 0 or 1) + ret
end

-- reverse math.clamp basically lol
-- if a number is not within [min; max], returns it

-- otherwise, returns either the min or max (whichever one's closer)
function math.Exclude(num, min, max)
	if num >= max or num <= min then
		return num
	else
		local rng = max - min
		if num - rng * 0.5 < min then
			return min
		else
			return max
		end
	end
end

function bit.bool(bool)
	return bool and 1 or 0
end

--why no 64bit bitops wtf mike
--these are not good, shut up

function bit.biglshift(num, amt)
	return num * 2^amt
end

function bit.bigrshift(num, amt)
	local n2 = num / 2^amt
	return n2 - n2 % 1
end

--there was a string->num and num->string but i gave up here