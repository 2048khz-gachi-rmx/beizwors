if not LibItUp.Networkable then include("networkable.lua") end
LibItUp.SetIncluded()

LibItUp.PlayerInfo = LibItUp.PlayerInfo or LibItUp.Emitter:callable()
local PI = LibItUp.PlayerInfo
PI.IsPlayerInfo = true
PI.CleanupIn = 300 -- being absent for 5min = playerinfo is cleaned up

LibItUp.PlayerInfoTables = LibItUp.PlayerInfoTables or {
	-- [info] = PI
	Player = {},
	SteamID = {},
	SteamID64 = {},

	Absent = {},
	Invalid = {},
}

LibItUp.AllPlayerInfos = LibItUp.AllPlayerInfos or {}

function LibItUp.CleanupAllPIs()
	-- extremely debug feature
	for k,v in pairs(LibItUp.PlayerInfoTables) do
		if istable(v) then
			LibItUp.PlayerInfoTables[k] = {}
		end
	end

	table.Empty(LibItUp.AllPlayerInfos)
end

local PIT = LibItUp.PlayerInfoTables

function PI:Initialize(id, is_sid64) -- we can't know that the id is a steamID64
	local ply
	local sid
	local sid64

	if IsPlayer(id) then
		ply = id
		sid = ply:SteamID()
		sid64 = ply:SteamID64()
	elseif not is_sid64 and string.IsSteamID(id) then
		ply = player.GetBySteamID(id)
		sid = id
		sid64 = util.SteamIDTo64(sid)
	else
		if not is_sid64 then
			LibItUp.Log("Initialized PlayerInfo using SteamID64 (`%s`), even though 2nd arg wasn't `true`.", id)
		end

		ply = player.GetBySteamID64(id)
		sid = util.SteamIDFrom64(id)
		sid64 = id
	end

	if not sid or not sid64 then
		errorf("Can't create PlayerInfo without SteamID or SteamID64. %s %s %s",
			sid or "[nil]", sid64 or "[nil]", ply or "[nil]")
		return
	end

	if ply then self:SetPlayer(ply) end
	self:SetSteamID(sid)
	self:SetSteamID64(sid64)

	self:ValidateNW()

	print(sid .. " new PlayerInfo created.", self:GetPublicNW(), self:GetPublicNW() and self:GetPublicNW():IsValid())
	print(PIT.Player[ply], PIT.Player[sid], PIT.Player[sid64])

	self._StartedSession = CurTime()
	self._EndedSession = nil
	self._TotalSession = 0

	if ply then PIT.Player[ply] = self end
	PIT.SteamID[sid] = self
	PIT.SteamID64[sid64] = self

	table.insert(LibItUp.AllPlayerInfos, self)

	PI.Revalidate(sid)
end

ChainAccessor(PI, "_SteamID", "SteamID")	-- 	  !! Using SteamID's is not advised due to its' behavior on bots !!
											-- Use SteamID64 instead since it has a hack to work on bots on both realms
ChainAccessor(PI, "_SteamID64", "SteamID64")
ChainAccessor(PI, "_PubNW", "PublicNW")
ChainAccessor(PI, "_PrivNW", "PrivateNW")

function PI:SetSteamID64(id)
	self._SteamID64 = id
	PIT.SteamID64[id] = self

	if not self:GetSteamID() then
		local sid = util.SteamIDFrom64(id)
		self:SetSteamID(sid)
	end

	if not self:GetPlayer() then
		local ply = player.GetBySteamID64(id)
		if ply then
			self:SetPlayer(ply)
		end
	end
end


function PI:SetPlayer(ply)
	if ply and not IsPlayer(ply) then return end
	self._Player = ply
	PIT.Player[ply] = self
	if ply then
		self._Nick = ply:Nick()
	end
end

function PI.Revalidate(id)
	local inv = PIT.Invalid[id]
	if not inv then return end

	PIT.Invalid[inv:GetSteamID64()] = nil
	PIT.Invalid[inv:GetSteamID()] = nil
	PIT.Invalid[inv:GetPlayer(true)] = nil
end

-- TODO: game event for nick change

ChainAccessor(PI, "_Nick", "Nick")
ChainAccessor(PI, "_Nick", "Name")

PI.Name = PI.GetNick
PI.Nick = PI.GetNick

function PI:GetPlayer(invalid)
	return (invalid and self._Player) or self._Player and self._Player:IsValid() and self._Player
end

PI.SteamID = PI.GetSteamID
PI.SteamID64 = PI.GetSteamID64

function PI:__tostring()
	return ("PlayerInfo [%s][ %s ]"):format(self:GetSteamID64() or "No SteamID64", self:GetPlayer() or "No Player")
end

-- mark "invalid" if youre ok with getting invalid PInfo
function PI:get(id, is_sid64, invalid, nocreate)
	if IsPlayerInfo(id) then return id end

	if is_sid64 and not id:IsMaybeSteamID64() then
		errorf("`%s` is almost certainly not a SteamID64. (and you tried to pass it off as one!)", id)
		return
	end

	-- dont return invalidated playerinfos if the player didnt join back
	if PIT.Invalid[id] and not invalid then return false end

	-- returns: pinfo, bool (newly created?)
	if IsPlayer(id) then
		local pin = LibItUp.PlayerInfoTables.Player[id]

		if pin and pin:IsValid() then return pin, false end

		-- didnt find by player; try to find by sid64
		local sid64 = id:SteamID64()

		if LibItUp.PlayerInfoTables.SteamID64[sid64] then
			local pi = LibItUp.PlayerInfoTables.SteamID64[sid64]
			if pi:IsValid() then
				pi:SetPlayer(id)
				return pi, false
			end
		end

	elseif not is_sid64 and string.IsSteamID(id) then
		local pin = LibItUp.PlayerInfoTables.SteamID[id]
		if pin and pin:IsValid() then return pin, false end

		local ply = player.GetBySteamID(id)

		if ply and LibItUp.PlayerInfoTables.Player[ply] then
			local info = LibItUp.PlayerInfoTables.Player[ply]
			if info:IsValid() then
				info:SetSteamID64(id)
			end
		end
	else
		-- try to guess the sid64 as a last resort
		local str = tostring(id)
		is_sid64 = is_sid64 or str:IsMaybeSteamID64()

		if is_sid64 then
			local pin = LibItUp.PlayerInfoTables.SteamID64[id]
			if pin and pin:IsValid() then return pin, false end

			local ply = player.GetBySteamID64(id)

			if ply and LibItUp.PlayerInfoTables.Player[ply] then
				local info = LibItUp.PlayerInfoTables.Player[ply]
				if info:IsValid() then
					info:SetSteamID64(id)
				end
			end
		else
			errorf("Unknown ID passed to PlayerInfo:Get() (id = `%s`, is_sid64 = `%s`)", id, is_sid64)
		end
	end

	if nocreate then return false, false end
	return PI:new(id, is_sid64), true
end

function PI:IsValid()
	return self._Valid ~= false
end

function PI:IsRemoving()
	return self._Removing ~= false
end

function PI:ValidateNW()
	if not self:GetPublicNW() or not self:GetPublicNW():IsValid() then
		self:SetPublicNW( Networkable("PI:" .. self:SteamID64()) )
		local pub = self:GetPublicNW()
		pub.PlayerInfoNW = self
		pub.IsPublicNW = self

		self:SetPrivateNW( Networkable("PI_Priv:" .. self:SteamID64()) )

		local priv = self:GetPrivateNW()
		priv.Filter = function(_, ply) return ply:SteamID64() == self:GetSteamID64() end
		priv.PlayerInfoNW = self
		priv.IsPrivateNW = self

		hook.NHRun("PlayerInfoNWCreate", self)
	end
end

function PI:_Destroy()

	table.RemoveByValue(LibItUp.AllPlayerInfos, self)

	-- run the hooks first in the event anyone tries to GetPlayerInfo
	xpcall(self.Emit, GenerateErrorer("PlayerInfoDestroyer"), self, "Destroy")
	hook.NHRun("PlayerInfoDestroy", self)
	self:GetPublicNW():Invalidate()

	-- and then get rid of ourselves
	self._Valid = false

	if self:GetPlayer(true) then
		PIT.Player[self:GetPlayer(true)] = nil
	end

	PIT.SteamID[self:GetSteamID()] = nil
	PIT.SteamID64[self:GetSteamID64()] = nil

	PIT.Invalid[self:GetSteamID64()] = self
	PIT.Invalid[self:GetSteamID()] = self
	PIT.Invalid[self:GetPlayer(true)] = self
end

function PI:RequestDestroy()
	-- should only be used for debug purposes!
	if LibItUp.PlayerInfoTables.Absent[self] then
		LibItUp.PlayerInfoTables.Absent[self] = CurTime() - PI.CleanupIn
	else
		ErrorNoHalt("Can't destroy a PInfo of a player still on!\n")
	end
end

function PI:_OnReconnect()
	if not self._EndedSession then return end
	self._TotalSession = self._TotalSession + (self._EndedSession - self._StartedSession)
	self._StartedSession = CurTime()
	self._EndedSession = nil

	PIT.Absent[self] = nil
end

function PI:_OnDisconnect()
	PIT.Player[self:GetPlayer()] = nil

	self:Emit("Disconnect", ply)

	self._AbsentSince = CurTime()
	self._EndedSession = CurTime()
	self._Absent = true
	-- self._Player = nil

	PIT.Absent[self] = self._AbsentSince
end

function PI:_GetCurrentSession()
	return (self._EndedSession or CurTime()) - self._StartedSession
end

function PI:GetSessionTime()
	return self._TotalSession + self:_GetCurrentSession()
end

function PI:GetAbsent()
	-- return #1: number or false (false if player is not currently absent)
	-- return #2: last absent duration: number or false (false if the player was never absent)

	local since, till = self._AbsentSince, (self._AbsentStop or CurTime())
	if not since then return false, false end

	if self._Absent then
		local prev = (self._AbsentStop and till - since) or false
		return till - since, prev
	else
		return false, self._AbsentStop - self._AbsentSince
	end
end

function PI:InsertByID(tbl, what, info, ply, sid, sid64)
	info = (info == nil) or info
	ply = (ply == nil) or ply
	sid = (sid == nil) or sid
	sid64 = (sid64 == nil) or sid64

	if info then
		tbl[self] = what
	end

	if ply and IsValid(self:GetPlayer()) then
		tbl[self:GetPlayer()] = what
	end

	if sid then
		tbl[self:GetSteamID()] = what
	end

	if sid64 then
		tbl[self:GetSteamID64()] = what
	end
end

if CLIENT then
	function PI:SetUserID(uid)	-- as soon as a player with this userID becomes valid, we'll assign steamid and shit to it
		hook.Add("PlayerJoined", "AssignPlayerInfo:" .. uid, function(ply)
			if ply:UserID() == uid then
				self:SetPlayer(ply)
				PIT.Player[ply] = self
			end
		end)
	end

	net.Receive("PlayerInfoFill", function()
		local uid = net.ReadUInt(16)
		local sid64 = net.ReadString()

		local pinfo = PI:get(sid64, true)

		if not Player(uid):IsValid() then
			pinfo:SetUserID(uid)
		end
	end)
else
	util.AddNetworkString("PlayerInfoFill")

	function PI:NotifyEveryone()
		net.Start("PlayerInfoFill")
			net.WriteUInt(self:GetPlayer():UserID(), 16)
			net.WriteString(self:GetSteamID64())
		net.Broadcast()
	end
end

hook.NHAdd("PlayerDisconnected", "PlayerInfoEmit", function(ply)
	local pinfo = PIT.Player[ply]
	if not pinfo then
		ErrorNoHalt("!!! PLAYER INFO FOR " .. tostring(ply) .. " HASN'T BEEN FOUND TO REMOVE !!!\n")
		ErrorNoHalt("!!! SteamID: " .. tostring(ply:SteamID()) .. ", SteamID64: " .. tostring(ply:SteamID64()) .. " !!!\n")
		return
	end

	pinfo:_OnDisconnect()
end)

hook.NHAdd("PlayerInitialSpawn", "PlayerInfoEmit", function(ply)
	local sid64 = ply:SteamID64()

	local pinfo, new = PI:get(sid64, true)

	if not new then
		PIT.Player[ply] = pinfo
		pinfo:_OnReconnect()
		pinfo:NotifyEveryone()
	end

	pinfo:Emit("Connect", ply)
end)

hook.Add("PlayerAuthed", "PlayerInfoEmit", function(ply, sid)
	PI.Revalidate(sid)

	local pinfo, new = PI:get(ply, false)

	if not new then
		pinfo:Emit("StartReconnect", ply)
		pinfo._AbsentStop = CurTime()
		pinfo._Absent = false
		PIT.Absent[pinfo] = nil
	end

	pinfo:NotifyEveryone()
end)

local function refill()
	for k,v in ipairs(player.GetAll()) do
		PI:get(v)
	end
end

hook.Add("InitPostEntity", "InitialFillPlayerInfo", refill)
refill()


local PLAYER = FindMetaTable("Player")
function PLAYER:GetPInfo()
	return PI:get(self)
end

function IsPlayerInfo(what)
	return istable(what) and what.IsPlayerInfo
end

function CanGetPInfo(what)
	-- can we turn the string into an ID?
	local can_turn = isstring(what) and (what:IsSteamID() or what:IsMaybeSteamID64())
	return IsPlayer(what) or can_turn or
			IsPlayerInfo(what)
end

CanGetPlayerInfo = CanGetPInfo

-- accepts SID, Player, PlayerInfo
-- accepts SID64 only if 2nd arg is true
function GetPlayerInfo(what, is_sid64)
	if not CanGetPInfo(what) then
		errorf("bad arg #1 to GetPlayerInfo" ..
			"(expected string [id], player or playerinfo, got %s (%s))", type(what),
			type(what) == "Player" and (what:IsValid() and "valid" or "invalid") or "not player")
		return
	end

	return PI:get(what, is_sid64)
end

function GetPlayerInfoMaybe(what, is_sid64)
	if not CanGetPInfo(what) then
		return false
	end

	return PI:get(what, is_sid64)
end

function GetPlayerInfoGuarantee(what, is_sid64)
	local pinfo = GetPlayerInfo(what, is_sid64)
	if not pinfo then errorf("Failed to obtain PlayerInfo using `%s` (%s)", what, type(what)) return end

	return pinfo, pinfo:GetPlayer()
end

function GetPlayerInfoIfExists(what, is_sid64)
	if not CanGetPInfo(what) then
		errorf("bad arg #1 to GetPlayerInfo" ..
			"(expected string [id], player or playerinfo, got %s (%s))", type(what),
			type(what) == "Player" and (what:IsValid() and "valid" or "invalid") or "not player")
		return
	end

	return PI:get(what, is_sid64, false, true)
end

function PIToPlayer(what)
	if IsPlayer(what) then return what end
	if IsPlayerInfo(what) then return what:GetPlayer() end
	if isstring(what) then
		local info = GetPlayerInfo(what)
		return info and info:GetPlayer()
	end
end

function GetAllPlayerInfos()
	return table.Copy(LibItUp.AllPlayerInfos)
end

function PInfoAccessor(k)
	PLAYER["Get" .. k] = function(self)
		local pin = self:GetPInfo()
		return pin["Get" .. k](pin)
	end

	PLAYER["Set" .. k] = function(self, v)
		local pin = self:GetPInfo()
		return pin["Set" .. k](pin, v)
	end
end

hook.Add("NetworkableAttemptCreate", "PlayerInfo", function(nwID)
	-- we only need to do this for public NW's; private should be fine
	if nwID:match("PI:(%d+)") then
		local sid64 = nwID:match("PI:(%d+)")

		local is_bot = sid64:match("^900") -- uhoh

		if is_bot then
			-- try to find a bot that'd match maybe possibly and pray
			-- i HATE GMOD I HATE GMOD I HATE GMOD
			for k,v in pairs(PIT.Player) do

				if v:IsValid() and v:SteamID64() == sid64 then -- updated steamid64?
					v:SetSteamID64(sid64)
					v:SetSteamID(util.SteamIDFrom64(sid64))
					v:GetPublicNW():SetNetworkableID(nwID)
					return v:GetPublicNW()
					-- AAAAAAAAAAAAAAAAAAAAAAAAA
				end
			end
		end

		local pin = GetPlayerInfoGuarantee(sid64, true)
		pin:ValidateNW()
		return true
	end
end)

timer.Create("PlayerInfoCleanup", 1, 0, function()
	local ct = CurTime()
	for pin, when in pairs(LibItUp.PlayerInfoTables.Absent) do
		if ct - when > PI.CleanupIn then
			LibItUp.PlayerInfoTables.Absent[pin] = nil
			pin:_Destroy()
		end
	end
end)

timer.Create("NameUpdate", 5, 0, function()
	for ply, pin in pairs(LibItUp.PlayerInfoTables.Player) do
		if not IsValid(ply) then continue end
		pin:SetNick(ply:Nick())
	end
end)