BaseWars.PlayerData = BaseWars.PlayerData or {}
local pd = BaseWars.PlayerData

local PLAYER = FindMetaTable("Player")

local db

local qries = {
	-- puid
	get_data_query = "SELECT * FROM bw_plyData WHERE puid = %s",

	-- comma-separated columns; comma-separated values
	upsert_data_query = "REPLACE INTO bw_plyData(%s, puid) VALUES (%s, %s)",

	-- column name ; column value ; puid
	set_column_query = "UPDATE bw_plyData SET `%s` = %s WHERE puid = %s",

	-- column name ; column value change ; puid
	add_column_query = "UPDATE bw_plyData SET `%s` = `%s` + %s WHERE puid = %s",
	sub_column_query = "UPDATE bw_plyData SET `%s` = `%s` - %s WHERE puid = %s",
}

function BaseWars.PlayerData.Load(ply)
	local sid64 = ply:SteamID64()
	local q = MySQLQuery(
		db:query( qries.get_data_query:format(sid64) ), true
	):Then(function(_, _, dat)
		local write = {}
		local pin = GetPlayerInfoGuarantee(sid64)
		pin._bwSyncedData = pin._bwSyncedData or {}

		for k,v in pairs(dat) do
			pin._bwSyncedData[k] = v
		end

		hook.NHRun("BW_LoadPlayerData", ply, dat[1] or {}, write)
		hook.NHRun("BW_LoadedPlayerData", ply)
	end, mysqloo.CatchError)
end

LoadData = BaseWars.PlayerData.Load

hook.Add("PlayerAuthed", "BW_SQLDataFetch", BaseWars.PlayerData.Load)

-- hook.NHAdd("PlayerDisconnected", "BW_SQLDataSave", SaveData)
hook.NHAdd("PlayerInitialSpawn", "BW_SQLDataFetch_Bots", function(ply)
	-- special hook for bots since they don't auth
	if not ply:IsBot() then return end
	BaseWars.PlayerData.Load(ply)
end)

local toSet = {}

local function queueChange(pin)
	pin = GetPlayerInfoGuarantee(pin)
	toSet[pin] = true
end

pd.QueueChange = queueChange

local autoSync = {"money", "xp", "level", "playtime"}
autoSync = table.KeysToValues(autoSync)

function pd.SyncBWIntoSQL()
	local qTpl = qries.set_column_query

	for pi,v in pairs(toSet) do
		local bwd = pi._bwData
		local sid = pi:GetSteamID64()

		for name, val in pairs(bwd) do
			if not autoSync[name] then
				local ok, doSync = hook.NHRun("BW_DataSync" .. name, pi, val)
				if ok and not doSync then continue end
			end

			if pi._bwSyncedData[name] == val then continue end

			pi._bwSyncedData[name] = val
			name = db:escape(name)
			val = isnumber(val) and val or db:escape(val)

			-- mfw
			--[[local second_arg = rep and name or val
			local third_arg = rep and val or sid
			local fourth_arg = rep and sid or nil

			local qry = qTpl:format(name, second_arg, third_arg, fourth_arg, fucking_end_me)
			]]

			local qry = qTpl:format(name, val, sid)

			MySQLQuery(db:query(qry), true)
				:Catch(mysqloo.CatchError)
		end

		toSet[pi] = nil
		hook.NHRun("BW_DataSync", pi)
	end

end

local function doQry(qTpl, rep, sid, name, val)
	assert(string.IsMaybeSteamID64(sid))

	if not autoSync[name] then
		local ok, doSync = hook.NHRun("BW_DataSync" .. name, nil, val)
		if ok and not doSync then return end
	end

	name = db:escape(name)
	val = isnumber(val) and val or db:escape(val)

	local second_arg = rep and name or val
	local third_arg = rep and val or sid
	local fourth_arg = rep and sid or nil

	local qry = qTpl:format(name, second_arg, third_arg, fourth_arg, fucking_end_me)

	MySQLQuery(db:query(qry), true)
		:Catch(mysqloo.CatchError)
end

function BaseWars.PlayerData.SetOffline(sid, name, val)
	doQry(qries.set_column_query, false, sid, name, val)
end

function BaseWars.PlayerData.AddOffline(sid, name, val)
	doQry(qries.add_column_query, true, sid, name, val)
end

function BaseWars.PlayerData.SubOffline(sid, name, val)
	doQry(qries.sub_column_query, true, sid, name, val)
end

timer.Create("BW_SQLSync", 0.5, 0, function()
	pd.SyncBWIntoSQL()
end)

local function setter()
	-- rep = the column name needs to be repeated
	return function(self, name, val)
		local pi = GetPlayerInfo(self)

		pi._bwData = pi._bwData or {}
		pi._bwSyncedData = pi._bwSyncedData or {}
		if pi._bwData[name] == val then return end

		pi._bwData[name] = val

		queueChange(pi)
	end
end

PLAYER.SetBWData = setter(qries.set_column_query)

function PLAYER:AddBWData(name, val)
	return self:SetBWData(name, self:GetBWData(name) + val)
end

function PLAYER:SubBWData(name, val)
	return self:SetBWData(name, self:GetBWData(name) - val)
end

PLAYER.GetBWData = function(self, key)
	local pi = GetPlayerInfo(self)
	return pi._bwData[key]
end

function PLAYER:InitBWData(name, val)
	local pi = GetPlayerInfo(self)
	local sid = pi:GetSteamID64()
	local qry = qries.upsert_data_query:format(name, val, sid)

	MySQLQuery(db:query(qry), true)
		:Catch(mysqloo.CatchError)
end

local PInfo = LibItUp.PlayerInfo
PInfo.SetBWData = PLAYER.SetBWData
PInfo.InitBWData = PLAYER.InitBWData
PInfo.AddBWData = PLAYER.AddBWData
PInfo.SubBWData = PLAYER.SubBWData

local function onDB(masterdb)

	local q = masterdb:query([[
	CREATE TABLE IF NOT EXISTS `bw_plyData` (
	  `puid` BIGINT UNSIGNED NOT NULL,
	  `money` BIGINT NOT NULL DEFAULT ]] .. BaseWars.Config.StartMoney .. [[,
	  `lvl` INT UNSIGNED NOT NULL DEFAULT 1,
	  `xp` BIGINT UNSIGNED NOT NULL DEFAULT 0,
	  PRIMARY KEY (`puid`),
	  UNIQUE INDEX `puid_UNIQUE` (`puid` ASC));

	ALTER TABLE `bw_plyData`
	CHANGE COLUMN `money` `money` BIGINT UNSIGNED NOT NULL DEFAULT ]] .. BaseWars.Config.StartMoney .. [[,
	CHANGE COLUMN `lvl` `lvl` INT UNSIGNED NOT NULL DEFAULT '1';
	]])

	MySQLQuery(q, true)
		:Catch(mysqloo.CatchError)

	db = masterdb
end

if not mysqloo.GlobalDatabase then
	hook.Add("OnMySQLReady", "BW_Money", onDB)
else
	onDB(mysqloo.GetDatabase())
end