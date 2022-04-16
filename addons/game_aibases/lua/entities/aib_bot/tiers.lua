--

ENT.TierData = {
	[1] = {
		models = {
			-- ZASED
			"models/player/group03/male_03.mdl", "models/player/group03/male_01.mdl",
			"models/player/group03/female_03.mdl", "models/player/group03/female_05.mdl",
		}
	},

	[2] = {
		models = {
			"models/player/guerilla.mdl", "models/player/arctic.mdl",
			"models/player/leet.mdl", "models/player/phoenix.mdl",
		}
	}
}
function ENT:InitializeTier(tier)
	tier = tier or 1

	local td = self.TierData[tier] or {}
	local mdl = td.models and table.Random(td.models) or "models/player/skeleton.mdl"

	self:SetModel(mdl)

	local wep = self.ForceWeapon
	if wep then
		local base = weapons.GetStored(wep)
		if base then
			-- raw weapon class
			self:Give(wep)
		else
			-- probably a type
			local class = AIBases.RollWeapon(wep, tier)
			print("giving:", class)
			self:Give(class)
		end
	end
end