
ValidIterable = ValidIterable or Object:callable()

ValidIterable._iter = pairs
ValidSeqIterable = ValidSeqIterable or Object:callable()

-- this shouldnt work wtf

local function validSeqIterator(self)
	local i = 0
	local ret_i = 0 -- how many times it actually returned things

	local iter

	iter = function()
		i = i + 1
		local val = self[i]
		if val ~= nil then
			if val:IsValid() then
				ret_i = ret_i + 1
				if ret_i ~= i then
					self[ret_i] = val
					self[i] = nil
				end
				return ret_i, val
			else
				return iter()
			end
		end
	end

	return iter
end

ValidSeqIterable._iter = validSeqIterator

function ValidIterable:iter()
	self:clean()
	return self:_iter()
end

function ValidSeqIterable:iter()
	return self:_iter()
end

function ValidIterable:len()
	local len = 0
	for k,v in self:_iter() do
		if not v:IsValid() then self[k] = nil end
		len = len + 1
	end

	return len
end

function ValidSeqIterable:isEmpty()
	-- cant use next here, have to actually clean
	for _, v in self:_iter() do
		print("ismpety:", v)
		return true
	end

	return false
end

function ValidSeqIterable:len()
	local len = 0
	for _,_ in self:_iter() do
		len = len + 1
	end

	return len
end

function ValidIterable:clean()

	for k, obj in self:_iter() do
		if not obj:IsValid() then
			self[k] = nil
		end
	end

end

function ValidIterable:MakeSequential()
	local t = {}

	local i = 0

	self:clean()

	for k, v in self:_iter() do
		i = i + 1
		t[i] = v
		self[k] = nil
	end

	for i2=1, i do
		self[i2] = t[i2]
	end

	setmetatable(t, ValidSeqIterable)
end

function ValidIterable:new(t, mode)
	local tbl = t or {}

	setmetatable(tbl, IterObj)

	return tbl
end

ValidIterable.__call = ValidIterable.new

function ValidSeqIterable:clean()

	local cur = 1
	local len = #self

	for i=1, len do
		local v = self[i]
		if v:IsValid() then
			self[cur] = v
			cur = cur + 1
		end
	end

	for i=cur, len do
		self[i] = nil
	end

end


-- can remove by key or by value; keeps the table sequential
-- 	if `what` is a number, will return the object corresponding to that key
-- 	if `what` is a valid object, will return the key where that object was stored

function ValidSeqIterable:remove(what)
	if isnumber(what) then -- remove as a key
		return table.remove(self, what)
	else -- remove as a value
		for k,v in ipairs(self) do -- don't bother with :iter(), they might wanna remove an invalid ent
			if v == what then
				table.remove(self, k)
				return k
			end
		end
	end
end


function ValidSeqIterable:add(v)
	if not v.IsValid or not v:IsValid() then return self, false end --tf you tryina do

	local key = #self + 1
	rawset(self, key, v)

	return self, key
end

function ValidSeqIterable:addExclusive(v)
	if not v.IsValid or not v:IsValid() then return self, false end

	local key = #self + 1

	for i=1, key-1 do
		if self[i] == v then return false end -- already exists
	end

	rawset(self, key, v)

	return self, key
end

local function ValidSeqInsert(self, k, v)
	if not v:IsValid() then return end
	self:add(v)
end

ValidSeqIterable.__newindex = ValidSeqInsert