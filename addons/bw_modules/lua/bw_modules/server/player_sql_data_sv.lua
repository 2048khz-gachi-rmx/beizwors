local PLAYER = debug.getregistry().Player

local db

local qries = {
	-- puid
	get_data_query = "SELECT * FROM bw_plyData WHERE puid = %s",

	-- comma-separated columns; comma-separated values
	upsert_data_query = "REPLACE INTO bw_plyData(%s) VALUES (%s)",

	-- column name ; column value ; puid
	set_column_query = "UPDATE bw_plyData SET `%s` = %s WHERE puid = %s",

	-- column name ; column value change ; puid
	add_column_query = "UPDATE bw_plyData SET `%s` = `%s` + %s WHERE puid = %s",
	sub_column_query = "UPDATE bw_plyData SET `%s` = `%s` - %s WHERE puid = %s",
}

function LoadData(ply)
	local sid64 = ply:SteamID64()
	local q = db:query( qries.get_data_query:format(sid64) )

	q.onSuccess = function(_, dat)
		local write = {}
		PrintTable(dat)
		hook.Run("BW_LoadPlayerData", ply, dat[1], write)

		-- todo: this is probably unnecessary

		--[[if not table.IsEmpty(write) then

			local columns = "puid, "
			local values = sid64 .. ", "
			for k,v in pairs(write) do
				columns = columns .. db:escape(k) .. ", "
				values = values .. db:escape(tostring(v)) .. ", "
			end
			columns = columns:sub(1, -3)
			values = values:sub(1, -3)

			local ups = qries.upsert_data_query:format(columns, values)
			local q = db:query(ups)
			q.onError = mysqloo.QueryError

			q:start()
		end]]
	end
	q.onError = mysqloo.QueryError

	q:start()
end

hook.Add("PlayerAuthed", "BW_SQLDataFetch", LoadData)
hook.Add("PlayerDisconnected", "BW_SQLDataSave", SaveData)

local function setter(q, rep)
	return function(self, name, val)
		name = db:escape(name)
		val = isnumber(val) and val or db:escape(val)

		-- mfw
		local second_arg = rep and name or val
		local third_arg = rep and val or self:SteamID64()
		local fourth_arg = rep and self:SteamID64() or nil

		local qry = q:format(name, second_arg, third_arg, fourth_arg, fucking_end_me)

		local q = db:query(qry)
		q.onError = mysqloo.QueryError
		q:start()
	end
end


PLAYER.SetBWData = setter(qries.set_column_query)
PLAYER.AddBWData = setter(qries.add_column_query, true)
PLAYER.SubBWData = setter(qries.sub_column_query, true)

local function onDB(masterdb)

	local q = masterdb:query([[
	CREATE TABLE IF NOT EXISTS `master`.`bw_plyData` (
	  `puid` BIGINT UNSIGNED NOT NULL,
	  `money` BIGINT NOT NULL DEFAULT ]] .. BaseWars.Config.StartMoney .. [[,
	  `lvl` INT UNSIGNED NOT NULL DEFAULT 1,
	  `xp` BIGINT UNSIGNED NOT NULL DEFAULT 0,
	  PRIMARY KEY (`puid`),
	  UNIQUE INDEX `puid_UNIQUE` (`puid` ASC) VISIBLE);

	ALTER TABLE `master`.`bw_plydata` 
	CHANGE COLUMN `money` `money` BIGINT UNSIGNED NOT NULL DEFAULT ]] .. BaseWars.Config.StartMoney .. [[,
	CHANGE COLUMN `lvl` `lvl` INT UNSIGNED NOT NULL DEFAULT '1' ;
	]])

	q.onError = mysqloo.QueryError
	q:start()

	db = masterdb
end

if not mysqloo.GlobalDatabase then
	hook.Add("OnMySQLReady", "BW_Money", onDB)
else
	onDB(mysqloo.GetDatabase())
end