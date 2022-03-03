--
BW.LeaderBoard = BW.LeaderBoard or {}
BW.Leaderboard = BW.LeaderBoard
BW.Leaderboard.Data = {}
BW.Leaderboard.SteamIDs = {}

local db
local prepSel

mysqloo.OnConnect(function()
	db = mysqloo.GetDB()
	prepSel = db:prepare("SELECT CAST(puid AS CHAR) AS sid, money FROM bw_plyData" ..
		" ORDER BY `money` DESC LIMIT 11")
end)

function BW.Leaderboard.Fetch()
	if not db then return end

	MySQLQuery(prepSel, true):Then(function(self, qry, dat)
		BW.Leaderboard.Data = dat
		for k,v in ipairs(dat) do
			BW.Leaderboard.SteamIDs[v.sid] = k
		end

		hook.Run("BW_LeaderboardUpdated", dat)
	end)
end

function BW.Leaderboard.OnCreateNW(nw)
	nw:On("CustomWriteChanges", "Encode", function(self, changes)
		net.WriteUInt(table.Count(changes), 8)
		for k, v in pairs(changes) do
			net.WriteUInt(k, 8)
			net.WriteDouble(v.money)
			net.WriteSteamID64(v.sid)
		end

		return true
	end)
end

timer.Create("LeaderboardDBUpdate", 60, 0, BW.Leaderboard.Fetch)
BW.Leaderboard.Fetch()


hook.Add("BW_LeaderboardUpdated", "Network", function(dat)
	for i=1, 10 do
		local v = dat[i]
		BW.Leaderboard.NW:SetTable(i, {
			sid = v.sid,
			money = v.money,
		})
	end
end)

hook.Add("BW_DataSyncedmoney", "LeaderboardUpdate", function(pin, money)
	if not BW.Leaderboard.Data or #BW.Leaderboard.Data < 10 then return end

	local sid64 = pin:SteamID64()

	local ind = BW.Leaderboard.SteamIDs[sid64]

	if ind then
		BW.Leaderboard.Data[ind].money = money
	else
		-- player wasnt in the leaderboard before; add their entry temporarily
		table.insert(BW.Leaderboard.Data, {sid = sid64, money = money})
	end

	-- sort by money
	table.sort(BW.Leaderboard.Data, function(a, b) return a.money > b.money end)

	if not ind then
		-- if we added the player temporarily, remove the last temporary entry
		-- if the player is now on the LB, they'll remain in it and push the last place out
		-- if they still arent, they'll just get removed
		table.remove(BW.Leaderboard.Data)
	end

	BW.Leaderboard.SteamIDs[sid64] = nil

	for k=1, 10 do
		local v = BW.Leaderboard.Data[k]
		local prev = BW.Leaderboard.NW:Get(k)
		BW.Leaderboard.SteamIDs[v.sid] = k

		if prev.sid == v.sid and prev.money == v.money then continue end

		BW.Leaderboard.NW:SetTable(k, {
			sid = v.sid,
			money = v.money
		})
	end
end)