AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/props/CS_militia/furnace01.mdl"


ENT.Refinery = true

function ENT:Init()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self:DrawShadow(false)
	self:SetModelScale(1)

	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableMotion(true)
	end

	if not Inventory.Inventories.Entity then self:Remove() return end --created too early?

	self:SHInit()

	self.Queue = {}
	self._LastThink = CurTime()

	if not self:IsPowered() then
		self:OnUnpower()
	end
end

util.AddNetworkString("OreRefinery")

function ENT:RemoveOre(slot)
	local it = self.OreInput[slot]
	self.OreInput[slot]:Delete()
end

function ENT:TimeItem(slot, when)
	local itm = self.OreInput:GetSlots()[slot]

	local itmStart = itm.StartedRefining or when or CurTime()

	if self:IsPowered() then
		-- we're powered; status value means start of refining
		-- get unpowered penalty (if any), apply and network
		local pwStart = self.Status:Get("DepowerTime", CurTime())
		local diff = CurTime() - math.max(pwStart, itmStart)

		itm.StartedRefining = itmStart + diff
		self.Status:Set(slot, itm.StartedRefining)
	else
		-- we're unpowered; status value means % refined when power was gone
		-- calculate time between "ore added" and "power shutoff"
		local passed = self.Status:Get("DepowerTime", CurTime()) - itmStart
		local frac = passed / itm:GetBase():GetSmeltTime()

		itm.StartedRefining = itmStart -- assign initial time if it didnt exist
		self.Status:Set(slot, frac)
	end
end

function ENT:OnPower()
	if not self.Status:Get("DepowerTime") then return end -- already powered

	for k,v in pairs(self.OreInput:GetSlots()) do
		self:TimeItem(k)
	end

	self.Status:Set("DepowerTime", nil)
end

function ENT:OnUnpower()
	if not IsValid(self.Status) or not IsValid(self) then return end -- yes this can happen apparently
	if self.Status:Get("DepowerTime") then return end -- already unpowered

	self.Status:Set("DepowerTime", CurTime())

	for k,v in pairs(self.OreInput:GetSlots()) do
		self:TimeItem(k)
	end
end

function ENT:Think()
	if not self:IsPowered() then
		self:NextThink(CurTime() + 0.2)
		return true
	end

	local fin_amt = {}
	local changed = false

	for k,v in pairs(self.OreInput:GetItems()) do
		local fin = v.StartedRefining + v:GetBase():GetSmeltTime()

		if CurTime() > fin then
			local smTo = v:GetBase():GetSmeltsTo()
			--?
			if not smTo then
				errorNHf("didn't find what %s smelts to", v:GetName())
				continue
			end

			local smIt = Inventory.NewItem(smTo)
			local has_left, ok = Inventory.GetInventoryStackInfo(self.OreOutput, smIt)

			if not ok then
				errorNHf("GetInventoryStackInfo returned 2 falses (invalid item?) %s", v)
				v:Delete()
				continue
			end

			if has_left then continue end
			v:Delete()
			fin_amt[smTo] = (fin_amt[smTo] or 0) + 1
			changed = true
		end
	end

	for name, amt in pairs(fin_amt) do
		local new, stk, unstk = self.OreOutput:NewItem(name, nil, {Amount = amt})

		changed = changed or #new > 0 or #stk > 0
	end

	if changed then
		self:SendInfo()
	end

	self:NextThink(CurTime() + 0.2)
	return true
end

function ENT:AddInputItem(inv, item, slot)
	local new = Inventory.NewItem(item:GetItemID())
	--new:SetSlot(slot)
	new:SetAmount(1)
	new:SetOwner(inv:GetOwner())
	new.AllowedRefineryInsert = true

	return self.OreInput:InsertItem(new, slot)
end

function ENT:QueueRefine(ply, inv, item, slot, bulk)

	if bulk then
		local prs = {}
		local amt = item:GetAmount()
		local ins = 0

		for i=1, self.OreInput.MaxItems do
			if self.OreInput.Slots[i] then continue end
			if ins >= amt or not item:IsValid() then break end

			local ok, pr = xpcall(self.AddInputItem, GenerateErrorer("Refinery"),
				self, inv, item, i)
			if not ok then print("couldn't add input item to #" .. i) continue end

			pr.slot = i
			--[[pr:Then(function()
				if not IsValid(self) then return end

				for k,v in ipairs(prs) do
					self:TimeItem(i)
				end
			end)]]

			self:TimeItem(i)
			--prs[#prs + 1] = pr

			ins = ins + 1

			item:SetAmount(item:GetAmount() - 1)
		end

		--Promise.OnAll(prs):Then(function()
			local plys = Filter(ents.FindInPVS(self), true):Filter(IsPlayer)
			Inventory.Networking.NetworkInventory(plys, self.OreInput)
			Inventory.Networking.UpdateInventory(ply, inv)
			self.Status:Network()
		--end, GenerateErrorer("RefineryPromise"))
	else

		if slot > self.OreInput.MaxItems then print("slot higher than max", slot, self.OreInput.MaxItems) return end
		if self.OreInput.Slots[slot] then print("there's already an item in that slot") return end

		local ok, pr = xpcall(self.AddInputItem, GenerateErrorer("Refinery"),
			self, inv, item, slot)
		if not ok then return end

		pr:Then(function()
			if not IsValid(self) then return end

			self:TimeItem(slot)
			item:SetAmount(item:GetAmount() - 1)
			local plys = Filter(ents.FindInPVS(self), true):Filter(IsPlayer)
			self.Status:Network()

			Inventory.Networking.NetworkInventory(plys, self.OreInput)
			Inventory.Networking.UpdateInventory(ply, inv)
		end, GenerateErrorer("RefineryPromise"))

	end
end

-- deposit request
net.Receive("OreRefinery", function(len, ply)
	if not ply:Alive() then return end

	local ent = net.ReadEntity()
	if ply:Distance(ent) > 192 then return end

	local self = ent

	local inv = Inventory.Networking.ReadInventory(ply)
	local item = Inventory.Networking.ReadItem(inv)

	if not inv.IsBackpack then print("inventory is not a backpack") return end
	if not item then print("didn't get item") return end

	local bulk = net.ReadBool()

	if bulk then
		ent:QueueRefine(ply, inv, item, nil, bulk)
		return
	end

	local slot = net.ReadUInt(16)
	ent:QueueRefine(ply, inv, item, slot, bulk)

end)

function ENT:SendInfo()
	local all = Filter(ents.FindInPVS(self), true):Filter(IsPlayer)
	Inventory.Networking.NetworkInventory(all, self.Inventory, INV_NETWORK_FULLUPDATE)
end

function ENT:Use(ply)
	if not self:DoCooldown(ply, 1) then return end

	Inventory.Networking.NetworkInventory(ply, self.Inventory, INV_NETWORK_FULLUPDATE)
	net.Start("OreRefinery")
		net.WriteEntity(self)
		net.WriteUInt(0, 4)
	net.Send(ply)
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
	dropItms(self, self.OreInput)
	dropItms(self, self.OreOutput)
end