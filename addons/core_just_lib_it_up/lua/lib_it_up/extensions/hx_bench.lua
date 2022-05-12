setfenv(1, _G)
LibItUp.SetIncluded()

--[[
	=== HeX's Benchmark script ===
	Examples at the bottom
	*** It seems to show different times taken if you re-run the same tests!, don't trust it! ***
	Its still useful though as it shows the difference, if not the accurate time taken.

	----------------------------

	pimp ma lib
	its cooler now

	bench([name,][times])
		creates a benchmark object
		if frames is defined, calling :print() on it won't print anything until it's been attempted to print `times` times

	b:Open()
		opens the benchmark (duh)
		can't open an opened benchmark or it'll throw an error

	b:Close()
		closes the benchmark and flushes the time it took into a different var
		can't close a closed benchmark or it'll throw an error

	b:Read()
		returns how many seconds it took in total

	b:Reset()
		resets the benchmark

	b:print() or b:p()
		prints out the benchmark
		use this instead of plain printing it if you're using `times` arg
]]

benchmark = benchmark or {}
benchmark.__index = benchmark

function benchmark.Init(Name)
	local Info = debug.getinfo(2)

	return setmetatable(
		{
			Where	= Info.short_src .. ":" .. Info.currentline,
			Name	= Name or "Bench @ " .. os.time(),
			BenchedFrames = 0,

			_Start	= 0,
			_Dur = 0,
			_LastPrint = SysTime(),

			OpenSubs = {},
			Subs = {},
		},
		benchmark
	)
end

local ST = SysTime

function benchmark:Open()
	if self._Start != 0 then Error("This bench is already started, Close it first!") end
	self._Start = ST()
	return self
end

function benchmark:Close()
	if self._Start == 0 then Error("Can't close what you didn't open!") end

	self._Dur = self._Dur + (ST() - self._Start)

	self._Start = 0

	return self
end

function benchmark:Reset()

	self._Start		= 0
	self._Dur 		= 0

	return self
end

function benchmark:Do(f, ...)
	local st = ST()
	local a, b, c, d = f(...)
	local et = ST()

	self._Dur = self._Dur + (et - st)
	self:print()
	return a, b, c, d
end

function benchmark:DoTimes(i, f, ...)
	local st = ST()
	for t = 1, i do
		f(...)
	end
	local et = ST()

	self._Dur = self._Dur + (et - st)
	return self
end

function benchmark:Read()
	return self._Dur
end

local function InMS(t)
	return t * 1000
end

function benchmark:__tostring(...)
	local st = ST()
	local str = "\"%s\" took %.3fms"
	local ms = InMS(self:Read())
	str = str:format(self.Name, ms)

	if self.Frames then
		local sinceLast = InMS(st - self._LastPrint)
		str = str .. (" (avg. across %d calls: %.3fms, since print: %.3fms; %.3f%%)"):format(
			self.Frames, ms / self.Frames, sinceLast, ms / sinceLast * 100
		)
	end

	if not table.IsEmpty(self.Subs) then
		for name, t in pairs(self.Subs) do
			str = str .. ("\n\t\"%s\" took %.3fms."):format(name, InMS(t))
		end
	end

	return str
end

function benchmark:SubOpen(name)
	local st = ST()

	if self.OpenSubs[name] then
		errorNHf("Subbench %s already open.", name)
		return
	end


	self.OpenSubs[name] = st

	return name
end

function benchmark:SubClose(name)
	local st = ST()

	if not self.OpenSubs[name] then
		errorNHf("Subbench %s never opened.", name)
		return
	end

	local diff = st - self.OpenSubs[name]
	self.Subs[name] = diff
end

local function longprint(...)
	local s = ""
	local args = {...}
	for k,v in ipairs(args) do
		s = s .. v .. (args[k + 1] and "\t" or "")
	end

	for i=1, #s, 2046 do
		Msg(s:sub(i, i + 2046))
	end
	Msg("\n")
end

function benchmark:print(min)

	if self.Frames then
		self.BenchedFrames = self.BenchedFrames + 1

		if self.BenchedFrames >= self.Frames then
			local s = self:__tostring()
			local t = self:Read()

			if not min or InMS(t) > min then
				longprint(s)
			end

			self.BenchedFrames = 0
			self:Reset()
			self._LastPrint = ST()
		end

	else
		local s = self:__tostring()
		local t = self:Read()
		if not min or InMS(t) > min then
			longprint(s)
		end

		self:Reset()
	end

	return self
end

benchmark.p = benchmark.print

function benchmark:__concat(Bench)	return self:__tostring() .. Bench:__tostring()	end
function benchmark:__eq(Bench)		return Bench:Read() == self:Read()				end
function benchmark:__lt(Bench)		return Bench:Read() < self:Read()				end
function benchmark:__le(Bench)		return Bench:Read() <= self:Read()				end

local i = 1

bench = function(n, frames)
	local b = benchmark.Init(n or "bench_" .. i)
	b.Frames = frames

	if not n then
		i = i + 1
	end

	return b
end



























