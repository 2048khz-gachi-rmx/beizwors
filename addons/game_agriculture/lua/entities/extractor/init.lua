include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

util.AddNetworkString("growything")

function ENT:SVInit(me)
	self.Choked = false
end

function ENT:OutTakeItem(inv, itm, toInv, slot, fromSlot, ply)
	self.Choked = false
	self:Think()
end

function ENT:CreateResult(itm)
	local smIt = Inventory.NewItem(self.ResultCreates)
	if not smIt then return end

	smIt:SetAmount(1)

	return smIt
end

function ENT:CheckCompletion()
	if self:GetProgress(i) ~= 1 then return end

	local res = self:CreateResult(itm)

	local left, its = self.Out:PickupItem(res)

	-- stack failed?
	if left or not its then
		self.Choked = true
		return
	end

	for i=1, self.In.MaxItems do
		local itm = self.In:GetItemInSlot(i)
		if not IsValid(itm) then
			printf("!!! Progress 1 but no item in slot %d !!!", i)
			return
		end

		local ok = itm:TakeAmount(1)
		if not ok then
			printf("!!! Somehow failed to take 1 from coca leaves? %s !!!", itm)
		end

		self:TimeSlot(i, true) -- time before drain because if the seed dies it'll be fucked
	end

	Inventory.Networking.UpdateInventory(self:GetSubscribers(), self.Inventory)
end

function ENT:Think()
	local lowestNext = 3

	for i=1, self.In.MaxItems do
		local _, et = self:GetTime(i)
		if et == 0 then continue end

		local left = et - CurTime()
		if self.Choked then -- already choked; reduce update rate for it
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

function ENT:InChanged(inv)
	print("timing!")
	-- no missing items; start
	self:TimeSlot()

	self.Status:Network()
end

function ENT:InTakeItem(inv, itm, toInv, slot, fromSlot, ply)
	-- taken something out = stop production, no questions asked
	self:SetTime(0, 0)
	self:TimeSlot(fromSlot)

	self.Status:Network()
end

function ENT:InMovedItem(inv, it, slot, it2, b4slot, ply)
	print("movedd item... should we handel somehow?")
	--self:SetTime(0, 0)
	--self:SetTime(0, 0)

	--self:TimeSlot(slot)
	--self:TimeSlot(b4slot)

	self.Status:Network()
end

function ENT:SetTime(sT, eT)
	if sT then self.Status:Set("TimeStart", sT) end
	if eT then self.Status:Set("TimeEnd", eT) end
end

function ENT:TimeSlot(restart)
	local pw = self:GetPowered()

	local shouldLaunch = true

	for i=1, self.In.MaxItems do
		-- missing item; dont start production
		if not self.In:GetItemInSlot(i) then shouldLaunch = false break end
	end

	local have = self:GetTime(i) ~= 0

	local exTime = self:GetLevelData().ExtractionTime or 30
	if not have or restart then

		if shouldLaunch then
			-- inserted item but its untimed; time it according to pw
			if pw then
				self:SetTime(CurTime(), CurTime() + exTime)
			else
				self:SetTime(0)
			end
		else
			self:SetTime(0)
		end

		return
	end

	if not shouldLaunch then
		self:SetTime(0, 0)
		return
	end

	if pw then
		local prog, have = self:GetProgress()

		self:SetTime(
			Lerp(prog, CurTime(), CurTime() - exTime),
			Lerp(1 - prog, CurTime(), CurTime() + exTime)
		)
	else
		local sT, eT = self:GetTime()
		self:SetTime(math.RemapClamp(CurTime(), sT, eT, 0, 1))
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