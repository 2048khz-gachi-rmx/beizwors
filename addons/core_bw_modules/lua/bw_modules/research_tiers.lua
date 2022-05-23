-- ?

hook.Add("BW_CanPurchase", "ResearchTiers", function(ply, itm)
	if itm.Category == "Printers" and not itm.ResolveResearch then
		local tier = itm.Tier
		if not tier then return end

		if not ply:HasPerkLevel("printer_tier", tier - 1) then return false end

	elseif istable(itm.RequiresResearch) then
		-- todo: accept a table of [resID] = lv,
		local res = itm.RequiresResearch
		for id, req in pairs(res) do
			if not  ply:HasPerkLevel(id, req) then return false end
		end
	end
end)