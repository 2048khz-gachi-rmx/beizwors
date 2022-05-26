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

function ENT:OnRemove()
	local spos = self:GetPos() + self:OBBCenter()
	for k,v in pairs(self.InVault:GetItems()) do
		local drop = ents.Create("dropped_item")

		drop:PickDropSpot({self}, {
			DropOrigin = spos,
		})

		self.InVault:RemoveItem(v, true)

		drop:SetCreatedTime(CurTime())
		drop:SetItem(v)
		drop:Spawn()
		drop:Activate()
		--drop:PlayDropSound(i2)
	end
end

--[=[
function ENT:RequestInVault(ply)
	-- im pretty sure like all of this is redundant; i could just
	-- use crossinv and hook onto pre/post, lol


	local inv, why1 = Inventory.Networking.ReadInventory(ply)
	local item, why2 = Inventory.Networking.ReadItem(inv)

	if not item then
		print("vault < backpack: no item", why1, why2)
		return false
	end

	if not inv.IsBackpack then
		print("vault < backpack: not backpack")
		return false
	end

	local slNum = net.ReadUInt(8)
	local slot = self.InVault:ValidateSlot( slNum )
	if not slot then printf("vault < backpack: bad slot (%s)", slNum) return false end

	--[[local cur = #self.InVault:GetSlots()
	if cur == self.InVault.MaxSlots then print("cant fit") return end]]

	local into = slot

	self._Allow = true
	local ok = inv:CrossInventoryMove(item, self.InVault, into, ply)
	self._Allow = false -- this sucks
	if not ok then
		errorNHf("crossinv gave shit? %s", ok)
		return false
	end


	ok:Then(function()
		self.Status:Set(into, 0)
		self.Status:Network()
		ply:UpdateInventory(inv)
		self:SendInfo(ply)
		self:UpdateState()
	end, function(...)
		print("bad move wtf", ...)
	end)
end]=]

function ENT:InVaultNewItem(myInv, itm, fromInv, slot, fromSlot, ply)
	self.Status:Set(slot, 0)
	self.Status:Network()
	if IsValid(ply) then
		ply:UpdateInventory(fromInv)
		self:SendInfo(ply)
	end
	self:UpdateState()
end

function ENT:PoweredThink(pw)
	local ch = false

	for i=1, self.InVault.MaxItems do
		local it = self.InVault:GetItemInSlot(i)
		if not it then continue end

		local to = it:GetTotalTransferCost()
		if self.Status:Get(i) == to then continue end

		local have = self.Status:Get(i, 0)
		local give = math.min(to - have, pw) -- this can be negative btw
		self.Status:Set(i, have + give)
		ch = true

		if give > 0 then
			if self.Status:Get(i) == to then
				-- just completed transfer
				self:UpdateState()
			end
		end

		pw = pw - math.max(0, give)
		if pw == 0 then break end
	end

	if ch then
		self.Status:Network()
	end
end

--[==================================[
		  allowing vault-take
--]==================================]

hook.Add("Vault_CanMoveTo", "Digitizer", function(vt, itm, from, slot)
	local dig = from:GetOwner()
	if not IsValid(dig) or not dig.IsMatterDigitizer then return end

	local sl = itm:GetSlot()
	if dig.Status:Get(sl, 0) >= itm:GetTotalTransferCost() then return true end
end)

local function findMDig(ply)
	local subs = ply:GetSubscribedTo()

	for k,v in ipairs(subs) do
		if not v.IsMatterDigitizer then continue end
		return v
	end
end

hook.Add("Vault_CanMoveFrom", "Digitizer", function(inv, ply, itm, inv2, slot)
	if not inv2.IsBackpack then return end

	local subs = ply:GetSubscribedTo()

	local found = findMDig(ply)
	if not found then return end

	local cost = itm:GetTotalTransferCost() --it.AttemptSplit)
	local grid = found:GetPowerGrid()

	if not grid then return end
	if not grid:HasPower(cost) then return end

	return true
end)

--[==================================[
	  draining post-vault-take
--]==================================]

local function wth(ply, ent)
	errorNHf("MDig managed to allow transfer but not take power...!? %s, %s", ply, ent)
end

hook.Add("Vault_CrossInventoryMovedFrom", "Digitizer", function(inv, itm)
	local found = findMDig(inv:GetOwner())
	if not found then return end -- moved not via mdig perhaps

	local cost = itm:GetTotalTransferCost() --it.AttemptSplit)
	local grid = found:GetPowerGrid()

	if not grid then wth(ply, "no grid " .. tostring(ent)) return end

	local a, b = grid:TakePower(cost)
	if not a then wth(ply, "no power in grid " .. cost) return end
end)

hook.Add("Vault_CrossStackOut", "Digitizer", function(inv, itmFrom, itmTo, amt)
	local found = findMDig(inv:GetOwner())
	if not found then return end

	local cost = itmFrom:GetTotalTransferCost(amt)
	local grid = found:GetPowerGrid()

	if not grid then wth(ply, "no grid " .. tostring(ent)) return end

	local a, b = grid:TakePower(cost)
	if not a then wth(ply, "no power in grid " .. cost) return end
end)

--[=[
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
]=]

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
