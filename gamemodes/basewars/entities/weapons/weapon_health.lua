AddCSLuaFile()

SWEP.PrintName 				= "Healgun"
SWEP.Author 				= "Masterbrian123"
SWEP.Instructions 			= "Heal Objects and Players"
SWEP.Purpose 				= "Heals"

SWEP.Spawnable 				= true
SWEP.AdminSpawnable 		= false

SWEP.ViewModelFOV 			= 65
SWEP.ViewModel 				= "models/weapons/v_superphyscannon.mdl"
SWEP.WorldModel 			= "models/weapons/w_physics.mdl"

SWEP.AutoSwitchTo 			= true
SWEP.AutoSwitchFrom 		= false

SWEP.Slot 					= 5
SWEP.SlotPos 				= 1

SWEP.HoldType 				= "smg"
SWEP.FiresUnderwater 		= true
SWEP.Weight 				= 20
SWEP.DrawCrosshair 			= true
SWEP.Category 				= "Masterbrian123's SWEPs"
SWEP.DrawAmmo 				= false
SWEP.Base 					= "weapon_base"

SWEP.HealAmount 			= 5
SWEP.PlayerHealMult 		= 2


SWEP.Primary.Damage     	= 0
SWEP.Primary.ClipSize 		= -1
SWEP.Primary.Ammo 			= "none"
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Spread 		= 0
SWEP.Primary.NumberofShots 	= 1
SWEP.Primary.Automatic 		= true
SWEP.Primary.Recoil 		= 0.05
SWEP.Primary.Delay 			= 0.1
SWEP.Primary.Force 			= 1

SWEP.Secondary.ClipSize 	= -1
SWEP.Secondary.DefaultClip 	= -1
SWEP.Secondary.Automatic 	= true
SWEP.Secondary.Ammo 		= "none"

SWEP.Range					= 2^16

SWEP.MachineRepairSounds = {
	["buttons/lever1.wav"] = 140,
	["buttons/lever4.wav"] = 165,
	["buttons/lever7.wav"] = 120,
	["buttons/lever8.wav"] = 170,
	["buttons/button4.wav"] = 150,
	["buttons/button22.wav"] = 120,
}

SWEP.MachineRepairDone = {
	["buttons/blip2.wav"] = 115,
	["buttons/button14.wav"] = 120,
}

SWEP.SoundFrequency = 0.3

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "LastSound")
end

local function IsHealable(ent)
	if not IsValid(ent) then return false end
	if IsPlayer(ent) then return true end
	if not BaseWars.ShouldUseHealth(ent) then return false end

	-- world can go fuck itself
	local ow = ent:BW_GetOwner()
	if not ow then return false end

	-- not a world prop or an owned entity; can blowtorch
	return ow
end

local function TempUnhealable(ent)
	if CurTime() - ent:GetNWFloat("LastDamage", 0) < 3 then
		return true
	end
end

function SWEP:Deny()
	self:EmitSound("weapons/physcannon/physcannon_dryfire.wav",
		45, math.random(100, 103), 0.6)
end

SWEP.DenySounds = {}
for i=1, 5 do
	SWEP.DenySounds[i] = ("npc/scanner/combat_scan%d.wav"):format(i)
end

function SWEP:TempDeny()
	self:EmitSound(self.DenySounds[math.random(#self.DenySounds)],
		40, 140, 0.6)
end


local SuppressHostEvents = SuppressHostEvents or function() end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if not IsFirstTimePredicted() then return end

	local ow = self:GetOwner()
	if ow:InRaid() then return end

	local tr = util.TraceLine({
		start = ow:GetShootPos(),
		endpos = ow:GetShootPos() + ow:GetAimVector() * self.Range,
		filter = ow
	})

	local ent = tr.Entity

	if not IsHealable(ent) then
		self:Deny()
		self:SetNextPrimaryFire(CurTime() + 0.5)
		return
	end

	if TempUnhealable(ent) then
		self:TempDeny()
		self:SetNextPrimaryFire(CurTime() + 0.75)
		return
	end

	local maxHP = ent:GetMaxHealth()
	if maxHP <= 0 then return end

	if ent:Health() >= ent:GetMaxHealth() then return end
	if ent:BW_GetOwner() and ent:BW_GetOwner():GetRaid() then return end

	local ef = EffectData()
	ef:SetOrigin( tr.HitPos )
	ef:SetStart( self:GetOwner():GetShootPos() )
	ef:SetAttachment( 1 )
	ef:SetEntity(self)

	util.Effect( "ToolTracer", ef )
	util.Effect( "inflator_magic", ef )

	if IsPlayer(ent) then
		if SERVER then
			ent:SetHealth(math.min(ent:GetMaxHealth(), ent:Health() + self.HealAmount * self.PlayerHealMult))
		end

		return
	end


	if ent.IsBaseWars then
		local pool
		local level, vol = 60, 0.6
		local max = ent:GetMaxHealth()

		local repairDone = math.min(ent:Health() + self.HealAmount, max) == max
		if repairDone then
			pool = self.MachineRepairDone
			level, vol = 90, 1.7
		elseif CurTime() - self.SoundFrequency >= self:GetLastSound() then
			pool = self.MachineRepairSounds
		end

		if pool then
			self:SetLastSound(CurTime())
			SuppressHostEvents(self:GetOwner())
				local pitch, snd = table.Random(pool)
				self:EmitSound(snd, level, pitch, vol, CHAN_AUTO)
			SuppressHostEvents()
		end
	end


	if SERVER then
		ent:SetHealth(math.min(ent:GetMaxHealth(), ent:Health() + self.HealAmount))

		if not ent.IsBaseWars then
			local color = ent:Health() / ent:GetMaxHealth() * 255
			ent:SetColor(Color(color, color, color))
		end
	end

end
