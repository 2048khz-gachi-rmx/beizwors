include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:CLInit(me)
	self:CreateInventories()
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:SendItem(slot, itm)
	print("Sending item:", slot, itm)
	local ns = Inventory.Networking.Netstack()

	net.Start("mdigitizer")
		net.WriteEntity(self)
		net.WriteBool(true)
		ns:WriteInventory(itm:GetInventory())
		ns:WriteItem(itm)
		ns:WriteUInt(slot, 8)
		ns()
	net.SendToServer()
end

function ENT:FetchItem(slot, itm)
	print("Transferring item vault -> BP:", slot, itm)
	local ns = Inventory.Networking.Netstack()

	net.Start("mdigitizer")
		net.WriteEntity(self)
		net.WriteBool(false)
		ns:WriteInventory(itm:GetInventory())
		ns:WriteItem(itm)
		ns:WriteUInt(slot, 8)
		ns()
	net.SendToServer()
end

local overlap = 8

function ENT:MakeToFrom(width, vault, bp)
	local ent = self

	local height = 60

	local toVt = vgui.Create("GradPanel")
	toVt:Bond(vault)
	toVt:SetColor(Colors.DarkGray)
	toVt:SetSize(width, height + overlap)
	toVt:CenterHorizontal()
	toVt.Y = bp.Y + bp:GetTall() * 0.25

	local arrSize = height * 0.5

	local titleFont, pwFont, timeFont = "OSB20", "BS18", "OS16"
	local total_h, hdH, pwH, tmH = draw.GetFontHeights(titleFont, pwFont, timeFont)
	total_h = total_h + 2 + hdH * 0.125

	local ic = Icons.Electricity:Copy()
	ic:SetColor(Colors.LighterGray)

	local clock = Icons.Clock:Copy()
	clock:SetColor(Colors.LighterGray)

	function toVt:PostPaint(w, _h)
		local h = height
		surface.SetDrawColor(255, 255, 255)
		surface.DrawMaterial("https://i.imgur.com/jFHSu7s.png", "arr_right.png",
				arrSize / 2 + w * 0.02, h / 2, arrSize, arrSize, 180)

		local y = height * 0.5 - total_h / 2
		local tw, th = draw.SimpleText("Cost:", titleFont,
			w * 0.05 + arrSize, y, color_white)
		-- surface.DrawOutlinedRect(w * 0.05 + arrSize, y, 128, th)
		-- surface.DrawOutlinedRect(w * 0.05 + arrSize, y, 128, total_h)
		y = y + hdH

		local icSz = pwH

		local x = w * 0.05 + arrSize + 8

		local iw, ih = ic:Paint(x, y, icSz, icSz)

		if self.Cost then
			draw.SimpleText(Language("Power", self.Cost), pwFont,
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

			draw.SimpleText(tStr, timeFont,
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
	fromVt:SetSize(width, 64)
	fromVt:CenterHorizontal()
	fromVt.Y = vault.Y + vault:GetTall() * 0.75 - fromVt:GetTall()

	local total_h, hdH, pwH = draw.GetFontHeights(titleFont, pwFont)

	function fromVt:PostPaint(w, h)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawMaterial("https://i.imgur.com/jFHSu7s.png", "arr_right.png",
				w - (arrSize / 2 + w * 0.02), h / 2, arrSize, arrSize, 0)

		local y = h * 0.5 - total_h / 2
		local x = w * 0.05
		draw.SimpleText("Cost:", titleFont,
			x, y, color_white)

		x = x + 8
		y = y + hdH

		local icSz = pwH

		local iw, ih = ic:Paint(x, y, icSz, icSz)

		if self.Cost then
			draw.SimpleText(Language("Power", self.Cost), pwFont,
				x + iw, y, Colors.LighterGray)
		end

		y = y + pwH + 2
	end

	hook.Add("InventoryItemDragStart", toVt, function(_, itFr, itm)
		if not itm then return end

		if itFr.IsBuffer then
			local it = itFr:GetItem(true)
			local pwNeed = it:GetTotalTransferCost()
			local fr = math.Remap(ent.Status:Get(itFr:GetSlot(), 0), 0, pwNeed, 0, 1)

			if fr >= 1 then
				vault:Highlight()
				return
			end
		end

		if not itm:GetInventory().IsBackpack then return end

		vault:Dehighlight()
	end)

	hook.Add("InventoryItemDragStop", toVt, function(_, itFr, itm, rec)
		vault:Unhighlight()
	end)

	hook.Add("InventoryItemHovered", toVt, function(_, itFr, itm)
		if not itm then return end
		if not itm:GetInventory() then return end

		if itm:GetInventory().IsVault then
			fromVt.Cost = itm:GetTotalTransferCost()
		elseif itm:GetInventory().IsBackpack then
			toVt.Cost = itm:GetTotalTransferCost()
		end
	end)

	hook.Add("InventoryItemUnhovered", toVt, function(_, itFr, itm)
		if not itm then return end

		fromVt.Cost = nil
		toVt.Cost = nil
	end)

	return fromVt, toVt
end

function ENT:MakeItemFrames(betweenW, vault, bp, inVt, outVt)
	local ent = self

	local hold = vgui.Create("FIconLayout")
	hold:Bond(vault)
	hold:SetSize(betweenW - 16, 80)
	hold:Center()
	hold.MarginX = 8

	hold.Y = inVt.Y + inVt:GetTall() - overlap

	local col = Colors.Sky:Copy()

	for i=1, self.MaxQueues do
		local sl = hold:Add("ItemFrame")
		sl:SetSize(56, 56)

		sl.Inventory = self.InVault
		sl:SetSlot(i)

		sl:BindInventory(sl.Inventory, sl:GetSlot())

		sl.OnItemDrop = function(...) hold:OnItemDrop(...) end

		sl:On("PostDrawBorder", "TransferProgress", function(self, w, h)
			local it = self:GetItem(true)
			local pwNeed = it:GetTotalTransferCost()
			local fr = math.Remap(ent.Status:Get(i, 0), 0, pwNeed, 0, 1)

			draw.RoundedBox(4, 0, h - fr * h, w, fr * h, col)
		end)

		sl:On("CanDrag", "CanTransfer", function(self, w, h)
			--[[local it = self:GetItem(true)
			local pwNeed = it:GetTotalTransferCost()
			local fr = math.Remap(ent.Status:Get(i, 0), 0, pwNeed, 0, 1)

			if fr ~= 1 then
				return false
			end]]
		end)

		sl.IsBuffer = true
	end

	hook.Add("Vault_CanMoveTo", hold, function(_, self, itm, from, slot)
		if from ~= ent.InVault then return end
		if ent.Status:Get(itm:GetSlot(), 0) >= itm:GetTotalTransferCost() then
			return true
		end
	end)

	hook.Add("Vault_CanMoveFrom", vault, function(_, inv, ply, itm, inv2, slot)
		local cost = itm:GetTotalTransferCost()
		local grid = ent:GetPowerGrid()

		if not grid then return false end
		if not grid:HasPower(cost) then return false end

		return true
	end)

	local hgtCol = Color(90, 220, 90)

	function hold:Highlight()
		self:LerpColor(self.GradColor, hgtCol, 0.1, 0, 0.3)
		self:To("GradSize", 2, 0.1, 0.1, 0.3)
	end

	function hold:Dehighlight()
		self:LerpColor(self.GradColor, color_black, 0.2, 0, 0.3)
		self:To("GradSize", 4, 0.1, 0, 0.3)
	end

	return hold
end

function ENT:OpenMenu()
	local frSize = ScrW() < 1200 and 500 or
			ScrW() < 1900 and 550 or 650

	local ent = self

	local st = Inventory.Panels.PickSettings()
	st.NoAutoSelect = true

	local inv = Inventory.Panels.CreateInventory(LocalPlayer().Inventory.Backpack,
		true, st)

	--inv:SetTall(350)
	inv:CenterVertical()

	local vt = Inventory.Panels.CreateInventory(LocalPlayer().Inventory.Vault,
		true, st)

	--inv:GetInventoryPanel().SupportsSplit = false
	--vt:GetInventoryPanel().SupportsSplit = false

	--vt:SetSize(frSize, inv:GetTall())
	--inv:SetWide(frSize)
	vt:CenterVertical()
	vt:PopIn()

	inv:Bond(vt)
	vt:Bond(inv)

	local betweenW = (64 + 8) * 3 + 16 * 2
	local sumW = vt:GetWide() + 8 + betweenW + 8 + inv:GetWide()

	vt.X = ScrW() / 2 - sumW / 2
	inv.X = vt.X + betweenW + 8 + vt:GetWide() + 8

	local fromVt, inVt = self:MakeToFrom(betweenW, vt, inv)
	local itQ = self:MakeItemFrames(betweenW, vt, inv, inVt, fromVt)

	-- inv:DoAnim()

	vt:MakePopup()
	vt.Inventory = inv
	vt:SetRetractedSize(0)

	inv:SetRetractedSize(0)
	Inventory.MatterDigitizerPanel = vt

	inv:SetDraggable(false)
	vt:SetDraggable(false)

	local hgtCol = Color(90, 220, 90)

	function vt:Unhighlight()
		self:AlphaTo(255, 0.2)
		self:LerpColor(self:GetInventoryPanel().GradColor, color_black, 0.2, 0, 0.3)
		itQ:Dehighlight()
	end

	function vt:Highlight()
		inv:AlphaTo(255, 0.2)
		self:LerpColor(self:GetInventoryPanel().GradColor, hgtCol, 0.1, 0, 0.3)
	end

	function vt:Dehighlight()
		self:AlphaTo(100, 0.1)
		self:LerpColor(self:GetInventoryPanel().GradColor, color_black, 0.2, 0, 0.3)
		itQ:Highlight()
	end

	function itQ:OnItemDrop(dropOn, dropWhat, item)
		ent:SendItem(dropOn:GetSlot(), item)
	end

	vt:GetInventoryPanel():On("CanSplit", "NoCross", function(self, itm, inv2)
		if self:GetInventory() ~= inv2 then return false end
	end)

	inv:GetInventoryPanel():On("CanSplit", "NoCross", function(self, itm, inv2)
		if self:GetInventory() ~= inv2 then return false end
	end)

	vt:On("ItemDropFrom", "Send", function(_, itmPnl, invPnl, item)
		if not invPnl:GetInventory() then return false end
		if invPnl:GetInventory() ~= vt:GetInventory() and not invPnl:GetInventory().IsBackpack then
			return false
		end
	end)

	inv:On("ItemDropFrom", "Send", function(_, itmPnl, invPnl, item)
		if not invPnl:GetInventory() then return false end
		if itmPnl:GetInventory().IsBackpack then return end

		if itmPnl:GetInventory().IsVault then
			self:FetchItem(itmPnl:GetSlot(), item)
			return false
		end
	end)
end


net.Receive("mdigitizer", function()
	local e = net.ReadEntity()
	e:OpenMenu()
end)