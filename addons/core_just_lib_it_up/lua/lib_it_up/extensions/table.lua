LibItUp.SetIncluded()
function table.LowestSequential(t)

	for k,v in ipairs(t) do
		if t[k + 1] == nil then return k end
	end
	return 0
end

function table.AddMissing(from, to)
	for k,v in pairs(to) do
		if from[k] ~= nil then continue end
		from[k] = v
	end

	return from
end

function table.KeysToValue(tbl)
	local ret = {}

	for k,v in pairs(tbl) do
		ret[v] = k
	end

	return ret
end
table.KeysToValues = table.KeysToValue

function table.ReplaceValue(t, what, with, seq)
	local f = seq and ipairs or pairs
	for k, v in f(t) do
		if v == what then
			t[k] = with
			return k
		end
	end
end

function table.RemapValues(t, to, seq)
	local iter = seq and ipairs or pairs
	for k,v in iter(t) do
		if to[v] ~= nil then
			t[k] = to[v]
		end
	end

	return t
end

function table.IsEmpty(t)
	return next(t) == nil
end

function table.PackUp(t) -- for lack of a better word
	if istable(t) then return t end
	return {t}
end

--[[
	Weak tables
]]

	WeakTable = Object:callable()

	function WeakTable:Initialize(t, mode)
		if isstring(t) then mode = t t = nil end

		return setmetatable(t or {}, {__mode = mode or "kv"})
	end

--[[
	Proxy tables
]]

	ProxyTable = {}

	ProxyTable.__call = function(self, t, func)

		t = t or {}	--the actual table

		local ud = {}	--what's returned
		local mtud = {IsProxy = true}	--metatable for what's returned
		local what = {}

		mtud.__index = function(self, key)

			if key == "Table" then print("No stop that wtf\n", debug.traceback()) return t end

			return rawget(mtud, key) or t[key] or what[key]
		end

		function what.__pairs(self)
			return _pairs(t)
		end
		function what:GetTable()
			return t
		end

		mtud.__newindex = function(self, key, value)

			if t[key] then

				if t.__modindex then
					local no = t.__modindex(t, key, value) == false
					if no then return end
					t[key] = value

				elseif func then
					local no = func(t, key, value) == false
					if no then return end
					t[key] = value
				else
					t[key] = value
				end
			else
				if t.__newindex then
					local no = t.__newindex(t, key, value)
					if no then return end
					t[key] = value
				else
					t[key] = value
				end
			end
		end

		--mtud.__metatable = "Don't set the ProxyTable's metatable itself! Set it on ProxyTable.Table!"
		setmetatable(ud, mtud)
		setmetatable(mtud, what)
		return ud
	end

	setmetatable(ProxyTable, ProxyTable)


--um?

--[[
_pairs = _pairs or pairs

function pairs(t)
	--sorry not sorry

	--if not istable(t) then error(("pairs: expected table, got %s instead"):format(type(t))) end
	if rawget(t, "IsProxy") and isfunction(t.GetTable) then return _pairs(t:GetTable()) end 

	return _pairs(t)
end
]]

function GetValids(t)
	local ret = {}

	for k,v in pairs(t) do
		if not IsValid(v) then continue end
		ret[k] = v
	end

	return ret
end

function ValidPairs(t)
	return pairs(GetValids(t))
end

function ValidiPairs(t)
	local ret = {}

	for k,v in ipairs(t) do
		if not IsValid(v) then continue end
		ret[#ret + 1] = v
	end

	return ipairs(ret)
end

ValidIPairs = ValidiPairs
ValidIpairs = ValidiPairs
Validipairs = ValidiPairs

function table.InsertVararg(t, ...)
	local len = select('#', ...)
	local tlen = #t

	for i=1, len do
		t[tlen + i] = select(i, ...)
	end

end

function table.ForEachRecursive(t, f)
	for k,v in pairs(t) do
		if istable(v) then
			table.ForEachRecursive(v, f)
		else
			f(t, k, v)
		end
	end
end

if not table.Shuffle then
	-- may be implemented in future gmod versions
	-- lifted from a pull request

	function table.Shuffle( t )
		local n = #t

		for i=1, n - 1 do
			local j = math.random(i, n)
			t[i], t[j] = t[j], t[i]
		end
	end

end

if not table.Filter then
	-- turns out plogs had this already

	function table.Filter(tab, func)
		local cur = 1
		local len = #tab

		for i=1, len do
			if func(tab[i]) ~= false then
				tab[cur] = tab[i]
				cur = cur + 1
			end
		end

		for i=cur, len do
			tab[i] = nil
		end

		return tab
	end

end

function table.SeqRandom(t)
	return t[math.random(1, #t)]
end

function eval(var, ...)

	if isfunction(var) then
		return var(...)
	else
		return var
	end

end