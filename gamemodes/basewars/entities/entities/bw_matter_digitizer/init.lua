include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

util.AddNetworkString("mdigitizer")

function ENT:Init(me)
	self:CreateInventories()
end

function ENT:Think()
	self:NextThink(CurTime() + 5)
	self:UpdateState()
	return true
end

function ENT:Use(ply)
	self:Subscribe(ply, 192)
	self:SendInfo(ply)

	net.Start("mdigitizer")
		net.WriteEntity(self)
	net.Send(ply)
end

function ENT:SendInfo(ply)
	ply:UpdateInventory(self.InVault)
end

function ENT:RequestInVault(ply)
	-- im pretty sure like all of this is redundant; i could just
	-- use crossinv and hook onto pre/post, lol

	local inv = Inventory.Networking.ReadInventory(ply)
	local item = Inventory.Networking.ReadItem(inv)

	if not inv.IsBackpack then print("vault < backpack: not backpack") return false end
	if not item then print("vault < backpack: no item") return false end

	local slNum = net.ReadUInt(8)
	local slot = self.InVault:ValidateSlot( slNum )
	if not slot then printf("vault < backpack: bad slot (%s)", slNum) return false end

	--[[local cur = #self.InVault:GetSlots()
	if cur == self.InVault.MaxSlots then print("cant fit") return end]]

	local into = slot

	inv:CrossInventoryMove(item, self.InVault, into):Then(function()
		self.want[into] = slot
		self.Status:Set(into, 0)
		ply:UpdateInventory(inv)
		self:SendInfo(ply)
		self:UpdateState()
	end, function(...)
		print("bad move wtf", ...)
	end)
end

function ENT:PoweredThink(pw)
	local key = 0

	for i=1, self.InVault.MaxItems do
		local it = self.InVault:GetItemInSlot(i)
		if not it then continue end

		local to = it:GetTotalTransferCost()
		if self.Status:Get(i) == to then continue end

		local have = self.Status:Get(i, 0)
		local give = math.min(to - have, pw)
		self.Status:Set(i, have + give)

		if give > 0 then
			if self.Status:Get(i) == to then
				-- just completed transfer
				self:UpdateState()
			end
		end

		pw = pw - give
		if pw == 0 then return end
	end
end

hook.Add("Vault_CanMoveTo", "Digitizer", function(vt, itm, from, slot)
	local dig = from:GetOwner()
	if not IsValid(dig) or not dig.IsMatterDigitizer then print("not dickitizer") return end

	local sl = itm:GetSlot()
	if dig.Status:Get(sl, 0) >= itm:GetTotalTransferCost() then print("transfer full") return true end
end)

hook.Add("Vault_CanMoveFrom", "Digitizer", function(inv, ply, itm, inv2, slot)
	local subs = ply:GetSubscribedTo()
	local found = false

	for k,v in ipairs(subs) do
		if not v.IsMatterDigitizer then continue end
		found = v
		break
	end

	if not found then return end

	local cost = itm:GetTotalTransferCost() --it.AttemptSplit)
	local grid = found:GetPowerGrid()

	if not grid then return end
	if not grid:TakePower(cost) then return end

	return true
end)

net.Receive("mdigitizer", function(len, ply)
	if not ply:Alive() then return end

	local ent = net.ReadEntity()
	if not ent or not ent.IsMatterDigitizer then return end
	if ply:Distance(ent) > 192 then return end

	local self = ent

	local in_vault = net.ReadBool()

	if in_vault then
		ent:RequestInVault(ply)
	--[[else
		ent:RequestFromVault(ply)]]
	end
end)


function ENT:OnFinalUpgrade()
	self:BaseRecurseCall("OnFinalUpgrade")
	self:UpdateState()
end

function ENT:UpdateState()
	local has_its = false

	for k,v in pairs(self.InVault:GetSlots()) do
		if self.Status:Get(k, 0) < v:GetTotalTransferCost() then
			has_its = true
			break
		end
	end

	self.PowerRequired = has_its and self:GetTransferRate() or self.IdleRate

	if self:GetPowerGrid() then
		self:GetPowerGrid():UpdatePowerOut()
	end
end
