local nsql = NX.SQL
local preps = nsql.PreparedQueries

mysqloo.OnConnect(coroutine.wrap(function()
	local db = mysqloo:GetDatabase()

	do
		local joinTbl = "nx_joins"
		local arg = LibItUp.SQLArgList()
			arg:AddArg("trackid", "INT NOT NULL AUTO_INCREMENT PRIMARY KEY")
			arg:AddArg("puid", "BIGINT NOT NULL")
			arg:AddArg("ip", "TINYTEXT NOT NULL")
			arg:AddArg("name", "TINYTEXT NOT NULL")
			arg:AddArg("time", "BIGINT NOT NULL")
			arg:AddArg("leaveTime", "BIGINT NOT NULL")

		mysqloo.CreateTable(db, joinTbl, arg)

		local args = arg:GetArgNames()
		table.remove(args, 1) -- autoincr

		local qry = --[["INSERT INTO `" .. joinTbl .. "`" ..
			"(" .. table.concat(args, ", ") .. ") VALUES(" .. string.rep("?", #args, ", ") .. ")"]]
			"INSERT INTO `nx_joins`(puid, ip, name, time, leaveTime) VALUES(?, ?, ?, ?, ?)"

		preps.trackJoin = db:prepare(qry)
	end

	local banTbl = "nx_bans"
	local arg = LibItUp.SQLArgList()
		arg:AddArg("puid", "BIGINT NOT NULL")
		arg:AddArg("banTime", "BIGINT NOT NULL")
		arg:AddArg("unbanTime", "BIGINT NOT NULL")
		arg:AddArg("admin", "MEDIUMTEXT")
		arg:AddArg("reason", "MEDIUMTEXT")
		arg:AddArg("lastname", "TINYTEXT")

	mysqloo.CreateTable(db, banTbl, arg)

	local args = arg:GetArgNames()

	local qry = "INSERT INTO `" .. banTbl .. "`" ..
		"(" .. table.concat(args, ", ") .. ") VALUES(" .. string.rep("?", #args, ", ") .. ")"

	preps.addBan = db:prepare(qry)
end))

local banStruct = Struct:extend({
	puid = TYPE_STRING,
	banTime = TYPE_NUMBER,
	unbanTime = TYPE_NUMBER,
	reason = TYPE_STRING,
	admin = {TYPE_STRING, "[none]"},
	name = {TYPE_STRING, "[untracked]"},
})

function NX.StartTrack(ply, sid)
	local sid64 = sid and util.SteamIDTo64(sid) or ply:SteamID64()
	local ip = ply:IPAddress()

	local q = nsql.PreparedQueries.trackJoin
	q:setString(1, sid64)
	q:setString(2, ip)
	q:setString(3, ply:Nick())
	q:setNumber(4, os.time())
	q:setNumber(5, os.time())

	MySQLQuery(q, true)
		:Then(function(self, q)
			ply._nxTrackerID = q:lastInsert()
		end)
end

hook.NHAdd("PlayerAuthed", "NX_Track", function(ply, sid)
	NX.StartTrack(ply, sid)
end)

function NX.UpdatePlayerTimes()
	local db = mysqloo.GetDB()
	if not db then return end

	local plys = player.GetAll()
	local ids = {}
	for k,v in ipairs(plys) do
		ids[#ids + 1] = tonumber(v._nxTrackerID)
	end

	if #ids == 0 then return end

	local qFmt = "UPDATE `nx_joins` SET leaveTime = %s WHERE trackid IN (%s)"
	qFmt = qFmt:format(os.time(), table.concat(ids, ", "))

	return MySQLQuery(db:query(qFmt), true)
end
timer.Create("nx_track_playtimes", 15, 0, function()
	NX.UpdatePlayerTimes()
end)

hook.NHAdd("PlayerDisconnected", "NX_TrackTime", function(ply)
	if not ply._nxTrackerID then return end

	local db = mysqloo.GetDB()
	if not db then return end

	local qFmt = "UPDATE `nx_joins` SET leaveTime = %s WHERE trackid = %s"
	qFmt = qFmt:format(os.time(), ply._nxTrackerID)

	MySQLQuery(db:query(qFmt), true)
end)

function NX.OnBanned(dat)
	local ok, key = dat:Require("puid", "banTime", "unbanTime", "reason")
	if not ok then errorf("not full struct: %s missing", key) return end

	local sid64 = dat.puid
	if string.IsSteamID(dat.puid) then
		sid64 = util.SteamIDTo64(dat.puid)
	end

	local q = nsql.PreparedQueries.addBan
	q:setString(1, sid64)
	q:setNumber(2, dat.banTime)
	q:setNumber(3, dat.unbanTime)
	q:setString(5, dat.admin)
	q:setString(4, dat.reason)
	q:setString(6, dat.name or "[untracked]")

	local em = MySQLQuery(q, true)
	em:Catch(print)
	return em
end

hook.Add("ULibPlayerBanned", "NX_Track", function(_, dat)
	local ban = banStruct:new()
		ban.puid = dat.steamID
		ban.banTime = tonumber(dat.time)
		ban.unbanTime = tonumber(dat.unban)
		ban.reason = dat.reason or "[none]"
		ban.admin = dat.admin
		ban.name = dat.name or "[untracked]"

	NX.OnBanned(ban)
end)