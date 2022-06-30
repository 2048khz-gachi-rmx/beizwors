ENT.Base = "bw_base_upgradable"
ENT.Type = "anim"

ENT.PrintName = "SpawnPoint"
ENT.Model = "models/props_trainstation/trainstation_clock001.mdl"

ENT.PowerRequired = 15
ENT.PowerCapacity = 5000
ENT.MaxHealth = 200

ENT.Levels = {
	{
		Cost = 0,
		SpawnTime = 1,
	}, {
		Cost = 5e6,
		SpawnTime = 0.8
	}, {
		Cost = 150e6,
		SpawnTime = 0.6
	}
}
-- ENT.AlwaysRaidable = true

if SERVER then

	AddCSLuaFile()

	local ForceAngle = Angle(-90, 0, 0)

	function ENT:SHInit()
		self:SetAngles(ForceAngle)
		self:SetCollisionGroup(COLLISION_GROUP_WORLD)
		--self:EnableCustomCollisions(true)

		local phys = self:GetPhysicsObject()

		if SERVER and IsValid(phys) then
			phys:EnableMotion(false)
		end

		self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end

	--[[function ENT:TestCollision()
		return false
	end]]

	function ENT:BW_PostBuy(ply, tr, class)
		local pos = ply:GetPos()

		self:SetPos(pos)
		self.SpawnAngle = ply:EyeAngles()
		self:Spawn()
		self:Activate()

		self:EmitSound("buttons/blip1.wav")
		if IsValid(ply.SpawnPoint) then
			ply.SpawnPoint.OwningPly = false
			ply.SpawnPoint:EmitSound("ambient/machines/thumper_shutdown1.wav")
		end

		self.OwningPly = ply
		ply.SpawnPoint = self
	end

	function ENT:OnRemove()
		if IsPlayer(self.OwningPly) then
			self.OwningPly.SpawnPoint = nil
		end
	end

	function ENT:RespawnPlayer(ply)
		if not self:IsPowered() then return end

		local Pos = self:GetPos() + Vector(0, 0, 16)
		local ang = self.SpawnAngle
		ang[1] = 0
		ang[3] = 0
		ply:SetPos(Pos)
		ply:SetEyeAngles(ang)

		hook.Run("SpawnpointUsed", ply, self)
	end
end

function ENT:AllowedUpgrade(ply)
	local lv = ply:GetPerkLevel("spoint")
	if not lv then return false end

	lv = lv:GetLevel()
	local curLv = self:GetLevel()

	if curLv > lv then return false end

	return lv - curLv + 1
end

hook.Add("PlayerDeath", "RespawnTime", function(ply, by, atk)
	local side = ply:GetSide()

	local cfg = BaseWars.Config
	local base = cfg.RespawnTime -- base respawn time

	local sideCd = {cfg.RespawnRaider, cfg.RespawnRaided}
	local spoint = ply.SpawnPoint
	local mult = spoint and spoint:GetLevelData().SpawnTime or 1

	if side then
		-- raider = 1, raided = 2
		local delay = sideCd[side] or base
		ply:SetRespawnTime(delay * mult)
	else
		ply:SetRespawnTime(base * mult)
	end
end)