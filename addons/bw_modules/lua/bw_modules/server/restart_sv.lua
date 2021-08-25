BaseWars.RestartWarnings = {
	60, 30, 15, 5, 2, 0
}

-- ascending order
table.sort(BaseWars.RestartWarnings, function(a, b) return a > b end)

BaseWars.RestartTime = 12 * 60 * 60



local ct = CurTime()

-- Do not sell your things; you will be automatically refunded 100% of the value.

hook.Add("Think", "CountDownWarn", function()
	ct = CurTime()
	local left_seconds = BaseWars.RestartTime - ct
	local left_minutes = math.floor(left_seconds / 60)

	local next_warn = BaseWars.RestartWarnings[1]
	if not next_warn then return end

	if left_minutes < next_warn then
		local append = "<scale=0.8, 0.8>don't sell your stuff; you will be automatically refunded 100% of the value."
		local now = "<color=255,60,60><translate=[-5 + rand()*10],[-5 + rand()*10]>IMMINENT!"
		local soon = "in <color=235,70,70><translate=0,[sin(t()*6)*5]>%d minutes!"

		local when = next_warn == 0 and now or
			next_warn < 10 and soon:format(next_warn) or
			("in %d minutes!"):format(next_warn)

		ChatAddText(Color(255, 70, 255),
			"[SERVER] ", color_white,
			"Automatic server restart " .. when)

		if next_warn <= 5 then
			ChatAddText(Color(150, 150, 150), append)
		end

		table.remove(BaseWars.RestartWarnings, 1)

		if not BaseWars.RestartWarnings[1] then
			aowl.CountDown(30, "Restart", function() RunConsoleCommand("_restart") end)
		end
	end

end)