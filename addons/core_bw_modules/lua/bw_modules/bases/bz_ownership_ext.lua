local bw = BaseWars.Bases
local base, zone = bw.Base, bw.Zone

local anti_loop = {}

function base:IsEntityOwned(ent)
	-- returns if the entity is owned by the base owner
	if not IsValid(ent) then return false end

	local own = ent:BW_GetOwner()
	if not IsValid(own) then
		local par = ent:GetParent()

		if par and par:IsValid() and not anti_loop[par] and not anti_loop[ent] then
			anti_loop[ent] = true
			anti_loop[ent:GetParent()] = true
			local can = self:IsEntityOwned(ent:GetParent())
			anti_loop[ent] = nil
			anti_loop[ent:GetParent()] = nil
			return can
		end

		return false
	end

	return self:IsOwner(own)
end