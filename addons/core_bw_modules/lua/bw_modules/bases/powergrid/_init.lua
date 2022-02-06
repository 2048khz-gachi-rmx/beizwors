
include("powergrid_sh.lua")
AddCSLuaFile("powergrid_sh.lua")

local function notPGrid(path)
	return not path:match("powergrid_sh%.lua$") and not path:match("_init%.lua$")
end

FInc.FromHere("*.lua", FInc.SHARED, FInc.RealmResolver():SetDefault(notPGrid))