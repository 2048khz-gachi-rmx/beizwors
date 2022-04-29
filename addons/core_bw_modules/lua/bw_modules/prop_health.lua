setfenv(1, _G)
--[[
	thank you based volvo

	[10:18 PM] code_gs: some CNetworkVars delay in their sending
	[10:18 PM] code_gs: Idk what the conditions or flags for that are but I noticed it a while ago
]]

local ENTITY = FindMetaTable("Entity")

__SetHealth = __SetHealth or ENTITY.SetHealth

ENTITY.SetHealth = function(self, hp)
	if self:GetClass() == "prop_physics" then
		self:SetDTInt(30, hp)
	else
		return __SetHealth(self, hp)
	end
end

__Health = __Health or ENTITY.Health

ENTITY.Health = function(self)
	if self:GetClass() == "prop_physics" then
		return self:GetDTInt(30)
	else
		return __Health(self)
	end
end

local function isDMG(t)
	return type(t) == "CTakeDamageInfo"
end

function BaseWars.DealDamage(ent, dmg)
	if ent.__dealingDmg then return end

	if isDMG(dmg) then dmg = dmg:GetDamage() end

	if BaseWars.ShouldUseHealth(ent) then
		ent.__dealingDmg = true
		local hp = ent:Health()
		if hp - dmg < 0 then
			ent.BW_DamageRemoved = true
			hook.NHRun("BW_EntityShotDown", ent, dmg)
			ent:Remove()
			return
		end
		ent:SetHealth(hp - dmg)

		local fr = (hp - dmg) / ent:GetMaxHealth()
		ent:SetNWFloat("LastDamage", CurTime())
		ent.__dealingDmg = nil
	--[[else
		print("!!! Unhandled DealDamage call on", ent)
		-- ??]]
	end
end

function BaseWars.ShouldUseHealth(ent)
	return ent.IsMediaPlayerEntity
		or ent:GetClass() == "prop_physics"
		or ent.IsBaseWars -- more to be added
		or ent:BW_GetOwner()
end

local dealStack = 0 -- depth
local popped = 0
local sparked = 0

hook.Add("BW_EntityShotDown", "StopPropblocking", function(ent, dmg)
	if ent:GetClass() ~= "prop_physics" then return end

	local ow = ent:BW_GetOwner()
	if not ow then return end

	local bz = ent:BW_GetBase()
	if bz and bz:IsEntityOwned(ent) then return end -- ignore owned props

	local max = ent:GetMaxHealth()

	-- prop shot down inside someone's base or outside of one; apply punishment
	local around = ents.FindInSphere(ent:GetPos() + ent:OBBCenter(), 96)
	local dealt = false
	local poppedByMe = 0
	local sparkedByMe = 0

	for k,v in ipairs(around) do
		-- deal damage to props around it
		if v:BW_GetOwner() ~= ow then continue end
		if v:GetClass() ~= "prop_physics" then continue end
		if v:BW_GetBase() and v:BW_GetBase():IsEntityOwned(v) then continue end
		if v == ent then continue end

		dealt = dealt or dealStack
		dealStack = dealt + 1

		BaseWars.DealDamage(v, max * 0.2) -- destroy stacked propblocks

		local par

		if v.BW_DamageRemoved then
			if popped > 3 then continue end
			par = "balloon_pop"

			popped = popped + 1
			poppedByMe = poppedByMe + 1
		else
			if sparked > 3 then continue end
			par = "cball_explode"

			sparked = sparked + 1
			sparkedByMe = sparkedByMe + 1
		end

		if not par then continue end

		local ef = EffectData()
		ef:SetOrigin(v:GetPos() + v:OBBCenter())
		ef:SetNormal(VectorRand())
		ef:SetEntity(v)
		ef:SetScale(0)
		util.Effect(par, ef)
	end

	popped = popped - poppedByMe
	sparked = sparked - sparkedByMe
	dealStack = dealStack - 1

	local curCD = ow.cooldownSpawn
	if not curCD or CurTime() > ow.cooldownSpawn then
		ow.cooldownSpawn = CurTime() + (BW.Config.SpawnCDForBrokenProp or 2)
	else
		ow.cooldownSpawn = math.min(
			CurTime() + (BW.Config.MaxSpawnCD or 10),
			ow.cooldownSpawn + (BW.Config.SpawnCDForBrokenProp or 2)
		)
	end
end)

hook.Add("PlayerSpawnProp", "StopPropblocking", function(ent, mdl)
	local pin = GetPlayerInfo(ent)
	if not pin then return end

	if not pin.cooldownSpawn then return end
	if CurTime() >= pin.cooldownSpawn then return end

	local left = pin.cooldownSpawn - CurTime()

	if not pin.nextPBNotif or CurTime() > pin.nextPBNotif then
		pin.nextPBNotif = CurTime() + left
		ent:PopupNotify(NOTIFY_ERROR, {"Some of your props were destroyed earlier; please wait.", left})
	end

	return false
end)