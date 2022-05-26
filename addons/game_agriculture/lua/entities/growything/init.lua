include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

util.AddNetworkString("growything")

function ENT:SVInit(me)

end

function ENT:OutTakeItem(inv, itm, toInv, slot, fromSlot, ply)
	if self.choke then
		self.choke[fromSlot] = nil
	end
	self:Think()
end

function ENT:CheckCompletion()
	local changed = false

	for i=1, self.In.MaxItems do
		if self:GetProgress(i) ~= 1 then continue end

		local itm = self.In:GetItemInSlot(i)
		if not itm then
			continue
		end

		local res = itm:CreateResult()

		local left, its = self.Out:PickupItem(res, {
			Slots = {i},
		})

		-- stack failed?
		if left or not its then
			self.choke[i] = true
			continue
		end

		changed = true
		itm:DrainHealth()
		self:TimeSlot(i, true) -- time before drain because if the seed dies it'll be fucked

		self.choke[i] = false
	end

	if changed then
		Inventory.Networking.UpdateInventory(self:GetSubscribers(), self.Inventory)
	end
end

function ENT:Think()
	local lowestNext = 3

	self.choke = self.choke or {} -- cba to respawn the entity lol

	for i=1, self.In.MaxItems do
		local _, et = self:GetTime(i)
		if et == 0 then continue end

		local left = et - CurTime()
		if self.choke[i] then -- already choked; reduce update rate for it
			left = math.max(left, 0.5)
		end

		lowestNext = math.min(left, lowestNext)
	end

	lowestNext = math.max(lowestNext, 0.05)

	self:CheckCompletion()
	self:NextThink(CurTime() + lowestNext)
	return true
end

function ENT:Use(ply)
	self:Subscribe(ply, 192)
	Inventory.Networking.NetworkInventory(ply, self.Inventory, INV_NETWORK_FULLUPDATE)

	net.Start("growything")
	net.WriteEntity(self)
	net.Send(ply)
end

function ENT:InNewItem(inv, itm, from, slot, fromSlot, ply)
	self:TimeSlot(slot)

	self.Status:Network()
end

function ENT:InTakeItem(inv, itm, toInv, slot, fromSlot, ply)
	self:SetTime(fromSlot, 0, 0)
	self:TimeSlot(fromSlot)

	self.Status:Network()
end

function ENT:InMovedItem(inv, it, slot, it2, b4slot, ply)
	self:SetTime(slot, 0, 0)
	self:SetTime(b4slot, 0, 0)

	self:TimeSlot(slot)
	self:TimeSlot(b4slot)

	self.Status:Network()
end

function ENT:SetTime(slot, sT, eT)
	if sT then self.Status:Set(slot * 2 - 2, sT) end
	if eT then self.Status:Set(slot * 2 - 1, eT) end
end

function ENT:TimeSlot(i, restart)
	local pw = self:GetPowered()

	local itm = self.In:GetItemInSlot(i)
	local have = self:GetTime(i) ~= 0

	if not have or restart then

		if itm then
			-- inserted item but its untimed; time it according to pw
			if pw then
				self:SetTime(i, CurTime(), CurTime() + itm:GetGrowTime())
			else
				self:SetTime(i, 0)
			end
		else
			self:SetTime(i, 0)
		end

		return
	end

	if not itm then
		printf("!!! HOW IS THIS POSSIBLE: NO ITEM IN %d; STATUS SAYS NOT 0 (= %s) !!", i, prog)
		return
	end

	if pw then
		local prog, have = self:GetProgress(i)

		self:SetTime(i,
			Lerp(prog, CurTime(), CurTime() - itm:GetGrowTime()),
			Lerp(1 - prog, CurTime(), CurTime() + itm:GetGrowTime())
		)
	else
		local sT, eT = self:GetTime(i)
		self:SetTime(i, math.RemapClamp(CurTime(), sT, eT, 0, 1))
	end
end

local function dropItms(self, inv)
	local spos = self:GetPos() + self:OBBCenter()

	for k,v in pairs(inv:GetItems()) do
		local drop = ents.Create("dropped_item")

		drop:PickDropSpot({self}, {
			DropOrigin = spos,
		})

		inv:RemoveItem(v, true)

		drop:SetCreatedTime(CurTime())
		drop:SetItem(v)
		drop:Spawn()
		drop:Activate()
		--drop:PlayDropSound(i2)
	end
end

function ENT:OnRemove()
	dropItms(self, self.In)
	dropItms(self, self.Out)
end

function ENT:OnPower()
	for i=1, self.In.MaxItems do
		self:TimeSlot(i)
	end

	self.Status:Set("Powered", self:GetPowered())
	self.Status:Network()
end

function ENT:OnUnpower()
	for i=1, self.In.MaxItems do
		self:TimeSlot(i)
	end

	self.Status:Set("Powered", self:GetPowered())
	self.Status:Network()
end