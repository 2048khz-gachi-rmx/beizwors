CustomizableWeaponry.ITEM_PACKS_TOP_COLOR = Color(0, 200, 255, 255)

local noDraw = {CHudAmmo = true,
	CHudSecondaryAmmo = true,
	CHudHealth = true,
	CHudBattery = true}

local noDrawAmmo = {
	CHudAmmo = true,
	CHudSecondaryAmmo = true
}

local wep, ply

local customHud = false
local customAmmo = false

timer.Create("CW_CheckConvars", 1, 0, function()
	customHud = GetConVarNumber("cw_customhud") >= 1
	customAmmo = GetConVarNumber("cw_customhud_ammo") >= 1
end)

local function CW_HUDShouldDraw(n)
	if not customHud and not customAmmo then return end
	if not CachedLocalPlayer or not CachedLocalPlayer() then return end

	local ply = CachedLocalPlayer()
	ply = ply and ply:Alive() and ply
	local wep = ply and ChainValid(ply:GetActiveWeapon())
	if not wep then return end

	if customAmmo then
		if wep.CW20Weapon then
			if noDrawAmmo[n] then
				return false
			end
		end
	end

	if customHud then
		if  wep.CW20Weapon then
			if noDraw[n] then
				return false
			end
		end
	end
end

hook.Add("HUDShouldDraw", "CW_HUDShouldDraw", CW_HUDShouldDraw)