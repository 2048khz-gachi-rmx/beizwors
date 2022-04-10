LibItUp.SetIncluded()
function tobit(what)
	return what and 1 or 0
end

function bit.GetLast(num, n)
	return num % (2^n)
end

function bit.GetFirst(num, n)
	local len = bit.GetLen(num)

	return bit.rshift(num, math.max(len - n, 0))
end

local FUCK = math.log(2)

function bit.GetLen(num)
	return math.max(0, math.floor( (math.log(num) / FUCK) + 1 ) )
end

-- returns whether every bit in ... is present in num
-- can take either multiple bits as varargs or one sum of those bits
-- useful for checking against masks
function bit.Has(num, ...)
	local bor = bit.bor(...)
	return bit.band(num, bor) == bor
end

-- returns a number with `num` LS bits as 1's
-- because i get autism every time i try to remember the algo lol

-- eg: bit.Fill(8) -> 0xFF
function bit.Fill(num)
	return (bit.lshift(1, num) - 1)
end

function bit.ToBytes(n, le)
	if le then errorNHf("NYI: bit.ToBytes little endian") return 0, 0, 0, 0 end

	return 	bit.rshift(	bit.band(n, 0xFF000000), 24),
			bit.rshift(	bit.band(n, 0xFF0000), 16),
			bit.rshift(	bit.band(n, 0xFF00), 8),
						bit.band(n, 0xFF)
end

function bit.ToInt(b1, b2, b3, b4, le)
	return le and bit.bor(
		bit.lshift(b4 or 0, 24),
		bit.lshift(b3 or 0, 16),
		bit.lshift(b2 or 0, 8),
		b1
	) or bit.bor(
		bit.lshift(b1 or 0, 24),
		bit.lshift(b2 or 0, 16),
		bit.lshift(b3 or 0, 8),
		b4
	)
end