--
BW.LeaderBoard = BW.LeaderBoard or {}
BW.Leaderboard = BW.LeaderBoard
BW.Leaderboard.Data = {}

local db
local prepSel

mysqloo.OnConnect(function()
	db = mysqloo.GetDB()
	prepSel = db:prepare("SELECT CAST(puid AS CHAR) AS puid, money FROM bw_plyData ORDER BY `money` DESC LIMIT 10")
end)

function BW.Leaderboard.Fetch()
	if not db then print("no db mfw") return end

	MySQLQuery(prepSel, true):Then(function(self, qry, dat)
		BW.Leaderboard.Data = dat
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
	for k, v in ipairs(dat) do
		BW.Leaderboard.NW:Set(k, {
			sid = v.puid,
			money = v.money,
		})
	end
end)