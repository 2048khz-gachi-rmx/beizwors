AddCSLuaFile("cl_init.lua")

ENT.Base 		= "base_gmodentity"
ENT.Type 		= "anim"
ENT.PrintName 	= "Spawned Weapon"

ENT.Model 		= "models/weapons/w_smg1.mdl"

ENT.WeaponClass = "weapon_smg1"

local function IsGroup(ply, group)
	if not ply.CheckGroup then error("what the fuck where's ULX") return end
	if not IsValid(ply) or not ply:IsPlayer() then return end

	if ply:CheckGroup(string.lower(group)) or (ply:IsAdmin() and (group=="vip" or group=="trusted")) or ply:IsSuperAdmin() then 
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
	if not IsValid(act) or not IsValid(call) or act ~= call or not act:IsPlayer() then return end

	local Class = self.WeaponClass
	local Wep = act:GetWeapon(Class)
	local ply = act 

	if Class == "csgo_default_knife" then
		if IsGroup(ply, "vip") then 

			local ktype = "default"

			if ply.KnifeType then

				for k,v in pairs(kt) do 
					if v==ply.KnifeType then ktype = v break end
				end
				ply:Give("csgo_"..ktype)
				self:Remove()
				return
			end


		end
	end

	if IsValid(Wep) then
	
		local Clip = Wep.Primary and Wep.Primary.DefaultClip
		
		ply:GiveAmmo(Clip or 30, Wep:GetPrimaryAmmoType())
		
	else
	
		local wep = ply:Give(Class)
		if self.Backup then 
			table.Merge(wep:GetTable(), self.Backup)
		end
	end
	
	
	self:Remove()

end
