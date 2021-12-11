include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:Initialize()

end

function ENT:Draw()
	self:DrawModel()
end

function ENT:SendItem(slot, itm)
	print("Sending item:", slot, itm)
end

function ENT:OpenMenu()
	local frSize = ScrW() < 1200 and 500 or
			ScrW() < 1900 and 550 or 650

	local st = Inventory.Panels.PickSettings()
	st.NoAutoSelect = true

	local inv = Inventory.Panels.CreateInventory(LocalPlayer().Inventory.Backpack,
		true, st)

	--inv:SetTall(350)
	inv:CenterVertical()

	local vt = Inventory.Panels.CreateInventory(LocalPlayer().Inventory.Vault,
		true, st)

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
	vt:SetRetractedSize(0)
	inv:SetRetractedSize(0)
	Inventory.MatterDigitizerPanel = vt

	vt:On("ItemDropOn", "Send", function(_, itmPnl, invPnl, item)
		self:SendItem(itmPnl:GetSlot(), item)
		return false
	end)

	inv:On("ItemDropFrom", "Send", function(_, itmPnl, invPnl, item)

	end)
end


net.Receive("mdigitizer", function()
	local e = net.ReadEntity()
	e:OpenMenu()
end)