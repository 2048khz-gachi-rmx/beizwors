local gen

-- internal:
local function findHigher(arr, v, lo, hi)
	local mid, val

	while lo <= hi do
		mid = math.floor( lo + (hi - lo) / 2 )
		val = arr[mid]

		if v < val then
			hi = mid - 1
		else
			lo = mid + 1
		end
	end

	return lo
end

local function findLower(arr, v, lo, hi)
	local mid, val

	while hi - lo > 1 do
		mid = math.floor( lo + (hi - lo) / 2 )
		val = arr[mid]

		if val >= v then
			hi = mid
		else
			lo = mid
		end
	end

	return hi
end

function gen()
	local WeightedRand = {}
	WeightedRand.NewEnvinroment = gen

	-- if your table will change at runtime, you should probably
	-- either invalidate the cache when it does (WeightedRand.InvalidateCache(tbl))
	-- or disable cache outright

	WeightedRand.ENABLE_CACHING = true

	local convertCache

	local function regenerateCache()
		convertCache = setmetatable({}, {__mode = "k"})
	end

	regenerateCache()

	-- not passing `tbl` will invalidate ALL cache
	function WeightedRand.InvalidateCache(tbl)
		if not tbl then
			regenerateCache()
		else
			convertCache[tbl] = nil
		end
	end

	--[==========================[
		functions for override

		every time a selection is needed, these will be called to convert data
		caching the output is advised
	--]==========================]


	--[[
	WeightedRand.ConvertInput(tbl):
		Usage:
			if your table looks different than the example above,
			you may override this function instead to accept your own layout

		Input:
			whatever you pass into WeightedRand.Select

		Output:
			1: array: {
				1.1: an array of keys
				1.2: an array of sums of weights prior to the i-th key
			}
			2: number: sum of all weights

			example: {
				{ "thing", 	"equal_thing", 	"better_thing", "never_pick_me"},
				{ 0.5, 		1, 				3, 				3 				},
			}, 3
	]]

	function WeightedRand.ConvertInput(tbl)
		local cc = convertCache[tbl]

		if WeightedRand.ENABLE_CACHING and cc then
			return cc[1], cc[2]
		end

		local out = { {}, {} }

		local sum = 0

		for k,v in pairs(tbl) do
			table.insert(out[1], k)
			sum = sum + v
			table.insert(out[2], sum)
		end

		if WeightedRand.ENABLE_CACHING then
			convertCache[tbl] = {out, sum}
		end

		return out, sum
	end

	local math_Random = math.random

	function WeightedRand.Select(tbl)
		local data, sum = WeightedRand.ConvertInput(tbl)
		local keys, sums = data[1], data[2]
		local len = #sums

		return keys[ findHigher(sums, math_Random() * sum, 1, len) ]
	end

	function WeightedRand.SelectTable(tbl, amt, into)
		local out = into or {}

		amt = amt or 1
		local data, sum = WeightedRand.ConvertInput(tbl)
		local keys, sums = data[1], data[2]
		local len = #sums

		for i=1, amt do
			local k = findHigher(sums, math_Random() * sum, 1, len)
			out[i] = keys[k]
		end

		return out
	end


	function WeightedRand.SelectNoRepeat(tbl, amt, into)
		local data, sum = WeightedRand.ConvertInput(tbl)
		assert(#data <= amt)

		local keys, sums = data[1], data[2]
		local len = #sums

		local sumCopy = {}
		for i=1, len do sumCopy[i] = sums[i] end

		local out = into or {}

		for i=1, amt do
			local rand = math_Random() * sum
			local k = findLower(sumCopy, rand, 0, len)

			local weight = sumCopy[k] - (sumCopy[k - 1] or 0)

			sum = sum - weight
			out[i] = keys[k]

			-- this will be slow for big tables, need a better algo
			for i2=k, len do
				sumCopy[i2] = sumCopy[i2] - weight
			end

			-- make this entry's sum be equal to the previous one
			-- the binary search will find the leftmost entry if there are duplicates,
			-- so this effectively means this entry will be ignored
			sumCopy[k] = (sumCopy[k - 1] or 0)
		end

		return out
	end

	return WeightedRand
end

WeightedRand = gen()
return WeightedRand