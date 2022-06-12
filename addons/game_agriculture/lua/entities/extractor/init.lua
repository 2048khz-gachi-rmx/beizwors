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

function ENT:CreateResult()
	local smIt = Inventory.NewItem(self.ResultCreates)
	if not smIt then return end

	smIt:SetAmount(1)
	local from = self.In.Slots
	local typ = self:GetResult(from)

	smIt:SetEffects(typ)

	return smIt
end

function ENT:CheckCompletion()
	if self:GetProgress(i) ~= 1 then return end

	local res = self:CreateResult(itm)

	local left, its = self.Out:PickupItem(res)

	-- stack failed?
	if left or not its then
		self.Choked = true
		self:SyncVis()
		return
	end

	local fr = 0
	local itm = self.Out.Slots[1]
	if itm then
		fr = math.Remap(itm:GetAmount(), 0, itm:GetMaxStack(), 0, 100)
	end

	self:SetCocainerFr(fr)

	self.Choked = false

	local total = 0
	local max = Inventory.Util.GetBase(self.IngredientTakes):GetMaxStack() * self.In.MaxItems

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

		total = total + itm:GetAmount()
	end

	Inventory.Networking.UpdateInventory(self:GetSubscribers(), self.Inventory)

	self:SetPoseParameter("arrow_1", total / max * 100)
end

function ENT:Think()
	local sT, eT = self:GetTime()
	local left = eT == 0 and 3 or eT - CurTime()
	local lowestNext = math.min(3, left)

	lowestNext = math.max(lowestNext, self.Choked and 0.5 or 0.05)

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
	-- no missing items; start
	self:TimeSlot()
	self:SyncVis()
	print("in changed")
end

function ENT:InTakeItem(inv, itm, toInv, slot, fromSlot, ply)
	-- taken something out = stop production, no questions asked
	self:SetTime(0, 0)
	self:TimeSlot(fromSlot)
end

function ENT:SetWork(b)
	if b ~= self:GetWorking() then
		self:SetWorkChanged(CurTime())
	end

	self:SetWorking(b)
	self:SyncVis()
end

function ENT:OutChanged()
	local itm = self.Out.Slots[1]
	local fr = 0
	if itm then
		fr = math.Remap(itm:GetAmount(), 0, itm:GetMaxStack(), 0, 100)
	end

	self:SetCocainerFr(fr)
	self:SyncVis()
end

function ENT:InMovedItem(inv, it, slot, it2, b4slot, ply)
	--self:SetTime(0, 0)
	--self:SetTime(0, 0)

	--self:TimeSlot(slot)
	--self:TimeSlot(b4slot)
end

function ENT:SetTime(sT, eT)
	--if sT then self.Status:Set("TimeStart", sT) end
	--if eT then self.Status:Set("TimeEnd", eT) end

	if sT then self:SetTime1(sT) end
	if eT then self:SetTime2(eT) end

	local st, et = self:GetTime()
	if st > 0 and et > 0
		and self:IsPowered() and not self.Choked then

		self:SetWork(true)
	else
		self:SetWork(false)
	end
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
	self:TimeSlot()
end

function ENT:OnUnpower()
	self:TimeSlot()
end