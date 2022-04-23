--

function Safezones.IsProtected(ent, nolinger)
	-- returns whether the entity is already protected

	if nolinger and not Safezones.IsIn(ent) then
		return false
	elseif not nolinger then
		-- player is not in a safezone; do linger logic

		if Safezones.IsLingering(ent) then
			return true
		end

		return false
	end

	return Safezones.TimeSinceIn(ent) > Safezones.TimeTillProtection
end