FInc.NonRecursive("darkhud/darkhud.lua", FInc.CLIENT)

FInc.Recursive("darkhud/*.lua", FInc.CLIENT, function(s)
	if s:find("darkhud%.lua$") then return false, false end
	return true, true
end)