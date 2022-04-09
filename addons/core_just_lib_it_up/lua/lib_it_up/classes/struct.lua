-- something like a protobuf..?

Struct = Object:extend()
Struct.map = {}
Struct.defaults = {}

local typeConv = {}

for k,v in pairs(_G) do
	if isstring(k) and k:find("^TYPE_") then
		typeConv[k] = v
		typeConv[v] = k
	end
end

function Struct:Initialize()
	--[[for k,v in pairs(self.defaults) do
		self[k] = v
	end]]
end

Struct.__newindex = function(self, k, v)
	local typ = self.map[k]
	if not typ then
		errorf("attempt to set non-struct member (%s = %s)", k, v)
		return
	end

	if typ ~= TypeID(v) then
		errorf("attempt to set struct member with wrong type (%s = %s, type %s, expected %s)",
			k, v, typeConv[TypeID(v)], typeConv[typ])
		return
	end

	rawset(self, k, v)
end

Struct.__cIndex = Struct.__index
Struct.__index = function(self, k)
	local par = getmetatable(self) -- get object class
	local def = par.defaults[k] -- try to grab the class' immediate default
	if def ~= nil then return def end

	-- no default; since this is Struct's level of __index, pass the index back to its' baseclass
	return par.__cIndex[k]
end

function Struct:OnExtend(new, ...)
	local args = {...}
	if #args == 0 then
		errorNHf("Extending an empty struct...?")
		return
	end

	new.map = table.Copy(self.map)
	new.defaults = table.Copy(self.defaults)

	new.__newindex = Struct.__newindex
	new.__cIndex = new.__index
	new.__index = Struct.__index

	if istable(args[1]) then
		--[[ table syntax:
		:extend({
			name = TYPE_STRING,
			id = TYPE_NUMBER,
			...
		})]]

		for name, dat in pairs(args[1]) do
			if not isstring(name) then
				errorf("non-string key: %s", name)
				return
			end

			local typ = isnumber(dat) and dat or istable(dat) and (dat[1] or dat.type)
			if not isnumber(typ) then
				errorf("incorrect value: %s (expected a TYPE_ or a table with TYPE_ as the first member)", typ)
				return
			end

			if not typeConv[typ] then
				errorf("non-type type descriptor: %s", typ)
				return
			end

			new.map[name] = typ
			if istable(dat) then
				new.defaults[name] = dat[2] or dat.default
			end
		end
	else
		errorf("NYI: array syntax")
		return
	end
end

function Struct:Require(...)
	local len = select("#", ...)
	if len == 0 then
		for k,v in pairs(self.map) do
			if not self[k] then
				return false, k
			end
		end

		return true
	end

	for i=1, len do
		if not self[select(i, ...)] then
			return false, select(i, ...)
		end
	end

	return true
end