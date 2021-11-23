NX.SQL = NX.SQL or {}
local nsql = NX.SQL

local db = mysqloo.GetDB()

nsql.PreparedQueries = nsql.PreparedQueries or {
	select = nil,
	insert = nil,
}

local pq = nsql.PreparedQueries
local tblName = "nx_detections"

mysqloo.OnConnect(coroutine.wrap(function()
	local db = mysqloo:GetDatabase()

	local arg = LibItUp.SQLArgList()
		arg:AddArg("dataid", "INT NOT NULL AUTO_INCREMENT PRIMARY KEY")
		arg:AddArg("uid", "BIGINT UNSIGNED NOT NULL")
		arg:AddArg("detection", "SMALLINT NOT NULL")
		arg:AddArg("date", "TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP")
		arg:AddArg("extra_data", "MEDIUMTEXT")
		
	mysqloo.CreateTable(db, tblName, arg)

	pq.select = db:prepare("SELECT detection, unix_timestamp(date) AS dt, extra_data FROM nx_detections WHERE uid = ?")
	pq.insert = db:prepare("INSERT INTO `" .. tblName .. "`(uid, detection, extra_data) VALUES(?, ?, ?)")
end))


function NX.GetInfractions(what)
	if not nsql.PreparedQueries.select then
		errorNHf("Not ready for SQL!")
		return
	end

	local sid = string.IsMaybeSteamID64(what) and what or GetPlayerInfoGuarantee(what):SteamID64()
	local sel = nsql.PreparedQueries.select

	local pr = Promise()

	local em = MySQLEmitter(sel)
	sel:setString(1, sid)
	sel:start()

	em:Then(function(_, _, dat)
		local ret = {}
		for k, v in ipairs(dat) do
			ret[k] = {
				-- todo: int to detection
				Detection = NX.GetDetection(v.detection),
				Date = v.dt
			}
		end

		pr:Resolve(ret)
	end)

	return pr
end

function NX.AddInfraction(who, id, moreData)
	if not nsql.PreparedQueries.insert then
		errorNHf("Not ready for SQL!")
		return
	end

	local sid = GetPlayerInfoGuarantee(who):SteamID64()
	local qry = nsql.PreparedQueries.insert

	local dt = NX.GetDetection(id)
	if not dt then errorNHf("No detection: %s", id) return end

	id = dt:GetID()

	local pr = Promise()

	local em = MySQLEmitter(qry)
	qry:setString(1, sid)
	qry:setNumber(2, id)

	if istable(moreData) then
		qry:setString(3, util.TableToJSON(moreData))
	elseif moreData then
		qry:setString(3, tostring(moreData))
	else
		qry:setNull(3)
	end

	qry:start()

	em:Then(pr:Resolver(), pr:Rejector())

	return pr
end