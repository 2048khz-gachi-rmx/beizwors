include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:CL_Init()

end

function ENT:Draw()
	self:DrawModel()
end

local function onBondRem(self, e)
	if not IsEntity(e) or self.byebye then return self.byebye and true or nil end

	self:MoveBy(-self.OffX, 0, 0.1, 0, 4)
	self:PopOut(0.1)
	self.byebye = true

	return false
end

function ENT:CreateWindow()
	local scale, scaleW = Scaler(1600, 900)

	self.Storage:SetName(self:GetPlayerName() .. "'s belongings")

	local f = Inventory.Panels.CreateInventory(self.Storage, true)
	f:Center()
	f:Bond(self)
	f:MakePopup()

	local inv = Inventory.Panels.CreateInventory( Inventory.GetTemporaryInventory(LocalPlayer()), true )
	inv:Center()
	inv:Bind(self)
	inv:MakePopup()

	local off = scaleW(48)

	inv.OffX = -off
	f.OffX = off

	inv:Bind(f)
	f:Bind(inv)

	inv:On("BondRemove", onBondRem)
	f:On("BondRemove", onBondRem)

	local pad = 8
	local total_w = f:GetWide() + inv:GetWide() + pad

	f.X = ScrW() / 2 - total_w / 2 - off
	inv.X = ScrW() / 2 + pad / 2 + off

	f:MoveBy(off, 0, 0.6, 0, 0.2)
	inv:MoveBy(-off, 0, 0.6, 0, 0.2)

	f:GetInventoryPanel():On("Click", "Transfer", function(_, _, _, itm)
		local sl = LocalPlayer():GetBackpack():GetFreeSlot()
		if not sl or not input.IsControlDown() then return end

		LocalPlayer():GetBackpack()
			:RequestPickup(itm)
	end)

	local ent = self
	local dist = ent.InteractDistance ^ 2
	f:On("Think", "Dist", function()
		if not IsValid(ent) then return end

		local cd = ent:GetPos():DistToSqr(LocalPlayer():GetPos())
		if cd > dist then onBondRem(inv, ent) onBondRem(f, ent) end
	end)
end


net.Receive("PlayerlootOpen", function()
	local e = net.ReadEntity()
	if not IsValid(e) then return end

	e:CreateWindow()
end)