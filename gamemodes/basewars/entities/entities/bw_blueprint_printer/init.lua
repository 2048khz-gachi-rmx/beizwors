include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

util.AddNetworkString("BlueprintPrinter")

function ENT:Init(me)
	self.LastPrint = CurTime()
	self.LastThink = CurTime()
	self:SetNextFinish(self.LastPrint + self.PrintTime)
end

function ENT:SendInfo(ply)
	if not ply and #self:GetSubscribers() == 0 then return end
	Inventory.Networking.NetworkInventory(ply or self:GetSubscribers()--[[Filter(ents.FindInPVS(self), true):Filter(IsPlayer)]], self.Inventory, INV_NETWORK_FULLUPDATE)
end

function ENT:IsFull()

	for i=1, self.Storage.MaxItems do
		local it = self.Storage.Slots[i]
		if not it then return false end

		if it:GetAmount() ~= it:GetBase():GetMaxStack() then return false end
	end

	return true

end

function ENT:OnRemove()
	local spos = self:GetPos() + self:OBBCenter()

	for k,v in pairs(self.Storage:GetItems()) do
		local drop = ents.Create("dropped_item")

		drop:PickDropSpot({self}, {
			DropOrigin = spos,
		})

		self.Storage:RemoveItem(v, true)

		drop:SetCreatedTime(CurTime())
		drop:SetItem(v)
		drop:Spawn()
		drop:Activate()
		--drop:PlayDropSound(i2)
	end
end

function ENT:ThinkFunc()
	local diff = CurTime() - self.LastThink
	if diff < math.min(CurTime() - self:GetNextFinish(), 0.5) then
		return
	end

	self.LastThink = CurTime()

	if not self:IsPowered() then self:SetNextFinish(self:GetNextFinish() + diff) return end

	if self:GetJammed() then
		if self:IsFull() then
			self.LastPrint = CurTime()
			return
		else
			self:SetJammed(false)
			self:SetNextFinish(self.LastPrint + self.PrintTime)
		end
	end

	if self:GetNextFinish() < CurTime() then
		if self:IsFull() then self:SetJammed(true) return end

		self.Storage:NewItem("blank_bp", function()
			self:SendInfo()
		end, nil, nil, nil, true)

		self.LastPrint = CurTime()
		self:SetNextFinish(self.LastPrint + self.PrintTime)

		self:SendInfo()
	end
end

function ENT:Use(ply)
	ply:Subscribe(self, 256)
	self:SendInfo(ply)
	net.Start("BlueprintPrinter")
		net.WriteEntity(self)
	net.Send(ply)
end

net.Receive("BlueprintPrinter", function(_, ply)
	local ent = net.ReadEntity()

	if not ent.BlueprintPrinter then return end
	if not ply:IsSubscribed(ent) then return end

	--self:SendInfo(ply)
end)