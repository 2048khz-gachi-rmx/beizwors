AddCSLuaFile()

local base = "bw_base_upgradable"
ENT.Base = base
ENT.Type = "anim"
ENT.PrintName = "Cocaine Extractor"

ENT.Model = "models/craphead_scripts/the_cocaine_factory/extractor/extractor.mdl"
ENT.Skin = 0

ENT.CanTakeDamage = true
ENT.NoHUD = false
ENT.WantBlink = false

ENT.IngredientsRequired = 4
ENT.ResultCreates = "raw_cocaine"
ENT.IngredientTakes = "coca"
local networkablePfx = "cex"

ENT.Levels = {
	{
		Cost = 0,
		SlotsOut = 1,
		ExtractionTime = 3,
	}, {
		Cost = 25e6,
		SlotsOut = 1,
		ExtractionTime = 2,
	}, {
		Cost = 250e6,
		SlotsOut = 1,
		ExtractionTime = 1,
	}
}

function ENT:DerivedDataTables()
	self:NetworkVar("Int", 2, "CocainerFr")
	self:NetworkVar("Bool", 2, "Working")
	self:NetworkVar("Float", 2, "Time1")
	self:NetworkVar("Float", 3, "Time2")
	self:NetworkVar("Float", 4, "WorkChanged")
end

function ENT:CanFromIn(ply, itm, toInv)
	if not toInv.IsBackpack then return false end

	return true
end

function ENT:CanToIn(ply, itm, fromInv)
	if not fromInv.IsBackpack then return false end
	if itm:GetItemName() ~= self.IngredientTakes then return false end

	return true
end

function ENT:AllowInteract(invWith, ply, itm, invFrom)
	if not ply:Alive() then return false end
	if ply:Distance(self) > 192 then return false end

	return true
end

function ENT:InNewItem(inv, itm, fromInv, slot, fromSlot, ply) end
function ENT:InChanged(inv) end
function ENT:OutChanged(inv) end
function ENT:InTakeItem(inv, itm, toInv, slot, fromSlot, ply) end
function ENT:InMovedItem(inv, it, slot, it2, b4slot, ply) end


function ENT:OutTakeItem(inv, itm, toInv, slot, fromSlot, ply) end

function ENT:CanFromOut(ply, itm, toInv)
	if not toInv.IsBackpack then return false end

	return true
end

function ENT:CreateInventories()
	self.Inventory = {
		Inventory.Inventories.Entity:new(self),
		Inventory.Inventories.Entity:new(self)
	}

	self.In = self.Inventory[1]
	self.In.SupportsSplit = true
	self.In.ActionCanMove = true

	self.In.ActionCanMerge = true
	self.In.ActionCanSplit = true

	self.In.ActionCanCrossInventoryFrom = function(inv, ply, ...)
		return self:CanFromIn(ply, ...)
	end

	self.In.ActionCanCrossInventoryTo = function(inv, ply, ...)
		return self:CanToIn(ply, ...)
	end

	self.In:On("AllowInteract", "Distance", function(...)
		return self:AllowInteract(...)
	end)

	self.In:On("CrossInventoryMovedTo", "Hook", function(...)
		self:InNewItem(...)
	end)

	self.In:On("CrossInventoryMovedFrom", "Hook", function(...)
		self:InTakeItem(...)
	end)

	self.In:On("Moved", "Hook", function(...)
		self:InMovedItem(...)
	end)

	self.In:On("Change", "Hook", function(...)
		self:InChanged(...)
	end)

	self.Out = self.Inventory[2]

	local maxLv = self:GetLevelData(#self.Levels)

	self.In.MaxItems = self.IngredientsRequired
	self.Out.MaxItems = maxLv.SlotsOut

	self.Out.SupportsSplit = false
	self.Out.ActionCanMove = false
	self.Out.ActionCanCrossInventoryTo = false

	self.Out.ActionCanCrossInventoryFrom = function(inv, ply, ...)
		return self:CanFromOut(ply, ...)
	end

	self.Out:On("CrossInventoryMovedFrom", "Hook", function(...)
		self:OutTakeItem(...)
	end)

	self.Out:On("AllowInteract", "Distance", function(...)
		return self:AllowInteract(...)
	end)

	self.Out:On("Change", "Hook", function(...)
		self:OutChanged(...)
	end)
end

function ENT:SHInit()
	self:CreateInventories()
end

function ENT:SyncVis()
	local seq = self:GetSequence()
	local on, off = self:LookupSequence("on"), self:LookupSequence("off")

	local work = self:GetWorking() and not self.Choked
	local seq_on = work and on or off

	if seq ~= seq_on then
		self:ResetSequence(seq_on)
		self:SetCycle(0)
		self:SetPlaybackRate(1)
	end

	self:SetSkin(work and 1 or 0)

	self:SetBGName("light_extractor", self:GetWorking() and 1 or 0)
	if self:GetWorking() then
		self:SetBGName("light_bucket_green", self.Choked and 0 or 1)
		self:SetBGName("light_bucket_red", self.Choked and 1 or 0)
	else
		self:SetBGName("light_bucket_green", 0)
		self:SetBGName("light_bucket_red", 0)
	end

	if SERVER then
		local total = 0
		local max = Inventory.Util.GetBase(self.IngredientTakes):GetMaxStack() * self.In.MaxItems
		local miss = false
		for i=1, self.In.MaxItems do
			local itm = self.In:GetItemInSlot(i)

			if itm then
				total = total + self.In:GetItemInSlot(i):GetAmount()
			else
				miss = true
			end
		end
		self:SetPoseParameter("arrow_1", total / max * 100)

		self:SetBGName("light_arrow_1", (miss or total / max * 100 < 25) and 1 or 0)

		self.steam = self.steam or CreateSound(self, "ambient/machines/gas_loop_1.wav")

		if work then
			self.steam:PlayEx(0.45, 80)
		else
			self.steam:FadeOut(1.5)
		end
	end
end

function ENT:GetResult(its, temp)
	local ints, cnts = {}, {}

	for k,v in ipairs(its) do
		if not v:GetItem() or not v:GetItem():GetTypeID() then continue end
		local id = v:GetItem():GetTypeID()
		ints[id] = (ints[id] or 0) + 1
		cnts[id] = (cnts[id] or 0) + 1 -- TODO: different intensities
	end

	for k,v in pairs(ints) do
		ints[k] = v / #its
	end

	return ints
end

function ENT:GetTime()
	return self:GetTime1(), self:GetTime2()
end

function ENT:GetProgress()
	local st, endt = self:GetTime()

	if st == 0 or endt == 0 then return 0, false end

	if not self:IsPowered() then
		-- unpowered: startTime becomes % at which progress stopped
		return st, true
	end

	return math.RemapClamp(CurTime(), st, endt, 0, 1), true
end