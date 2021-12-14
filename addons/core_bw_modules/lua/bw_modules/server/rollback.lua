
BaseWars.Rollback = BaseWars.Rollback or {}
local rb = BaseWars.Rollback

rb.SavedWorth = rb.SavedWorth or {}

local db

local function onDB()

	db = mysqloo.GetDB()

	local q = db:query([[
	CREATE TABLE IF NOT EXISTS `bw_rollback` (
	  `puid` BIGINT UNSIGNED NOT NULL,
	  `money` BIGINT UNSIGNED,
	  `ents` JSON,
	  PRIMARY KEY (`puid`),
	  UNIQUE INDEX `puid_UNIQUE` (`puid` ASC));
	]])

	MySQLQuery(q, true)
		:Catch(mysqloo.CatchError)
end

ChainAccessor(LibItUp.PlayerInfo, "_Worth", "Worth")

mysqloo.OnConnect(onDB)

hook.Add("EntityOwnershipChanged", "RollbackTracker", function(ply, ent, old)
	if old then
		local opi = GetPlayerInfo(old)
		local prevOwWorth = opi:GetWorth() or 0
		opi:SetWorth(math.max(prevOwWorth - BaseWars.Worth.Get(ent), 0))
		opi:SetBWData("Worth", opi:GetWorth())
	end

	local ow = GetPlayerInfo(ply)

	local prevOwWorth = ow:GetWorth() or 0
	ow:SetWorth(prevOwWorth + BaseWars.Worth.Get(ent))
	rb.SavedWorth[ent] = BaseWars.Worth.Get(ent)

	ow:SetBWData("Worth", ow:GetWorth())
end)

hook.Add("EntityWorthChanged", "RollbackTracker", function(ent)
	local pin = ent:BW_GetOwner()
	if not pin then return end

	local prevOwWorth = pin:GetWorth() or 0
	local prevWorth = rb.SavedWorth[ent] or 0

	rb.SavedWorth[ent] = BaseWars.Worth.Get(ent)
	pin:SetWorth(math.max(prevOwWorth - prevWorth + rb.SavedWorth[ent], 0))
	pin:SetBWData("Worth", pin:GetWorth())
end)

hook.Add("EntityActuallyRemoved", "RollbackTracker", function(ent)
	local wth = rb.SavedWorth[ent]
	if not wth or wth == 0 then return end

	local pin = ent:BW_GetOwner()

	if pin then
		pin:SetWorth(math.max( (pin:GetWorth() or 0) - (rb.SavedWorth[ent] or 0) , 0))
		pin:SetBWData("Worth", pin:GetWorth())
	end

	rb.SavedWorth[ent] = nil
end)


hook.Add("BW_DataSyncWorth", "RollbackSync", function(pin, wth)
	wth = math.max(wth, 0)
	local fmt = "REPLACE INTO `bw_rollback`(puid, `money`) VALUES (%s, %s)"
	fmt = fmt:format(pin:SteamID64(), wth)

	local q = db:query(fmt)
	MySQLQuery(q, true)
		:Catch(mysqloo.CatchError)
end)

function rb.LoadPlayer(ply)
	local pin = GetPlayerInfoGuarantee(ply)

	local fmt = "SELECT `money` FROM `bw_rollback` WHERE puid = %s;" ..
		"UPDATE `bw_rollback` SET `money` = %s WHERE puid = %s"

	local wth = pin:GetWorth() or 0
	fmt = fmt:format(pin:SteamID64(), wth, pin:SteamID64())

	local q = db:query(fmt)

	MySQLQuery(q, true)
		:Then(function(_, ar, data)
			if not data[1] then return end

			local mon = data[1].money

			-- getting rollback from SQL when there's worth in memory
			-- should, like, never happen; good to handle it nonetheless i think
			local to_add = mon - wth

			if to_add > 0 then
				pin:AddMoney(to_add)
				pin:SetBWData("Worth", wth) -- this will cause BW_DataSyncWorth to be called
				pin:SetWorth(wth)

				MsgC("refunding player " .. pin:Name() .. " (" .. pin:SteamID() .. ")" ..
					" money for crash: " .. BaseWars.NumberFormat(to_add) .. "(" .. to_add .. ")\n")

				ply:OnFullyLoaded(function()
					local tcol = Color(50, 180, 110)
					local mcol = Color(60, 220, 60)

					ply:ChatAddText(tcol, "You were refunded ",
						mcol, string.Comma(to_add) .. "$ ",
						tcol, "for unsold entities since last time.")
				end)
			end
		end, mysqloo.CatchError)

end

hook.Add("BW_LoadPlayerData", "RollbackLoad", rb.LoadPlayer)