PlayTime = PlayTime or {}

local PLAYER = debug.getregistry().Player

if SERVER then
	local incrFreq = 10
	PlayTime.LastThink = CurTime()

	hook.Add( "Think", "PlayTime.Think", function()
		if CurTime() < PlayTime.LastThink + incrFreq then return end
		PlayTime.LastThink = CurTime()

		for _, ply in next, player.GetAll() do
			ply:AddBWData("playtime", incrFreq)
		end

	end)

	hook.Add("BW_LoadPlayerData", "BW_PlayTime", function(ply, dat)
		ply:SetNW2Float("JoinTime", CurTime())
		ply:SetNW2Int("PlayTime", dat.playtime)

		ply.JoinTime = CurTime()
		ply.PlayedTime = dat.playtime
		ply:SetBWData("playtime", dat.playtime)
	end)

	hook.Add( "PlayerDisconnected", "PlayTime.Disconnect", function(ply)
		-- how much time left until next increment of X seconds
		ply:AddBWData("playtime", PlayTime.LastThink - CurTime())
	end)

	hook.Add( "ShutDown", "PlayTime.ShutDown", function()
		for _, ply in ipairs(player.GetAll()) do
			ply:AddBWData("playtime", PlayTime.LastThink - CurTime())
		end
	end	)

end

function PLAYER:GetPlayTime()
	if SERVER then
		return math.Round((CurTime() - self.JoinTime) + self.PlayedTime)
	else
		return (CurTime() - self:GetNW2Float("JoinTime", 0)) +
			self:GetNW2Int("PlayTime", 0)
	end
end

function PLAYER:GetPlayTimeTable()

	local tbl = {}
	local time = self:GetPlayTime() or 0

	tbl.h = math.floor(time / 60 / 60)
	tbl.m = math.floor(time / 60) % 60
	tbl.s = math.floor(time) % 60

	return tbl

end

function PLAYER:GetSessionTime()
	if SERVER then
		return math.Round(CurTime() - self.JoinTime or 0)
	else
		return CurTime() - self:GetNW2Float("JoinTime", 0)
	end
end

function PLAYER:GetSessionTable()
	local tbl = {}
	local time = self:GetSessionTime() or 0

	tbl.h = math.floor(time / 60 / 60)
	tbl.m = math.floor(time / 60) % 60
	tbl.s = math.floor(time) % 60

	return tbl
end

-- import old times
do return end

local _, folders = file.Find("basewars_time/*", "DATA")

for _, sid in ipairs(folders) do
	local time = file.Read("basewars_time/" .. sid .. "/time.txt", "DATA")
	time = time and tonumber(time)
	if not time then continue end

	file.Rename("basewars_time/" .. sid .. "/time.txt",
		"basewars_time/" .. sid .. "/_imported_time.txt")

	BaseWars.PlayerData.AddOffline(sid, "playtime", time)
	print("import: added", time, "to", sid)

	local ply = player.GetBySteamID64(sid)
	if ply then
		BaseWars.PlayerData.Load(ply)
	end

	PlayTime.LastThink = CurTime()
end