local function doSwitch(map, time)
	time = tonumber(time) or 10
	map = map:gsub("%.bsp$", "")
	aowl.CountDown(time, "CHANGING MAP TO " .. map, function()
		game.ConsoleCommand("changelevel " .. map .. "\n")
	end)
end

local found

CUM.AddCommand({"map", "changemap", "setmap"}, function(ply, map, time)
	found = nil

	if file.Exists("maps/" .. map .. ".bsp", "GAME") then
		found = map
		doSwitch(map, time)
		return
	else
		local maps = file.Find("maps/*.bsp", "GAME")
		local match

		for k,v in ipairs(maps) do
			if v:match(map) then
				if match then
					return false, CUM.SendError(nil, ("multiple matching maps found (`%s` and `%s`)"):format(match, map))
				end

				match = v
			end
		end

		if match then
			found = match:gsub("%.bsp$", "")
			doSwitch(match, time)
			return
		end

		return false, CUM.SendError(nil, "map not found")
	end

end)
	:AddStringArg(false, "Map to switch to.")
	:AddNumberArg(true, 10, "Countdown timer.")

	:SetSilent(true)

	:SetReportFunc(function(self, rply, caller, map, time)
		return "{1} is switching map to {2} in {3} seconds.", {[2] = "<col=240,210,100>" .. found, [3] = "<col=100,220,100>" .. tostring(time)}
	end)

CUM.AddCommand({"reboot", "restart"}, function(ply, time)
	time = math.max(tonumber(time) or 20, 1)

	aowl.CountDown(time, "RESTARTING SERVER" .. (reason and reason ~= "" and Format(" (%s)", reason) or ""), function()
		game.ConsoleCommand("changelevel " .. game.GetMap() .. "\n")
	end)
end)
	:AddNumberArg(true, 20, "Countdown timer.")

	:SetSilent(true)

	:SetReportFunc(function(self, rply, caller, time)
		return "{1} is restarting server in {2} seconds!", {[3] = "<col=100,220,100>" .. tostring(time)}
	end)

