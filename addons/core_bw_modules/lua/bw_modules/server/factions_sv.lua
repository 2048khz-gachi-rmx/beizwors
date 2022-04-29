Factions = Factions or {}
MODULE.Name = "FactionsSV"

util.AddNetworkString("Factions")

local facs = Factions

local PLAYER = debug.getregistry().Player

facs.Players = facs.Players or {}
facs.Factions = facs.Factions or {}
facs.FactionIDs = facs.FactionIDs or {}

local facmeta = Factions.meta

facmeta.IsFaction = true

function IsFaction(t)
	local meta = getmetatable(t)

	return meta and meta.IsFaction
end

function facmeta:GetMembers()
	return self.memvals
end

function facmeta:GetMembersInfo()
	return self.meminfovals
end

function facmeta:IsMember(what)
	local pinfo = GetPlayerInfoGuarantee(what)
	return self.meminfo[pinfo] and pinfo
end

function facmeta:GetName()
	return self.name
end

function facmeta:GetColor()
	return self.col
end

function facmeta:GetPassword()
	return self.pw or false
end

ChainAccessor(facmeta, "id", "ID")
ChainAccessor(facmeta, "own", "Leader")
ChainAccessor(facmeta, "own", "Owner")
ChainAccessor(facmeta, "ownInfo", "LeaderInfo")
ChainAccessor(facmeta, "ownInfo", "OwnerInfo")

function facmeta:Update(now)
	--self.PublicNW:Set("Members", self.memvals)
	self.PublicNW:Set("Leader", self.ownInfo)
	self.PublicNW:Set("PlayerInfo", self.meminfovals)

	self:Emit("Update")
end

function facmeta:_AddToMembers(what)
	local pinfo, ply = GetPlayerInfoGuarantee(what)

	local new = not self.meminfo[pinfo]

	self.memvals[#self.memvals + 1] = ply
	self.meminfovals[#self.meminfovals + 1] = pinfo
	pinfo._Faction = self
	self.members[ply] = true
	self.meminfo[pinfo] = true

	if new then
		self:Emit("JoinFaction", ply, pinfo)
		hook.NHRun("PlayerJoinedFaction", self, ply, pinfo)
	end
end

function facmeta:_RemoveFromMembers(what)
	local pinfo = GetPlayerInfoGuarantee(what)
	local ply = pinfo:GetPlayer(true)

	if ply and Factions.Players[ply] == self then
		Factions.Players[ply] = nil
	end

	local had = self.meminfo[pinfo]

	table.RemoveByValue(self:GetMembers(), ply)
	table.RemoveByValue(self:GetMembersInfo(), pinfo)

	if ply then self.members[ply] = nil end
	self.meminfo[pinfo] = nil
	pinfo._Faction = nil

	if had then
		self:Emit("LeaveFaction", ply, pinfo)
		hook.NHRun("PlayerLeftFaction", self, ply, pinfo)
	end
end

function facmeta:Join(ply, pw, force)

	if #self.memvals >= 4 then return false, "Too many members!" end
	if ply:InFaction() then return false, "Player is already in a faction!" end
	if ply:InRaid() then return false, "Player is in a raid!" end
	if self:IsMember(ply) then return false, "Player is already part of the faction!" end

	if self.pw and self.pw ~= pw and not force then
		net.Start("Factions")
			net.WriteUInt(10, 4) --hey buddy i think you got the wrong password
			Factions.Errors[1]:Write()
		net.Send(ply)

		return false, "wrong password boy"
	end

	self:_AddToMembers(ply)

	Factions.Players[ply] = self:GetName()

	ply:SetTeam(self:GetID())

	self:Update(true)
end

function facmeta:OnRaided()
	self.RaidCooldown = CurTime()
	self.PublicNW:Set("RaidCooldown", self.RaidCooldown)
end

function facmeta:Initialize(ply, id, name, pw, col)

	if not id or not name then error('what??? ' .. tostring(id) .. " " .. tostring(name)) return false end --for real?

	if Factions.Factions[name] then return false end

	team.SetUp(id, name, col, false)

	self.id = id
	self.name = name
	self.col = col
	self.pw = pw

	self.members = {}		-- [ply] = true
	self.memvals = {}		-- [seq_id] = ply
	self.meminfo = {}		-- [plyInfo] = true
	self.meminfovals = {}	-- [seq_id] = plyInfo

	if IsPlayer(ply) then
		Factions.Players[ply] = name
		ply:SetTeam(id)
		self:_AddToMembers(ply)
	elseif ply ~= false then
		error("Attempted to create a faction with no player; use `false` as the first arg if this is intentional.")
	end

	Factions.Factions[name] = self
	Factions.FactionIDs[id] = self

	if id > 0 then
		self.own = ply
		self.ownInfo = GetPlayerInfoGuarantee(ply)

		self.PublicNW = Networkable:new("Faction:" .. id)
		self.PublicNW:On("WriteChangeValue", "WritePlayerInfo", self._SerializePlayerInfo)

		self.PublicNW:Alias("Members", 1)
		self.PublicNW:Alias("Leader", 2)
		self.PublicNW:Alias("PlayerInfo", 3)

		self:Update(true)
	end

	self:On("Raided", "CooldownTracker", self.OnRaided)
end

hook.NHAdd("RaidStart", "FactionRaids", function(raid, rder, rded, fac)
	if not fac then return end

	rded:OnRaided()
end)

function facmeta:_SerializePlayerInfo(key, val)
	if key == "PlayerInfo" then
		net.WriteUInt(#val, 4)
		for k,v in ipairs(val) do
			net.WriteString(v:GetSteamID64())
		end
		return false
	end

	if key == "Leader" then
		net.WriteString(val:GetSteamID64())
		return false
	end
end

function facmeta:IsRaidable(caller)
	-- caller can be nil if it's checked as "generally raidable"
	local can, err = hook.Run("IsFactionRaidable", self)
	if can == false then return can, err end

	if caller then
		can, err = BaseWars.Raid.CanGenerallyRaid(caller, false)
		if can == false then
			return can, err
		end
	end

	can, err = BaseWars.Raid.CanRaidFaction(caller, self)
	if can == false then
		return can, err
	end

	return true
end

function facmeta:ChangeOwnership(to)
	-- prioritize a random player from _online_ dudes
	to = to or table.SeqRandom(self.memvals)
	if not to or not IsValid(to) then
		-- try to pick offline people?
		to = table.SeqRandom(self:GetMembersInfo())
		if not to then
			-- not supposed to happen
			self:Remove()
			error("Noone to change ownership to; killing faction")
			return
		end
	end

	local pin = GetPlayerInfoGuarantee(to)
	local ply = IsValid(pin:GetPlayer()) and pin:GetPlayer()

	self:SetOwner(ply) -- they might be invalid for all i know
	self:SetOwnerInfo(pin)
	self:Update(true)
end

function facmeta:CleanMember(ply)
	if not self:IsMember(ply) then return end

	self:GetMembersInfo()
	self.members[ply] = nil
end

function facmeta:CleanInvalids()
	local m = self:GetMembers()
	for i=#m, 1, -1 do
		if not IsValid(m[i]) then
			table.remove(m, i)
			self.members[i] = nil
		end
	end
end

function facmeta:RemovePlayer(ply)
	if not self:IsMember(ply) then return end

	local pin = GetPlayerInfoGuarantee(ply)
	ply = IsValid(pin:GetPlayer()) and pin:GetPlayer()

	self:_RemoveFromMembers(pin)

	if ply then
		ply:SetTeam(Factions.FactionlessTeamID)
	end

	--[[if #self:GetMembersInfo() == 0 then
		self:Remove()
		return
	end]]

	-- no online people present; disband
	if #self:GetMembers() == 0 then
		self:Remove()
		return
	end

	if self:GetOwnerInfo() == pin then
		self:ChangeOwnership()
	end
	self:Update(true)
end

function facmeta:Remove()
	if self == Factions.NoFaction then return end

	self._Valid = false

	Factions.Factions[self.name] = nil
	Factions.FactionIDs[self.id] = nil

	for k,v in ipairs(self.memvals) do
		if not IsValid(v) then
			errNHf("still not fixed - invalid player %s in faction %s", v, self)
			continue
		end

		v:SetTeam(Factions.FactionlessTeamID)
		Factions.Players[v] = nil
	end

	for k, pinfo in ipairs(self.meminfovals) do
		pinfo:SetFaction(nil)
	end

	hook.NHRun("FactionDisbanded", self)

	net.Start("Factions")
		net.WriteUInt(3, 4)	--delete
		net.WriteUInt(self.id, 24)
	net.Broadcast()

	if self.id > 0 then
		self.PublicNW:Invalidate()
	end
	self:Emit("Remove")
end

function facmeta:IsValid()
	return self._Valid ~= false
end

function Factions.Validate()

	for k,v in pairs(Factions.Factions) do
		if v == Factions.NoFaction then continue end

		v:CleanInvalids()

		table.Filter(v.members, function(v)
			return v:IsValid()
		end)

		if table.Count(v.members) == 0 then
			-- todo: check the timer before removing
			v:Remove()
			continue
		end

		--Owner checking

		if not IsValid(v:GetOwnerInfo()) then
			v:ChangeOwnership()
			if not IsValid(v:GetOwnerInfo()) then
				-- !?! ?!?
				v:Remove()
				ErrorNoHalt("Wtf, ownerinfo invalid even after changing ownership")
				continue
			end
		end

		if not IsValid(v:GetOwner()) then
			v:SetOwner(v:GetOwnerInfo():GetPlayer())
		end

		-- v:Update()
	end

end

function Factions.GetPlayerFaction(ply, ply2)
	local pin = GetPlayerInfoGuarantee(ply)
	-- passed a name as the second arg; check if player belongs to
	-- the named faction
	if isstring(ply2) and not CanGetPInfo(ply2) then
		local fac2 = Factions.Factions[ply2]

		return pin:GetFaction() == fac2
	end

	local pin2 = CanGetPInfo(ply2) and GetPlayerInfo(ply2)

	if pin2 then
		return pin:GetFaction() == pin2:GetFaction()
	else
		return pin:GetFaction()
	end
end

PLAYER.GetFaction = Factions.GetPlayerFaction
PLAYER.InFaction = Factions.GetPlayerFaction

function Factions.Get(name)
	return Factions.Factions[name]
end

function Factions.RandomizeOwner(name)
	local fac = IsFaction(name) and name or Factions.Factions[name]
	fac:ChangeOwnership()
end


local cooldowns = {}

function Factions.CreateFac(ply, name, pw, col)
	if cooldowns[ply] and CurTime() - cooldowns[ply] < 1 then return end

	pw = pw and utf8.sub(pw, 0, 32)
	name = utf8.sub(name, 0, 32)

	if not Factions.CanCreate(name, pw, col, ply) then print("err can't create fac:", Factions.CanCreate(name, pw, col, ply)) return end

	Factions.Validate()

	if not name or name == "" then error('uh no name?') return end
	if pw == "" then pw = nil end

	local id = 101

	for k,v in pairs(Factions.Factions) do
		if v.id+1 > id then id = v.id+1 end
	end

	if not col then col = Color(math.random(0, 255), math.random(0, 255), math.random(0, 255)) end

	local fac = facmeta:new(ply, id, name, pw, col)

	cooldowns[ply] = CurTime()

	-- first make them aware of the faction, then network its' details

	net.Start("Factions")
		net.WriteUInt(2, 4)	--update
		net.WriteUInt(id, 24)
		net.WriteString(name)
		net.WriteColor(col)

		local haspw = false
		if pw then haspw = true end
		net.WriteBool(haspw)

	net.Broadcast()

	fac:Update(true)

	-- anyone that tries to network data about the faction will do it afterwards
	-- no data races on my watch
	hook.NHRun("FactionCreated", ply, fac)
end

PLAYER.CreateFaction = Factions.CreateFac

function Factions.LeaveFac(ply)
	local fac = ply:GetFaction()
	if not fac then return end

	fac:RemovePlayer(ply)
end

PLAYER.LeaveFaction = Factions.LeaveFac

function Factions.JoinFac(ply, id, pw, force)

	local fac = Factions.FactionIDs[id] or (IsFaction(id) and id)
	if not fac then return false, Factions.Errors.NoFac end

	local can, why = Factions.CanJoin(ply, fac)
	if not can then return false, why end

	if fac.pw and fac.pw ~= pw then
		return false, Factions.Errors.BadPassword
	end

	fac:Join(ply, pw, force)

	Factions.Validate()
	return true
end

PLAYER.JoinFaction = Factions.JoinFac

function Factions.KickOut(ply)
	local fac = ply:GetFaction()
	if not fac then return end

	fac:RemovePlayer(ply)

	-- more logic if needed here; different from just leaving fac
end

PLAYER.KickFromFaction = Factions.KickOut

hook.Add("PlayerInfoDestroy", "FactionDisband", function(pin)
	local fac = pin:GetFaction()
	if not fac then return end

	if fac:GetOwnerInfo() == pin then
		fac:ChangeOwnership()
	end
end)

hook.NHAdd("PlayerDisconnected", "FactionClean", function(ply)
	local fac = GetPlayerInfoGuarantee(ply):GetFaction()
	if not fac then return end

	fac:CleanMember(ply)
end)

local function throwError(ply, uid, lang)
	lang = lang or Factions.Errors.Generic
	net.Start("Factions")
		net.WriteUInt(10, 4)
		net.WriteUInt(uid, 8)
		net.WriteBool(false)
		lang:Write()
	net.Send(ply)
end

local function throwSuccess(ply, uid)
	net.Start("Factions")
		net.WriteUInt(10, 4)
		net.WriteUInt(uid, 8)
		net.WriteBool(true)
	net.Send(ply)
end

net.Receive("Factions", function(_, ply)

	local mode = net.ReadUInt(4)
	local reqID

	if mode == Factions.CREATE then
		-- Creating a faction
		reqID = net.ReadUInt(8)
		local name = net.ReadString()
		local pw = net.ReadString()
		local col = net.ReadColor()

		name = name:gsub("%c", "")
		pw = pw:gsub("%c", "")
		col.a = 255

		local can, err = facs.CanCreate(name, pw, col, ply)
		if not can then
			throwError(ply, reqID, err)
			--[[if ply.canCreateFacCD and CurTime() - ply.canCreateFacCD < 1 then return end
			ply:ChatAddText(Color(220, 75, 75), "Failed to create faction!\n", err)
			ply.canCreateFacCD = CurTime()]]
			return
		end

		Factions.CreateFac(ply, name, pw, col)
		throwSuccess(ply, reqID)
	elseif mode == Factions.LEAVE then
		reqID = net.ReadUInt(8)

		-- Leaving a faction
		local can, err = facs.CanLeave(ply)
		if not can then
			throwError(ply, reqID, err)
			return
		end

		Factions.LeaveFac(ply)
		throwSuccess(ply, reqID)

	elseif mode == Factions.JOIN then
		-- Joining a faction
		reqID = net.ReadUInt(8)

		local id = net.ReadUInt(24)
		local has_pw = net.ReadBool()
		local pw

		if has_pw then pw = net.ReadString() end

		local ok, why = Factions.JoinFac(ply, id, pw)

		if ok == false then
			throwError(ply, reqID, why)
		else
			throwSuccess(ply, reqID)
		end

	elseif mode == Factions.KICK then
		-- Kicking a faction member

		local whomst = net.ReadEntity()
		if not IsPlayer(whomst) then return end

		if ply:GetFaction() ~= whomst:GetFaction() then
			errorf("%s (%s) attempted to kick %s (%s) from a faction they are not in.", ply:Nick(), ply:SteamID64(), whomst:Nick(), whomst:SteamID64())
			return
		end

		if ply:GetFaction():GetOwner() ~= ply then
			errorf("%s (%s) attempted to kick %s (%s) despite not being the leader.", ply:Nick(), ply:SteamID64(), whomst:Nick(), whomst:SteamID64())
			return
		end

		whomst:KickFromFaction()
	end

end)

hook.NHAdd("PlayerInitialSpawn", "FactionNetwork", function(ply)
	Factions.FullUpdate()
end)

function Factions.FullUpdate()
	Factions.Validate()

	net.Start("Factions")
		net.WriteUInt(1, 4)
		net.WriteUInt(table.Count(Factions.Factions), 16)
		for k,v in pairs(Factions.Factions) do
			net.WriteUInt(v.id, 24)
			net.WriteString(v.name)
			net.WriteColor(v.col)

			local haspw = false
			if v.pw then haspw = true end
			net.WriteBool(haspw)
		end
	net.Broadcast()
end


Factions.FullUpdate()

function PLAYER:IsFacmate(ply2)
	return Factions.Players[self] == Factions.Players[ply2]
end

function PLAYER:FactionMembers()
	return (not self:GetFaction() and {self}) or (self:GetFaction() and self:GetFaction().memvals)
end


hook.Add("PlayerInfoDestroy", "FactionRemove", function(pin)
	if pin:GetFaction() then
		pin:GetFaction():RemovePlayer(pin)
	end
end)