--

local PLAYER = FindMetaTable("Player")
local db

function PLAYER:FetchResearch()
	local sid = self:SteamID64()
	local pin = self:GetPInfo()

	MySQLQuery(
	db:query( ("SELECT `perks` FROM `research` WHERE `puid` = %s"):format(sid) ),
	true)
		:Catch(mysqloo.CatchError)
		:Then(function(_, qry, dat)
			dat = dat[1] or {}

			local perks = util.JSONToTable(dat.perks or "[]")

			if not perks then
				errorf("Something went wrong: failed to decode player's perks JSON? %s", dat.perks)
				return
			end

			pin:SetResearchedPerks(perks)

			if #dat == 0 then
				local q = db:query( ("INSERT IGNORE INTO `research`(puid) VALUES(%s)"):format(sid) )
				MySQLQuery(q, true)
					:Catch(mysqloo.CatchError)
			end

			hook.Run("Research_PerksFetched", self, perks)
		end, mysqloo.CatchError)
end

hook.Add("PlayerAuthed", "Research", function(ply)
	ply:FetchResearch()
end)

function Research.SaveResearch(what)
	local pin = GetPlayerInfoGuarantee(what)
	local json = util.TableToJSON(pin:GetResearchedPerks())

	local q = "REPLACE INTO `research` (puid, perks) VALUES(%s, %s)"
	q = q:format(pin:SteamID64(), mysql.quote(db, json))

	MySQLQuery(db:query(q), true)
		:Catch(mysqloo.CatchError)
end

hook.Add("PlayerResearched", "Store", function(pin, perk, lv)
	Research.SaveResearch(pin)
end)

mysql.OnConnect(function()
	local q = mysqloo.GetDB():query([[
		CREATE TABLE IF NOT EXISTS `research` (
		`puid` BIGINT(19) NOT NULL,
		`perks` JSON NULL DEFAULT NULL,
		PRIMARY KEY (`puid`)
	)
	]])

	MySQLQuery(q, true)
		:Catch(mysqloo.CatchError)
		:Then(function() Research.Log("Created table.") end)

	db = mysqloo.GetDB()
end)