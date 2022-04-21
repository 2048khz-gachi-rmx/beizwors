setfenv(1, _G)
local tierToColor = {
	Colors.Money,
	Colors.Golden,
	Colors.Red,
}

hook.Add("BW_GetBaseHUDName", "AIBases", function(ptr, base)
	local tier = base:GetAITier()
	if not tier then return end

	return tierToColor[tier], base:GetName() .. " (T" .. tier .. ")"
end)

hook.Add("BW_UpdateClaimHUD", "AIBases", function(ptr, base, dt, pc)
	local tier = base:GetAITier()
	if not tier then return end

	pc:ReplaceText(dt.BaseStarterID, "AI Base: ")
	local _, new = pc:ReplaceText(dt.BaseNameID, "Tier " .. tier)

	if new then
		new.Color = tierToColor[tier]:Copy():MulHSV(1, 1, 0.75)
	end

	return true
end)