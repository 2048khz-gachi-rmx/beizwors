local PLAYER = FindMetaTable("Player")

function PLAYER:BW_DropWeapon(wep, force, nostrip)
	if not wep then return end

	if IsValid(wep) and (force or not wep.DisallowDrop) then
		local mdl = wep:GetModel()
		local class = wep:GetClass()

		if not force and BaseWars.Config.WeaponDropBlacklist[class] then
			return false
		end

		local tr = {}

		tr.start = self:EyePos()
		tr.endpos = tr.start + self:GetAimVector() * 85
		tr.filter = self

		tr = util.TraceLine(tr)

		local pos = tr.HitPos + BaseWars.Config.SpawnOffset
		local ang = self:EyeAngles()

		ang.p = 0
		ang.y = ang.y + 180
		ang.y = math.Round(ang.y / 45) * 45

		local Ent = ents.Create("bw_weapon")
			Ent.WeaponClass = class
			Ent.Model = mdl
			Ent:SetPos(pos)
			Ent:SetAngles(ang)
			Ent.Dropped = true

		Ent:Spawn()
		Ent:Activate()

		hook.Run("BW_DropWeapon", self, wep, Ent)
		if not nostrip then
			self:StripWeapon(class)
		end

		return Ent
	end
end

function PLAYER:ActiveWeaponWorkaround()
	for k,v in ipairs(self:GetWeapons()) do
		if v:GetInternalVariable("m_iState") == 2 then
			return v
		end
	end
end

hook.Add("PlayerDeath", "DropWeapon", function(ply)
	local wep = ply:ActiveWeaponWorkaround()
	if IsValid(wep) then
		local wp = ply:BW_DropWeapon(wep, nil, true)
		if not wp then return end

		wp:SetPos(ply:EyePos())
		wp:SetAngles(ply:EyeAngles())
		local vel = ply:GetVelocity()
		wp:GetPhysicsObject():SetVelocity(vel + ply:GetAimVector() * 256)
	end
end)