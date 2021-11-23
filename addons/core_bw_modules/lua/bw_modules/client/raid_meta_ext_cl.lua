local raid = Raids

local raidmeta = raid.RaidMeta or Emitter:callable()
raid.RaidMeta = raidmeta

local function pID(ply)
	return (ply:IsBot() and "BOT:" .. ply:UserID()) or ply:SteamID64() -- ugh
end

function raidmeta:__tostring()
	return ("Raid [%d_%s][%.1f]"):format(self:GetID(),
		self.Faction and "fac" or "nonfac",
		self:GetLeft())
end

function raidmeta:AddParticipant(obj, side)
	assert(isnumber(side))

	if IsFaction(obj) then
		for k, ply in ipairs(obj:GetMembersInfo()) do
			local pin = GetPlayerInfoGuarantee(ply)

			pin:InsertByID(raid.Participants, self)

			if side then
				pin:InsertByID(self.Participants, side)
			end
			pin:SetRaid(self)
		end

	elseif IsPlayer(obj) then
		local pin = GetPlayerInfoGuarantee(obj)
		pin:InsertByID(raid.Participants, self)
		if side then
			pin:InsertByID(self.Participants, side)
		end
		pin:SetRaid(self)
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
	if self.Participants[obj] then
		return self.Participants[obj] == 1
	end

	return self.Raider == obj
end

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

function raidmeta:IsValid()
	return self._Valid ~= false
end

function raidmeta:Stop()
	hook.Run("RaidStop", self)

	self:Emit("Stop")
	self._Valid = false
	raid.OngoingRaids[self.ID] = nil

	for k,v in pairs(raid.Participants) do
		if v == self then
			raid.Participants[k] = nil
		end
	end
end

function raidmeta:GetSides()
	return self.Raider, self.Raided, self.Faction
end

function raidmeta:Initialize(rder, rded, when, id, vsfac)
	self.ID = id
	self.Start = when
	self.Participants = {}

	self:AddParticipant(rder, 1)
	self:AddParticipant(rded, 2)

	self.Raider = rder
	self.Raided = rded

	self.Faction = vsfac
	self._Valid = true

	raid.OngoingRaids[id] = self

	if self:IsParticipant(LocalPlayer()) then
		raid.MyRaid = self
	end

	hook.NHRun("RaidStart", self, rder, rded, vsfac)
end