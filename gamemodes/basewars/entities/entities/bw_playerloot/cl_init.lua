include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:CL_Init()

end

function ENT:Draw()
	self:DrawModel()
end

function ENT:CreateWindow()
	local f = Inventory.Panels.CreateInventory(self.Storage, true)
	f:Center()
	f:Bond(self)
	f:MakePopup()

	local inv = Inventory.Panels.CreateInventory( Inventory.GetTemporaryInventory(LocalPlayer()), true )
	inv:Center()
	inv:Bind(self)
	inv:MakePopup()

	inv:Bind(f)
	f:Bind(inv)

	local pad = 8
	local total_w = f:GetWide() + inv:GetWide() + pad
	inv.X = ScrW() / 2 - total_w / 2
	f.X = ScrW() / 2 + pad / 2

	f:GetInventoryPanel():On("Click", "Transfer", function(_, _, _, itm)
		local sl = LocalPlayer():GetBackpack():GetFreeSlot()
		if not sl or not input.IsControlDown() then return end

		LocalPlayer():GetBackpack()
			:RequestPickup(itm)
	end)
end


net.Receive("PlayerlootOpen", function()
	local e = net.ReadEntity()
	if not IsValid(e) then return end

	e:CreateWindow()
end)