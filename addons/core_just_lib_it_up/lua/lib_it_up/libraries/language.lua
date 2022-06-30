Language = Language or {}

Language.eval = function(self, key, ...)
	local val = Language[key]
	if not isstring(val) then
		return val(...), true
	else
		return val, true
	end

	return ("[Invalid language: %s]"):format(key), false
end

Language.__index = function(self, key)
	return LocalString:new(Language.Invalid(key), "InvalidGeneric")
end
Language.__call = Language.eval

setmetatable(Language, Language)

LocalString = LocalString or Object:callable()
LocalString.All = LocalString.All or {}

function LocalString:Initialize(str, id)
	self._IsLang = true
	self.Str = str
	self.ID = id

	if id then
		local crc = tonumber(util.CRC(id))
		local old = LocalString.All[crc]
		if old and old.ID ~= id then
			errorNHf("LocalString hash collision: hash %d, IDs: %s & %s",
				crc, id, old.ID)
		end

		LocalString.All[crc] = self
		self.NumID = crc

	elseif id ~= false then
		errNHf("!! creating LocalString without ID %s !!", str)
	end

	self.IsString = isstring(str)
end

function LocalString:__tostring()
	if self.IsString then return self.Str end
	return self.Str()
end

function LocalString:__call(...)
	if self.IsString then return self.Str:format(...) end
	return self.Str(...)
end

function LocalString.__concat(a, b)
	return tostring(a) .. tostring(b)
end

function LocalString:Write()
	net.WriteUInt(self.NumID, 32)
end

function net.ReadLocalString()
	local id = net.ReadUInt(32)
	return LocalString.All[id] or Language.epicnetfail
end

function IsLanguage(what)
	return istable(what) and what._IsLang
end

IsLocalString = IsLanguage

function MakeLanguage(k, v)
	Language[k] = LocalString(v, k)
end

MakeLanguage("epicnetfail", "Failed to receive a net message.")