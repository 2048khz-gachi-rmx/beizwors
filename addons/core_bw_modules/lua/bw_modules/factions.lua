MODULE.Name = "FactionsSH"

--[[
	Hooks:
		PLAYERS ARENT GUARANTEED TO BE VALID!!! USE PLAYERINFO

		[SH] PlayerLeftFaction : faction, player, playerinfo
		[SH] PlayerJoinedFaction : faction, player, playerinfo
		[SH] FactionDisbanded : faction
]]

Factions = Factions or {}

Factions.Factions = Factions.Factions or {}
Factions.FactionIDs = Factions.FactionIDs or {}

Factions.MaxMembers = 4

Factions.FactionlessTeamID = 1


Factions.CREATE = 1		-- cl -> sv
Factions.LEAVE = 2		-- cl -> sv
Factions.JOIN = 3		-- cl -> sv
Factions.KICK = 4

Factions.FULLUPDATE = 1 -- sv -> cl
Factions.UPDATE = 2 	-- sv -> cl
Factions.DELETE = 3		-- sv -> cl


Factions.meta = Factions.meta or Emitter:extend()

local facmeta = Factions.meta

facmeta.__tostring = function(self)
	return ("[Faction %q]"):format(self.name)
end
facmeta.IsFaction = true

function IsFaction(t)
	local meta = getmetatable(t)
	return meta and meta.IsFaction
end


Factions.Errors = {}
local err = Factions.Errors
local err_id = 0

local function makeErr(s)
	err[err_id] = LocalString(s, "fac_err:" .. err_id)

	err_id = err_id + 1

	return err[err_id - 1]
end

local errs = Factions.Errors

errs.Generic 			= 	makeErr("Something went wrong.")
errs.BadPassword 		= 	makeErr("Incorrect password!")
errs.NamelessFac 		= 	makeErr("Can't create a faction without a name!")
errs.AlreadyIn 			= 	makeErr("Can't create a new faction while in one!")
errs.NameLength 		= 	makeErr("Faction names must be 5-32 characters long.")
errs.PasswordLength 	= 	makeErr("Faction passwords must be 5-32 characters long.")
errs.NameExists 		= 	makeErr("A faction with this name already exists.")
errs.NoFac 				= 	makeErr("No such factions exist!")
errs.JoinInRaid 		= 	makeErr("Can't join a faction while being raided!")
errs.JoinInFac 			= 	makeErr("Can't join a faction while already in one!")
errs.JoinWithBase		=	makeErr("Can't join a faction while owning a base!")
errs.CreateInRaid		=	makeErr("Can't create a faction while in a raid!")
errs.LeaveInRaid		=	makeErr("Can't leave a faction while in a raid!")

function LibItUp.PlayerInfo:GetFaction()
	local fac = self._Faction
	if fac and not fac:IsValid() then
		errorf("Something went wrong: %s has faction set as %s, but it isn't valid.", self, fac)
		return
	end

	return fac
end

function LibItUp.PlayerInfo:SetFaction(fac)
	assert( (IsFaction(fac) and fac:IsValid()) or fac == nil )
	self._Faction = fac
end

hook.Add("PlayerJoinedFaction", "PlayerInfoFill", function(fac, ply, pinfo)
	pinfo:SetFaction(fac)
end)

hook.Add("PlayerLeftFaction", "PlayerInfoFill", function(fac, ply, pinfo)
	pinfo:SetFaction(nil)
end)

hook.Add("FactionDisbanded", "PlayerInfoFill", function(fac)
	for k,v in ipairs(fac:GetMembersInfo()) do
		v:SetFaction(nil)
	end
end)

function facmeta:RaidedCooldown()
	local has, max = false, 0
	for k,v in ipairs(self:GetMembersInfo()) do
		local vh, vm = v:GetRaidCD()
		if vh then
			has = true
			max = math.max(max, vm)
		end
	end

	return has, max
end

function facmeta:GetBase()
	local base

	if SERVER then
		base = self._Base
	else
		base = BaseWars.Bases.Bases[self.PublicNW:Get("OwnedBase", -1)]
	end

	if base then
		if not base:IsValid() then
			return false
		end

		if not base:IsOwner(self) then
			errorf("Something went wrong: %s has base set as %s, but it doesn't own it.", self, base)
			return
		end
	end

	return base
end

function facmeta:SetBase(base)
	assert(not base or BaseWars.Bases.IsBase(base))

	if base then
		base:On("Unclaim", self, function(_)
			if self._Base == base then
				self:SetBase(nil)
			end
		end)
	end

	self._Base = base
	self.PublicNW:Set("OwnedBase", base and base:GetID() or nil)
end

local PLAYER = debug.getregistry().Player

function PLAYER:IsTeammate(ply)
	return (ply:Team() == 1 and ply == self) or ply:Team() == self:Team()
end

function PLAYER:GetFaction()
	return Factions.FactionIDs[self:Team()]
end

function PLAYER:GetFactionName()
	local fac = Factions.FactionIDs[self:Team()]
	if fac then return fac.name end

	return "no faction"
end


function Factions.CanCreate(name, pw, col, ply)
	if not name then
		return false, Factions.Errors.NamelessFac
	end

	local nmLen = utf8.len(name)
	local pwLen = pw and utf8.len(pw)

	if ply:InFaction() then
		return false, Factions.Errors.AlreadyIn
	end

	if ply:InRaid() then
		return false, Factions.Errors.CreateInRaid
	end

	if nmLen < 5 or nmLen > 32 then
		return false, Factions.Errors.NameLength
	end

	if pw and pw ~= "" and (pwLen < 5 or pwLen > 32) then
		return false, Factions.Errors.PasswordLength
	end

	if Factions.Factions[name] then
		return false, Factions.Errors.NameExists
	end

	return true
end

function Factions.CanLeave(ply)
	if not ply:GetFaction() then
		return false, Factions.Errors.Generic
	end

	if ply:InRaid() then
		return false, Factions.Errors.LeaveInRaid
	end

	return true
end

function Factions.CanJoin(ply, fac)
	if ply:InFaction() then
		return false, Factions.Errors.JoinInFac
	end

	if ply:InRaid() or fac:InRaid() then
		return false, Factions.Errors.JoinInRaid
	end

	if ply:GetBase() then
		return false, Factions.Errors.JoinWithBase
	end

	return true
end

function Factions.GetFaction(id)
	if SERVER then Factions.Validate() end
	if isnumber(id) then return Factions.FactionIDs[id] or false end
	return Factions.Factions[id] or false
end

function Factions.CreateEmptyFaction()
	local fac

	if CLIENT then
		fac = Factions.meta:new(-1, "No Faction", Color(100, 100, 100))
	else
		fac = Factions.meta:new(false, -1, "No Faction", nil, Color(100, 100, 100))
	end

	-- factions with ID < 0 are automatically considered invalid and don't get a networkableID

	Factions.NoFaction = fac

	Factions.Factions["No Faction"] = nil
	Factions.FactionIDs[-1] = nil
end

hook.Add("BasewarsModuleLoaded", "CreateEmptyFaction", function(nm)
	if nm ~= "FactionsSV" and nm ~= "FactionsCL" then return end

	if not Factions.NoFaction then
		Factions.CreateEmptyFaction()
	end
end)