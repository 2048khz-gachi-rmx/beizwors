setfenv(1, _G)

BitBuffer = BitBuffer or Object:callable()

local bit_band = bit.band
local bit_bor = bit.bor
local bit_rshift = bit.rshift
local bit_lshift = bit.lshift
local bit_bxor = bit.bxor
local bit_bnot = bit.bnot

function BitBuffer:Initialize()
	self[1] = 1  -- cell
	self[2] = 0  -- bit

	-- data
	self[3] = {}
end

function BitBuffer:ResetCursor()
	self[1] = 1
	self[2] = 0
end

function BitBuffer:Reset()
	self:ResetCursor()
	self[3] = {}
end

function BitBuffer:_readPastEdge(n, sz)
	errorf("attempted to read %s past size (total size: %dbits, tried to read [%d - %d]",
		n, -- name of the read
		#self[3] * 32, -- size
		self[1] * 32 + self[2], -- read start
		self[1] * 32 + self[2] + sz) -- read end
end

function BitBuffer:_readCellPastEdge(n)
	errorf("attempted to read %s past size (total size: %dbits, tried to read [%d - %d]",
		n, -- name of the read
		#self[3] * 32, -- size
		self[1] * 32, -- read start
		(self[1] + 1) * 32) -- read end
end

local _readCellPastEdge = BitBuffer._readCellPastEdge

local floor = math.floor -- cant have god do all the work

function BitBuffer:IncrementBits(n)
	local c = self[1]
	if n == 32 then self[1] = c + 1 end

	local new = self[2] + n
	self[1] = floor(c + new * 0.03125) -- / 32
	self[2] = new % 32
end

local IncrementBits = BitBuffer.IncrementBits

function BitBuffer:DecrementBits(n)
	local new = self[2] - n
	local subCell = new < 0 and math.ceil(-new / 32) or 0

	self[1] = self[1] - subCell
	self[2] = new % 32
end

local mks = {}

for i=1, 32 do
	mks[i] = bit_rshift(0xFFFFFFFF, 32 - i)
end

function mask(e, s)
	-- UB moment
	if e == 0 then return mks[s] end

	return bit_bxor( mks[e], mks[s] )
end

local rprint, rprintf = print, printf



--local print = BlankFunc
--local printf = BlankFunc

function BitBuffer:_readCell(why)
	local n = self[3][self[1]]
	if not n then
		self:_readCellPastEdge(why)
		return
	end

	return n
end

function BitBuffer:ReadBits(a)
	local b = self[2]
	local m1 = mask(b, math.min(32, b + a))
	local n = bit_rshift(bit_band(self:_readCell("bits"), m1), b)

	local c = self[1]
	IncrementBits(self, a)

	if c ~= self[1] then
		local left = a - (32 - b)
		local n2 = bit_band(self:_readCell("bits"), mask(0, left))
		n = bit_bor(n, bit_lshift(n2, left))
	end

	return n
end

-- slow function; use if absolutely necessary

function BitBuffer:WriteBits(len, t)
	local d, c, b = self[3], self[1], self[2]
	local n = d[c] or 0

	IncrementBits(self, len)

	--printf("write %s:%s + %d -> %s:%s", c, b, len, self[1], self[2])

	if b + len > 32 then
		local m1 = mask(len, 32 - b)
		--printf("write: %s %s %s", len, b, m1)
		local add1 = bit_band(t, bit_bnot(m1))
		local add2 = bit_band(t, m1)

		d[c] = bit_bor(n, bit_lshift(add1, b))
		d[self[1]] = bit_rshift(add2, 32 - b)

		--[[printf("writebits unfull: %x -> %x (%x), %x (%x)", t,
			add1, bit_lshift(add1, b),
			add2, bit_rshift(add2, 32 - b))]]
	else
		d[c] = bit_bor(n, bit_lshift(t, 32 - len - b))
		--print("writebits full")
	end
end

function BitBuffer:ReadByte()
	local n = self[3][self[1]] -- self:_readCell("byte")
	local b = self[2]
	if b <= 24 then
		-- printf("%s:%s -> %x", self[1], b, n)
		IncrementBits(self, 8)
		local mk = mask(b, b + 8)

		local r = bit_rshift(bit_band(n, mk), b)
		-- printf("%s, %x & %x : %x >> %s = %s", b, n, mk, bit_band(n, mk), b, r)
		return r
	end

	return self:ReadBits(8)
end

function BitBuffer:ReadUInt8()
	return self:ReadByte()
end

function BitBuffer:ReadInt8()
	local b = self:ReadByte()
	if bit_band(b, 0x80) == 1 then return -b end
	return b
end

function BitBuffer:ReadShort()
	local n = self[3][self[1]] -- self:_readCell("short")
	local b = self[2]
	if b <= 16 then
		-- printf("%s:%s -> %x", self[1], b, n)
		IncrementBits(self, 16)
		local mk = mask(b, b + 16)

		local r = bit_rshift(bit_band(n, mk), b)
		-- printf("%s, %x & %x : %x >> %s = %s", b, n, mk, bit_band(n, mk), b, r)
		return r
	end

	return self:ReadBits(16)
end

function BitBuffer:ReadUInt16()
	return self:ReadShort()
end

function BitBuffer:ReadInt16()
	local b = self:ReadShort()
	if bit_band(b, 0x8000) ~= 0 then return -b end
	return b
end

function BitBuffer:ReadLong(i)
	local b = self[2]

	if b == 0 then
		local n = self[3][self[1]] -- self:_readCell("long")

		IncrementBits(self, 32)
		local mk = mask(b, b + 32)

		if not n then
			print("wtF", i)
		end
		local r = bit_rshift(bit_band(n, mk), b)
		-- printf("%s, %x & %x : %x >> %s = %s", b, n, mk, bit_band(n, mk), b, r)
		return r
	end

	return self:ReadBits(32)
end

function BitBuffer:ReadUInt32()
	return self:ReadLong()
end

function BitBuffer:ReadInt32()
	local b = self:ReadLong()
	if bit_band(b, 0x80000000) ~= 0 then return -b end
	return b
end

function BitBuffer:WriteByte(t)
	local b = self[2]
	local d, c = self[3], self[1]
	local n = d[c] or 0

	if b <= 24 then
		IncrementBits(self, 8)

		-- fast pass outta here
		d[c] = n --bit_bor(n, bit_lshift(t, b))
		return
	end

	self:WriteBits(8, t)
end

BitBuffer.WriteUInt8 = BitBuffer.WriteByte
BitBuffer.WriteInt8 = BitBuffer.WriteByte

function BitBuffer:WriteShort(t)
	local b = self[2]

	if b <= 16 then
		local d, c = self[3], self[1]
		local n = d[c] or 0

		IncrementBits(self, 16)
		d[c] = bit_bor(n, bit_lshift(t, b))
		return
	end

	self:WriteBits(16, t)
end

BitBuffer.WriteUInt16 = BitBuffer.WriteShort
BitBuffer.WriteInt16 = BitBuffer.WriteShort

function BitBuffer:WriteLong(t)
	local b = self[2]
	local d, c = self[3], self[1]

	if b == 0 then
		IncrementBits(self, 32)
		d[c] = t
		return
	end

	print("long: slkow path")
	self:WriteBits(32, t)
end

BitBuffer.WriteUInt32 = BitBuffer.WriteLong
BitBuffer.WriteInt32 = BitBuffer.WriteLong


function BitBuffer:WriteString(s, lim)
	-- lim turns the string into a fixed-size string
	-- if lim is not a number but truthy, it'll automatically append the string length
	-- if lim is a number, (length) will be the lim and only the first lim chars will be written
	-- if lim is false(-y), behavies like a C string (NULL-terminated)
	local len = #s
	local cur = 1

	if lim then
		len = isnumber(lim) and lim or #s
		if not isnumber(lim) then
			self:WriteLong(len)
		end
	end


	-- try to defragment first
	if self[2] % 8 == 0 and self[2] ~= 0 then
		local to = (32 - self[2]) / 8 -- amt of chars to write to align
		for i=1, to do
			local b = string.byte(s, i)
			self:WriteByte(b)
		end

		cur = to + 1
	end

	local bundles = math.floor(len / 4)

	-- write in packs of 4 bytes (as longs)
	for i=cur, (bundles - 1) * 4, 4 do
		local b1, b2, b3, b4 = string.byte(s, i, i + 3)

		local int = bit_bor(
			bit_lshift(b4 or 0, 24),
			bit_lshift(b3 or 0, 16),
			bit_lshift(b2 or 0, 8),
			b1
		)
		self:WriteLong(int)

		cur = i + 4
	end

	-- write the remaining bytes that were too small to be a long
	for i=cur, len do
		local b = string.byte(s, i)
		self:WriteByte(b)
	end

	if not lim then
		self:WriteByte(0)
	end

	--self:_spew()
end

local FRAC_LEN = 23
local FRAC_MASK = 0x007FFFFF
local FRAC_POS = bit.lshift(1, FRAC_LEN)

local math_floor = math.floor
local math_frexp = math.frexp

-- i think 2^len is faster than bit.lshift(1, len), wtf?

function BitBuffer:ReadFloat(i)
	local num = self:ReadLong(i)
	local sign = 1

	if num >= 0x80000000 then
		num = num - 0x80000000
		sign = -1
	end

	local exp = bit_rshift(bit_band(num, 0x7F800000), FRAC_LEN)
	local frac = bit_band(num, FRAC_MASK) / (FRAC_MASK + 1)

	-- thx wiki u da best

	if exp == 0xFF then -- float repr. of infinity or nan (depending on fraction)
		return (frac == 0 and math.huge * sign) or 0 / 0
	elseif exp == 0 then
		return math.ldexp(frac, -0x7E) * sign
	else
		-- oh hey lua even has a function for it
		return math.ldexp(1 + frac, exp - 127) * sign
	end
end

function BitBuffer:WriteFloat(n)
	local sign = n < 0 and 0x80000000 or 0

	if n == 0 then
		self:WriteLong(0)
		return -- 0
	elseif n ~= n then
		self:WriteLong(0xFFFFFFFF)
		return -- 0xFFFFFFFF
	end

	local frac, exp = math_frexp(n)
	exp = exp + 0x7E

	if exp <= 0 then
		frac = math_floor(frac * 2 ^ (FRAC_LEN + exp) + 0.5)
		exp = 0
	else
		frac = math_floor((frac * 2 - 1) * FRAC_POS + 0.5)
	end

	-- frac = math.floor(math.ldexp(frac, FRAC_LEN) + 0.5)

	local ret = sign + bit_band(exp, 0xFF) * FRAC_POS
		+ bit_band(frac, FRAC_MASK)

	self:WriteLong(ret)
end

function BitBuffer:_spew()
	rprint("cells:")
	for i=1, #self[3] do
		rprintf("	%02d: % 10s (% -8s)", i, self[3][i], bit.tohex(self[3][i]))
	end
end

function BitBuffer:ReadString(lim)
	local len
	local s = ""

	if lim then
		-- self:_spew()
		len = isnumber(lim) and lim or self:ReadLong(-1)
	end

	local cur = 1
	-- try to defragment first
	if self[2] % 8 == 0 and self[2] ~= 0 then
		local to = (32 - self[2]) / 8 -- amt of chars to write to align
		for i=1, to do
			local byte = self:ReadByte()
			if not len and byte == 0 then return s end

			local c = string.char(byte)

			s = s .. c
		end

		cur = to + 1
	end

	-- read in packs of 4 bytes (as longs)
	print("reading", cur, len and math.floor(len / 4) * 4 or math.huge)
	for i=cur, len and math.floor(len / 4) * 4 or math.huge, 4 do
		local long = self:ReadLong(i)

		local b1, b2, b3, b4 =
			bit_rshift(	bit_band(long, 0xFF000000), 24),
			bit_rshift(	bit_band(long, 0xFF0000), 16),
			bit_rshift(	bit_band(long, 0xFF00), 8),
						bit_band(long, 0xFF)

		local chunk = string.char(b4, b3, b2, b1)

		-- not very fancy ey?
		if not len then
			if b4 == 0 then
				self:DecrementBits(3 * 8)
				break
			end

			if b3 == 0 then
				s = s .. chunk:sub(1, 1)
				self:DecrementBits(2 * 8)
				break
			end

			if b2 == 0 then
				s = s .. chunk:sub(1, 2)
				self:DecrementBits(1 * 8)
				break
			end

			if b1 == 0 then
				s = s .. chunk:sub(1, 3)
				--self:DecrementBits(1 * 8)
				break
			end
		end

		s = s .. chunk
	end

	-- read the remaining bytes that were too small to be a long
	if len then
		for i=#s + 1, len do
			local byte = self:ReadByte()
			if not len and byte == 0 then return s end

			local c = string.char(byte)
			s = s .. c
		end
	end

	return s
end


local nums = {}

local iMax = 20000
local iTimes = 10

local genInt = function(k)
	local maxRand = 2 ^ (8 * (2 ^ (k - 1))) - 1
	return math.random(1, maxRand) - (k > 1 and math.floor(maxRand / 2) or 0)
end

local rand = function()
	return math.random() * 99999
end

local gens = {
	genInt, genInt, genInt,
	rand
}
local b = BitBuffer()

function profileOp(k, v)
	b:Reset()
	local rand = gens[k](k)

	local write, read = b["Write" .. v], b["Read" .. v]

	local bn1, bn2 = bench(), bench()
	local cum = {}

	local gU = GLib.BitConverter.FloatToUInt32(rand)
	local gF = GLib.BitConverter.UInt32ToFloat(gU)

	bn1:Open()
		for i=1, iMax do
			local o = write(b, rand)

			--[[if o ~= gU then
				errorf("fuck 1 %s %s", bit.tohex(gU), bit.tohex(o))
			end]]
		end
	bn1:Close()

	b:ResetCursor()

	bn2:Open()
		for i=1, iMax do
			local n = read(b)
			if n ~= gF then
				errorf("fuck 2 %s %s %s", n, rand, gF)
			end
		end
	bn2:Close()

	return bn1:Read() * 1000, bn2:Read() * 1000
end

function proFileOp(k, v)
	local maxRand = 2 ^ (8 * (2 ^ (k - 1))) - 1
	local rand = math.random(1, maxRand) - (k > 1 and math.floor(maxRand / 2) or 0)

	local fl = file.Open("random.txt", "wb", "DATA")

	local bn1, bn2 = bench(), bench()

	local write, read = fl["Write" .. v], fl["Read" .. v]

	bn1:Open()
	for i=1, iMax do
		write(fl, rand)
	end
	bn1:Close()

	local fl2 = file.Open("random.txt", "rb", "DATA")

	bn2:Open()
	for i=1, iMax do
		read(fl2)
	end
	bn2:Close()

	fl:Close() fl2:Close()

	return bn1:Read() * 1000, bn2:Read() * 1000
end


jit.flush()

local ops = { false, false, false, --[["Byte", "Short", "Long",]] "Float" }
local outs, fouts = {}, {}

-- FProfiler.start()
--[[local b = bench():Open()
for k,v in ipairs(ops) do
	for i=1, 1 do
		profileOp(4, ops[4])
		--proFileOp(k, v)
	end
end
b:Close():print()]]
-- FProfiler.stop()

for k,v in ipairs(ops) do
	if not v then outs[k] = {0, 0} continue end

	local t1, t2 = 0, 0
	for i=1, iTimes do
		local a1, a2 = profileOp(k, v)
		t1 = t1 + a1
		t2 = t2 + a2
	end

	outs[k] = {t1, t2}
end

--[[for k,v in ipairs(ops) do
	local t1, t2 = 0, 0
	for i=1, iTimes do
		local a1, a2 = proFileOp(k, v)
		t1 = t1 + a1
		t2 = t2 + a2
	end

	fouts[k] = {t1, t2}
end]]



printf("Ran x%d * %d times:", iMax, iTimes)

--[[for k,v in ipairs(ops) do
	local name = "File  :%6s%-6s"

	printf("	%s: %.3fms.", name:format("Write", v), fouts[k][1])
	printf("	%s: %.3fms.", name:format("Read", v), fouts[k][2])
	print("")
end]]

for k,v in ipairs(ops) do
	local name = "bitbuf:%6s%-6s"

	printf("	%s: %.3fms.", name:format("Write", v), outs[k][1])
	printf("	%s: %.3fms.", name:format("Read", v), outs[k][2])

	local ratio = --[[(fouts[k][1] + fouts[k][2]) / ]] (outs[k][1] + outs[k][2])
	printf("--> %.2fx %s over file", ratio, ratio > 1 and "speedup" or "slowdown")
	print()
end

do return end


bn:Open()
for i=1, 100000 do
	nums[i] = rand
	b:WriteLong(rand)
end
bn:Close():print():Reset()

b:ResetCursor()

bn:Open()
for i=1, 100000 do
	if b:ReadLong() ~= nums[i] then
		print("epic failure")
		return
	end
end
bn:Close():print():Reset()
--[[
	b:WriteUInt8(8)
	b:WriteUInt8(8)
	b:WriteUInt8(8)

	b:WriteUInt16(0x0812)

local s = "Hello World!"

b:WriteUInt8(#s)

for i=1, #s do
	b:WriteByte(s[i]:byte())
end

b:WriteString(s)
b:WriteString("Sup World", true)
b:WriteString(("VERYLONGTEXTNaM"):rep(10), 5)

b:ResetCursor()

local r = b:ReadBits(28)
local r2 = b:ReadBits(12)

rprint("OUT: ", r, bit.tohex(r))
rprint("OUT: ", r2, bit.tohex(r2))

local len = b:ReadByte()

for i=1, len do
	MsgC(string.char(b:ReadByte()))
end
MsgC("\n")

print(b:ReadString())
print(b:ReadString(true))
print(b:ReadString(5))

rprint("cells:")
for i=1, #b[3] do
	rprintf("	%d: % 9s (% -8s)", i, b[3][i], bit.tohex(b[3][i]))
end
-- PrintTable(b)
]]