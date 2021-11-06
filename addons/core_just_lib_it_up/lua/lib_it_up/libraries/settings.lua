Settings = Settings or {}
Settings.Settings = Settings.Settings or {}
Settings.Categories = Settings.Categories or muldim:new()

Settings.Setting = Settings.Setting or Emitter:extend()
local stg = Settings.Setting

Settings.Table = dat

function stg:Initialize(id)
	Settings.Settings[id] = self
	self:SetID(id)
	self:SetValue(Settings.Get(id))
end

local alias = {
	["boolean"] = "bool"
}

function stg:Cast(v, totyp)
	totyp = totyp or self:GetType()
	local typ = alias[type(v)] or type(v)

	local f = _G["to" .. self:GetType()]
	local ret = f and f(v)
	if ret then
		v = ret
	else
		errorNHf("Failed to convert %q (%q) to %q for the setting %q.", typ, v, toTyp, self:GetID())
	end
end

function stg:SetValue(v)
	local typ = alias[type(v)] or type(v)
	if self:GetType() and typ ~= self:GetType() then
		v = self:Cast(v, typ)
	end

	local old = self:GetValue()
	cookie.Set("Setting:" .. self:GetID(), (v ~= nil and tostring(v)) or nil)
	self._Value = v
	self:Emit("Change", old, v)
	return self
end

function stg:SetDefaultValue(v)
	if cookie.GetString("Setting:" .. self:GetID()) then return self end
	self:SetValue(v)
	return self
end

function stg:SetCategory(c)
	if self:GetCategory() then
		Settings.Categories:RemoveSeqValue(self, self:GetCategory(), self:GetID())
	end

	Settings.Categories:Set(self, c, self:GetID())
	self._Category = c
	return self
end

ChainAccessor(stg, "_ID", "ID")
ChainAccessor(stg, "_Name", "Name")
ChainAccessor(stg, "_Value", "Value", true)
ChainAccessor(stg, "_Category", "Category", true)
ChainAccessor(stg, "_Type", "Type")

function Settings.Get(k, v)
	local val = cookie.GetString("Setting:" .. k, v)
	if val == "false" or val == "true" then return tobool(val) end
	if isnumber(val) then return tonumber(val) end

	return (val == nil and v) or val --(dat[k] ~= nil and dat[k]) or v
end

function Settings.Set(k, v)
	cookie.Set("Setting:" .. k, v)
	--[[dat[k] = v
	if not timer.Exists("SettingsFlush") then
		timer.Create("SettingsFlush", 3, 1, Settings.Flush)
	end]]
end

function Settings.Flush()
	--[[local json = util.TableToJSON(dat, true)
	file.Write(fn, json)]]
end

local acceptable = table.KeysToValues({
	"bool",
	"number",
	"string"
})

function stg:SetType(typ)
	typ = (tostring(typ) or ""):lower()

	if not acceptable[typ] then
		errorNHf("Unacceptable setting type: %q", typ)
		return
	end

	self._Type = typ
	return self
end


function Settings.Create(k, typ, cb, override)
	typ = (tostring(typ) or ""):lower()

	if not acceptable[typ] then
		errorNHf("Unacceptable setting type: %q", typ)
		return
	end

	local st = Settings.Settings[k]
	if not st or override then
		st = stg:new(k)
	end

	st:SetType(typ)

	if cb then
		st:On("Change", cb)
	end

	return st
end

-- legacy settings import

local fn = "_server_settings.txt"
if not file.Exists(fn, "DATA") then return end

local jsonDat = file.Read(fn, "DATA")
local dat = jsonDat and util.JSONToTable(jsonDat) or {}

file.Delete(fn)

for k,v in pairs(dat) do
	Settings.Set(k, v)
end