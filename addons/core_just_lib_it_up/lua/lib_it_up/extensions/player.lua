LibItUp.SetIncluded()

function ENTITY:Distance(ent)
	return self:GetPos():Distance(ent:GetPos())
end

function IsPlayer(ent)
	if type(ent) ~= "Player" or not IsValid(ent) then return false end
	return true
end

if SERVER then

	local rtimes = {}

	function PLAYER:SetRespawnTime(time, abs)
		local rt = rtimes

		if not abs then
			rt[self] = CurTime() + time
		else
			rt[self] = time
		end

		self:SetNW2Float("NextRespawn", rt[self])
	end

	PLAYER.SetNextRespawn = PLAYER.SetRespawnTime

	hook.Add("PlayerSpawn", "DoRespawnTime", function(ply)
		rtimes[ply] = nil
		ply:SetNW2Float("NextRespawn", 0)
		ply:SetNW2Float("DeathTime", 0)
	end)

	hook.Add("PlayerDeath", "DoDeathTime", function(ply)
		ply:SetNW2Float("DeathTime", CurTime())
	end)

	hook.Add("PlayerDeathThink", "DoRespawnTime", function(ply)
		local t = rtimes[ply]
		if t and t > CurTime() then return true end
	end)

	function PLAYER:GetRespawnTime()
		return rtimes[self] or (self.NextSpawnTime - CurTime()) --base gamemode
	end


	hook.Add("PlayerInitialSpawn", "CountBotIndex", function(ply)
		if ply:IsBot() then
			local curSID = ply:SteamID64()
			local diff = tonumber(curSID:sub(-5)) - tonumber(BotDefaultSteamID64:sub(-5))
			ply:SetNWInt("BotIndex", diff)
		end
	end)
else

	function PLAYER:GetRespawnTime()
		local t = self:GetNW2Float("NextRespawn")

		if t == 0 then return nil else return t end
	end

	function PLAYER:GetDeathTime()
		local t = self:GetNW2Float("DeathTime")

		if t == 0 then return nil else return t end
	end

	function PLAYER:GetRespawnLeft()
		local t = self:GetNW2Float("NextRespawn")

		if t == 0 then
			return false
		else
			return CurTime() - t
		end
	end

	local physPlys = { --[=[   [ply] = {entity, hitPos}   ]=]  }

	function PLAYER:GetPhysgunningEntity()
		local t = physPlys[self]
		return t and t[1], t and t[2]
	end

	hook.Add("DrawPhysgunBeam", "LibItUp_TrackPhysgun", function(ply, pgun, isEnabled, whomst, bone, where)
		if isEnabled then
			local t = physPlys[ply] or {}
			physPlys[ply] = t

			t[1] = whomst
			t[2] = where
		else
			physPlys[ply] = nil
		end

	end)

	PLAYER.__RealSteamID64 = PLAYER.__RealSteamID64 or PLAYER.SteamID64

	function PLAYER:SteamID64()
		if self:IsBot() then
			local first = "900719968423"
			local second = 77216 + self:GetNWInt("BotIndex", 0)
			return first .. second
		end
		return PLAYER.__RealSteamID64(self)
	end

end

PLAYER.__RealSteamID = PLAYER.__RealSteamID or PLAYER.SteamID

_G.BotDefaultSteamID64 = "90071996842377216"

function PLAYER:SteamID()
	if self:IsBot() then
		return util.SteamIDFrom64(self:SteamID64()) -- `NULL` cl or `BOT` sv --> "STEAM_0:0:0", "STEAM_0:0:1", so on
	end
	return PLAYER.__RealSteamID(self)
end

PLAYER.GetNextRespawn = PLAYER.GetRespawnTime

function IsPred()
	return CurTime() ~= UnPredictedCurTime()
end

function PLAYER:Retry()
	self:ConCommand("retry")
end

if SERVER then
	util.AddNetworkString("FullLoad")

	FullyLoaded = FullyLoaded or {}

	-- wait for either the client's net message or source's Move hook

	net.Receive("FullLoad", function(_, ply)
		if FullyLoaded[ply] then return end

		FullyLoaded[ply] = true
		hook.Run("PlayerFullyLoaded", ply)
	end)

	hook.Add("PlayerInitialSpawn", "PlayerFullyLoaded", function(ply)

		hook.OnceRet("SetupMove", ply, function(ply, mv_ply, mv, cmd)
			if mv_ply ~= ply then return false end
			if mv_ply == ply and not cmd:IsForced() then
				if FullyLoaded[ply] then return end

				FullyLoaded[ply] = true
				hook.NHRun("PlayerFullyLoaded", ply)
			end

			local should_remove = mv_ply == ply and not cmd:IsForced()

			return should_remove
		end)

	end)

else

	FullLoadSent = FullLoadSent or false
	FullLoadRan = FullLoadRan or false

	hook.Add("CalcView", "FullyLoaded", function()
		if FullLoadSent then
			hook.Remove("CalcView", "FullyLoaded")
			return
		end

		net.Start("FullLoad")
		net.SendToServer()

		FullLoadSent = true

		hook.Remove("CalcView", "FullyLoaded")

		hook.Run("PlayerFullyLoaded", LocalPlayer())

		FullLoadRan = true

	end)

	-- clientside PlayerInitialSpawn basically

	gameevent.Listen("player_info")
	local ran = {}

	local function runHook(ply, uid)
		hook.Run("PlayerJoined", ply)
		ran[uid] = true
	end

	hook.Add("player_info", "GarryPls", function(dat)
		local uid = dat.userid

		if not ran[uid] then

			hook.Add("Think", "ValidatePlayer" .. uid, function() --yikes
				if ran[uid] then hook.Remove("Think", "ValidatePlayer" .. uid) return end

				local ply = Player(uid)
									-- YIKES 			-- DOUBLE YIKES
				if ply:IsValid() and ply:Team() ~= 0 and ply:Nick() ~= "unconnected" then
					runHook(ply, uid)
				end
			end)

		end

	end)
end
