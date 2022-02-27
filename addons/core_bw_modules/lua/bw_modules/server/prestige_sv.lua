MODULE.Name     = "Prestige"
MODULE.Realm = 1

BaseWars.Prestige = BaseWars.Prestige or {}

local PLAYER = debug.getregistry().Player
local PInfo = LibItUp.PlayerInfo

util.AddNetworkString("Prestige")
BaseWars.Prestige = BaseWars.Prestige or {}
local MODULE = BaseWars.Prestige

MODULE.Log = Logger("BW-Prestige", Color(0, 230, 250))
MODULE.Functions = {}
local FUNCS = MODULE.Functions

local INTERNAL_KEY = "_prestige"
local FUNC_NAME = "Prestige"
local BWDATA_NAME = "prestige"

function FUNCS:SyncPrestige()
	self:GetPublicNW():Set(BaseWars.Prestige.NWKey, self:GetPrestige())
end

local function getInt(self)
	return self[INTERNAL_KEY]
end

local function setInt(self, v)
	self[INTERNAL_KEY] = v
	self["Sync" .. FUNC_NAME] (self)
end

local function setBWData(self)
	self:SetBWData(BWDATA_NAME, getInt(self))
end

-->  ==========
FUNCS["Set" .. FUNC_NAME] = function(self, amt, no_write)
	self = GetPlayerInfoGuarantee(self)

	if not getInt(self) and not no_write then
		errorf("attempting to set " .. BWDATA_NAME .. " to a player before their bwdata initializes! ( %s (%s) -> %d )",
			self:Nick(), self:SteamID64(), amt)
		return
	end

	setInt(self, math.Round(amt))

	if not no_write then
		setBWData(self)
	end
end



--> +++++++++++
FUNCS["Add" .. FUNC_NAME] = function(self, amt, no_write)
	self = GetPlayerInfoGuarantee(self)

	if not self._money then
		MODULE.Log("Attempt to modify a player's " .. BWDATA_NAME .. " before init.\n	(%s (%s) : +%d)\n	Trace:\n%s",
			self:Nick(), self:SteamID64(), amt, debug.traceback())
		return
	end

	setInt(self, math.Round(getInt(self) + amt))

	if not no_write then
		setBWData(self)
	end
end


--> -----------
FUNCS["Take" .. FUNC_NAME] = function(self, amt, no_write)
	self = GetPlayerInfoGuarantee(self)

	if not self._money then
		MODULE.Log("Attempt to modify a player's " .. BWDATA_NAME .. " before init.\n	(%s (%s) : -%d)\n	Trace:\n%s",
			self:Nick(), self:SteamID64(), amt, debug.traceback())
		return
	end

	setInt(self, math.Round(getInt(self) - amt))

	if not no_write then
		setBWData(self)
	end
end


FUNCS["Load" .. FUNC_NAME] = function(self, dat, write)
	local var = dat[BWDATA_NAME]

	if not var then --bruh
		var = 0

		MODULE.Log("Reset " .. BWDATA_NAME .. " for \"%s\" (%s) to starting (%s)",
			self:Nick(), self:SteamID64(), var)
	end

	self["Set" .. FUNC_NAME] (self, var, true)
	setBWData(self)
	--applyPreInit(self)
end

for k,v in pairs(FUNCS) do
	PLAYER[k] = function(self, ...)
		local pin = GetPlayerInfoGuarantee(self)
		return v (pin, ...)
	end

	PInfo[k] = function(...)
		return v (...)
	end
end

hook.NHAdd( "BW_LoadPlayerData", "BW" .. FUNC_NAME .. ".Load", PLAYER["Load" .. FUNC_NAME] )