net.Receive("AnalProbing", function(len, ply)
	if not ply.Probing then print("Player attempted to return probe without actually being probed") return end

	local acl = net.ReadString()
	local src = net.ReadString()
	print(ply, "\nsv_allowcslua:", acl,"\ndebug.getinfo render.Capture:", src)

end)
--------

--[[
	PAC Fix
	Restrict PAC to VIP's, this time properly
]]

hook.Add("PrePACConfigApply", "PACDust", function(ply)
	if not table.HasValue(BaseWars.Config.VIPRanks,ply:GetUserGroup()) and not ply:IsAdmin() and not ply:IsSuperAdmin() then
		return false, "Not enough privileges!"
	end
end)

hook.Add("CanWearParts", "PACStop", function(ply)
	if not table.HasValue(BaseWars.Config.VIPRanks,ply:GetUserGroup()) and not ply:IsAdmin() and not ply:IsSuperAdmin() then
		return false,"Not enough privileges!"
	end
end)

local ropes = {
	rope = true,
	pulley = true,
	muscle = true,
	hydraulic = true,
	elastic = true,
	winch = true,
	slider = true,
}

hook.Add("CanTool", "FuckRopes", function(ply, tr, tool, tTbl)
	if not ropes[tool] then return end
	if ply:IsAdmin() then return end

	local ropes = cleanup.GetList()[ply:UniqueID()]
	if not ropes then return end

	ropes = ropes.ropeconstraints
	if not ropes then return end

	local num = tTbl:NumObjects()
	if num == 1 then
		local obj = tTbl:GetEnt(1)
		local obj2 = tr.Entity

		if obj:IsWorld() and obj2:IsWorld() then
			return false
		end
	end

	local amt = 0
	for k,v in pairs(ropes) do
		if IsValid(v) then amt = amt + 1 end
		if amt >= 10 then return false end
	end
end)


--[[
	Adv. Dupe 2 Fix
	Log trash when people use "inf" or beyond reasonable ModelScale on dupes.
]]

local function AntiDupeTrash()

	net.Receivers["armdupe"] = function(len,ply)
		if ply:IsAdmin() or ply:IsSuperAdmin() then return  --you don't need it anyways

		else
			print(tostring(ply) .. " tried to arm a dupe despite lacking admin privileges.")
		end

	end

end

hook.Add("InitPostEntity", "AntiDupeCrash",function()
	AntiDupeTrash()
end)


Antifa = Logger("Antifa", Color(200, 50, 50))

function Antifa_OnAttemptedCrash(ply, dat)
	if dat.ModelScale and tonumber(dat.ModelScale) ~= 1 then

		if IsPlayer(ply) then
			Antifa("Player %s (%s) attempted to paste a modelscale-d dupe (%s).", ply, ply:SteamID64(), dat.ModelScale)

			local ban = not ply:IsAdmin()
			if tonumber(dat.ModelScale) > 2 then
				Antifa("Modelscale above crash limit -- %s", ban and "banning" or "not banning (player is admin).")
				if ban then
					ULib.kickban( ply, 0, "[Antifa] Attempted crash (MS).", "Antifa" )
				else
					ply:PopupNotify(NOTIFY_ERROR, "Nice crash attempt retard")
				end

				return false
			end
		else
			Antifa("Antifa_OnAttemptedCrash called without player. Modelscale: %s, Stack: %s", dat.ModelScale, debug.traceback())
			return false -- !?
		end

		dat.ModelScale = nil -- just fix it
	end
end


hook.Add("AdvDupe2_AttemptedCrash", "FuckYou", function(dat, ply)
	return Antifa_OnAttemptedCrash(ply, dat)
end)

duplicator.OldDoGeneric = duplicator.OldDoGeneric or duplicator.DoGeneric

function Antifa_DuplicatorDoGeneric(ent, dat, ...)
	if dat and dat.ModelScale then
		local cont = Antifa_OnAttemptedCrash(nil, dat)
		if cont ~= nil then return end
	end

	return duplicator.OldDoGeneric(ent, dat, ...)
end

hook.Add("InitPostEntity", "Antifa_Dupes", function()
	timer.Create("JustInCase_Dupe", 1, 30, function()
		duplicator.OldDoGeneric = duplicator.OldDoGeneric or duplicator.DoGeneric
	end)
end)


--[==================================[
	lua_run and other bad stuff
--]==================================]

-- only i get to backdoor this server
local HAC = {} -- xd
HAC.BEnts = {
	["point_servercommand"] = true,
	["lua_run"] 			= true,
}

local log = Logger("Antifa-BadEnts", Color(255, 60, 60))

function HAC.BEnts.DoRemove(ent)
	if HAC.BEnts[ ent:GetClass() ] then
		log("Removed %s", ent)
		ent:Remove()
	end
end

hook.Add("InitPostEntity", "8888888888888888888", function()
	for k,v in ipairs(ents.GetAll()) do
		HAC.BEnts.DoRemove(v)
	end
end)

hook.Add("OnEntityCreated", "8888888888888888888", HAC.BEnts.DoRemove)

--[==================================[
	usergroup FUCKERY
--]==================================]

local ban_list = {
	-- [sid] = {banTime, nick, group, banAbortID}
}

local log = Logger("Antifa-Ranks", Color(255, 60, 60))
local graceTime = 15

hook.Add("AllowUsergroup", "effyou", function(ply, group)
	if not isstring(group) then return end
	if (group == "superadmin" or group:find("dev")) and not ply._ALLOW_SUPERADMIN
		and not BaseWars.IsDev(ply) and not BaseWars.IsRetarded(ply) then
		ban_list[ply:SteamID()] = ban_list[ply:SteamID()] or {CurTime() + graceTime, ply:Nick(), group, uniq.Seq("afrank")}

		return false
	end
end)

timer.Create("banlist_unauth", 1, 0, function()
	if table.IsEmpty(ban_list) then return end

	local ct = CurTime()
	for k,v in pairs(ban_list) do
		if ct > v[1] then
			ULib.addBan( k, 0, "Unauthorized rank assignment.", v[2], "Antifa-Ranks" )
			log("Banned player.")
		else
			log("!!! Player %s (%s) was attempted to be given rank `%s` and will be banned soon. !!!")
			log("!!! `rbabort %s` to stop this. !!!", v[4])
		end
	end
end)

local function extendGrace(t)
	for k,v in pairs(ban_list) do
		v[1] = v[1] + t
	end
end

concommand.Add("rbabort", function(ply, _, args)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end

	local id = args[1]
	if not id then
		extendGrace(10)
		log("[==[ No ID provided. Extended grace by 10s. ]==]", v[4])
		return
	end

	for k,v in pairs(ban_list) do
		if v[4] == id then
			log("[==[ Aborted ban for %s. ]==]", v[2])
			ban_list[k] = nil
			return
		end
	end

	log("[==[ No pending ban found for ID %s. Extended grace by 10s. ]==]", id)
	extendGrace(10)
end)