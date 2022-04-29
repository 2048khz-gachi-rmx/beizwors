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
