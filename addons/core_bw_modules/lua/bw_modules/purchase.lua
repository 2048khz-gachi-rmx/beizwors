--
BaseWars.Purchase = BaseWars.Purchase or {}

function BaseWars.GetItem(catName, catID)
	if istable(catName) and catName.IsBWCatItem then return catName end

	if not catName or not catID then return end

	local cat = BaseWars.SpawnList[catName]
	if not cat then return end

	local its = cat.Items[catID]

	return its, cat
end

function BaseWars.CanPurchase(ply, cat, itemid)
	local itm = BaseWars.GetItem(cat, itemid)

	if not itm then
		errorNHf("not item: %s / %s", cat, itemid)
		return false
	end

	local ret = hook.Run("BW_CanPurchase", ply, itm)
	if ret ~= nil then return ret end

	return true
end