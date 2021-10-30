local PLAYER = FindMetaTable("Player")

sql.Debugging = false

function sql.isPlayer(ply)
	local ch1 = (ply and isentity(ply) and IsValid(ply))
	local ch2 = false
	local sid = nil
	if ch1 then ch2=ply:IsPlayer() else return false end
	if ch2 then sid = ply:SteamID64() end

   return (ch1 and ch2 and sid) or false

end

function sql.DumpInfo(tblname)
	local t = sql.Check("SELECT * FROM " .. tblname, true)
	if istable(t) then
		PrintTable(t)
	else
		print("No info!")
	end
end

function sql.Check(query, expectres)
	local res = sql.Query(query)

	if res == nil and expectres then
		if sql.Debugging then
			printf("SQL Error(?): expected a result, got nil instead.\nQuery: %s", query)
		end
		return false, false
	end

	if res == false then
		print("SQL Error: \nQuery: %s \n Error: %s", query, sql.LastError())
		return false, true
	end

	if expectres then return res end
end

function sql.AssignUID(ply, alsoget)

	local sid = (isstring(ply) and ply) or sql.isPlayer(ply)
	if not sid then return end

	local r, err = sql.Check("SELECT PlayerUID FROM player_IDs WHERE SteamID64=='".. sid .."'", true)
	if not r and err then return end
	if not r and not err then
		sql.Check("INSERT OR IGNORE INTO player_IDs(SteamID64) VALUES('".. sid .."')")
	end
	if alsoget then return sql.GetPUID(sid) end
end
PLAYER.AssignUID = sql.AssignUID

sql.UIDs = sql.UIDs or {}
sql.BackUIDs = sql.BackUIDs or {}

function PLAYER:GetUID(dbl)

	local sid = sql.isPlayer(self)
	if not sid then return end
	local ret

	if not sql.UIDs[sid] then
		local r, err = sql.Check("SELECT PlayerUID FROM player_IDs WHERE SteamID64=='".. sid .."'", true)
		if not r and not err and not dbl then return self:AssignUID(true) end
		if not r then return end
		ret = r[1].PlayerUID
		sql.UIDs[sid] = ret
		sql.BackUIDs[ret] = sid
	else
		ret = sql.UIDs[sid]
	end

	return ret

end

PLAYER.GetPUID = PLAYER.GetUID

function sql.GetByPUID(puid, ply)

	if not sql.BackUIDs[puid] then
		local r, err = sql.Check("SELECT SteamID64 FROM player_IDs WHERE PlayerUID=='".. puid .."'", true)
		if not r then return false end

		if r then
			if ply then
				return player.GetBySteamID64(r[1].SteamID64), r[1].SteamID64
			else
				return r[1].SteamID64
			end
		end
	else

		if ply then
			return player.GetBySteamID64(sql.BackUIDs[puid]), sql.BackUIDs[puid]
		else
			return sql.BackUIDs[puid]
		end
	end

end

function sql.GetPUID(ply)
	if isstring(ply) then
		local r, err = sql.Check("SELECT PlayerUID FROM player_IDs WHERE SteamID64=='".. ply .."'", true)

		if not r and not err then
			local uid = sql.AssignUID(ply, true)

			return uid
		end

		if r and not err then return r[1].PlayerUID end

		return false
	end
	if not ply or not IsValid(ply) or not ply:IsPlayer() then return false end
	return ply:GetUID()
end
