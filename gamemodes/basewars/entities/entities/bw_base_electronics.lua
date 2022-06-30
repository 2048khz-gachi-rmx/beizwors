AddCSLuaFile()

local base = "bw_base"
ENT.Base = base
ENT.Type = "anim"
ENT.PrintName = "Base Electricals"


ENT.Model = "models/props_c17/metalPot002a.mdl"
ENT.Skin = 0

ENT.IsElectronic = true
ENT.PowerType = "Consumer"

ENT.PowerRequired = 20
ENT.EmitUnusableBeeps = true

ENT.ConnectDistance = 550
ENT.ConnectPoint = Vector()

ENT.RebootTime = 3

function ENT:Reboot()
	self.RebootStart = CurTime()
	self:SetRebooting(true)
end

function ENT:IsPowered(amt)
	if amt then
		return self:GetPowerGrid() and self:GetPowerGrid():HasPower(amt)
	end

	return self:GetPowered()
end

ENT.GetPower = ENT.IsPowered

function ENT:DrainPower(amt)
	if not self:GetPowerGrid() then return end
	return self:GetPowerGrid():TakePower(amt)
end

function ENT:GetBaseConsumption()
	local ent_base = scripted_ents.GetStored(self:GetClass()).t
	return ent_base.PowerRequired or self.PowerRequired
end

function ENT:GetConsumption()
	return self.PowerRequired
end

function ENT:SetConsumption(pw)
	self.PowerRequired = math.floor(pw)

	if self:GetPowerGrid() then
		self:GetPowerGrid():UpdatePowerOut()
	end
end

function ENT:SetConsumptionMult_Add(id, amt)
	local old = self.ConsumptionMults[id] or 1
	local new_total = self.CurConsumptionMult - old + amt
	self.CurConsumptionMult = new_total
	self.ConsumptionMults[id] = amt

	self:SetConsumption(self:GetBaseConsumption() * self:GetTotalConsumptionMult())
end

function ENT:SetConsumptionMult_Mult(id, amt)
	local old = self.ConsumptionMultsExp[id] or 1
	local new_total = self.CurConsumptionExp - old + amt
	self.CurConsumptionExp = new_total
	self.ConsumptionMultsExp[id] = amt

	self:SetConsumption(self:GetBaseConsumption() * self:GetTotalConsumptionMult())
end

function ENT:GetTotalConsumptionMult()
	return self.CurConsumptionMult * self.CurConsumptionExp
end

function ENT:SetupDataTables()
	baseclass.Get(base).SetupDataTables(self)

	self:NetworkVar("Bool", 0, "Powered")
	self:NetworkVar("Float", 0, "RebootTime")
end

if SERVER then
	function ENT:Think()
		local me = self:GetTable()

		local hpfrac = self:Health() / self:GetMaxHealth()

		if hpfrac < 0.2 and
			CurTime() > (me.NextSpark or 0) and
			math.random(0, 10) == 0 then
			self:Spark()
			me.NextSpark = CurTime() + math.random(5, 15) / 10
		end

		return me.ThinkFunc(self)
	end

	function ENT:CheckUsable()

	end

	function ENT:Use(activator, caller, usetype, value)

		if self:CheckUsable() == false then return end

		if (not self:IsPowered() or self:BadlyDamaged()) then

			if (not self.LastUnusuableBeep or CurTime() - self.LastUnusuableBeep > 1) and self.EmitUnusableBeeps then
				self.LastUnusuableBeep = CurTime()
				self:EmitSound("buttons/button10.wav")
			end

			return
		end

		self:UseFunc(activator, caller, usetype, value)

	end

	function ENT:Initialize()
		self:BaseRecurseCall("Initialize")
		--baseclass.Get("bw_base").Initialize(self)
		self.ConsumptionMults = {}
		self.ConsumptionMultsExp = {}
		self.CurConsumptionMult = 1
		self.CurConsumptionExp = 1
	end

else

	function ENT:Initialize()
		self:BaseRecurseCall("Initialize")
		--baseclass.Get("bw_base").Initialize(self)
	end

end
