local bw = BaseWars.Bases

bw.CanModify = function(ply)
	return ply:IsAdmin()
end

bw.MaxBaseNameLength = 120
bw.MinBaseNameLength = 2

bw.MaxZoneNameLength = 120
-- zones don't have a minimum name requirement; they can be unnamed

ChainAccessor(bw.Base, "ID", "ID")
ChainAccessor(bw.Zone, "ID", "ID")

ChainAccessor(bw.Base, "Data", "Data")
ChainAccessor(bw.Zone, "Data", "Data")

function bw.Zone:__tostring()
	return ("BWZone [%d][%s]"):format(self:GetID(), self:GetName())
end

function bw.Base:__tostring()
	return ("BWBase [%d][%s]"):format(self:GetID(), self:GetName())
end

function bw.GetZone(id)
	return BaseWars.Bases.Zones[id]
end

function bw.IsBase(what)
	return getmetatable(what) == bw.Base
end

function bw.IsZone(what)
	return getmetatable(what) == bw.Zone
end

--[[-------------------------------------------------------------------------
	Zone object
---------------------------------------------------------------------------]]

function bw.Zone:GetBounds()
	return self._Mins, self._Maxs
end

function bw.Zone:GetCenter()
	return self._Center
end

function bw.Zone:SetBounds(mins, maxs)
	CheckArg(1, mins, isvector, "zone mins")
	CheckArg(2, maxs, isvector, "zone maxs")

	OrderVectors(mins, maxs)

	local prevMin, prevMax = self._Mins, self._Maxs
	self._Mins, self._Maxs = mins, maxs

	self._Center = (mins + maxs)
	self._Center:Mul(0.5)

	self:Emit("BoundsChanged", prevMin, prevMax)
	return self
end

bw.Zone.DefaultColor = Color(91, 151, 147)
bw.Zone.PreviewColor = Color(243, 255, 78)

ChainAccessor(bw.Zone, "DefaultColor", "DefaultColor")

function bw.Zone:SetDefaultColor(col)
	if self.Color == self.DefaultColor then
		self.Color = col:Copy()
	end

	self.DefaultColor:Set(col)
end

function bw.Zone:_Validate()
	local id = self:GetID()
	if id < 0 then return false, "ID" end

	local mins, maxs = self:GetBounds()
	if not mins or not maxs then return false, "Bounds" end

	if BaseWars.Bases.Zones[id] then
		local oldZone = BaseWars.Bases.Zones[id]
		local base = oldZone:GetBase()

		if base then
			base:AddZone(self)
		end

		oldZone:Remove()
	end

	BaseWars.Bases.Zones[id] = self
	self._Valid = true

	return true
end

function bw.Zone:Validate(optional)
	local ok, why = self:_Validate()

	self._Valid = ok
	if not ok and not optional then
		errorf("bw.Zone:Validate() : %s were incorrect.", why)
		return
	end

end

function bw.Zone:SpawnBrush()
	self:_CheckValidity()

	self.Brush = ents.Create("bw_zone_brush")

	if not self.Brush:IsValid() then
		ErrorNoHalt("Failed to create a zone brush entity.\n")
		return
	end

	self.Brush:SetZone(self)
	self.Brush:Activate()
	self.Brush:Spawn()
end

function bw.Zone:Initialize(id, mins, maxs)
	CheckArg(1, id, isnumber, "zone ID")

	local valid = id >= 0
	-- use an id < 0 to create a fake zone
	if valid then
		CheckArg(2, mins, isvector, "zone mins")
		CheckArg(3, maxs, isvector, "zone maxs")
	end

	self:SetID(id)

	if valid then
		OrderVectors(mins, maxs)
		self:SetBounds(mins, maxs)
	end

	self.Data = {}
	self._ShouldPaint = false
	self._Name = ""
	self._Alpha = 0
	self:SetColor( self.DefaultColor:Copy() )

	self:Validate(CLIENT)

	self.Players = {}
	self.Entities = {}

	if SERVER and valid then
		self:SpawnBrush()
	end
end

function bw.Zone:Remove(baseless)
	if not self:IsValid() then return end

	-- call remove first, then invalidate
	self:Emit("Remove")
	bw:Emit("DeleteZone", self)

	if SERVER and self.Brush:IsValid() then
		self.Brush:Remove()
	end

	if not baseless and self:GetBase() then
		self:GetBase():RemoveZone(self)
	end

	BaseWars.Bases.Zones[self:GetID()] = nil
	bw.ZonePaints[self:GetID()] = nil

	self._Valid = false
end

ChainAccessor(bw.Zone, "_Name", "Name")
ChainAccessor(bw.Zone, "_Color", "Color")
ChainAccessor(bw.Zone, "_Alpha", "Alpha")

function bw.Zone:IsValid()
	return self._Valid and bw.Zones[self:GetID()] == self
end

function bw.Zone:GetBase()
	if not self.BaseID then return false end
	return BaseWars.Bases.Bases[self.BaseID]
end

function bw.Zone:EntityEnter(ent)
	self:_CheckValidity()

	self.Entities[ent] = ent:EntIndex()

	if IsPlayer(ent) then
		self.Players[ent] = ent:EntIndex()
	end
end

function bw.Zone:EntityExit(ent)
	self:_CheckValidity()

	self.Entities[ent] = nil

	if IsPlayer(ent) then
		self.Players[ent] = nil
	end
end

--[[-------------------------------------------------------------------------
	Base object
---------------------------------------------------------------------------]]

ChainAccessor(bw.Base, "BaseCore", "BaseCore")
ChainAccessor(bw.Base, "PowerGrid", "PowerGrid")
ChainAccessor(bw.Base, "PublicNW", "NW")
ChainAccessor(bw.Base, "PublicNW", "PublicNW")
ChainAccessor(bw.Base, "EntsNW", "EntsNW")
ChainAccessor(bw.Base, "OwnerNW", "OwnerNW")
ChainAccessor(bw.Base, "_Claimed", "Claimed")

function bw.Base:Initialize(id, json)
	CheckArg(1, id, isnumber, "base ID")

	self.ID = id

	self.Zones = {}			-- sequential table of zones
	self.ZonesByID = {}		-- [zone_id] = zone_obj

	self.Players = {}

	self.Entities = {}

	self.Data = {}

	self.PublicNW = Networkable("BasePub" .. id)

	local pubNW = self.PublicNW
		pubNW:Alias("Claimed", 0)
		pubNW:Alias("ClaimedBy", 1)
		pubNW:Alias("ClaimedFaction", 2)
		pubNW.Base = self
		pubNW:AddDependency(bw.NW.Bases)

	self.OwnerNW = Networkable("BasePriv" .. id)
		self.OwnerNW.Base = self
		self.OwnerNW.Filter = self.OwnerNWFilter
		self.OwnerNW:AddDependency(bw.NW.Bases)

	self.EntsNW = Networkable("BaseEnts" .. id)
		self.EntsNW.Base = self
		self.EntsNW.Filter = self.OwnerNWFilter
		self.EntsNW:AddDependency(bw.NW.Bases)

	self.PowerGrid = bw.PowerGrid:new(self)

	if BaseWars.Bases.Bases[id] then
		local old = BaseWars.Bases.Bases[id]
		BaseWars.Bases.Bases[id]:Remove(true)

		self.Owner = old.Owner
	else
		self.Owner = {
			Faction = nil,
			Player = nil
		}
	end

	if json and isstring(json) and SERVER then
		local t = json:FromJSON()
		if t then
			self.Data = t
			self:SpawnCore()
		end
	end

	self.Name = "-unnamed base-"
	self._Valid = true

	BaseWars.Bases.Bases[id] = self

	if self._PostInit then
		self:_PostInit()
	end

end

if SERVER then
	ChainAccessor(bw.Base, "Entities", "Entities")
	ChainAccessor(bw.Base, "Players", "Players")
end

ChainAccessor(bw.Zone, "Entities", "Entities")
ChainAccessor(bw.Zone, "Players", "Players")

function bw.Base:EntityEnter(ent)
	self:_CheckValidity()
	local _, enter = hook.NHRun("EntityEnterBase", self, ent)
	if SERVER and enter == false then return end

	self.Entities[ent] = ent:EntIndex()
	self.EntsNW:Set(ent:EntIndex(), true)

	if IsPlayer(ent) then
		self.Players[ent] = ent:EntIndex()
	end

	self:Emit("EntityEntered", ent)
	ent:Emit("EnteredBase", self)
	if ent.OnEnteredBase then
		ent:OnEnteredBase(self)
	end

	hook.NHRun("EntityEnteredBase", self, ent)
end

function bw.Base:EntityExit(ent)
	self:_CheckValidity()

	local _, exit = hook.NHRun("EntityExitBase", self, ent)

	if SERVER and exit == false and not ent:IsRemoving() then return end

	local eid = self.Entities[ent] or ent:EntIndex()
	self.Entities[ent] = nil
	self.EntsNW:Set(eid, nil)

	if IsPlayer(ent) then
		self.Players[ent] = nil
	end

	self:Emit("EntityExited", ent)
	ent:Emit("ExitedBase", self)
	if ent.OnExitedBase then
		ent:OnExitedBase(self)
	end

	hook.NHRun("EntityExitedBase", self, ent)
end


function bw.Base:Remove(replaced)
	self._Valid = false

	if not replaced then
		for k,v in ipairs(self.Zones) do
			v:Remove(true)
		end

		self.PublicNW:Invalidate()
		self.OwnerNW:Invalidate()
		self.EntsNW:Invalidate()
		self.PowerGrid:Remove()
	end

	if SERVER and IsValid(self:GetBaseCore()) then
		self:GetBaseCore():Remove()
	end

	BaseWars.Bases.Bases[self:GetID()] = nil
	if bw.NW.Bases:IsValid() then
		bw.NW.Bases:Set(self:GetID(), nil)
	end

	self:Emit("Remove")
	bw:Emit("DeleteBase", self)
end

ChainAccessor(bw.Base, "Zones", "Zones")
ChainAccessor(bw.Base, "Name", "Name")

function bw.Base:IsValid()
	return self._Valid and bw.Bases[self:GetID()] == self
end

function bw.Base:RemoveZone(zone)
	table.RemoveByValue(self.Zones, zone)
	self.ZonesByID[zone:GetID()] = nil
end

function bw.Base:AddZone(zone)
	self:_CheckValidity()

	if isnumber(zone) then zone = bw.Zones[zone] end
	CheckArg(1, zone, bw.IsZone, "bwzone")

	zone.BaseID = self.ID

	local old = self.ZonesByID[zone.ID]
	if old and old ~= zone then
		old:Remove(true)
		table.ReplaceValue(self.Zones, old, zone, true)
	elseif not old then
		self.Zones[#self.Zones + 1] = zone
	end

	self.ZonesByID[zone.ID] = zone
end

function bw.Base:IsOwner(what)
	assert(IsPlayer(what) or isstring(what) or IsPlayerInfo(what) or IsFaction(what))

	self:_CheckValidity()

	local fac, infos = self:GetOwner()

	if IsFaction(what) then
		return fac == what
	elseif infos then
		local pin = GetPlayerInfo(what)
		for k,v in ipairs(infos) do
			if v == pin then return true end
		end

		return false
	end
end

--[[-------------------------------------------------------------------------
	Utils
---------------------------------------------------------------------------]]

function bw.GetBase(id)
	if isnumber(id) then
		return BaseWars.Bases.Bases[id]
	elseif bw.IsBase(id) then
		return id
	else
		for k,v in pairs(BaseWars.Bases.Bases) do
			if v:GetName() == id then
				return v
			end
		end
	end
end

function bw.IsCore(what)
	return IsEntity(what) and what:IsValid() and what:GetClass() == "bw_basecore"
end

function bw.Zone:_CheckValidity()
	if not self:IsValid() then
		errorf("Zone CheckValidity failed!")
		return
	end
end

function bw.Base:_CheckValidity()
	if not self:IsValid() then
		errorf("Base CheckValidity failed!")
		return
	end
end

function bw.Base:CanClaim(who)
	self:_CheckValidity()

	if self:GetClaimed() then return false, bw.Errors.AlreadyClaimed(self) end
	if who and who:GetBase() then return false, bw.Errors.AlreadyHaveABase(who) end
	local pin = CanGetPInfo(who) and GetPlayerInfo(who)

	--print(pin, pin:GetFaction(), pin:GetFaction():GetOwnerInfo(), pin)

	if pin and pin:GetFaction() and
		pin:GetFaction():GetOwnerInfo() ~= pin then
		return false, bw.Errors.NotOwner
	end

	return true
end

function bw.Base:CanUnclaim(who)
	self:_CheckValidity()

	if not self:GetClaimed() then return false, bw.Errors.AlreadyUnclaimed(self) end
	if who and who:GetBase() ~= self then return false, bw.Errors.NotYourBase end
	if who and who:GetFaction() and
		who:GetFaction():GetOwnerInfo() ~= GetPlayerInfo(who) then
		return false, bw.Errors.NotOwner
	end

	return true
end

hook.Add("PostCleanupMap", "RespawnBaseZone", function()
	if CLIENT then return end

	for k,v in pairs(bw.Zones) do
		v:SpawnBrush()
	end

	for k,v in pairs(bw.Bases) do
		v:SpawnCore()
	end


	for k,v in pairs(bw.Zones) do
		v:GetBrush():ForceScanEnts()
	end
end)


include("bz_objects_ext_" .. Rlm(true) .. ".lua")
include("areamark/_init.lua")
include("bz_ownership_ext.lua")

-- not deprecated, fuck you.
IncludeCS("baseview/_init.lua")
IncludeCS("powergrid/_init.lua")

-- subfolders in client/ aren't autoincluded
FInc.FromHere("client/*", _CL, false, function(fn)
	return false
end)

-- files are tho
FInc.FromHere("client/*.lua", _CL)

FInc.FromHere("server/*.lua", _SV)