include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:Initialize()

end

function ENT:Draw()
	self:DrawModel()
end

function ENT:OpenMenu()
	local frSize = ScrW() < 1200 and 500 or
			ScrW() < 1900 and 550 or 650

	local inv = Inventory.Panels.CreateInventory(LocalPlayer().Inventory.Backpack,
		true, Inventory.Panels.PickSettings())

	--inv:SetTall(350)
	inv:CenterVertical()

	local vt = Inventory.Panels.CreateInventory(LocalPlayer().Inventory.Vault,
		true, Inventory.Panels.PickSettings())

	--vt:SetSize(frSize, inv:GetTall())
	--inv:SetWide(frSize)
	vt:CenterVertical()
	vt:PopIn()

	local sumW = vt:GetWide() + 8 + inv:GetWide()

	inv:Bond(vt)
	vt:Bond(inv)

	vt.X = ScrW() / 2 - sumW / 2
	inv.X = vt.X + vt:GetWide() + 8
	-- inv:DoAnim()

	vt:MakePopup()
	vt.Inventory = inv

	Inventory.MatterDigitizerPanel = vt

	print("add ems on")
	print(vt)
	print(inv)
	print("----")
	vt:On("ItemDropOn", "Send", function(self, rec, pnl, item)
		print("Vault drop - ", self, rec, pnl, item)
	end)

	inv:On("ItemDropFrom", "Send", function(self, rec, pnl, item)
		print("From BP drop - ", self, rec, pnl, item)
	end)
end


net.Receive("mdigitizer", function()
	local e = net.ReadEntity()
	e:OpenMenu()
end)