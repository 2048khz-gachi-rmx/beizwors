local raid = Raids

local raidmeta = raid.RaidMeta or Emitter:callable()
raid.RaidMeta = raidmeta
raid.Participants = raid.Participants or {}

local function pID(ply)
	return (ply:IsBot() and "BOT:" .. ply:UserID()) or ply:SteamID64() -- ugh
end

function raidmeta:AddParticipant(obj, side)

	if IsFaction(obj) then
		for k, ply in ipairs(obj:GetMembers()) do
			local pid = pID(ply)

			raid.Participants[ply] = self
			raid.Participants[pid] = self
			if side then
				self.Participants[ply] = side
				self.Participants[pid] = side
			end
		end

	elseif IsPlayer(obj) then
		local pid = pID(obj)
		raid.Participants[pid] = self
		if side then
			self.Participants[pid] = side
		end
	end

	raid.Participants[obj] = self
	if side then
		self.Participants[obj] = side
	end
end

function raid.IsParticipant(obj)
	return raid.Participants[obj]
end

function raidmeta:IsParticipant(obj)
	return self.Participants[obj]
end

function raidmeta:IsRaider(obj)
	if IsPlayer(obj) or isstring(obj) then
		return self.Participants[obj] == 1
	end

	return self.Raider == obj
end

function raidmeta:IsRaided(obj)
	if IsPlayer(obj) or isstring(obj) then
		return self.Participants[obj] == 2
	end

	return self.Raided == obj
end

function raidmeta:GetParticipants()
	return self.Participants
end

function raidmeta:GetSide(obj)
	return self:IsParticipant(obj)
end

function raidmeta:GetID()
	return self.ID
end

function raidmeta:GetStart()
	return self.Start
end

function raidmeta:GetEnd()
	return self.Start + Raids.RaidDuration
end

function raidmeta:GetLeft()
	return self:GetEnd() - CurTime()
end

function raidmeta:Stop()
	hook.Run("RaidStop", self)

	raid.OngoingRaids[self.ID] = nil

	for k,v in pairs(raid.Participants) do
		if v == self then
			raid.Participants[k] = nil
		end
	end
end

function raidmeta:Initialize(rder, rded, when, id, vsfac)
	self.ID = id
	self.Start = when
	self.Participants = {}
	print("intiailized", rder, rded)
	self:AddParticipant(rder, 1)
	self:AddParticipant(rded, 2)

	self.Raider = rder
	self.Raided = rded

	self.Faction = vsfac

	raid.OngoingRaids[id] = self

	if self:IsParticipant(LocalPlayer()) then raid.MyRaid = self end

	hook.Run("RaidStart", rder, rded, vsfac)
end