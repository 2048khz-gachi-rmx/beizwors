include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

function ENT:Init(me)

end

function ENT:Think()
	self:NextThink(CurTime() + 1)
	return true
end

function ENT:Use(ply)

end

hook.Add("BW_LeaderboardUpdated", "Network", function(dat)

end)

local function loadFile()
	include("sv_dbdata.lua")
end

if not LibItUp then
	hook.Add("LibItUp", "Leaderboard", loadFile)
else
	loadFile()
end