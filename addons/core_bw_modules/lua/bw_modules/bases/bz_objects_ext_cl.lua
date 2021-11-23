-- placeholder

local bw = BaseWars.Bases

local waitingEnts = {}
bw.EntIDToBase = bw.EntIDToBase or {}

hook.Add("NotifyShouldTransmit", "BWBaseEntityList", function(ent, enter)
	local eid = ent:EntIndex()
	local base = waitingEnts[eid]

	if enter and base and base:IsValid() then
		base:EntityEnter(ent)
		waitingEnts[eid] = nil
	end
end)

local function indexer(nm, base)
	return function(...)
		return bw.Base[nm] (...)
	end
end

function bw.Base:GetEntities()
	-- you can't get entities of a base you don't own
	if not self:IsOwner(LocalPlayer()) then return {} end

	return self.Entities
end

function bw.Base:GetPlayers()
	if not self:IsOwner(LocalPlayer()) then return {} end
	return self.Players
end

function bw.Base.PubNetworkedChanged(self, changes)
	--print("pub network change", self:Get("ClaimedBy"))
	local base = self.Base
	if self:Get("ClaimedBy") then
		base:SetClaimed(true)

		if not IsPlayerInfo(self:Get("ClaimedBy")) and self:Get("ClaimedFaction") == false then
			-- assume ClaimedBy is a steamid64, make it a playerinfo
			self:Set( "ClaimedBy", GetPlayerInfoGuarantee(self:Get("ClaimedBy"), true) )
		elseif not IsFaction(self:Get("ClaimedBy")) and self:Get("ClaimedFaction") == true then
			-- assume ClaimedBy is a faction ID, make it into a faction
			self:Set( "ClaimedBy", Factions.GetFaction(self:Get("ClaimedBy")) )
		end
		hook.Run("BaseClaimed", base)
	else
		--print("base now unclaimed; also unclaiming", self:Get("ClaimedBy"))
		base:SetClaimed(false)
		base:Emit("Unclaim")
		hook.Run("BaseUnclaimed", base)
	end
end

function bw.Base:EntNetworkedChanged(changes)
	-- self is entity nw

	local base = self.Base
	for entID, change in pairs(changes) do
		local old, new = change[1], change[2]

		local ent = Entity(entID)

		if not ent:IsValid() then
			if new then
				waitingEnts[entID] = base
				bw.EntIDToBase[entID] = base
				continue
			else
				bw.EntIDToBase[entID] = nil
				for k,v in pairs(base.Entities) do
					if v == entID then
						base.Entities[k] = nil	-- i can't believe i have to do this
						continue
					end
				end
			end
		end

		if not old and new then
			base:EntityEnter(ent)
			bw.EntIDToBase[ent:EntIndex()] = base
		elseif old and not new then
			base:EntityExit(ent)
			bw.EntIDToBase[ent:EntIndex()] = nil
		end
	end

end

function bw.Base:_PostInit()
	local pub = self.PublicNW
	local priv = self.OwnerNW
	local entNW = self.EntsNW

	local base = self

	pub:On("NetworkedChanged", "GetPlayerInfo", indexer("PubNetworkedChanged"))
	entNW:On("NetworkedChanged", "GetEntitiesInfo", indexer("EntNetworkedChanged"))

end

function bw.Base:GetOwner()
	-- return #1: faction or nil
	-- return #2: table of playerinfo(s)
	local pub = self.PublicNW
	local claimed = pub:Get("Claimed")
	if not claimed then return false, false end

	local by = pub:Get("ClaimedBy")
	local fac = pub:Get("ClaimedFaction")

	if fac and IsFaction(by) then
		return by, by:GetMembersInfo()
	else
		return false, {by}
	end
end

function bw.Base:GetOwnerFaction()
	local pub = self.PublicNW
	local fac = pub:Get("ClaimedFaction")
	if fac then
		return pub:Get("ClaimedFaction")
	end

	return false
end

bw.Base.IsFactionOwned = bw.Base.GetOwnerFaction

function bw.Base:IsOwner(what)
	local pub = self.PublicNW

	local by = pub:Get("ClaimedBy")
	local fac = pub:Get("ClaimedFaction")

	if fac then
		return by == what or by:IsMember(what)
	else
		if IsFaction(what) then return false end
		return by == GetPlayerInfo(what)
	end
end


function bw.Base:_Ready()
	if self._Ready then return end

	self:Emit("Ready")
	hook.Run("BaseReceived", self)
	self._Ready = true
end

function bw.Base:_OnReady()
	local cores = ents.FindByClass("bw_basecore") 	-- find all cores on the map; any cores that enter PVS
													-- will be handled by NotifyShouldTransmit
	for k,v in ipairs(cores) do
		-- TODO:  THE BASE CAN LACK THE BASECLASS TABLE
		-- MEANING GETBASE WONT EXIST! THANKS GMOD

		local base = v:GetBase()
		if base == self then
			self:SetBaseCore(v)

			-- a base is only ready if it has a core assigned to it as well
			self:_Ready()
			break
		end
	end
end
