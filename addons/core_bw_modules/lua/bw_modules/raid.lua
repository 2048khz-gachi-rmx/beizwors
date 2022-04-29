
local PLAYER = debug.getregistry().Player

BaseWars.Raid = BaseWars.Raid or {}

Raids = BaseWars.Raid

Raids.FactionCooldown = 900
Raids.RaidCoolDown = 900
Raids.RaidDuration = 360

local raid = BaseWars.Raid

raid.Cooldowns = raid.Cooldowns or {}
raid.Participants = raid.Participants or {}

function PLAYER:InRaid()
	return raid.Participants[self]
end

raid.Errors = {}
local err = raid.Errors
local id = 0

local function makeErr(s)
	err[id] = LocalString(s, "raid_errs:" .. id)

	id = id + 1

	return err[id - 1]
end

--[[-----------------------------]]
--	  	 Faction v. Faction
--[[-----------------------------]]

	err.NeedAFaction 		= "You can't raid a faction without being in a faction yourself!"
	err.OwnFaction 			= "You can't really raid your own faction..."
	err.LowLevelFaction 	= "Every player's level in that faction is too low!"
	err.ThatAintNoFac		= function(what)
		return ("Fellas, if your value\n" ..
		"- doesn't pass IsFaction\n" ..
		"- can't be raided\n" ..
		"- isn't a player,\n" ..
		"that's not a faction\n" ..
		"that's a motherfucking %s"):format(type(what))
	end

	err.RaidedByOthers 		= "This faction is already being raided by someone else."
	err.RaidingOthers 		= "This faction is currently raiding someone else."
	err.RaidedByYou 		= "This faction is already being raided by you!"
	err.YouAreRaidedByThem 	= "You are currently being raided by this faction!"

--[[-----------------------------]]
--	  	  Player v. Player
--[[-----------------------------]]

	err.PlayerRaidedByOthers 	= "This player is already being raided by someone else."
	err.PlayerRaidingOthers 	= "This player is currently raiding someone else."
	err.PlayerRaidedByYou 		= "This player is already being raided by you!"
	err.PlayerYouAreRaidedByThem 	= "You are currently being raided by this player!"

	err.CantHaveAFaction 		= "You can't raid a player while in a faction!"
	err.RaidingSelf				= "Might be better to just sell your own stuff, y'know?"

	err.LowLevelPlayer 			= "This player's level is too low!"

--[==================================[
	Both
--]==================================]

	err.YouAreRaided 		= "You are currently being raided!"
	err.YouAreRaiding 		= "You are currently raiding someone else!"
	err.NoRaidables			= "There are no raidable entities!"
	err.Generic				= "Generic error. Dunno."
	err.YouNeedBase			= "You need a base to raid others!"
	err.TheyNeedBase		= "They don't have a base to raid!"
	err.YouAreUnraidable	= function(why)
		if why then
			return ("You are unraidable!\n(%s)"):format(why)
		else
			return "You are unraidable!"
		end
	end

	err.TargetUnraidable	= function(why)
		print("target unraidable:", why)
		if why then
			return ("Target is unraidable!\n(%s)"):format(why)
		else
			return "Target is unraidable!"
		end
	end

	err.RaidedOnCooldown 	= function(what)
		local who = IsFaction(what) and "This faction" or "This player"
		local _, left = what:RaidedCooldown()
		return ("%s is currently on cooldown from being raided.\n(%ds. remaining)"):format(who, left)
	end


for k,v in pairs(err) do
	err[k] = makeErr(v)
end

function raid.PickRaidedError(rder, rded)
	local rd = raid.IsParticipant(rded)
	if not rd then return end

	local prefix = IsFaction(rded) and "" or "Player"
	local main

	-- `rded` are raiding...
	if rd:IsRaider(rded) then
		if rd:IsRaided(rder) then
			-- ...you
			main = "YouAreRaidedByThem"
		else
			-- ...someone else
			main = "RaidingOthers"
		end
	else
		-- they are being raided by...
		if rd:IsRaider(rder) then
			-- ...you
			main = "RaidedByYou"
		else
			-- ...someone else
			main = "RaidedByOthers"
		end
	end

	if not main or not err[prefix .. main] then
		print("======")
		print("Unhandled condition?")
		print("	Raider:", rder)
		print("	Raided:", rded)
		print("	Prefix/main:", prefix, "/", main)
		print("=====")
		return err.Generic
	end

	return err[prefix .. main]
end

function raid.CanGenerallyRaid(ply, nonfac)
	if bit.bxor(ply:GetFaction() and 1 or 0, nonfac and 1 or 0) == 0 then
		return false, nonfac and err.CantHaveAFaction() or err.NeedAFaction()
	end

	local pin = GetPlayerInfoGuarantee(ply)
	if not pin:GetBase() then
		return false, pin:GetPlayer() == ply and
			err.YouNeedBase() or err.TheyNeedBase()
	end

	return true
end

function raid.CanRaidPlayer(ply, ply2)
	local fac = ply:GetFaction() or ply2:GetFaction()

	if ply == ply2 then return false, err.RaidingSelf end
	if fac then return false, err.CantHaveAFaction end

	if ply2:GetRaidCD() then
		return false, err.RaidedOnCooldown(ply2)
	end

	if not ply2:GetBase() then
		return false, err.TheyNeedBase()
	end

	if ply:InRaid() or ply2:InRaid() then
		return false, raid.PickRaidedError(ply, ply2)
	end

	return true
end

function raid.CanRaidFaction(caller, fac2)
	-- caller isnt guaranteed to be present, in that case
	-- we're checking the raidability of our own (`fac2`) faction

	local self_check = caller == false
	local fac = not self_check and caller:GetFaction()

	if not IsFaction(fac2) then return false, err.ThatAintNoFac(fac2) end
	if not fac and not self_check then return false, err.NeedAFaction end
	if fac == fac2 then return false, err.OwnFaction end

	if not self_check and fac:InRaid() then
		local rder, rded = fac:InRaid():GetSides()
		return false, raid.PickRaidedError(fac, rded)
	end

	if fac2:InRaid() then
		local rded, rder = fac2:InRaid():GetSides()
		return false, raid.PickRaidedError(fac2, rded)
	end

	if not self_check and fac2:RaidedCooldown() then
		return false, err.RaidedOnCooldown(fac2)
	end

	if not fac2:GetBase() then
		return false, caller and err.TheyNeedBase() or err.YouNeedBase()
	end

	if SERVER then
		local has_raidables = false

		for k,v in pairs(fac2:GetMembers()) do
			local ents = BaseWars.Ents.GetOwnedBy(v)

			for _, ent in ipairs(ents) do
				if ent.IsValidRaidable then has_raidables = true break end
			end
		end

		if has_raidables then
			return true
		else
			return false, err.NoRaidables
		end
	else
		return true
	end
end

local PINFO = LibItUp.PlayerInfo

function PINFO:GetRaid()
	local rd = self._Raid and self._Raid:IsValid() and self._Raid
	if rd then return rd end

	rd = raid.Participants[self:SteamID64()]
	return rd and rd:IsValid() and rd
end

function PINFO:SetRaid(rd)
	if rd and not rd:IsValid() then return end

	self._Raid = rd

	if rd then
		rd:On("Stop", "PInfoStore", function()
			if self._Raid == rd then self._Raid = nil end
		end)
	end
end

hook.Add("RaidStop", "CleanRaids", function(rd)
	for k,v in pairs(rd:GetParticipants()) do
		if string.IsSteamID(v) then
			local pin = GetPlayerInfo(v)
			if pin:GetRaid() == rd then
				pin:SetRaid(nil)
			end
		end
	end
end)

function PINFO:IsEnemy(what)
	what = GetPlayerInfo(what)
	if not what or not what:IsValid() then return end

	local rd = self:GetRaid()
	if not rd then return false end

	local rd2 = what:GetRaid()
	if not rd2 then return false end

	if rd ~= rd2 then return end

	return rd:GetSide(self) ~= rd2:GetSide(what)
end

function PINFO:GetRaidCD()
	local nw = self:GetPublicNW()
	local rtime = nw:Get("RaidCD", 0)
	local left = rtime - CurTime()

	return left > 0, math.max(left, 0)
end

function PINFO:SetRaidCD(t)
	local nw = self:GetPublicNW()
	nw:Set("RaidCD", CurTime() + Raids.RaidCoolDown - (t and Raids.RaidCoolDown - t or 0))
end

function PLAYER:GetRaidCD()
	local pin = GetPlayerInfo(self)
	return pin:GetRaidCD()
end

PInfoAccessor("RaidCD")
PLAYER.RaidedCooldown = PLAYER.GetRaidCD