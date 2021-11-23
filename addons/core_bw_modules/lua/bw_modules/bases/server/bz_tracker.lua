local bw = BaseWars.Bases
setfenv(1, _G)

-- If an entity touches multiple bases at once, then, first of all, it's your fault,
-- and second, the oldest entered base will be considered as the `current` one.

-- If the player leaves that oldest base, the one that came after will be considered the `current` one.
-- This repeats for multiple bases (so you can touch 10 bases (you absolute madman),
-- and the oldest one will be the current)

-- Current base: [ent] = cur_base

bw.BasePresence = bw.BasePresence or {
	-- [ent] = base_obj
}

for ent, base in pairs(bw.BasePresence) do
	if not base:IsValid() or not ent:IsValid() then
		bw.BasePresence[ent] = nil
	end
end

-- Base queue: [ent] = { oldest_base, ..., newest_base }
bw.BasePresenceQueue = bw.BasePresenceQueue or {}

for ent, queue in pairs(bw.BasePresenceQueue) do
	table.Filter(queue, bw.Base.IsValid)
end

-- Zone presence: [ent] = { oldest_zone, ..., newest_zone }
-- Also a queue, like Base queue, and operates on the same principles
bw.ZonePresence = bw.ZonePresence or {}

for ent, queue in pairs(bw.ZonePresence) do
	table.Filter(queue, bw.Zone.IsValid)
end

local ENTITY = FindMetaTable("Entity")

-- returns the current base the ent is in, false if in none
local function getBase(ent)
	return bw.BasePresence[ent] or false
end

-- returns the base queue for ent, guaranteed to be a table
local function getBaseQueue(ent)
	local t = bw.BasePresenceQueue[ent]

	if not t then
		t = {}
		bw.BasePresenceQueue[ent] = t
	end

	return t
end

-- returns all zones ent is in, guaranteed to be a table
local function getZones(ent)
	local t = bw.ZonePresence[ent]

	if not t then
		t = {}
		bw.ZonePresence[ent] = t
	end

	return t
end

-- please make sure you're not modifying these or shit'll break :v

function ENTITY:BW_GetOldestZone()
	return getZones(self)[1]
end

function ENTITY:BW_GetNewestZone()
	local t = getZones(self)
	return t[#t]
end

function ENTITY:BW_GetAllZones()
	local t = getZones(self)
	return table.Copy(t) -- dont fuck it up
end


function ENTITY:BW_GetBase()
	return getBase(self)
end

function ENTITY:BW_GetZone()
	return self:BW_GetOldestZone() -- self:BW_GetNewestZone()
end

function ENTITY:BW_GetAllBases()
	return getBaseQueue(self)
end

local function enterBase(ent, base)
	if not base:IsValid() then return end
	bw.BasePresence[ent] = base
	base:EntityEnter(ent)
end

function ENTITY:BW_EnterBase(base)
	return enterBase(self, base)
end

	local function exitBase(ent, base) -- exit a specific base; the only difference is the sanity check
		--[[if base ~= getBase(ent) then
			errorf("Sanity check failed: %s != %s", base, getBase(ent))
			return
		end]]

		if bw.BasePresence[ent] == base then
			bw.BasePresence[ent] = nil
		end

		if base:IsValid() then
			base:EntityExit(ent, ent._ForceBaseRemove)
		end
	end

function ENTITY:BW_ExitBase(base)
	return exitBase(self, base)
end

--[[-------------------------------------------------------------------------
	Public
		Working with the base queue; bases may or may not be in the base queue

		Calling addBase when the base is in queue already and
		calling removeBase when it's not is perfectly fine.
---------------------------------------------------------------------------]]
local function addBase(ent, base)
	CheckArg(2, base, bw.IsBase)

	local t = getBaseQueue(ent)

	if not t[1] then -- the queue was empty; make us the current base
		enterBase(ent, base)
		t[1] = base
		return
	end

	-- actually, just make us the new base lol
	enterBase(ent, base)

	-- make sure we don't put the base in multiple times
	local baseID = base:GetID()
	for k,v in ipairs(t) do
		if baseID == v:GetID() then return end
	end

	table.insert(t, base)
end

-- remove `base` if it was in ent's presence queue
local function removeBase(ent, base)
	CheckArg(2, base, bw.IsBase)

	local t = getBaseQueue(ent)
	if not t[1] then return end -- the queue was empty; don't bother

	-- if we're removing the current base, also remove us from being current
	--if getBase(ent) == base then
		exitBase(ent, base)
	--end

	local baseID = base:GetID()

	for k,v in ipairs(t) do
		if baseID == v:GetID() then
			table.remove(t, k)
			-- there was an another base in queue and we were the current base;
			-- make that one the new current base
			if t[1] and k == 1 then
				enterBase(ent, t[1])
			end
			return
		end
	end
end

-- after changing the zone presence, call this to make sure
-- we update our base presence using zone presence
local function checkZoneBases(ent)
	local zones = getZones(ent)
	local bases = getBaseQueue(ent)
	local revBases = table.KeysToValues(bases) -- [base] = number

	--print("checking zoneBases", ent, #zones, #bases)
	local newBases = {} -- [confirmed_present_base] = true

	-- check for entering new bases
	for k,v in ipairs(zones) do
		-- for every zone we're in, check if we're also in that zone's base
		local base = v:GetBase()
		if revBases[base] then newBases[base] = true continue end -- we're already in that base; don't care
		-- we entered a new base: register
		addBase(ent, base)

		revBases[base] = true
		newBases[base] = true
	end

	-- check for exiting bases
	-- if some base is not present in newBases, that means we're
	-- no longer in any zones, which belong to that base

	for _, base in ipairs(bases) do
		if not newBases[base] then
			removeBase(ent, base)
		end
	end
end

local function addZone(ent, zone)
	local t = getZones(ent)
	if table.HasValue(t, zone) then return end

	table.insert(t, zone)

	zone:EntityEnter(ent)
	checkZoneBases(ent)
	hook.NHRun("EntityEnteredZone", zone, ent)
end

local function _doRemove(ent, t, k, zone)
	local ok, allow = hook.NHRun("EntityExitZone", zone, ent)
	if allow == false and not ent._ForceBaseRemove then return end
	table.remove(t, k)

	if zone:IsValid() then
		zone:EntityExit(ent)
	end

	checkZoneBases(ent)
	hook.NHRun("EntityExitedZone", zone, ent)
end

local function removeZone(ent, zone)
	local t = getZones(ent)
	if not t[1] then return end -- presence was empty; don't bother

	assert(bw.IsZone(zone) or isnumber(zone))

	if isnumber(zone) then -- given key
		_doRemove(ent, t, zone, t[zone])
		return
	end

	for k,v in ipairs(t) do
		if v == zone then
			_doRemove(ent, t, k, v)
			return
		end
	end
end

local function removeZones(ent)
	local t = getZones(ent)

	for i=#t, 1, -1 do
		removeZone(ent, t[i])
	end

	bw.BasePresenceQueue[ent] = nil
	bw.BasePresence[ent] = nil
end

function bw.Zone:_EntityEntered(brush, ent)
	addZone(ent, self)
end

function ENTITY:EnterZone(zone)
	addZone(self, zone)
end

function bw.Zone:_EntityExited(brush, ent)
	removeZone(ent, self)
end

function ENTITY:ExitZone(zone)
	removeZone(self, zone)
end

bw:On("DeleteZone", "Tracker", function(self, delzone)
	for ent, bases in pairs(bw.ZonePresence) do
		removeZone(ent, delzone)
	end
end)

bw:On("DeleteBase", "Tracker", function(self, delbase)
	for ent, bases in pairs(bw.BasePresenceQueue) do
		removeBase(ent, delbase)
	end
end)

hook.Add("EntityActuallyRemoved", "UntrackBases", function(ent)
	ent._ForceBaseRemove = true
	local zones = bw.ZonePresence[ent]
	if zones then
		removeZones(ent)
	end
end)

hook.Add("EntityEnteredBase", "NetworkPlayerBase", function(base, ent)
	if not IsPlayer(ent) then return end

	local nw = bw.GetPlayerNW(ent)
	if not nw then return end

	nw:Set("CurrentBase", base:GetID())
	nw:Network()
end)

hook.Add("EntityExitedBase", "NetworkPlayerBase", function(base, ent)
	if not IsPlayer(ent) then return end

	local nw = bw.GetPlayerNW(ent)
	if not nw then return end -- can happen if a player leaves while in a base

	nw:Set("CurrentBase", nil)
	nw:Network()
end)

hook.Add("EntityEnteredZone", "NetworkPlayerZone", function(zone, ent)
	if not IsPlayer(ent) then return end

	local nw = bw.GetPlayerNW(ent)
	if not nw then return end

	local oldest = ent:BW_GetOldestZone()

	if zone:GetBase() ~= oldest:GetBase() then
		-- different bases; stay in the oldest one
		nw:Set("CurrentZone", oldest:GetID())
	else
		-- same base; update to new zone
		nw:Set("CurrentZone", zone:GetID())
	end

	nw:Network()
end)

hook.Add("EntityExitedZone", "NetworkPlayerZone", function(zone, ent)
	if not IsPlayer(ent) then return end

	local nw = bw.GetPlayerNW(ent)
	if not nw then return end

	local z = ent:BW_GetOldestZone()

	nw:Set("CurrentZone", z and z:GetID() or nil)
	nw:Network()
end)

timer.Create("BWBases_CollectGarbage", 5, 0, function()
	for ent, v in pairs(bw.ZonePresence) do
		if not ent:IsValid() then
			removeZones(ent)
			bw.ZonePresence[ent] = nil
		end
	end

	for ent, v in pairs(bw.BasePresenceQueue) do
		if not ent:IsValid() then
			printf("not supposed to happen - NULL [%s] in BasePresenceQueue @ %s\n" ..
				"even though removeZone should've cleaned it out!", ent, v)
			bw.BasePresenceQueue[ent] = nil
		end
	end

	for ent, v in pairs(bw.BasePresence) do
		if not ent:IsValid() then
			printf("not supposed to happen - NULL [%s] in BasePresence @ %s\n" ..
				"even though removeZone should've cleaned it out!", ent, v)

			bw.BasePresence[ent] = nil
		end
	end
end)
