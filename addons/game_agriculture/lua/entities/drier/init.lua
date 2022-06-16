include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

util.AddNetworkString("cocdrier")

function ENT:SVInit(me)

end

function ENT:OnCompleted()
	self.Buf:GetItemInSlot(1):SetProcessed(true)

	Inventory.Networking.UpdateInventory(self:GetSubscribers(), self.Inventory)
	return 2
end

function ENT:Use(ply)
	self:Subscribe(ply, 192)
	Inventory.Networking.NetworkInventory(ply, self.Inventory, INV_NETWORK_FULLUPDATE)

	net.Start("cocdrier")
	net.WriteEntity(self)
	net.Send(ply)
end

function ENT:InNewItem(inv, itm, from, slot, fromSlot, ply)
	self:UpdateTime()
end

function ENT:InTakeItem(inv, itm, toInv, slot, fromSlot, ply)
	self:UpdateTime(true)
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
	dropItms(self, self.Buf)
end

net.Receive("cocdrier", function(_, ply)
	local e = net.ReadEntity()
	if not IsValid(e) or not e.CocaineDrier then return end

	if not e:IsSubscribed(ply) then return end

	local b = net.ReadBool()
	e:SetLightsOn(b)
	e:UpdateTime()
end)