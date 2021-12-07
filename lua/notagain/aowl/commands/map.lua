--[[local function doSwitch(map, time)
	time = tonumber(time) or 10

	aowl.CountDown(time, "CHANGING MAP TO " .. map, function()
		game.ConsoleCommand("changelevel " .. map .. "\n")
	end)
end

aowl.AddCommand("map", function(ply, line, map, time)
	if not map then return false, "map required" end

	if map and file.Exists("maps/"..map..".bsp", "GAME") then
		doSwitch(map, time)
		return
	else
		local maps = file.Find("maps/*.bsp", "GAME")
		local match

		for k,v in ipairs(maps) do
			if v:match(map) then
				if match then
					return false, ("multiple matching maps found (`%s` and `%s`)"):format(match, map)
				end

				match = v
			end
		end

		if match then doSwitch(match, time) return end

		return false, "map not found"
	end

end, "developers")]]

aowl.AddCommand("setnextmap", function(ply, line, map)
	if map and file.Exists("maps/"..map..".bsp", "GAME") then
		game.SetNextMap(map)
		ply:ChatPrint("The next map is now "..game.NextMap())
	else
		return false, "map not found"
	end
end, "developers")

aowl.AddCommand("maprand", function(player, line, map, time)
	time = tonumber(time) or 10
	local maps = file.Find("maps/*.bsp", "GAME")
	local candidates = {}

	for k, v in ipairs(maps) do
		if (not map or map=='') or v:find(map) then
			table.insert(candidates, v:match("^(.*)%.bsp$"):lower())
		end
	end

	if #candidates == 0 then
		return false, "map not found"
	end

	local map = table.Random(candidates)

	aowl.CountDown(tonumber(time), "CHANGING MAP TO " .. map, function()
		game.ConsoleCommand("changelevel " .. map .. "\n")
	end)
end, "developers")

aowl.AddCommand("maps", function(ply, line)
	local files = file.Find("maps/" .. (line or ""):gsub("[^%w_]", "") .. "*.bsp", "GAME")
	for _, fn in pairs( files ) do
		ply:ChatPrint(fn)
	end

	local msg="Total maps found: "..#files

	ply:ChatPrint(("="):rep(msg:len()))
	ply:ChatPrint(msg)
end, "developers")

aowl.AddCommand("resetall", function(player, line)
	aowl.CountDown(line, "RESETING SERVER", function()
		game.CleanUpMap()
		for k, v in ipairs(_G.player.GetAll()) do v:Spawn() end
	end)
end, "developers")

aowl.AddCommand({"clearserver", "cleanupserver", "serverclear", "cleanserver", "resetmap"}, function(player, line,time)
	if(tonumber(time) or not time) then
		aowl.CountDown(tonumber(time) or 5, "CLEANING UP SERVER", function()
			game.CleanUpMap()
		end)
	end
end,"developers")

--[[
aowl.AddCommand("restart", function(player, line, seconds, reason)
	local time = math.max(tonumber(seconds) or 20, 1)

	aowl.CountDown(time, "RESTARTING SERVER" .. (reason and reason ~= "" and Format(" (%s)", reason) or ""), function()
		game.ConsoleCommand("changelevel " .. game.GetMap() .. "\n")
	end)
end, "developers")

aowl.AddCommand("reboot", function(player, line, target)
	local time = math.max(tonumber(line) or 20, 1)

	aowl.CountDown(time, "SERVER IS REBOOTING", function()
		BroadcastLua("LocalPlayer():ConCommand(\"disconnect; snd_restart; retry\")")

		timer.Simple(0.5, function()
			game.ConsoleCommand("shutdown\n")
			game.ConsoleCommand("_restart\n")
		end)
	end)
end, "developers")
]]

aowl.AddCommand("uptime",function()
	PrintMessage(3, "Server uptime: "..string.NiceTime(SysTime()))
end)
