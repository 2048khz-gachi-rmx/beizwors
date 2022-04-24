--

function ENT:QueueGesture(act)
	self._wantGesture = act
end

function ENT:DoGestures()
	if self._wantGesture then
		self:RemoveAllGestures()
		local layer = self:AddGesture(self._wantGesture)
		self:SetLayerBlendIn(layer, 0.2)
		self:SetLayerBlendOut(layer, 0.2)
		self._wantGesture = nil
	end
end

ENT.AnimActivities = {
	default = {
		aggro = ACT_MP_WALK, -- gmod will translate these into player animations
		aggro_idle = ACT_MP_WALK,
		aggro_run = ACT_MP_RUN,

		passive = ACT_HL2MP_WALK_PASSIVE,
		passive_idle = ACT_HL2MP_WALK_PASSIVE,
		passive_run = ACT_HL2MP_RUN,

		reload = ACT_HL2MP_WALK_CROUCH,
	},

	ar2 = {
		reload = ACT_HL2MP_WALK_CROUCH_AR2,
	},

	shotgun = {
		reload = ACT_HL2MP_WALK_CROUCH_SHOTGUN,
	},

	pistol = {
		passive = ACT_HL2MP_WALK,
		passive_idle = ACT_HL2MP_IDLE,
		passive_run = ACT_HL2MP_RUN,
	},

	smg = {},

	revolver = {
		passive = ACT_HL2MP_WALK,
		passive_idle = ACT_HL2MP_IDLE,
		passive_run = ACT_HL2MP_RUN,
	}
}

ENT.EquippedType = "ar2"
ENT.HostileMoods = {
	engaging = true,
	chasing = true,
	covering = true,
	alert = true,
}

function ENT:_getAc(base, pfx, sfx)
	local ac = self.AnimActivities[self.EquippedType]
	if not ac then print("no activities!") return ACT_HL2MP_WALK_PASSIVE end

	local def = self.AnimActivities.default

	return 	ac[pfx .. base .. sfx] or def[pfx .. base .. sfx] or
			ac[pfx .. base 		 ] or def[pfx .. base	   ] or
			ac[		  base .. sfx] or def[		base .. sfx] or
			ac[		  base		 ] or def[		base	   ]
end

function ENT:GetDesiredActivity()
	local wep = self:GetActiveWeapon()
	if wep:IsValid() then
		self.EquippedType = wep:GetHoldType() or self.EquippedType
	end

	local acts = self.AnimActivities[self.EquippedType]
	if not acts then print("no acts tard", self.EquippedType) return ACT_HL2MP_WALK_PASSIVE end

	local len = self.loco:GetVelocity():Length()

	local sfx = len > 100 and "_run"
		or len == 0 and "_idle"
		or ""

	local pfx = ""

	if self:HasActivity("Reload") then
		return self:_getAc("reload", pfx, sfx)
	end

	if self.HostileMoods[self:GetMood()] then
		return self:_getAc("aggro", pfx, sfx)
	end

	return self:_getAc("passive", pfx, sfx)
end

function ENT:MatchActivity()
	local wep = self:GetCurrentWeapon()
	local want = self:GetDesiredActivity()
	if not want then
		errorNHf("no desired activity found? %s [mood: %s, hold: %s]",
			want, self:GetMood(), self.EquippedType)
		return
	end

	local wanted = want

	if IsValid(wep) then
		local toTr = istable(want) and want[1] or want
		local tr = wep:TranslateActivity(toTr)
		if tr == -1 then
			if istable(want) then want = want[2] end
		else
			want = tr
		end
	end

	if want ~= self:GetActivity() then
		self:StartActivity(want)
		--[[printf("server: activity set to [%s] -> %s (seq: %s = %s)",
			wanted, want, self:GetSequence(), self:GetSequenceName(self:GetSequence()))
		printf("	translated %s -> %s", want, self:SelectWeightedSequence(want))]]
	end
end
