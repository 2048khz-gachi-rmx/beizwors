include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

util.AddNetworkString("BlueprintConstructor")

function ENT:Init(me)
	self.LastThink = CurTime()
end

function ENT:OpenMenu(ply)
	net.Start("BlueprintConstructor")
		net.WriteEntity(self)
	net.Send(ply)
end

function ENT:SendInfo(ply)
	if not ply and #self:GetSubscribers() == 0 then return end

	Inventory.Networking.NetworkInventory(ply or self:GetSubscribers(),
		self.Inventory, INV_NETWORK_FULLUPDATE)
end

function ENT:GetFinish()
	local finish = self:GetTimeLeft()

	if finish == 0 then
		finish = self:GetBPStart() + self:GetBPDur()
	else
		finish = finish + CurTime()
	end

	return finish
end

function ENT:OnPower()
	self:SetBPStart(CurTime() - (self:GetBPDur() - self:GetTimeLeft()))
	self:SetTimeLeft(0)
end

function ENT:OnUnpower()
	if self:GetActive() then
		local finish = self:GetFinish()
		self:SetTimeLeft(finish - CurTime())
	end
end

function ENT:ThinkFunc()
	local diff = CurTime() - self.LastThink
	local finish = self:GetFinish()

	local nextThink = self:GetActive() and
		math.min(finish - CurTime(), 0.5) or 0.5

	if diff < nextThink or not self:GetActive() then
		self:SetHasBP(self.Storage.Slots[1] ~= nil)
		self:NextThink(CurTime() + nextThink)
		return true
	end

	self:SetHasBP(self.Storage.Slots[1] ~= nil)
	self.LastThink = CurTime()

	if not self:IsPowered() then
		return
	end

	if finish < CurTime() then
		local itm = Inventory.Blueprints.Generate(self:GetBPTier(), self:GetBPType())
		itm._CtorPrinted = true
		self.Storage:InsertItem(itm):Then(function()
			self:SendInfo()
		end)

		self:SetActive(false)
		self:SetHasBP(true)
	end

end

function ENT:QueueCreation(tier, type)
	self:SetActive(true)
	self:SetBPType(type)
	self:SetBPTier(tier)
	self:SetBPDur( self:TimeForTier(tier) )
	self:SetBPStart(CurTime())
	self:SetHasBP(false)
	self.LastThink = CurTime()

	if not self:IsPowered() then
		self:SetTimeLeft(self:GetBPDur())
	end
end

function ENT:Use(ply)
	ply:Subscribe(self, 256)
	self:SendInfo(ply)
	self:OpenMenu(ply)
end

local bps

net.Receive("BlueprintConstructor", function(_, ply)
	bps = bps or Inventory.Blueprints

	local ent = net.ReadEntity()

	if not ent.BlueprintConstructor then print("not ctor") return end
	if not ply:IsSubscribed(ent) then print("not sub") return end

	local tier = net.ReadUInt(4)
	local type = net.ReadString()

	local can = ply:HasPerkLevel("blueprints", tier - 1)
	if not can then
		print("player has no research for tier ", tier)
		return
	end

	print("attempting to create tier, type:", tier, type)

	local base_cost = Inventory.Blueprints.Costs[tier]
	if not base_cost or base_cost < 0 then
		errorf("%s attempted to craft 'tier %d' blueprint which is invalid (cost: %s)", ply, tier, base_cost)
		return
	end

	local ttype = Inventory.Blueprints.Types[type]
	if not ttype then
		errorf("%s attempted to craft '%s' tier %d blueprint which does not exist", ply, type, tier)
		return
	end

	local full_cost = Inventory.Blueprints.GetCost(tier, type)
	if not full_cost then print("no tier or type:", tier, type) return end

	print("full cost is", full_cost)

	local ok = Inventory.TakeItems(ply.Inventory.Backpack, "blank_bp", full_cost)
	if not ok then print("player didnt have enough bp's (" .. full_cost .. ")") return end

	ent:QueueCreation(tier, type)
	ply:UI(ply.Inventory.Backpack)
end)