hook.Add("ChatText", "___Nope", function(ind, name, txt, type)
	if type == "joinleave" then return true end
end)

--[[
gameevent.Listen( "player_disconnect" )

hook.Add( "player_disconnect", "Cya", function( data )
	local name = data.name
	local reason = data.reason and data.reason:gsub("[\r\n]*$", "")

	local txt = "Player " .. name .. " has left the server. (" .. reason .. ")"

	chat.AddText(Color(250, 30, 30), "[Disconnect] ", Color(200, 200, 200), txt .. ".")
	MsgC(Color(250, 30, 30), "[Disconnect] ", Color(200, 200, 200), txt .. ".	", Color(100, 220, 100), data.networkid .. "\n")
	surface.PlaySound("npc/roller/mine/combine_mine_deploy1.wav")
end)
]]

Colors.Leave = Color(220, 70, 70)

net.Receive("NewPlayerBroadcast", function()
	local typ = net.ReadUInt(4)

	local startConnect = typ == 0
	local joinFull = typ == 1

	local left = typ >= 2
	local leftUnconnected = typ == 2
	local leftConnected = typ == 3

	local plyname = net.ReadString()
	local sid = net.ReadString()

	local dat = {
		Colors.Yellowish, "[Connect] ",
		Color(200, 200, 200), "Player ",
		Color(100, 220, 100), plyname, " ",
		Color(160, 160, 160), "[STEAMID]",
	}

	local append

	if left then
		dat[1] = Colors.Leave
		dat[2] = "[Disconnect] "
	elseif joinFull then
		dat[1] = Colors.Sky
	end

	if startConnect then
		surface.PlaySound("npc/scanner/scanner_nearmiss1.wav")

		append = {
			Color(200, 200, 200), "has started connecting to the server.",
		}
	elseif joinFull then
		surface.PlaySound("garrysmod/content_downloaded.wav")

		append = {
			Color(200, 200, 200),
			"finished loading after ",
			Color(220, 200, 35), ("%d"):format(net.ReadUInt(16)),
			Color(200, 200, 200), "s.",
		}
	elseif leftUnconnected then
		surface.PlaySound("npc/turret_floor/retract.wav")

		append = {
			Color(200, 200, 200),
			"gave up on joining after ",
			Color(220, 200, 35), ("%d"):format(net.ReadUInt(16)),
			Color(200, 200, 200), "s.",
		}
	elseif leftConnected then
		surface.PlaySound("npc/turret_floor/retract.wav")
		surface.PlaySound("npc/roller/mine/combine_mine_deploy1.wav")

		append = {
			Color(200, 200, 200),
			"left after playing for ",
			Color(220, 200, 35), ("%d"):format(net.ReadUInt(16)),
			Color(200, 200, 200), "s.",
		}
	end

	--surface.PlaySound("npc/roller/mine/rmine_blip1.wav")

	for k,v in ipairs(append) do
		table.insert(dat, v)
	end

	local key = table.ReplaceValue(dat, "[STEAMID]", "", true)

	chat.AddText(unpack(dat))

	dat[key] = ("(%s) "):format(sid)

	MsgC(unpack(dat))
	MsgC("\n")
end)