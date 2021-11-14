local bw = BaseWars.Bases

bw.EntityToPowerGrid = {}
bw.PowerGrid = bw.PowerGrid or Emitter:extend()

local pg = bw.PowerGrid
pg.ThinkInterval = 0.5
pg.DefaultCapacity = 100

function pg:Initialize(base)
	CheckArg(1, base, bw.IsBase)

	local id = base:GetID()

	self:SetValid(true)

	self:SetNW( LibItUp.Networkable:new("PG:" .. id) )
		:SetBase(base)
		:SetPower(0)
		:SetConsumers({})
		:SetGenerators({})
		:SetBatteries({})
		:SetAllEntities({})
		:SetCapacity(pg.DefaultCapacity)

	self:SetPowerIn(0)
	self:SetPowerOut(0)

	local nw = self:GetNW()
		nw.Filter = base.OwnerNWFilter
		nw.Base = base
		nw:Alias("Power", 0)
		nw:Alias("PowerIn", 1)
		nw:Alias("PowerOut", 2)
		nw:AddDependency(bw.NW.Bases)
		nw:AddDependency(bw.NW.Zones)

	self:Emit("Initialize", base)
end

function pg:Update()
	if not IsValid(self) then return end
	self:GetNW():Set("Power", self:GetPower())
end

function pg:SetPower(pw)
	self._Power = pw
	self:Update()
	return self
end

function pg:AddPower(pw)
	local new_pw = math.min(self:GetPower() + pw, self:GetCapacity())
	self:SetPower(new_pw)
end

function pg:TakePower(pw, drain)
	if not drain then
		if self:GetPower() < pw then return false end -- can't take that much power
		self:SetPower(self:GetPower() - pw)
		return true -- took successfully
	else
		-- in drain mode, it tries to drain out power even if it doesnt have enough
		local new_pw = math.min(self:GetPower() - pw, 0)
		self:SetPower(new_pw)
	end
end

function pg:HasPower(pw)
	return self:GetPower() > pw
end

function pg:Remove()
	self:GetNW():Invalidate()
	self:SetValid(false)
end

function pg:IsValid()
	return self:GetValid()
end

function pg:SetPowerIn(n)
	if not IsValid(self) then return end
	self._PowerIn = n
	self:GetNW():Set("PowerIn", n)
end

function pg:SetPowerOut(n)
	if not IsValid(self) then return end
	self._PowerOut = n
	self:GetNW():Set("PowerOut", n)
end

function pg:SetCapacity(n)
	if not IsValid(self) then return end
	self._Capacity = n
	self:GetNW():Set("Capacity", n)
end

function pg:AddEntity(ent)

	if not ent.IsBaseWars then
		return
	end

	if self:GetAllEntities()[ent] then
		return
	end -- already added
	if not IsValid(self) then return end

	if self:Emit("CanAddEntity", ent) == false then
		return
	end

	local old_grid = bw.EntityToPowerGrid[ent]
	if old_grid then
		old_grid:RemoveEntity(ent)
	end

	self:GetAllEntities()[ent] = true
	bw.EntityToPowerGrid[ent] = self

	if ent.IsElectronic then
		table.insert(self:GetConsumers(), ent)
		self:Emit("AddedConsumer", ent)
	elseif ent.IsGenerator then
		table.insert(self:GetGenerators(), ent)
		self:Emit("AddedGenerator", ent)
	elseif ent.IsBattery then
		table.insert(self:GetBatteries(), ent)
		self:Emit("AddedBattery", ent)
	end
end

hook.NHAdd("EntityActuallyRemoved", "PowerGrid_Clear", function(ent)
	if bw.EntityToPowerGrid[ent] then
		local pg = bw.EntityToPowerGrid[ent]
		pg:RemoveEntity(ent)
		bw.EntityToPowerGrid[ent] = nil
	end
end)

function pg:RemoveEntity(ent)
	if not ent.IsBaseWars then return end
	if not self:GetAllEntities()[ent] then return end
	if not IsValid(self) then return end

	self:GetAllEntities()[ent] = nil

	if bw.EntityToPowerGrid[ent] == self then
		bw.EntityToPowerGrid[ent] = nil
	end

	if ent.IsElectronic then
		table.RemoveByValue(self:GetConsumers(), ent)
		self:Emit("RemovedConsumer", ent)
	elseif ent.IsGenerator then
		table.RemoveByValue(self:GetGenerators(), ent)
		self:Emit("RemovedGenerator", ent)
	elseif ent.IsBattery then
		table.RemoveByValue(self:GetBatteries(), ent)
		self:Emit("RemovedBattery", ent)
	end
end

ChainAccessor(pg, "_Networkable", "NW")
ChainAccessor(pg, "_Base", "Base")
ChainAccessor(pg, "_Capacity", "Capacity", true)
ChainAccessor(pg, "_Power", "Power", true)
ChainAccessor(pg, "_PowerIn", "PowerIn", true)
ChainAccessor(pg, "_PowerOut", "PowerOut", true)
ChainAccessor(pg, "_Valid", "Valid")
ChainAccessor(pg, "_Consumers", "Consumers")
ChainAccessor(pg, "_Generators", "Generators")
ChainAccessor(pg, "_Batteries", "Batteries")
ChainAccessor(pg, "_AllEntities", "AllEntities")

include("powergrid_ext_" .. Rlm(true) .. ".lua")
AddCSLuaFile("powergrid_ext_cl.lua")

local ENTITY = FindMetaTable("Entity")

function ENTITY:GetPowerGrid()
	local base = self:BW_GetBase()
	if base then
		return base:GetPowerGrid()
	end
end

if SERVER then
	function ENTITY:GetAllPowerGrids()
		local bases = self:BW_GetAllBases()
		local ret = {}
		for k,v in ipairs(bases) do
			ret[k] = v:GetPowerGrid()
		end

		return ret
	end
end