Settings = Settings or {}
Settings.Settings = Settings.Settings or {}
Settings.Categories = Settings.Categories or muldim:new()

Settings.Setting = Settings.Setting or Emitter:extend()
local stg = Settings.Setting

Settings.Table = dat

function Settings.GetObject(id)
	return Settings.Settings[id]
end

function stg:Initialize(id)
	Settings.Settings[id] = self
	self:SetID(id)
	self:SetValue(Settings.GetStored(id))
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

	local v2 = self:Emit("Remap", v)
	self._RemappedValue = (v2 == nil and v) or v2
	self:Emit("Change", old, self._RemappedValue)
	return self
end

function stg:GetValue(real)
	if real then return self._Value end
	return self._RemappedValue
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

function stg:SetInverted(b)
	if b == nil or b then
		self:On("Remap", "_Invert", function(_, v) return not v end)
	else
		self:RemoveListener("Remap", "_Invert")
	end

	self:SetValue(self:GetValue(true))

	return self
end

ChainAccessor(stg, "_ID", "ID")
ChainAccessor(stg, "_Name", "Name")
--ChainAccessor(stg, "_Value", "Value", true)
ChainAccessor(stg, "_Category", "Category", true)
ChainAccessor(stg, "_Type", "Type")

local function changeByRun(cv, val)
	if isbool(val) then
		RunConsoleCommand(cv:GetName(), val and "1" or "0")
	else
		RunConsoleCommand(cv:GetName(), tostring(val))
	end
end

local function changeByMethod(cv, val)
	if isbool(val) then
		cv:SetBool(val)
	elseif isnumber(val) then
		cv:SetFloat(val)
	else
		cv:SetString(val)
	end
end


function stg:SetConVar(v)
	self._Convar = v
	local cvar_obj
	self:On("Change", "CvarUpdate", function()
		cvar_obj = cvar_obj or GetConVar(v)
		if not cvar_obj then errorNHf("Missing setting convar: %s", v:GetConVar()) return end

		local changer = changeByMethod
		if not cvar_obj:IsFlagSet(FCVAR_LUA_CLIENT) and not cvar_obj:IsFlagSet(FCVAR_LUA_SERVER) then
			changer = changeByRun
		end

		changer(cvar_obj, self:GetValue())
	end)

	return self
end

ChainAccessor(stg, "_Convar", "ConVar", true)
ChainAccessor(stg, "_Convar", "Convar", true)


function Settings.GetStored(k, v)
	local val = cookie.GetString("Setting:" .. k, v)

	if val == "false" or val == "true" then
		val = tobool(val)
	elseif isnumber(val) then
		val = tonumber(val)
	end

	return (val == nil and v) or val
end

function Settings.Get(k, v)
	local obj = Settings.GetObject(k)
	if not obj then errorNHf("No such setting: %s", k) return false end

	local val = obj:GetValue()
	return (val == nil and v) or val
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
		errorNHf("Unrecognized setting type: %q", typ)
		return
	end

	self._Type = typ
	return self
end


function Settings.Create(k, typ, cb, override)
	typ = (tostring(typ) or ""):lower()

	if not acceptable[typ] then
		errorNHf("Unrecognized setting type: %q", typ)
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

LibItUp.OnInitEntity(function()
	for k,v in pairs(Settings.Setting) do
		if not v:GetConVar() then continue end
		local cv = GetConVar(v:GetConVar())

		if not cv then
			errorNHf("Missing setting convar: %s", v:GetConVar())
			continue
		end

		cv:SetString(v:GetValue())
	end
end)