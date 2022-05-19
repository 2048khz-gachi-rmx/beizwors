-- ?

hook.Add("BW_CanPurchase", "ResearchTiers", function(ply, itm)
	if itm.Category == "Printers" and not itm.ResolveResearch then
		local tier = itm.Tier
		if not tier then return end

		if not ply:HasPerkLevel("printer_tier", tier - 1) then return false end

	elseif itm.RequiresResearch then
		-- todo: accept a table of strings or a string (required research IDs)
	end
end)