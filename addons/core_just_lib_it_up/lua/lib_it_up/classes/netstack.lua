LibItUp.SetIncluded()
netstack = netstack or Emitter:callable()
netstack.IsNetStack = true

local nsm = netstack

local COORD_INTEGER_BITS = 14
local COORD_FRACTIONAL_BITS	= 5
local NORMAL_FRACTIONAL_BITS = 11

local sizes = {
	Float = 4*8,
	Double = 8*8,
	Entity = 16,

	-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/tier1/bitbuf.cpp#L654-L672
	-- assuming worst case
	Vector = (3 + COORD_INTEGER_BITS + COORD_FRACTIONAL_BITS) * 3 + 3,

	--https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/tier1/bitbuf.cpp#L692-L710
	Normal = (NORMAL_FRACTIONAL_BITS + 1) * 2 + 3,

	-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/tier1/bitbuf.cpp#L712
	-- it might've been changed but i'll keep it the same as BitVec3Coord since i don't know for sure
	Angle = (3 + COORD_INTEGER_BITS + COORD_FRACTIONAL_BITS) * 3 + 3,
	Color = 8 * 4,
	Bool = 1,
	Bit = 1,
}

local function determineSize(typ, ...)
	typ = typ:gsub("Write", "")
	if typ == "UInt" or typ == "Int" then
		return select(2, ...)
	elseif typ == "String" then
		return #(select(1, ...) or "") * 8 + 8 -- + 8 = null byte
	elseif typ == "Data" then
		return select(2, ...) * 8
	else
		return sizes[typ] or 0
	end
end

for k,v in pairs(net) do
	if k:find("Write.+") then
		nsm[k] = function(self, ...)
			local aeiou = {...}	--stupid stupid lua
			local tbl = {
				type = k,
				args = aeiou,
				size = determineSize(k, ...),
				func = function()
					net[k](unpack(aeiou)) --i cant use ... cuz its outside of this function!!!
				end,
				trace = debug.traceback()
			}

			local where = self:Emit("WriteOp", k, tbl)
			if where ~= nil then return tbl end

			self:WriteAtCursor(tbl)
			self:AdvanceCursor()
			return tbl
		end
	end
end


local function detourSender(s)
	_G["__realnet" .. s] = _G["__realnet" .. s] or net[s]

	net[s] = function(...)
		hook.Run("NetSent", s, ...)
		return _G["__realnet" .. s] (...)
	end
end

detourSender("Send")
detourSender("SendPVS")
detourSender("SendPAS")
detourSender("SendOmit")
detourSender("SendToServer")

function net.WriteNetStack(ns)
	if not ns.Ops then local str = "net.WriteNetStack: expected netstack; got %s" error(str:format(type(ns))) return end

	for k,v in ipairs(ns.Ops) do
		local ok, err = pcall(v.func)
		if not ok then
			local args = v.args
			local str = ""

			for _, v in ipairs(args) do
				str = str .. tostring(v) .. ", "
			end

			str = str:sub(1, #str - 2)

			local errs = "Error while writing netstack: \"%s\"\nError while writing op #%d\nType: %s\nArgs: %s\nCaller traceback: %s\n\n\n"

			errs = errs:format(err, k, v.type, str, v.trace)
			error(errs)
		end
	end
end

local hijacked = {} --cache for hijacked functions that write into the active netstack

local function hijackNet()
	for k,v in pairs(net) do
		local name = k:find("^Write.+")
		if name and v ~= net.WriteNetStack and isfunction(v) then

			if not net["__Real" .. k] then net["__Real" .. k] = v end

			local hj = hijacked[name] or function(...)
				if net.ActiveNetstack then
					return net.ActiveNetstack[k] (net.ActiveNetstack, ...)
				else
					local ok, err = pcall(net["__Real" .. k], ...)
					if not ok then
						error(err, 2)
					end
				end
			end

			net[k] = hj
		end
	end
end

local function unhijackNet()
	for k,v in pairs(net) do
		local name = k:find("Write.+")
		if name and v ~= net.WriteNetStack and net["__Real" .. name] then
			net[k] = net["__Real" .. k]
		end
	end
end

netstack.__call = net.WriteNetStack

function netstack:Initialize()
	self.Ops = {}
	self.Cursor = 1
	self.LastOpNum = 1
	self.LastBits = 0
end

function netstack:GetOps()
	return self.Ops
end

function netstack:SetCursor(where)
	self.Cursor = where
end

local blank = {
	func = BlankFunc,
	args = {"You're not supposed to see this!"},
	size = 69,
	type = "You're not supposed to see this!"
}

function netstack:WriteAtCursor(what)
	if self.Mode == "a" then
		table.insert(self.Ops, self.Cursor, what)
		if self.Cursor < (self.LastOpNum or 1) then
			-- inserting behind cache cursor; add new bitsize
			self.LastBits = (self.LastBits or 0) + what.size
		end
	else
		local prev = self.Ops[self.Cursor]

		if prev and self.Cursor < (self.LastOpNum or 1) then
			-- writing behind cache cursor; update bitsize
			self.LastBits = (self.LastBits or 0) - prev.size + what.size
		end

		self.Ops[self.Cursor] = what
	end
end

function netstack:AdvanceCursor()
	self.Cursor = self.Cursor + 1
end

function netstack:GetCursor()
	return self.Cursor
end

function netstack:SetMode(m)
	if not isstring(m) then self.Mode = nil end
	if m:lower() == "w" or m:lower() == "write" then self.Mode = nil end
	if m == "a" or m == "append" then self.Mode = "a" end
end

function netstack:BytesWritten()
	local bits = self.LastBits or 0
	local from, to = self.LastOpNum or 1, #self.Ops

	for i=from, to do
		bits = bits + self.Ops[i].size
	end

	self.LastBits = bits
	self.LastOpNum = to + 1

	--[[local bits = 0

	for k,v in ipairs(self.Ops) do
		bits = bits + v.size
	end]]

	return bits / 8, bits
end

-- hijacks all net.Write* calls to instead write to this netstack

function netstack:Hijack(b)
	if b == nil or b then
		net.ActiveNetstack = self
		hijackNet()

		hook.Once("NetSent", ("unhijack_netstack:%p"):format(self), function()
			self:Hijack(false)
		end)

	else
		net.ActiveNetstack = nil
		unhijackNet()
	end
end

-- add an op on cursor & advance it
function netstack:AddTop(tbl)
	self:WriteAtCursor(tbl)
	self:AdvanceCursor()
end

function netstack:MergeInto(ns)
	for k,v in ipairs(self.Ops) do
		ns:AddTop(v)
	end
end

function netstack:Send(netname, where)
		net.Start(netname)
			net.WriteNetStack(self)
	if CLIENT then
		net.SendToServer()
	else
		net.Send(where)
	end
end

function netstack:Write()
	return net.WriteNetStack(self)
end

netstack.__tostring = function(self)
	local head = "NetStack: %d ops:"
	head = head:format(#self.Ops)

	local args = ""

	for k,v in ipairs(self.Ops) do
		local argsstr = ""	--can't do `table.concat(v.args, ", ")` because it may have shit like userdata(entities) which table.concat doesn't like
		for k,v in ipairs(v.args) do
			argsstr = argsstr .. tostring(v) .. ", "
		end

		argsstr = argsstr:sub(1, #argsstr - 2)
		if v.Description then
			argsstr = argsstr .. "	| " .. v.Description
		end
		args = args .. ("%d: %s - %s\n"):format(k, v.type, argsstr)
	end

	args = args:sub(1, #args - 1)

	return head .. "\n" .. args
end

function netstack:print()
	--[[local head = "NetStack: %d ops:"
	head = head:format(#self.Ops)

	local args = {}

	for k,v in ipairs(self.Ops) do
		local argsstr = ""	--can't do `table.concat(v.args, ", ")` because it may have shit like userdata(entities) which table.concat doesn't like
		for k,v in ipairs(v.args) do
			argsstr = argsstr .. tostring(v) .. ", "
		end

		argsstr = argsstr:sub(1, #argsstr - 2)
		if v.Description then
			argsstr = argsstr .. "	| " .. v.Description
		end

		args[#args + 1] = ("#%d %s: %s\n"):format(k, v.type, argsstr)
	end]]
	
	print(tostring(self))
end

function IsNetStack(what)
	return istable(what) and what.IsNetStack
end
IsNetstack = IsNetStack