local wrand = WeightedRand --require("./wrand.lua")

--[[local ExampleTable = {
	thing = 0.5,
	equal_thing = 0.5,

	better_thing = 1,
	never_pick_me = 0,
}]]

local ExampleTable = {
	thing = 0.5,
	equal_thing = 0.5,

	better_thing = 1,
	hellyea = 99,
	ohyea = 99,
	meh = 5,
	never_pick_me = 0,
}

print("randomly picked:", wrand.Select(ExampleTable))


local counters = {}

local function resetCounters()
	for k,v in pairs(ExampleTable) do
		counters[k] = 0
	end
end

resetCounters()

local n = 10
local t = {}

local function validate(i, c)
	for k,v in pairs(c) do if v > i then print("wrong", k, v, i) return false end end
	return c.never_pick_me == 0
end

local b = bench():Open()

for i=1, n do
	local pick = wrand.SelectNoRepeat(ExampleTable, 3, t)
	for i=1, 3 do
		counters[pick[i]] = counters[pick[i]] + 1
	end

	--[[if not validate(i, counters) then
		print("broke", i, counters.ohyea)
		break
	end]]
end
b:Close():print()

print("distribution over " .. n .. " samples:")
for k,v in pairs(counters) do
	local fmt = ("	%s: %.1f%%"):format(k, v / n * 100)
	print(fmt)
end

assert(counters["never_pick_me"] == 0)