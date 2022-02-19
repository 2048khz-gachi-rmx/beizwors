util.AddNetworkString("NewPlayerBroadcast")

BaseWars.Announcer = BaseWars.Announcer or {}
local an = BaseWars.Announcer

an.IPs = an.IPs or {}
an.JoinTimes = an.JoinTimes or {}
an.LeaveTimes = an.LeaveTimes or {}
an.SpawnTimes = an.SpawnTimes or {}
an.UIDToSID = an.UIDToSID or {}

local IPs = an.IPs
local joinTimes = an.JoinTimes
local leaveTimes = an.LeaveTimes
local spawnTimes = an.SpawnTimes
local u2s = an.UIDToSID

local announceCD = 10

local function getJoinTime(sid)
	if joinTimes[sid] then return SysTime() - joinTimes[sid], true end
	return 0, false
end

local function getLeaveTime(sid)
	if leaveTimes[sid] then return SysTime() - leaveTimes[sid], true end
	return 0, false
end

local function getPlayTime(sid)
	if spawnTimes[sid] then return SysTime() - spawnTimes[sid], true end
	return 0, false
end

function an.AnnounceJoin(name, sid64, ip, sub)
	local sid = util.SteamIDFrom64(sid64)

	net.Start("NewPlayerBroadcast")
		net.WriteUInt(0, 4)
		net.WriteString(name)
		net.WriteString(sid)
	net.Broadcast()

	local txt = name .. (" has started connecting to the server. (%s @ %s)")
		:format(sid64, ip)

	MsgC(
		Colors.Yellowish, "[Connect] ",
		Color(230, 230, 230), txt,
		"\n"
	)

	joinTimes[sid64] = joinTimes[sid64] or SysTime() - (sub or 0)
	IPs[sid64] = ip

	hook.Run("AnnounceConnect", name, sid64, ip)
end

function an.OnJoin(name, sid64, ip)
	local time, was = getLeaveTime(sid64)
	local cd = announceCD - time

	if was and cd > 0 then
		timer.Create("announcejoin_" .. sid64, cd, 1, function()
			an.AnnounceJoin(name, sid64, ip, cd)
		end)
	else
		an.AnnounceJoin(name, sid64, ip)
	end
end

function an.AnnounceLeave(name, sid64, reason)
	local passed = getJoinTime(sid64)
	joinTimes[sid64] = nil
	leaveTimes[sid64] = SysTime()

	local dat = {
		Colors.Red, "[Disconnect] ",
		Color(200, 200, 200), "TX1",
		Color(100, 220, 100), "NAME",
		Color(160, 160, 160), "DETAILS",
		Color(200, 200, 200), "TX2",
		Color(160, 160, 160), "WHY",
		"\n"
	}

	local remap = {
		TX1 = "Player ",
		NAME = name .. " ",
		DETAILS = ("(%s @ %s) "):format(sid64, IPs[sid64] or "??? untracked IP?"),
		TX2 = ("has given up on connecting after %ds. "):format(passed),
		WHY = ("(%s)"):format( reason:gsub("^%(", ""):gsub("%)$", "") )
	}


	table.RemapValues(dat, remap, true)

	MsgC(unpack(dat))

	net.Start("NewPlayerBroadcast")
		net.WriteUInt(2, 4)
		net.WriteString(name)
		net.WriteString(sid64)
		net.WriteUInt(math.floor(passed), 16)
	net.Broadcast()

	hook.Run("AnnounceLeave", name, sid64, reason, true)
	hook.Run("AnnounceAbortJoin", name, sid64, reason, true)
end

function an.AnnounceLeaveGame(name, sid64, reason)
	local passed = getPlayTime(sid64)
	spawnTimes[sid64] = nil

	local dat = {
		Colors.Red, "[Disconnect] ",
		Color(200, 200, 200), "TX1",
		Color(100, 220, 100), "NAME",
		Color(160, 160, 160), "DETAILS",
		Color(200, 200, 200), "TX2",
		Color(160, 160, 160), "WHY",
		"\n"
	}

	local remap = {
		TX1 = "Player ",
		NAME = name .. " ",
		DETAILS = ("(%s @ %s) "):format(sid64, IPs[sid64] or "??? untracked IP?"),
		TX2 = "has left the server. ",
		WHY = ("(%s)"):format( reason:gsub("^%(", ""):gsub("%)$", "") )
	}

	table.RemapValues(dat, remap, true)

	MsgC(unpack(dat))

	net.Start("NewPlayerBroadcast")
		net.WriteUInt(3, 4)
		net.WriteString(name)
		net.WriteString(sid64)
		net.WriteUInt(math.floor(passed), 16)
	net.Broadcast()

	hook.Run("AnnounceLeave", name, sid64, reason, false)
	hook.Run("AnnounceLeaveGame", name, sid64, reason)
end

function an.OnLeave(name, sid64, reason)
	local pt, played = getPlayTime(sid64)
	if played then
		-- leaving after actually spawning and playing
		an.AnnounceLeaveGame(name, sid64, reason)
		return
	end

	-- unspawned leave; ratelimit
	local time, was = getLeaveTime(sid64)
	local cd = announceCD - time

	print("onLeave:", time, was, sid64)

	if was and cd > 0 then
		-- on cooldown from announcing; bail
		return
	else
		an.AnnounceLeave(name, sid64, reason)
	end
end

hook.Add("CheckPassword", "BroadcastJoin", function( sid64, ip, pw1, pw2, name )
	local sid = util.SteamIDFrom64( sid64 )
	if pw1 and pw2 and #pw1 > 0 and pw1 ~= pw2 then
		local id_tx = "%s (%s) failed password."
		local dat = {
			Colors.Red, "[Disconnect] ",
			Color(200, 200, 200), id_tx:format(name, sid, pw1, pw2), " (",
			Color(70, 210, 70), pw1,
			Color(200, 200, 200), " vs. ",
			Color(160, 70, 70), pw2,
			Color(200, 200, 200), ").\n"}

		ChatAddText(unpack(dat))
		MsgC(unpack(dat))
		return
	end

	an.OnJoin(name, sid64, ip)
end)



gameevent.Listen( "player_disconnect" )
hook.NHAdd("player_disconnect", "TrackLeave", function( data )
	local name = data.name
	local reason = data.reason and data.reason:gsub("[\r\n]*$", "")
	local sid64 = u2s[data.userid] or util.SteamIDTo64(data.networkid)
	
	an.OnLeave(name, sid64, reason)
end)

hook.Add("PlayerFullyLoaded", "BroadcastJoin", function(ply)
	u2s[ply:UserID()] = ply:SteamID64() -- botz

	local passed = getJoinTime(ply:SteamID64())
	joinTimes[ply:SteamID64()] = nil
	spawnTimes[ply:SteamID64()] = SysTime()

	local dat = {
		Colors.Sky, "[Connect] ",
		Color(200, 200, 200), "Player ",
		Color(100, 220, 100), ply:Nick(), " ",
		Color(160, 160, 160), ("(%s @ %s) "):format(ply:SteamID64(), ply:IPAddress()),
		Color(200, 200, 200), "finished connecting after ",
		Color(220, 200, 35), ("%d"):format(passed),
		Color(200, 200, 200), "s.",
		"\n"
	}

	net.Start("NewPlayerBroadcast")
		net.WriteUInt(1, 4)
		net.WriteString(ply:Nick())
		net.WriteString(ply:SteamID())
		net.WriteUInt(math.floor(passed), 16)
	net.Broadcast()

	MsgC(unpack(dat))

	hook.Run("AnnounceJoin", ply:Nick(), ply:SteamID64(), ply:IPAddress(), ply)
end)