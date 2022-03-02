AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()

	self.time = CurTime()
	self.time_p = CurTime()

	self:SetCapacity(self.Capacity)

	self.Money = 0
	self.Multiplier = 1
	self:SetHealth(self.PresetMaxHealth or 100)

	self:SetMultiplier(1)

	self.Level = 1
	self:SetLevel(1)

	self.Overclockable = true
	self.Overclocker = false
	self.Mods = {}

	if self.TTR then
		self.PrintAmount = math.Round(BaseWars.Worth.Get(self) / self.TTR)
	end

	self:SetPrintAmount(self.PrintAmount)

	if not self.BypassMaster then
		BaseWars.Printers.Add(self)
	end

	self:BaseRecurseCall("Initialize")
	--scripted_ents.Get("bw_base_upgradable").Initialize(self)
end


function ENT:Overclock(lv, mult)
	if not self.Overclockable or self.Overclocker then return false end
	self.Overclockable = false
	self.Overclocker = lv
	self:SetMultiplier(self.Multiplier * mult)
	self.Multiplier = self.Multiplier * mult

	BaseWars.Printers.MasterTable[self].mult = self.Multiplier

	return true
end

function ENT:OnFinalUpgrade()
	self.Level = self:GetLevel()
	local amt = BaseWars.Printers.GetPrintRate(self)
	if amt then
		self:SetPrintAmount(amt)
		self:SetConsumptionMult_Add("LevelPower", self:GetLevel())
	end
end

function ENT:NetworkVars()
	local t = self:GetTable()

	t.SetNWMoney(self, t.Money)
	t.SetMultiplier(self, t.Multiplier)
end

function ENT:PlayerTakeMoney(ply, suppress)
	local owInfo = self:BW_GetOwner()
	if not owInfo or owInfo:GetPlayer() ~= ply then return end

	local money = self.Money

	local can, msg = hook.Run("BaseWars_PlayerCanEmptyPrinter", ply, self, money)

	if can == false then
		if msg then
			ply:ChatNotify({BASEWARS_NOTIFICATION_ERROR, msg})
		end
		return
	end

	self:SetNWMoney(0)

	self.Money = 0

	ply:GiveMoney(money)

	if not suppress then
		ply:EmitSound("mvm/mvm_money_pickup.wav")
	end

	hook.NHRun("BaseWars_PlayerEmptyPrinter", ply, self, money)

	return money
end

function ENT:UseFunc(activator, caller, usetype, value, suppress)

	if self.Disabled then print('no') return end

	if activator:IsPlayer() and caller:IsPlayer() and self:GetNWMoney() > 0 then
		return self:PlayerTakeMoney(activator, suppress)
	end

end

function ENT:SetDisabled(a)

	self.Disabled = a and true or false
	self:SetNWBool("printer_disabled", a and true or false)

end
