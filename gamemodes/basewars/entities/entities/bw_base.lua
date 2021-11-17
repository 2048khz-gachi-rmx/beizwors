AddCSLuaFile()

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "BW Base Entity"

ENT.Model = "models/props_interiors/pot02a.mdl"
ENT.Skin = 0
ENT.PresetMaxHealth = 100

ENT.IsBaseWars = true

ENT.Level = 1

function ENT:Init()

end

function ENT:ThinkFunc()

end

function ENT:UseFunc()

end

function ENT:CLInit()

end

function ENT:DerivedDataTables()

end

function ENT:ForceUpdate()
	self.TransmitTime = CurTime()
end

function ENT:GetMaxLevel()
	return self.MaxLevel
end

function ENT:UpdateTransmitState()
	if not self.TransmitTime or CurTime() - self.TransmitTime < 0.5 then
		self.TransmitTime = self.TransmitTime or CurTime()
		return TRANSMIT_ALWAYS
	end
	return TRANSMIT_PVS
end

function ENT:BadlyDamaged()

	return self:Health() <= (self:GetMaxHealth() / 5)

end

function ENT:GetPower()
	return true
end

function ENT:SetupDataTables()
	self:DerivedDataTables()
end

function ENT:IsRebooting()
	return self:GetRebootTime() ~= 0, self.RebootTime - (CurTime() - self:GetRebootTime())
end

function ENT:OnChangeGridID(new)

end

function ENT:SHInit()

end

if SERVER then

	function ENT:Initialize()
		self:SetModel(self.Model)
		self:SetSkin(self.Skin)

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		self:SetUseType(SIMPLE_USE)
		self:AddEffects(EF_ITEM_BLINK)

		self:PhysWake()
		self:Activate()

		self:SetHealth(self.PresetMaxHealth or self.MaxHealth)

		self:Init(me)
		self:SHInit()

		self:SetMaxHealth(self:Health())

		timer.Simple(0.5, function()
			if IsValid(self) then self:RemoveEFlags(EFL_FORCE_CHECK_TRANSMIT) end
		end)

	end

	function ENT:Repair()
		self:SetHealth(self:GetMaxHealth())
	end

	function ENT:Spark(a, ply)

		local vPoint = self:GetPos()
		local effectdata = EffectData()
		effectdata:SetOrigin(vPoint)
		util.Effect(a or "ManhackSparks", effectdata)
		self:EmitSound("DoSpark")

		if ply and ply:GetPos():Distance(self:GetPos()) < 80 and math.random(0, 10) == 0 then

			local d = DamageInfo()

			d:SetAttacker(ply)
			d:SetInflictor(ply)
			d:SetDamage(ply:Health() / 2)
			d:SetDamageType(DMG_SHOCK)

			local vPoint = ply:GetPos()
			local effectdata = EffectData()
			effectdata:SetOrigin(vPoint)
			util.Effect(a or "ManhackSparks", effectdata)

			ply:TakeDamageInfo(d)

		end

	end

	function ENT:OnTakeDamage(dmginfo)
		local dmg = dmginfo:GetDamage()
		local Attacker = dmginfo:GetAttacker()

		self:SetHealth(self:Health() - dmg)

		if self:Health() <= 0 and not self.BlownUp then

			self.BlownUp = true

			xpcall(BaseWars.UTIL.PayOut, GenerateErrorer("EntBase Payout"), self, Attacker)

			if dmginfo:IsExplosionDamage() then
				self:Explode(false)
				return
			end

			self:Explode()

			return
		end

		if dmginfo:GetDamage() < 1 then return end

		self:Spark(nil, Attacker)

	end

	function ENT:Explode(e)

		if e == false then

			local vPoint = self:GetPos()
			local effectdata = EffectData()
			effectdata:SetOrigin(vPoint)
			util.Effect("Explosion", effectdata)

			self:Remove()

		return end

		local ex = ents.Create("env_explosion")
			ex:SetPos(self:GetPos())
		ex:Spawn()
		ex:Activate()

		ex:SetKeyValue("iMagnitude", 100)

		ex:Fire("explode")

		self:Spark("cball_bounce")
		self:Remove()

		SafeRemoveEntityDelayed(ex, 0.1)

	end

else

	function ENT:CLInit()

	end

	function ENT:Initialize()
		self:CLInit()
		self:SHInit()
	end
end
