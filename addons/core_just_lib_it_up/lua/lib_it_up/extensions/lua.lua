LibItUp.SetIncluded()

TrueFunc = function() return true end
FalseFunc = function() return false end

function Curry(f, ...)
	local args = {...}
	local len = #args

	return function(...)
		local len2 = select('#', ...)

		for i=len + 1, len + len2 + 1 do
			args[i] = select(i - len, ...)
		end

		args[len + len2 + 2] = nil
		f(unpack(args))
	end
end

function Carry(...)
	local args = {...}
	return function(...)
		return unpack(args)
	end
end

function RotateArgs(...)
	local args = {...}
	local len = select('#', ...)

	for i=1, len / 2 do
		local temp = args[i]
		args[i] = args[len - i + 1]
		args[len - i + 1] = temp
	end

	return unpack(args, 1, len)
end

function CheckArg(num, arg, check, expected_type)
	if isfunction(check) then
		if not check(arg) then
			local err = (expected_type and
							"expected '" .. expected_type .. "', got '" .. type(arg) .. "' instead")
						or
							"failed check function on '" .. type(arg) .. "'"
			errorf("bad argument #%d (%s)", num, err)
		end
	elseif isstring(check) then
		if type(arg) ~= check then
			local err = "expected '" .. (expected_type or check) .. "', got '" .. type(arg) .. "' instead"
			errorf("bad argument #%d (%s)", num, err)
		end
	end
end

function ComplainArg(num, wanted, got)
	errorf("bad argument #%d (expected '%s', got '%s' instead)", num, wanted, got)
end

function util.gary()
	error("gary")
end

function ChainValid(what)
	if IsValid(what) then return what end
	return false
end

local errorers = {}

-- nohalt run: will throw an ErrorNoHalt
function GenerateErrorer(err)
	if errorers[err] then
		return errorers[err]
	end

	local fmt = tostring(err) .. " error: %s\n%s\n"

	errorers[err] = function(err)
		return ErrorNoHalt(fmt:format(err, debug.traceback("", 2)))
	end

	return errorers[err]
end

local cur = {}
local buf = {}

function GCMark(n)
	if SERVER then return end

	cur[n] = collectgarbage("count")
end

function GCPrint(n)
	if SERVER then return end

	local g = collectgarbage("count")

	buf[n] = (buf[n] or 0) + g - (cur[n] or math.huge)
	cur[n] = nil
end

hook.Add("HUDPaint", "GC_Trk", function()
	if table.IsEmpty(buf) then return end

	local sw, sh = ScrW(), ScrH()
	local cnt = table.Count(buf)

	local y = sh / 2 - cnt * 18

	for k,v in SortedPairs(buf) do
		local _, th = draw.SimpleText(k .. ": " .. ("%.2f"):format(v), "OS20",
			sw - 4, y, color_white, 2)
		y = y + th

		buf[k] = nil
	end
end)

if CLIENT then
	collectgarbage("stop")

	local MB = bit.lshift(1, 10)

	local START, START_STEP = 1200 * MB, 120
	local END, END_STEP = 1900 * MB, 250

	local PANIC = jit.arch == "x64" and 3000 * MB or 1800 * MB

	timer.Create("GC_Slow", 30, 0, function()
		local cnt = math.min(collectgarbage("count"), END)
		if cnt < START then return end -- not worth collecting

		local stepSz = math.Remap(cnt, START, END, START_STEP, END_STEP)

		collectgarbage("step", stepSz)
	end)

	timer.Create("GC_Panic", 1, 0, function()
		local cnt = collectgarbage("count")
		if cnt > PANIC then
			print("!!! PANICKING GARBAGE COLLECTION !!!")
			collectgarbage()
			collectgarbage()
		end
	end)
end