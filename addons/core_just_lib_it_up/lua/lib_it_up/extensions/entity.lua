LibItUp.SetIncluded()
EntitySubscribers = EntitySubscribers or {}

local subs = EntitySubscribers.Players or {} 		-- key = player, value = { {ply, dist_sqr, callback}, {ply, dist_sqr, callback} }
EntitySubscribers.Players = subs					-- this is used for distance-checking logic 

local ent_subs = EntitySubscribers.Entities or {}		-- key = entity, value = { [player] = ntid_in_plysub, [player] = entid_in_plysub }
EntitySubscribers.Entities = ent_subs					-- this is used for adding/removing subs from entity

--[[
	onunsub callback will be called with args:
		entity - from which the player unsubscribed
		player - which got unsubscribed

	make 4th arg "true" if you want to add subscriber multiple times
]]


local BlankFunc = function() end


local lookupCache = setmetatable({}, {__mode = "kv"})
EntTableLookup = lookupCache

hook.Add("EntityActuallyRemoved", "cleanupShit", function(e)
	timer.Simple(10, function()
		EntTableLookup[e] = nil
	end)
end)

timer.Create("cleanup_invalid_ents_lkup", 10, 0, function()
	for k,v in pairs(EntTableLookup) do
		if not k:IsValid() then
			EntTableLookup[k] = nil
		end
	end
end)

local ENTITY = FindMetaTable("Entity")
local WEAPON = FindMetaTable("Weapon")

local get_table = ENTITY.GetTable

function ENTITY:__index( key )
	local val = ENTITY[key]
	if val != nil then return val end

	local tab = lookupCache[self]

	if not tab then
		tab = get_table(self)
		lookupCache[self] = tab
	end

	if tab then
		val = tab[key]
		if val != nil then return val end
	end

	-- todo: destroy this piece of shit
	if ( key == "Owner" ) then return ENTITY.GetOwner( self ) end

	return nil
end

ENTITY._oldSetTable = ENTITY._oldSetTable or ENTITY.SetTable
function ENTITY:SetTable(t)
	lookupCache[self] = t
	ENTITY._oldSetTable(self, t)
end

function WEAPON:__index( key )
	-- weapon meta
	local val = WEAPON[key]
	if ( val != nil ) then return val end

	-- ent meta
	val = ENTITY[key]
	if ( val != nil ) then return val end

	-- cached instance table
	local tab = lookupCache[self]

	if !tab then
		tab = get_table(self)
		lookupCache[self] = tab
	end

	if ( tab != nil ) then
		val = tab[ key ]
		if ( val != nil ) then return val end
	end

	-- shitfuck
	if ( key == "Owner" ) then return ENTITY.GetOwner( self ) end

	return nil
end



function ENTITY:Subscribe(ply, dist, onunsub, addtwice)

	if CLIENT then
		ply = LocalPlayer()
	end

	onunsub = onunsub or BlankFunc

	if ent_subs[self] and ent_subs[self][ply] and not addtwice then return end  --prevent subscribing multiple times for the same entity
																				--..unless you want to.

	local sub_ply = subs[ply] or {}
	subs[ply] = sub_ply

	local plysub_key = #sub_ply + 1

	sub_ply[plysub_key] = {self, dist^2, onunsub}


	local sub_ent = ent_subs[self] or {}
	ent_subs[self] = sub_ent

	sub_ent[ply] = ply
end

function ENTITY:IsSubscribed(ply)
	local my_subs = ent_subs[self]

	if my_subs and my_subs[ply] then
		return true
	end

	return false
end

function ENTITY:Unsubscribe(ply)
	local my_subs = ent_subs[self]

	if my_subs then
		table.remove(subs, my_subs[ply])
		ent_subs[self][ply] = nil
	end
end

function ENTITY:GetSubscribers()
	local t = {}
	local i = 1

	local my_subs = ent_subs[self]

	if my_subs then

		for k,v in pairs(my_subs) do
			t[i] = k
			i = i + 1
		end

	end

	return t
end

function ENTITY:DoCooldown(key, t)
	t = t or 1
	self.__cds = self.__cds or {}
	local c = self.__cds
	if not c[key] or CurTime() - c[key] > 0 then
		c[key] = CurTime() + t
		return true
	end

	return false
end

function ENTITY:SetCooldown(key, t)
	t = t or 1
	self.__cds = self.__cds or {}
	local c = self.__cds
	c[key] = CurTime() + t
end

function ENTITY:OnCooldown(key)
	self.__cds = self.__cds or {}
	local c = self.__cds

	if not c[key] or CurTime() - c[key] > 0 then
		return true
	end

	return false
end

function ENTITY:BaseRecurseCall(methodName, ...)
	self._recursing = self._recursing or {}
	if self._recursing[methodName] then return end

	self._recursing[methodName] = true
	local base = scripted_ents.GetStored(self.Base).t
	local lastBaseName = self.Base
	clprint("Calling", base.PrintName, methodName)

	while base do
		clprint("Calling", base.PrintName, methodName)
		if base[methodName] then
			base[methodName] (self, ...)
		end
		if not base.Base or base.Base == lastBaseName then break end
		lastBaseName = base.Base
		base = scripted_ents.GetStored(lastBaseName).t
	end

	self._recursing[methodName] = nil
end

function ENTITY:GetSubscribersKeys()

	local my_subs = ent_subs[self]

	return my_subs or {}
end


function PLAYER:Subscribe(ent, ...)
	return ent:Subscribe(self, ...)
end

function PLAYER:IsSubscribed(ent)
	return ent:IsSubscribed(self)
end

function PLAYER:GetSubscribedTo()
	local ret = {}
	for k,v in pairs(subs[self] or {}) do
		if not v[1]:IsValid() then continue end
		ret[#ret + 1] = v[1]
	end

	return ret
end

hook.Add("FinishMove", "EntitySubscriptions", function(pl, mv)
	if not subs[pl] then return end

	local pos = mv:GetOrigin()
	local len = #subs[pl]

	for key = len, 1, -1 do --start from the top so table.remove'ing doesn't make us skip keys

		local dat = subs[pl][key]

		local ent = dat[1]
		local dist = dat[2]
		local callback = dat[3]
		if not IsValid(ent) then table.remove(subs[pl], key) continue end

		local epos = ent:GetPos()

		if pos:DistToSqr(epos) > dist then
			local unsub = callback(ent, pl)

			if unsub ~= false then
				table.remove(subs[pl], key) --preserve sequential order
				ent_subs[ent][pl] = nil
			end

		end

	end
end)

--[=[

ENTITY._PrevIsValid = ENTITY._PrevIsValid or ENTITY.IsValid
function ENTITY:IsValid()
	return ENTITY._PrevIsValid(self) --[[and
		not (lookupCache[self] or self).__removing]]
end

]=]

function ENTITY:IsRemoving()
	return not not (lookupCache[self] or self).__removing
end

-- ty garry
hook.Add("EntityRemoved", "EntityActuallyRemoved", function(ent)
	local t = ent:GetTable()
	local eid = ent:EntIndex()

	ent.__removing = true

	if CLIENT then
		timer.Simple(0, function()
			if not ent:IsValid() then
				hook.Run("EntityActuallyRemoved", ent, t, eid)
			else
				ent.__removing = false
			end
		end)
	else
		hook.Run("EntityActuallyRemoved", ent, t)
	end
end)


if CLIENT then
	local wait = {}

	function EventualEntity(eid, dontcare)
		local pr = Promise()

		local ent = Entity(eid)
		if ent:IsValid() then
			pr:Resolve(ent)
			return pr
		else
			if wait[eid] then
				return wait[eid]
			else
				wait[eid] = pr
				pr._run_insta = dontcare
			end

			return pr
		end
	end

	hook.Add("NotifyShouldTransmit", "EventualEntities", function(ent, add)
		if not add then return end
		local eid = ent:EntIndex()
		if not wait[eid] then return end

		local pr = wait[eid]
		wait[eid] = nil

		if pr._run_insta then
			pr:Resolve(ent)
		else
			-- i hate this
			ent:Timer("EventualTimer", 0, 300, function()
				if not ent.Base then return end -- AAAAAAAAAAAAAAA
				pr:Resolve(ent)
				ent:RemoveTimer("EventualTimer")
			end)
		end
	end)
end

include("entity_dt.lua")
AddCSLuaFile("entity_dt.lua")