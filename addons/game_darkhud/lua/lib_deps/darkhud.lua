FInc.NonRecursive("darkhud/darkhud.lua", FInc.CLIENT)

FInc.Recursive("darkhud/*.lua", FInc.CLIENT, true, function(s)
	if s:find("darkhud%.lua$") then return false, false end
	return true, true
end)