AddCSLuaFile()

local KROMER = GetGlobalBool("KROMER")

if SERVER then
	_KROMER = (_KROMER == nil and math.random() < 0.03) or _KROMER
	SetGlobalBool("KROMER", _KROMER)
elseif not KROMER then
	timer.Create("cringe network race", 1, 10, function()
		if GetGlobalBool("KROMER") then
			include(file.PathToMe())
			timer.Remove("cringe network race")
		end
	end)
end

local CURRENCY = KROMER and "KR" or "$" --"£"



local Strings = {}


Strings.Currency = CURRENCY
Strings.CURRENCY = CURRENCY

Strings.Invalid			= "[Invalid language: %s]"
Strings.InvalidGeneric	= "[Invalid language]"

Strings.NoPower 		= "No power!"
Strings.NoCharges 		= "No charges!"
Strings.NoHealth 		= "Low health!"
Strings.NoPrinters 	= "Target does not have enough printers!"
Strings.PowerGen 	= "+%spw"
Strings.PowerGenManual 	= "+%spw/use"
Strings.PowerStored = "%spw"

Strings.PerSecond = "/s."
Strings.PerTick = "/t."

Strings.Power = "%spw"
Strings.PowerGen 	= "+%spw"
Strings.PowerGenManual 	= "+%spw/use"
Strings.PowerStored = "%spw"

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

	Strings.Money = Strings.Price
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

	Strings.Money = Strings.Price
end

Strings.Health 			= "Health: %s/%s"

Strings.Yes = "Yes"
Strings.No = "No"

Strings.Tip = "Tip!"
Strings.PrinterUpgradeTip = "Type /upg or /upgrade while looking at\n" ..
	"something to upgrade it.\n" ..
	"You can specify how many levels " ..
	"you want to upgrade something by, for example: \"/upg 4\".\nTry it now!"

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
Strings.DeadBuy				= "Dead people buy nothing."
Strings.DontBuildSpawn 		= "Don't build at spawn."
Strings.CannotPurchaseRaid  = "You cannot purchase this in a raid."
if KROMER then
	Strings.UpgradeNoMoney		= "YOU [NoPossess] ENOUGH KR0<MER!"
	Strings.SpawnMenuMoney		= "YOU [NoPossess] KR0M+3r TO BUY [Goods]!"
end

for k,v in pairs(Strings) do
	MakeLanguage(k, v)
end

BaseWars.LANG = Language
