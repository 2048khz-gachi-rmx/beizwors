LibItUp.SetIncluded()

UnionTable = UnionTable or Object:callable()

UnionTable.IsUnion = true

function UnionTable:__index(key)
	local raw = rawget(UnionTable, key)

	if raw or isnumber(key) then
		return raw
	end

	--[[
		we have to construct a closure each time, i can't think of an another way :(
	]]

	local func = function(...)
		local outs = {}

		local useself = false
		local idx = 1

		-- cry about it
		if (...) == self then
			useself = true
			idx = 2
		end

		for k,v in pairs(self) do
			local val = v[key]

			if isfunction(val) then
				outs[v] = val( useself and v or args_orig[1], select(idx, ...) )
			else
				outs[v] = val
			end
		end

		return outs
	end

	return func
end

function UnionTable:OnExtend(new)
	new.__index = UnionTable.__index
end

function UnionTable:Initialize(t)
	if t then return setmetatable(t, UnionTable) end
end
