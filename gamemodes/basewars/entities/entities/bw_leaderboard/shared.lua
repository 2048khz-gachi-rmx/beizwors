AddCSLuaFile()

BW.LeaderBoard = BW.LeaderBoard or {}
BW.Leaderboard = BW.LeaderBoard


ENT.Base = "bw_base"
ENT.Type = "anim"
ENT.PrintName = "Template Entity"

ENT.Model = "models/hunter/plates/plate3x6.mdl" -- forgor
ENT.Skin = 0

ENT.CanTakeDamage = false
ENT.NoHUD = true

function ENT:DerivedDataTables()

end

local nw

function ENT:GetNW()
	return nw
end

if CLIENT then

	function BW.Leaderboard.OnCreateNW(nw)
		nw:On("CustomReadChanges", "Decode", function(self, changes)
			BW.Leaderboard.LastUpdate = CurTime()
			local amt = net.ReadUInt(8)

			for i=1, amt do
				local k = net.ReadUInt(8)

				local money = net.ReadDouble()
				local sid64 = net.ReadSteamID64()

				self:Set(k, {money = money, sid = sid64})
			end

			return true
		end)
	end

end

local function load()
	if SERVER then include("sv_dbdata.lua") end

	nw = Networkable("bw_leaderboard")
	BW.Leaderboard.NW = nw
	BW.Leaderboard.OnCreateNW(nw)
end

if not LibItUp then
	hook.Add("LibItUp", "Leaderboard", load)
else
	load()
end