AddCSLuaFile()

local KROMER = GetGlobalBool("KROMER")
if SERVER then
	SetGlobalBool("KROMER", math.random() < 0.03)
elseif not KROMER then
	timer.Create("cringe network race", 1, 10, function()
		if GetGlobalBool("KROMER") then
			include("language.lua")
			timer.Remove("cringe network race")
		end
	end)
end

local CURRENCY = KROMER and "KR" or "$" --"£"
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


local Strings = {}


Strings.Currency = CURRENCY
Strings.CURRENCY = CURRENCY

Strings.Invalid			= "[Invalid language: %s]"
Strings.InvalidGeneric	= "[Invalid language]"

Strings.NoPower 		= "No power!"
Strings.NoCharges 		= "No charges!"
Strings.NoHealth 		= "Low health!"
Strings.NoPrinters 	= "Target does not have enough printers!"

Strings.PayOutOwner 	= function(s, c)
	if isnumber(s) then s = BaseWars.NumberFormat(s) end
	return string.format("You got %s%s for the destruction of your %s",
		Strings.Currency, s, c or "Something")
end

Strings.PayOut 		= function(s, c)
	if isnumber(s) then s = BaseWars.NumberFormat(s) end
	return string.format("You got %s%s for destroying a %s!",
		Strings.Currency, s, c or "Something")
end


Strings.You 			= "You"

Strings.Level 			= function(str, s2)
	if str then
		if s2 then
			return ("Level %d/%d"):format(str, s2)
		else
			return ("Level %d"):format(str)
		end
	else
		return "Level"
	end
end


Strings.UpgCost = function(pr)
	if pr then
		return "Next level: " .. Strings.Price(pr)
	else
		return "Upgrade cost"
	end
end

Strings.WelcomeBackCrash 	= "Welcome back!"

local KROMER = GetGlobalBool("KROMER")
if SERVER then
	SetGlobalBool("KROMER", math.random() < 0.03)
elseif not KROMER then
	timer.Create("cringe network race", 1, 10, function()
		if GetGlobalBool("KROMER") then
			include("language.lua")
			timer.Remove("cringe network race")
		end
	end)
end

if KROMER then
	Strings.Refunded			= function(s)
		if isnumber(s) then s = BaseWars.NumberFormat(s) end
		return ("YOU WERE REFUNDED %s [[KR0MER]] AFTER [[Server Burning Down]]."):format(CURRENCY)
	end
	
	Strings.Price = function(str)
		if isnumber(str) then
			return BaseWars.NumberFormat(str) .. " [[KROMER]]"
		else
			return (str or "???") .. " [[KROMER]]"
		end
	end
else
	Strings.Refunded			= function(s)
		if isnumber(s) then s = BaseWars.NumberFormat(s) end
		return ("You were refunded %s%s after a crash."):format(CURRENCY, s)
	end
	
	Strings.Price = function(str)
		if isnumber(str) then
			return CURRENCY .. BaseWars.NumberFormat(str)
		else
			return CURRENCY .. (str or "???")
		end
	end
end

Strings.Health 			= "Health: %s/%s"
Strings.Power 				= "Power: %s/%s"

Strings.Yes = "Yes"
Strings.No = "No"

Strings.Tip = "Tip!"
Strings.PrinterUpgradeTip = "Type /upg or /upgrade while looking at\n" ..
	"something to upgrade it.\n" ..
	"You can specify how many levels " ..
	"you want to upgrade something by.\nTry it now!"

Strings.PrinterUpgradeTipFont = "OS28"

Strings.ChargesCounter = function(s)
	return ("%s %s%s"):format(s, "stim", s == 1 and "" or "s")
end

Strings.StimCostTip = "each stim costs 75 charge"
Strings.StimsLevel = "stims are only generated at level 2+"

Strings.BPNextPrint = "Next print in:"
Strings.BPNextPrintTime = "%.1fs."
Strings.BPNextPrintNextTime = "LV%d.: %.1fs."


Strings.Inv_StatSpread    = "Spread"
Strings.Inv_StatHipSpread = "Hip Spread"
Strings.Inv_StatMoveSpread  = "Moving Spread"
Strings.Inv_StatDamage      = "Damage"
Strings.Inv_StatRPM         = "RPM"
Strings.Inv_StatRange       = "Range"
Strings.Inv_StatReloadTime  = "Reload Time"
Strings.Inv_StatMagSize     = "Mag Size"
Strings.Inv_StatRecoil      = "Recoil"
Strings.Inv_StatHandling    = "Sight Time"
Strings.Inv_StatMoveSpeed   = "Movement Speed"
Strings.Inv_StatDrawTime    = "Draw Time"

Strings.SpawnMenuConf 		= "Confirm Purchase"
Strings.UpgradeNoMoney		= "You don't have enough money!"
Strings.SpawnMenuMoney		= "You don't have enough money to buy this!"
Strings.EntLimitReached		= "You reached the limit for %s (max. %s)!"
Strings.SpawnMenuBuyConfirm = "Are you sure you want to purchase %s for " .. Strings.Currency .. "%s?"

if KROMER then
	Strings.UpgradeNoMoney		= "YOU [NoPossess] ENOUGH KR0<MER!"
	Strings.SpawnMenuMoney		= "YOU [NoPossess] KR0M+3r TO BUY [Goods]!"
end

setmetatable(Language, Language)

LocalString = Object:callable()
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
	return LocalString.All[id]
end

function IsLanguage(what)
	return istable(what) and what._IsLang
end

IsLocalString = IsLanguage

for k,v in pairs(Strings) do
	Language[k] = LocalString(v, k)
end

--[[
	Raids.
]]

BaseWars.LANG = Language
