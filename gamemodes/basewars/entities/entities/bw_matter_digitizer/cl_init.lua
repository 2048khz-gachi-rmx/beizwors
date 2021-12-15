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

function ENT:MakeToFrom(width, vault, bp)
	local ent = self

	local toVt = vgui.Create("GradPanel")
	toVt:Bond(vault)
	toVt:SetColor(Colors.DarkGray)
	toVt:SetSize(width, 80)
	toVt:CenterHorizontal()
	toVt.Y = bp.Y + bp:GetTall() * 0.25

	local arrSize = toVt:GetTall() * 0.4
	local total_h, hdH, pwH, tmH = draw.GetFontHeights("OSB24", "BS20", "OS18")

	local ic = Icons.Electricity:Copy()
	ic:SetColor(Colors.LighterGray)

	local clock = Icons.Clock:Copy()
	clock:SetColor(Colors.LighterGray)

	function toVt:PostPaint(w, h)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawMaterial("https://i.imgur.com/jFHSu7s.png", "arr_right.png",
				arrSize / 2 + w * 0.02, h / 2, arrSize, arrSize, 180)

		local y = h * 0.5 - total_h / 2
		draw.SimpleText("Cost:", "OSB24",
			w * 0.05 + arrSize, y, color_white)

		y = y + hdH

		local icSz = pwH

		local x = w * 0.05 + arrSize + 8

		local iw, ih = ic:Paint(x, y, icSz, icSz)

		if self.Cost then
			draw.SimpleText(Language("Power", self.Cost), "BS18",
				x + iw, y, Colors.LighterGray)
		end

		y = y + pwH + 2

		icSz = 16
		x = x + 2
		local iw, ih = clock:Paint(x, y + tmH / 2 - icSz / 2, icSz, icSz)

		if self.Cost then
			local time = self.Cost / ent:GetTransferRate() * BaseWars.Bases.PowerGrid.ThinkInterval
			local tStr = string.FormattedTime(time, "%02d:%02d")
			local rStr = ("    - %s%s"):format(Language("Power", ent:GetTransferRate()),
				Language("PerTick"))

			draw.SimpleText(tStr, "BS18",
				x + iw + 2, y, Colors.LighterGray)
			surface.SetFont("EXM16")
			surface.DrawText(rStr)
		end

		y = y + tmH
	end

	-- shameless copypaste

	local fromVt = vgui.Create("GradPanel")
	fromVt:Bond(vault)
	fromVt:SetColor(Colors.DarkGray)
	fromVt:SetSize(width, 80)
	fromVt:CenterHorizontal()
	fromVt.Y = vault.Y + vault:GetTall() * 0.75 - fromVt:GetTall()

	function fromVt:PostPaint(w, h)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawMaterial("https://i.imgur.com/jFHSu7s.png", "arr_right.png",
				w - (arrSize / 2 + w * 0.02), h / 2, arrSize, arrSize, 0)

		local y = h * 0.5 - total_h / 2
		local x = w * 0.05
		draw.SimpleText("Cost:", "OSB24",
			x, y, color_white)

		x = x + 8
		y = y + hdH

		local icSz = pwH

		local iw, ih = ic:Paint(x, y, icSz, icSz)

		if self.Cost then
			draw.SimpleText(Language("Power", self.Cost), "BS18",
				x + iw, y, Colors.LighterGray)
		end

		y = y + pwH + 2

		icSz = 16
		x = x + 2
		local iw, ih = clock:Paint(x, y + tmH / 2 - icSz / 2, icSz, icSz)

		if self.Cost then
			local time = self.Cost / ent:GetTransferRate() * BaseWars.Bases.PowerGrid.ThinkInterval
			local tStr = string.FormattedTime(time, "%02d:%02d")
			local rStr = ("    - %s%s"):format(Language("Power", ent:GetTransferRate()),
				Language("PerTick"))

			draw.SimpleText(tStr, "BS18",
				x + iw + 2, y, Colors.LighterGray)
			surface.SetFont("EXM16")
			surface.DrawText(rStr)
		end
		y = y + tmH
	end

	hook.Add("InventoryItemHovered", toVt, function(_, itFr, itm)
		if not itm then return end

		if itm:GetInventory().IsVault then
			fromVt.Cost = itm:GetTransferCost()
		elseif itm:GetInventory().IsBackpack then
			toVt.Cost = itm:GetTransferCost()
		end
	end)

	hook.Add("InventoryItemUnhovered", toVt, function(_, itFr, itm)
		if not itm then return end

		--[[if itm:GetInventory().IsVault then
			fromVt.Cost = nil
		elseif itm:GetInventory().IsBackpack then
			toVt.Cost = nil
		end]]
	end)
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

	local betweenW = 250
	local sumW = vt:GetWide() + 8 + betweenW + 8 + inv:GetWide()

	self:MakeToFrom(betweenW, vt, inv)

	inv:Bond(vt)
	vt:Bond(inv)

	vt.X = ScrW() / 2 - sumW / 2
	inv.X = vt.X + betweenW + 8 + vt:GetWide() + 8
	-- inv:DoAnim()

	vt:MakePopup()
	vt.Inventory = inv
	vt:SetRetractedSize(0)

	inv:SetRetractedSize(0)
	Inventory.MatterDigitizerPanel = vt

	inv:SetDraggable(false)
	vt:SetDraggable(false)


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