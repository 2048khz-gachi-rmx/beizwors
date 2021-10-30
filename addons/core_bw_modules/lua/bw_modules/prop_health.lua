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
	if isDMG(dmg) then dmg = dmg:GetDamage() end

	if BaseWars.ShouldUseHealth(ent) then
		local hp = ent:Health()
		if hp - dmg < 0 then
			ent:Remove()
		end
		ent:SetHealth(hp - dmg)

		local fr = (hp - dmg) / ent:GetMaxHealth()
		ent:SetNWFloat("LastDamage", CurTime())
	else
		print("!!! Unhandled DealDamage call on", ent)
		-- ??
	end
end

function BaseWars.ShouldUseHealth(ent)
	return ent.IsMediaPlayerEntity
		or ent:GetClass() == "prop_physics"
		or ent.IsBaseWars -- more to be added
end