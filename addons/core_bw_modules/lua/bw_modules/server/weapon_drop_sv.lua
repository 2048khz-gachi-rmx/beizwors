local PLAYER = FindMetaTable("Player")

function PLAYER:BW_DropWeapon(wep, force)
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
		self:StripWeapon(class)
	end
end