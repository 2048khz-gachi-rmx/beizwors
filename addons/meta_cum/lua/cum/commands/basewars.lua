--123

CUM.CurCat = "BaseWars"

local lastReq = 0

CUM.AddCommand({"uptime", "time", "ut"}, function(ply)
	if not IsValid(ply) then return end -- console doesn't influence cooldown

	if CurTime() - lastReq < 15 then return false end
	lastReq = CurTime()
end)
	:SetPerms("user")
	:SetSilent(true)

	:SetReportFunc(function(self, rply, caller, time)
		local nextRe = BaseWars.GetNextRestart() / 60
		nextRe = string.FormattedTime(nextRe, "%02dh. %02dm.")

		local cur = CurTime() / 60
		cur = string.FormattedTime(cur, "%02dh. %02dm.")

		return
			"{1} requested server uptime.\n" ..
			"	Server uptime: {2}\n" ..
			"	Next restart: {3}",

			{
				[2] = "<col=60,170,255>" .. cur,
				[3] = "<col=240,210,100>" .. nextRe
			}
	end)