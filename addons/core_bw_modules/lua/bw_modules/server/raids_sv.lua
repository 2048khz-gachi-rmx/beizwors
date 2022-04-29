local PLAYER = debug.getregistry().Player

util.AddNetworkString("Raid")


local CurrentReply	-- only 1 active at a time, so...

BaseWars.Raid = BaseWars.Raid or {}
local raid = BaseWars.Raid

raid.Cooldowns = raid.Cooldowns or {}

local raidmeta = raid.RaidMeta or Emitter:callable()
raid.RaidMeta = raidmeta

raid.OngoingRaids = raid.OngoingRaids or {} 	--{[RaidID] = RaidMeta}
--raid.Participants : Participants as {[player/SID64/faction] = RaidMeta}

local log = Logger("BW-RaidsSV")
local function replyEveryone(accept, ns)

	local filt = RecipientFilter()
	filt:AddAllPlayers()
	if CurrentReply then
		filt:RemovePlayer(CurrentReply.Owner)
	end

	net.Start("Raid")
		net.WriteBool(false)
		net.WriteNetStack(ns)
	net.Send(filt)

	if CurrentReply then
		filt:RemoveAllPlayers()
		filt:AddPlayer(CurrentReply.Owner)

		ns:SetMode("a")
		ns:SetCursor(1)
		CurrentReply:Reply(accept, ns)

		net.Start("Raid")
			net.WriteBool(true)
			net.WriteNetStack(ns)
		net.Send(filt)
	end

	return ns
end

local function replySender(accept, ns)
	if not CurrentReply then print("no current reply!!!") return end

	if ns then
		ns:SetMode("a")
		ns:SetCursor(1)

		CurrentReply:Reply(accept, ns)

		net.Start("Raid")
			net.WriteBool(true)
			net.WriteNetStack(ns)
		net.Send(CurrentReply.Owner)
	else
		CurrentReply:ReplySend("Raid", accept)
	end

	return ns
end

local function Date()
	local ts = os.time()
	local date = os.date( "%H:%M:%S - %d.%m.%Y" , ts )
	return date
end

local function Time()
	local ts = os.time()
	local date = os.date( "%H:%M:%S" , ts )
	return date
end

function raidmeta:AddParticipant(obj, side)
	assert(isnumber(side))

	if IsPlayer(obj) then
		obj = GetPlayerInfo(obj) or obj
	end

	if IsPlayerInfo(obj) then
		obj:InsertByID(raid.Participants, self)

		if side then
			obj:InsertByID(self.Participants, side)
		end
		obj:SetRaid(self)

	elseif IsFaction(obj) then
		for k, ply in ipairs(obj:GetMembers()) do
			local pin = ply:GetPInfo()
			self:AddParticipant(pin, side)
		end

		raid.Participants[obj] = self

		if side then
			self.Participants[obj] = side
		end
	end

end

-- obj = Player, SteamID64 or Faction

-- returns the Raid object `obj` is participating in (or nil)
function raid.IsParticipant(obj)
	return raid.Participants[obj]
end

-- returns true if `obj` is participating in this Raid
function raidmeta:IsParticipant(obj)
	if self.Faction then
		if IsPlayer(obj) then return self.Raider:IsMember(obj) or self.Raided:IsMember(obj) end
		return obj == self.Raider or obj == self.Raided
	else
		return self.Raider == obj or self.Raided == obj
	end
end

-- returns true if `obj` is on the Raider side in this Raid
function raidmeta:IsRaider(obj)
	if self.Participants[obj] then
		return self.Participants[obj] == 1
	end

	return self.Raider == obj
end

-- returns true if `obj` is on the Raided side in this Raid
function raidmeta:IsRaided(obj)
	if self.Participants[obj] then
		return self.Participants[obj] == 2
	end

	return self.Raided == obj
end

function raidmeta:GetParticipants()
	return self.Participants
end

function raidmeta:GetSide(obj)
	if IsFaction(obj) and self:IsParticipant(obj) then
		return self:IsRaider(obj) and 1 or 2
	end

	return self.Participants[obj]
end

function raidmeta:IsValid()
	return self._Valid ~= false
end

function raidmeta:Initialize(rder, rded, fac)
	if not IsPlayer(rder) and not IsFaction(rder) then
		errorf("bad argument #1 (expected player or faction, got %s instead)", type(rder))
		return
	end

	if not IsPlayer(rded) and not IsFaction(rded) then
		errorf("bad argument #2 (expected player or faction, got %s instead)", type(rded))
		return
	end

	self.Start = CurTime()

	self.Raider = rder
	self.Raided = rded

	self.Faction = fac
	self._Valid = true

	local id = uniq.Seq("raid", 16)

	raid.OngoingRaids[id] = self
	self.ID = id

	self.Participants = {}

	self:AddParticipant(rder, 1)
	self:AddParticipant(rded, 2)


	hook.NHRun("RaidStart", self, rder, rded, fac)
end

function IsRaid(obj)
	return getmetatable(obj) == raidmeta
end

function raidmeta:GetID()
	return self.ID
end

function raidmeta:Stop()

	hook.Run("RaidStop", self)
	self:Emit("Stop")

	local parts = self:GetParticipants()

	for k,v in pairs(parts) do
		if string.IsSteamID(k) and self:IsRaided(k) then
			local pin = GetPlayerInfo(k)
			if pin then
				pin:SetRaidCD()
			end
		end
	end

	self._Valid = false

	-- remove everything that mentions this raid in raid.Participants
	for k,v in pairs(raid.Participants) do
		if v == self then
			raid.Participants[k] = nil
		end
	end

	for k,v in pairs(raid.OngoingRaids) do
		if v == self then
			raid.OngoingRaids[k] = nil
			break
		end
	end

	local ns = netstack:new()
	ns:WriteUInt(3, 4)
	ns:WriteUInt(self:GetID(), 16)

	replyEveryone(true, ns)
end

PLAYER.PutOnRaidedCooldown = PLAYER.SetRaidCD

function PLAYER:PutOffRaidedCooldown()
	self:GetPInfo():SetRaidCD(0)
end

hook.NHAdd("PlayerInitialSpawn", "BeginCooldown", function(ply)
	local onCD = ply:GetRaidCD()

	if not onCD then
		-- put them on CD until they fully load in
		local putOff = false

		hook.ObjectOnce("PlayerFullyLoaded", ply, 1, function(...)
			if not putOff then
				ply:PutOffRaidedCooldown()
				putOff = true
			end
		end)

		ply:PutOnRaidedCooldown(120)	-- i give you 120 seconds to load in bud

		ply:Timer("JoinRaidProtection", 120, function()
			if not putOff then
				ply:PutOffRaidedCooldown()
				putOff = true
			end
		end)
	end
end)

function PLAYER:GetRaid()
	local fac = self:GetFaction()
	return raid.Participants[self] or (fac and raid.Participants[fac])
end

function PLAYER:IsRaided()
	local raidObj = self:GetRaid()
	if not raidObj then return false end

	return raidObj:IsRaided(self)
end

function PLAYER:IsRaider()
	local raidObj = self:GetRaid()
	if not raidObj then return false end

	return raidObj:IsRaider(self)
end

function PLAYER:GetSide()
	local rd = self:GetRaid()
	if not rd then return false end

	return rd:GetSide(self)
end


function PLAYER:IsEnemy(ply2)
	return GetPlayerInfoGuarantee(self):IsEnemy(GetPlayerInfoGuarantee(ply2))
end


function raid.Stop(obj) -- obj = player, sid64 or faction
	local raidObj = IsRaid(obj) and obj or raid.IsParticipant(obj)
	if not raidObj then return end

	raidObj:Stop()
end

function PLAYER:StopRaid()
	local rd = raid.IsParticipant(self)
	if rd then
		rd:Stop()
	end
end

local cdf = "Target is on cooldown!\n(%ds. remaining)"


function raid.TryStart(caller, rder, rded, fac)
	local oncd, rem = rded:RaidedCooldown()
	if oncd then  return false, cdf:format(rem) end

	if raid.IsParticipant(rder) then
		return false, raid.PickRaidedError(rder, rded)
	end

	if raid.IsParticipant(rder) then
		return false, raid.Errors.YouAreRaiding
	end

	local rderCan, rderWhy = rder:IsRaidable(false)
	if not rderCan then return false, raid.Errors.YouAreUnraidable(rderWhy) end

	local rdedCan, rdedWhy = rded:IsRaidable(caller)
	if not rdedCan then return false, raid.Errors.TargetUnraidable(rdedWhy) end

	return raid.Start(rder, rded, fac)
end

function raid.Start(rder, rded, fac)

	local ns = netstack:new()

	if fac then
		local rtbl = raidmeta:new(rder, rded, fac)

		ns:WriteUInt(2, 4)
		ns:WriteUInt(rder.id, 24)
		ns:WriteUInt(rded.id, 24)
		ns:WriteFloat(rtbl.Start)
		ns:WriteUInt(rtbl:GetID(), 16)

		replyEveryone(true, ns)

		return rtbl
	end

	local rtbl = raidmeta:new(rder, rded, fac)

	rder:SetNWBool("Raided", true)
	rded:SetNWBool("Raided", true)

	ns:WriteUInt(1, 4)
	ns:WriteUInt(rder:UserID(), 24)
	ns:WriteUInt(rded:UserID(), 24)
	ns:WriteFloat(rtbl.Start)
	ns:WriteUInt(rtbl:GetID(), 16)

	replyEveryone(true, ns)


	return rtbl
end


hook.NHAdd("PlayerDisconnected", "RaidLog", function(ply) --aiaiai
	--[[local rd = ply:GetRaid()
	if not rd then return end

	local plys = {}

	for k, side in pairs(rd:GetParticipants()) do
		if IsPlayer(k) and rd:IsRaider(k) then
			plys[#plys + 1] = k
		end
	end

	if #plys == 1 then	-- every raider left; stop the raid
		rd:Stop()
		return
	end]]
end)

function PLAYER:IsRaidable()
	local can, err = hook.Run("IsPlayerRaidable", self)
	if can == false then return can, err end

	-- todo: move this V to a hook
	-- if self:GetLevel() < 75 then return false, raid.Errors.LowLevelPlayer end

	for _, ent in ipairs(BaseWars.Ents.GetOwnedBy(self)) do
		if ent.IsValidRaidable then return true end
	end

	return false, raid.Errors.NoRaidables
end

hook.Add("PlayerSpawnObject", "RaidPropsPrevent", function(ply, mdl, skin)
	if ply:InRaid() then return false end
end)

hook.Add("CanTool", "RaidToolsPrevent", function(ply)
	if ply:InRaid() then return false end
end)

function ReportFail(ply, err)
	local ns = netstack:new()
	ns:WriteString(tostring(err))
	replySender(false, ns)

	CurrentReply = nil
end

local CURRENT_PLAYER

local function check(ok, err)
	if not ok then
		ReportFail(CURRENT_PLAYER, err)
		CURRENT_PLAYER = nil
		return false
	end

	return true
end

net.Receive("Raid", function(_, ply)
	local pr = net.ReplyPromise(ply)

	CurrentReply = pr
	local mode = net.ReadUInt(4)
	--1 = start vs. player
	--2 = start vs. fac
	--3 = concede
	print('Received raid request, mode', mode)

	CURRENT_PLAYER = ply

	if mode == 1 then
		local ent = net.ReadEntity()
		if not IsPlayer(ent) then return end

		check(raid.CanGenerallyRaid(ply, true))
		check(raid.CanRaidPlayer(ply, ent))
		check(raid.TryStart(ply, ply, ent, false))

	elseif mode == 2 then
		local facID = net.ReadUInt(24)

		local fac2 = Factions.GetFaction(facID)

		if not check(raid.CanGenerallyRaid(ply, false)) then return end
		if not check(raid.CanRaidFaction(ply, fac2)) then return end

		local fac1 = ply:GetFaction()

		if fac1:InRaid() or fac2:InRaid() then
			ReportFail(ply, "That faction is in a raid already!")
			return
		end

		print("Mode 2; starting raid(?)")
		local ok, err = raid.TryStart(ply, ply:GetFaction(), fac2, true)
		print(ok, "yes")
		if not ok then
			print("returning no", err)
			ReportFail(ply, err, pr)
		end

	elseif mode == 3 then
		-- these aren't usual, so no need to get all fancy with localization
		if not raid.Participants[ply] then
			ReportFail(false, "yo youre not even participating")
			return false
		end
		if ply:IsRaided() then
			ReportFail(false, "yo youre not even the raider")
			return false
		end --do not accept concedes from raided

		if ply:IsRaider() then
			raid.Stop(ply)
		end
	end

	CURRENT_PLAYER = nil
	CurrentReply = nil
end)

hook.Add("Think", "RaidsThink", function()
	for k,v in pairs(raid.OngoingRaids) do
		if CurTime() - v.Start > raid.RaidDuration then
			raid.Stop(v)
		end
	end
end)

hook.Remove("PlayerSpawn", "RaidsSpawn")
hook.Remove("PlayerDeathThink", "RaidsDeath")

--[==================================[
		   Raid Damage Logic
--]==================================]

function raid.CanDealDamage(ply, ent, infl, dmg)
	if not IsPlayer(ply) then return end -- non-players dealing damage is not our domain
	if ent:IsNPC() or ent:IsNextBot() then return end

	if IsPlayer(ent) then
		return raid.CanDealDamagePlayer(ply, ent, infl, dmg)
	end

	local ow = ent:BW_GetOwner()

	if ow and not IsPlayerInfo(ow) then
		-- owner is world
		if ent:CreatedByMap() then
			return true -- can break map stuff
		end

		return false -- might change?
	end

	if IsPlayerInfo(ow) then
		if not ow:IsValid() then return true end -- idk, deal damage to invalid owner's stuff. see if i care.
		if ent.AlwaysRaidable then return true end -- always raidable = always damageable

		if ow == GetPlayerInfo(ply) and not raid.IsParticipant(ply) then
			return true -- self-damage allowed outside of raids
		end

		local rd = raid.IsParticipant(ply)
		local rd2 = raid.IsParticipant(ow)

		if rd and rd2 and -- in raid?
			rd == rd2 and rd:IsRaider(ply) and rd:IsRaided(ow) then
			if not ent.IsBaseWars then
				dmg:ScaleDamage(BaseWars.Config.Raid_BulletPropDamage)
			end

			local can = hook.Run("BW_CanDealRaidDamage", ply, ent, infl, dmg) ~= false
			return can -- raider -> raided allowed
		end
	end

	return false -- basewars ents cant get damaged outside of this
end

function raid.CanBlowtorch(ply, ent, wep, dmg)
	local ow = ent:BW_GetOwner()

	if not IsPlayerInfo(ow) then
		return false -- cant blowtorch anything unowned or world prop'd
	end

	if not ow:IsValid() then return false end -- see raid.CanDealDamage
	if ent.AlwaysRaidable then return false end

	if ow == GetPlayerInfo(ply) then
		return true
	end


	local rd = raid.IsParticipant(ply)
	local rd2 = raid.IsParticipant(ow)

	if rd and rd2 and -- in raid?
		rd == rd2 and rd:IsRaider(ply) and rd:IsRaided(ow) then
		local can = hook.Run("BW_CanBlowtorch", ply, ent, wep, dmg) ~= false
		return can -- raider -> raided allowed
	else
		return hook.Run("BW_CanBlowtorchRaidless", ply, ent, wep, dmg)
	end

end

function raid.CanDealDamagePlayer(ply, vict, infl, dmg)
	if not ply:InRaid() and not vict:InRaid() then return end

	local r1, r2 = ply:InRaid(), vict:InRaid()

	if r1 and not r2 then
		-- raider attacks non-raider: start duel
		return raid.RaidDuelRaider(ply, vict, infl, dmg)
	elseif r2 and not r1 then
		-- non-raider attacks raider: check for a duel
		return raid.RaidDuelNonRaider(ply, vict, infl, dmg)
	end

	-- raider and raider
	if ply:IsEnemy(vict) then
		return true
	end
end

--[==================================[
			  Raid Duels
--]==================================]

function raid.RaidDuelRaider(rder, rded, infl, dmg)
	local last = rder.DuelChallenged and rder.DuelChallenged[rded]
	rder.DuelChallenged = rder.DuelChallenged or {}
	-- 10s with no damage dealt = duel abort
	-- 1st time is start time, 2nd is time since last damage apply
	rder.DuelChallenged[rded] = rder.DuelChallenged[rded] or {CurTime(), CurTime()}

	if not last or CurTime() - last[1] < 0.5 then
		return false -- some time between getting shot and damage starting to go through
	end

	if CurTime() - rder.DuelChallenged[rded][2] > 10 then
		-- 10s passed with no damage; reset duel state
		rder.DuelChallenged[rded] = {CurTime(), CurTime()}
		return false
	end

	rder.DuelChallenged[rded][2] = CurTime()
end

function raid.RaidDuelNonRaider(rded, rder, infl, dmg)
	-- raider never shot the attacker; disallow damage
	if not rder.DuelChallenged or not rder.DuelChallenged[rded] then
		return false
	end
	local dat = rder.DuelChallenged[rded]

	if CurTime() - dat[1] < 0.5 then
		return false -- some time between getting shot and damage starting to go through
	end

	if CurTime() - dat[2] > 10 then
		-- 10s passed with no damage; reset duel state
		rder.DuelChallenged[rded] = nil
		return false
	end

	dat[2] = CurTime() -- allow damage, reset timer
end

hook.Add("PlayerDeath", "RaidDuels", function(ply, infl, atk)
	ply.DuelChallenged = nil
	if IsPlayer(atk) and atk.DuelChallenged then
		atk.DuelChallenged[ply] = nil
	end
end)



local sidToDiscord = {
	["STEAM_0:1:504566785"] = "244148600110579712",
	["STEAM_0:0:40277849"] = "276279540056195074"
}

function doRaidNotify(rd)
	local rded = {}
	local rders = {}

	for k,v in pairs(rd:GetParticipants()) do
		if IsPlayer(k) and k:IsBot() then return end -- dont notify debug raids

		if string.IsSteamID(k) and rd:IsRaided(k) then
			if sidToDiscord[k] then
				table.insert(rded, "<@" .. sidToDiscord[k] .. ">")
			else
				local pin = GetPlayerInfo(k)
				table.insert(rded, discord.Escape(pin:Nick()))
			end
		elseif IsPlayerInfo(k) and rd:IsRaider(k:SteamID()) then
			local ins = discord.Escape(k:Nick())
			if sidToDiscord[k:SteamID()] then
				ins = ins .. (" (<@" .. sidToDiscord[k:SteamID()] .. ">)")
			end

			table.insert(rders, ins)
		end

	end

	local fmt = "%s started a raid on %s!"
	discord.SendUnescaped("raids", "Raid Notifier",
		fmt:format(table.concat(rders, ", "), table.concat(rded, ", ")))
end

hook.NHAdd("RaidStart", "DiscordNotify", function(rd, rder, rded, fac)
	doRaidNotify(rd)
end)