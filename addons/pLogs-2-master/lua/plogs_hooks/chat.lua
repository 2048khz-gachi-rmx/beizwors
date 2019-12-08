plogs.Register('Chat', false)

local hook_name = DarkRP and 'PostPlayerSay' or 'PlayerSay'
plogs.AddHook(hook_name, function(pl, text)
	if (text ~= '') then
		plogs.PlayerLog(pl, 'Chat', pl:NameID() .. ' said ' .. string.Trim(text), {
			['Name'] 	= pl:Name(),
			['SteamID']	= pl:SteamID()
		})
	end
end)