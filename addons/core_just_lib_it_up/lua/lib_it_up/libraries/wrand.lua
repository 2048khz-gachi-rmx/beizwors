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

	function WeightedRand.Select(tbl)
		local data, sum = WeightedRand.ConvertInput(tbl)
		local keys, sums = data[1], data[2]
		local len = #sums

		return keys[ findHigher(sums, math.random() * sum, 1, len) ]
	end

	function WeightedRand.SelectTable(tbl, amt, into)
		local out = into or {}

		amt = amt or 1
		local data, sum = WeightedRand.ConvertInput(tbl)
		local keys, sums = data[1], data[2]
		local len = #sums

		for i=1, amt do
			local k = findHigher(sums, math.random() * sum, 1, len)
			out[i] = keys[k]
		end

		return out
	end

	return WeightedRand
end

WeightedRand = gen()