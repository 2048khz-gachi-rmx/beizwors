AddCSLuaFile("cl_init.lua")

ENT.Base 		= "base_gmodentity"
ENT.Type 		= "anim"
ENT.PrintName 	= "Spawned Weapon"

ENT.Model 		= "models/weapons/w_smg1.mdl"

ENT.WeaponClass = "weapon_smg1"

local function IsGroup(ply, group)
	if not ply.CheckGroup then error("what the fuck where's ULX") return end
	if not IsValid(ply) or not ply:IsPlayer() then return end

	if ply:CheckGroup(string.lower(group)) or
		(ply:IsAdmin() and (group=="vip" or group=="trusted"))
		or ply:IsSuperAdmin() then

		return true
	end

	return false

end

function ENT:Initialize()
	self.BaseClass:Initialize()

	self:SetModel(self.Model)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)

	self:PhysWake()

	self:Activate()

	self:SetUseType(SIMPLE_USE)

	local despawnTime = 20
	local blips = 3

	self:Timer("DisappearWarn", despawnTime - blips - 1, 1, function()
		self:EmitSound("npc/roller/mine/rmine_tossed1.wav", 70, 120, 1)

		self:Timer("Disappear", blips + 1, 1, function()
			local pos = self:LocalToWorld(self:OBBCenter())

			print("disappear timer, playing and yeeting", pos)

			sound.Play("weapons/arccw/ricochet0" .. math.random(1, 5) .. ".wav",
				pos, 70, math.random(90, 110), 1)
			sound.Play("weapons/arccw/malfunction.wav",
				pos, 70, math.random(90, 110), 1)

			local ef = EffectData()
			ef:SetOrigin(pos)
			ef:SetStart(pos)
			ef:SetScale(0.3)
			ef:SetMagnitude(0.5)
			ef:SetEntity(self)

			util.Effect( "inflator_magic", ef )

			self:SetNoDraw(true)
			self:SetNotSolid(false)
			self.Gone = true

			util.Effect( "entity_remove", ef )

			self:Timer("DoRemove", 0.5, 1, function()
				self:Remove()
			end)
		end)
	end)
end


local kt = {
	"bowie",
	"karambit",
	"butterfly",
	"default",
	"falchion",
	"bayonet",
	"flip",
	"gut",
	"huntsman",
	"m9",
	"daggers"
}
function ENT:Use(act, call, usetype, value)
	if self.Gone then return end
	if not IsValid(act) or not IsValid(call) or act ~= call or not act:IsPlayer() then return end

	local Class = self.WeaponClass
	local Wep = act:GetWeapon(Class)
	local ply = act

	if Class == "csgo_default_knife" then

		if IsGroup(ply, "vip") then
			local ktype = "default"

			if ply.KnifeType then
				for k,v in pairs(kt) do
					if v == ply.KnifeType then ktype = v break end
				end
				ply:Give("csgo_" .. ktype)
				self:Remove()
				return
			end
		end

	end

	if IsValid(Wep) then
		--local Clip = Wep.Primary and Wep.Primary.DefaultClip
		--ply:GiveAmmo((Clip and Clip * 2) or 30, Wep:GetPrimaryAmmoType())
		return
	else
		Wep = ply:Give(Class)
		if not IsValid(Wep) then
			errNHf("Failed to give weapon class `%s` - invalid.", Wep)
			return
		end

		if self.Backup then
			table.Merge(Wep:GetTable(), self.Backup)
		end

		if not self.Dropped then
			local Clip = Wep.Primary and Wep.Primary.DefaultClip
			local aType = Wep:GetPrimaryAmmoType()
			local already_given = ply:GetDeathVar("bwweapon_ammo_" .. aType, 0)

			local to_give = math.max(0, ((Clip and Clip * 2) or 30) - already_given)

			if to_give > 0 then
				ply:SetDeathVar("bwweapon_ammo_" .. aType, already_given + to_give)
				ply:GiveAmmo(to_give, aType)
			end
		end

		hook.Run("BW_WeaponPickedUp", self, Wep, ply)
	end


	self:Remove()
end
