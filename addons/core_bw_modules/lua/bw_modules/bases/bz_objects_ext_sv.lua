local bw = BaseWars.Bases

hook.Add("FactionDisbanded", "BaseListen", function(fac)
	for k, base in pairs(bw.Bases) do
		local owfac, ows = base:GetOwner()
		if owfac == fac then
			base:Unclaim()

			if IsValid(fac:GetOwnerInfo()) then
				base:Claim(fac:GetOwnerInfo())
			end
		end
	end
end)

hook.Add("PlayerInfoDestroy", "BaseUnclaim", function(pin)
	for k, base in pairs(bw.Bases) do
		local fac, owners = base:GetOwner()
		if fac then continue end -- fac unclaims are handled by destroying the faction

		if owners[1] == pin then
			base:Unclaim()
		end
	end
end)

function bw.Base:AttemptClaim(by, ply)
	self:_CheckValidity()

	if not self:CanClaim(by, ply) then return false end

	if IsFaction(by) then
		if by:GetBase() then return false end
	else
		local info = by:GetPInfo()
		if info:GetBase() then return false end
	end

	return self:Claim(by)
end

function bw.Base:SaveData()
	local json = util.TableToJSON(self:GetData())
	local a, err = bw.SQL.SaveData(self:GetID(), json)

	if err then
		print("error:", err)
		return
	end
end

function bw.Base:AddData(k, v)
	self.Data[k] = v
	self:SaveData()
end

function bw.Base:Claim(by)
	self:_CheckValidity()

	if self:GetClaimed() then
		self:Unclaim(true)
	end

	self.PublicNW:Set("Claimed", true)

	if IsFaction(by) then
		self.Owner.Faction = by
		self.Owner.Player = nil

		by:SetBase(self)

		self.PublicNW:Set("ClaimedFaction", true)
		self.PublicNW:Set("ClaimedBy", by:GetID())

	elseif IsPlayer(by) or IsPlayerInfo(by) then
		local pinfo = GetPlayerInfoGuarantee(by)
		pinfo:SetBase(self)

		self.Owner.Faction = nil
		self.Owner.Player = pinfo

		self.PublicNW:Set("ClaimedFaction", false)
		self.PublicNW:Set("ClaimedBy", pinfo:GetSteamID64())
	end

	self:SetClaimed(true)
	self:Emit("Claim")
	self:UpdateNW()
	hook.NHRun("BaseClaimed", self, IsFaction(by) and by or GetPlayerInfo(by))

	return true
end

hook.Add("FactionCreated", "BWBaseOwnership", function(ply, fac)
	local base = GetPlayerInfo(ply):GetPlayerBase(true)

	if base and base:IsValid() then
		base:Claim(fac)
	end
end)

function bw.Base:AttemptUnclaim(by)
	self:_CheckValidity()
	if not self:CanUnclaim(by) then return false end
	return self:Unclaim()
end

function bw.Base:Unclaim(temporarily)
	self:_CheckValidity()

	if not self:GetClaimed() then
		errorf("Tried to unclaim an unclaimed base!")
		return
	end

	local prev = self.Owner.Player or self.Owner.Faction

	self.Owner.Faction = nil
	self.Owner.Player = nil

	self.PublicNW:Set("Claimed", false)

	if not temporarily then
		self:SetClaimed(false)

		self.PublicNW:Set("ClaimedFaction", false)
		self.PublicNW:Set("ClaimedBy", nil)

		self:Emit("Unclaim")
		hook.NHRun("BaseUnclaimed", self, prev)

		self:UpdateNW()
	end
end

function bw.Base:Spawn()
	local dat = self:GetData()
	if dat.AIEntrance then AIBases.SpawnBase(self) return end

	if dat.BaseCore then self:SpawnCore() end
end

function bw.Base:SpawnCore()
	local dat = self:GetData()
	if not dat.BaseCore then return end

	local bc = dat.BaseCore
	local pos, ang, mdl = bc.pos, bc.ang, bc.mdl

	if not isvector(pos) or not isangle(ang) or not util.IsValidModel(mdl) then
		errorf("Invalid data for base's basecore spawn.\
	Position: %s (valid: %s)\
	Angle: %s (valid: %s)\
	Model: %s (valid: %s)",
			tostring(pos), isvector(pos),
			tostring(ang), isangle(ang),
			tostring(mdl), util.IsValidModel(mdl))
	end

	local prevCore = IsValid(self:GetBaseCore()) and self:GetBaseCore()
	local core = prevCore or ents.Create("bw_basecore")
	core:SetPos(pos)
	core:SetAngles(ang)

	if not prevCore then
		core:Spawn()
	end

	self:AddToNW()

	core:SetBase(self)
	core:SetModel(mdl)

	self:SetBaseCore(core)
end

-- This filter is used in multiple places
function bw.Base.OwnerNWFilter(nw, ply)
	local self = nw.Base
	return self:IsOwner(ply)
end

function bw.Base:GetOwner()
	self:_CheckValidity()

	-- return #1: faction or nil
	-- return #2: table of playerinfo(s)
	local fac = self:GetOwnerFaction()
	local plys = fac and fac:GetMembersInfo() or {self.Owner.Player}

	return fac, plys
end

function bw.Base:GetOwnerFaction()
	self:_CheckValidity()

	return self.Owner.Faction
end

bw.Base.IsFactionOwned = bw.Base.GetOwnerFaction

function bw.Base:GetOwnerPlayer()
	self:_CheckValidity()
	return self.Owner.Player
end

function bw.Base:IsOwner(what)
	assert(IsPlayer(what) or isstring(what) or IsPlayerInfo(what) or IsFaction(what))

	self:_CheckValidity()

	local fac, infos = self:GetOwner()

	if IsFaction(what) then
		return fac == what
	else
		local pin = GetPlayerInfo(what)
		for k,v in ipairs(infos) do
			if v == pin then return true end
		end

		return false
	end
end

function bw.Zone:RescanEnts()
	if not IsValid(self:GetBrush()) then return end
	self:GetBrush():ForceScanEnts()
end

bw.Zone.ForceScanEnts = bw.Zone.RescanEnts

ChainAccessor(bw.Zone, "Brush", "Brush")

hook.Add("BWBasesLoaded", "BrushRescan", function()
	for k,v in pairs(bw.Zones) do
		v:RescanEnts()
	end
end)