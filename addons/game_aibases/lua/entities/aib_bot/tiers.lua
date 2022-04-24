--

--[[
vars = {
	ChaseChainDelay = 0.7,
	InitialChaseDelay = 4,
	_curChaseDelay = ENT.InitialChaseDelay,
}
]]
ENT.TierData = {
	[1] = {
		models = {
			-- ZASED
			"models/player/group03/male_03.mdl", "models/player/group03/male_01.mdl",
			"models/player/group03/female_03.mdl", "models/player/group03/female_05.mdl",
		},

		vars = {
			ChaseChainDelay = 0.5,
			InitialChaseDelay = 1.6,

			LockedShootTime = 0.3,
			LockedRequiredLostDelay = 1.3,
			AimSpeed = 240,

			DamageMult = 0.4,
		},

		health = 100,
	},

	[2] = {
		models = {
			"models/player/guerilla.mdl", "models/player/arctic.mdl",
			"models/player/leet.mdl", "models/player/phoenix.mdl",
		},

		vars = {
			ChaseChainDelay = 0.25,
			InitialChaseDelay = 0.7,

			LockedShootTime = 0.25,
			LockedRequiredLostDelay = 1.7,
			AimSpeed = 300,

			DamageMult = 0.5,
		},

		health = 150,
	},

	[3] = {
		models = {
			"models/player/riot.mdl", "models/player/urban.mdl",
			"models/player/gasmask.mdl", "models/player/swat.mdl",
		},

		vars = {
			ChaseChainDelay = 0.1,
			InitialChaseDelay = 0.6,

			LockedShootTime = 0.2,
			LockedRequiredLostDelay = 2.3,
			AimSpeed = 360,

			DamageMult = 0.65,
		},

		health = 200,
	},

	[4] = {
		models = {
			"models/player/riot.mdl", "models/player/urban.mdl",
			"models/player/gasmask.mdl", "models/player/swat.mdl",
		},

		vars = {
			ChaseChainDelay = 0,
			InitialChaseDelay = 0.3,

			LockedShootTime = 0.175,
			LockedRequiredLostDelay = 2.8,
			AimSpeed = 400,

			DamageMult = 0.75,
		},

		health = 300,
	},
}


function ENT:InitializeTier(tier)
	tier = tier or 1

	local td = self.TierData[tier] or {}

	if not self.ModelOverride then
		local mdl = td.models and table.Random(td.models) or "models/player/skeleton.mdl"
		self:SetModel(mdl)
	else
		self:SetModel(self.ModelOverride)
		print("le model", self.ModelOverride)
	end

	local wep = self.ForceWeapon
	if wep then
		local base = weapons.GetStored(wep)
		if base then
			-- raw weapon class
			self:Give(wep)
		else
			-- probably a type
			local class = AIBases.RollWeapon(wep, tier)
			self:Give(class)
		end
	end

	for k,v in pairs(td.vars or {}) do
		self[k] = v
	end

	if td.health then
		self:SetMaxHealth(td.health)
		self:SetHealth(td.health)
	end

	self._curChaseDelay = self.InitialChaseDelay
end