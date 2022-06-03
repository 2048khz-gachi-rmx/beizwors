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

ENT.ResultCreates = "coca"
ENT.IngredientTakes = "coca"
local networkablePfx = "cex"

ENT.Levels = {
	{
		Cost = 0,
		Slots = 2,
		ExtractionTime = 10,
	}, {
		Cost = 25e6,
		Slots = 3,
		ExtractionTime = 5,
	}, {
		Cost = 250e6,
		Slots = 4,
		ExtractionTime = 2,
	}
}

function ENT:DerivedDataTables()

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
	self.In.MaxItems = self.Levels[#self.Levels].Slots
	self.In.SupportsSplit = false
	self.In.ActionCanMove = true

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


	self.Out = self.Inventory[2]
	self.Out.MaxItems = self.In.MaxItems

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
end

function ENT:SHInit()
	self:CreateInventories()

	self.Status = Networkable(networkablePfx .. ":" .. self:EntIndex())
	self.Status:Bind(self)

	self.Status:Alias("Powered", -1, "Bool")

	for i=1, self.In.MaxItems * 2 do
		self.Status:Alias(i - 1, i - 1, "Float")
	end
end

function ENT:IsWorking()
	if not self.Status:Get("Powered") then return false, false end

	for i=1, self.In.MaxItems do
		local prog, work = self:GetProgress(i)
		if not work then continue end
		if prog == 0 or prog == 1 then continue end

		return true
	end
end

function ENT:GetTime(slot)
	-- [evenIdx] = start;   [oddIdx] = end;
	return self.Status:Get(slot * 2 - 2, 0), self.Status:Get(slot * 2 - 1, 0)
end

function ENT:GetProgress(slot)
	local st, endt = self:GetTime(slot)

	if st == 0 or endt == 0 then return 0, false end

	if not self.Status:Get("Powered") then
		-- unpowered: startTime becomes % at which progress stopped
		return st, true
	end

	return math.RemapClamp(CurTime(), st, endt, 0, 1), true
end

local LVData = ENT.Levels

hook.Add("NetworkableAttemptCreate", "Extractor", function(nwid)
	if not nwid:match("^" .. networkablePfx .. ":%d+") then return end

	local nw = Networkable(nwid)
	nw:Alias("Powered", -1, "Bool")

	for i=1, LVData[#LVData].Slots * 2 do
		nw:Alias(i - 1, i - 1, "Float")
	end

	return true
end)