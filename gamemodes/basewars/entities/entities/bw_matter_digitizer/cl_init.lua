include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:CLInit(me)
	self:CreateInventories()
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:SendItem(slot, itm)
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

local overlap = 8

function ENT:MakeToFrom(width, vault, bp)
	local ent = self

	local height = 48

	local unhovTime = 0

	local toVt = vgui.Create("GradPanel")
	toVt:Bond(vault)
	toVt:SetColor(Colors.Gray)
	toVt:SetSize(width, height + overlap)
	toVt:CenterHorizontal()
	toVt.Y = bp.Y + bp:GetTall() * 0.25

	local titleFont, pwFont, timeFont = "OSB20", "BS18", "OS16"
	local total_h, pwH, tmH = draw.GetFontHeights(pwFont, timeFont)
	total_h = total_h + 2

	local arrSize = total_h

	local ic = Icons.Electricity:Copy()
	ic:SetColor(Colors.LighterGray)

	local clock = Icons.Clock:Copy()
	clock:SetColor(Colors.LighterGray)

	local costCol = Colors.LighterGray:Copy()
	local noPwCol = Colors.Reddish:Copy()

	local function doAlpha(col)
		local a = unhovTime and math.Remap(SysTime() - unhovTime, 0, 0.8, 1, 0) or 1
		a = Ease(a, 1.2)
		col.a = a * 255
	end

	function toVt:PostPaint(w, h)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawMaterial("https://i.imgur.com/jFHSu7s.png", "arr_right.png",
				arrSize / 2 + w * 0.02, h / 2, arrSize, arrSize, 180)

		local y = h / 2 - arrSize / 2

		local icSz = pwH

		local x = w * 0.05 + arrSize + 8

		local iw, ih = ic:Paint(x, y, icSz, icSz)

		if self.Cost then
			draw.SimpleText(Language("Power", math.floor(self.Cost)), pwFont,
				x + iw, y, costCol)
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

			doAlpha(costCol)

			draw.SimpleText(tStr, timeFont, x + iw + 2, y, costCol)
			surface.SetFont("EXM16")
			surface.DrawText(rStr)
		end

		y = y + tmH
	end

	-- shameless copypaste

	local fromVt = vgui.Create("GradPanel")
	fromVt:Bond(vault)
	fromVt:SetColor(Colors.Gray)
	fromVt:SetSize(width, height + overlap)
	fromVt:CenterHorizontal()
	fromVt.Y = vault.Y + vault:GetTall() * 0.75 - fromVt:GetTall()

	local total_h = pwH

	function fromVt:PostPaint(w, h)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawMaterial("https://i.imgur.com/jFHSu7s.png", "arr_right.png",
				w - (arrSize / 2 + w * 0.02), h / 2, arrSize, arrSize, 0)

		local x = w * 0.05

		x = x + 8

		local icSz = math.ceil(height * 0.4)

		local iw, ih = ic:Paint(x, math.ceil(h / 2 - icSz / 2), icSz, icSz)

		if self.Cost then
			local col = costCol

			local cost = self.Cost
			local grid = ent:GetPowerGrid()

			if not grid or not grid:HasPower(cost) then
				col = noPwCol
			end

			doAlpha(col)

			draw.SimpleText(Language("Power", math.floor(self.Cost)), pwFont,
				x + iw, h / 2, col, 0, 1)
		end
	end

	hook.Add("InventoryItemDragStart", toVt, function(_, itFr, itm)
		if not itm then return end

		unhovTime = math.huge

		if itFr.IsBuffer then
			local it = itFr:GetItem(true)
			local pwNeed = it:GetTotalTransferCost()
			local fr = math.Remap(ent.Status:Get(itFr:GetSlot(), 0), 0, pwNeed, 0, 1)

			if fr >= 1 then
				vault:Highlight()
				return
			end
		end

		if not itm:GetInventory() then return end

		if itm:GetInventory().IsVault then
			vault:FadeQueue(true)
			return
		end

		vault:Fade()
	end)

	hook.Add("InventoryItemDragStop", toVt, function(_, itFr, itm, rec)
		itm = itm or rec:GetItem() -- huh
		unhovTime = SysTime()  + 0.25

		if itFr:GetInventory().IsVault then
			vault:FadeQueue(false)
			return
		end

		vault:Unhighlight()
	end)

	hook.Add("InventoryItemHovered", toVt, function(_, itFr, itm)
		if not itm then return end
		local inv = itm:GetInventory()
		if not inv or (not inv.IsVault and not inv.IsBackpack) then return end

		unhovTime = nil


		if itm:GetInventory().IsVault then
			fromVt.Cost = fromVt.Cost or 0
			fromVt:To("Cost", itm:GetTotalTransferCost(), 0.1, 0, 0.3)
			toVt.Cost = nil
		elseif itm:GetInventory().IsBackpack then
			toVt.Cost = toVt.Cost or 0
			toVt:To("Cost", itm:GetTotalTransferCost(), 0.1, 0, 0.3)
			fromVt.Cost = nil
		end
	end)

	hook.Add("InventoryItemUnhovered", toVt, function(_, itFr, itm)
		if not itm then return end

		if unhovTime ~= math.huge then
			unhovTime = SysTime() + 0.25
		end
		--[[fromVt.Cost = nil
		toVt.Cost = nil]]
	end)

	return fromVt, toVt
end

function ENT:MakeItemFrames(betweenW, vault, bp, inVt, outVt)
	local ent = self

	local hold = vgui.Create("FIconLayout")
	hold:Bond(vault)
	hold:SetSize(betweenW - 16, 80)
	hold:Center()
	hold:DockPadding(8, 8 + 4, 8, 24)
	hold:SetColor(Colors.DarkGray)
	hold.UseDockProperties = true
	hold.MarginX = 8

	hold.Y = inVt.Y + inVt:GetTall() - overlap

	local col = Colors.Sky:Copy()

	for i=1, self.MaxQueues do
		local sl = hold:Add("ItemFrame")
		sl:SetSize(64, 64)

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

		-- vault <- digitizer -> backpack
		sl:On("Click", "Transfer", function(self)
			if not self:GetItem(true) then return end

			if input.IsControlDown() then
				local it = self:GetItem(true)

				local pw = ent.Status:Get(self:GetSlot(), 0) == it:GetTotalTransferCost()

				if pw then
					-- charged items go to vault
					LocalPlayer():GetVault()
						:RequestPickup(self:GetItem(true))
				else
					-- uncharged items go to backpack
					LocalPlayer():GetBackpack()
						:RequestPickup(self:GetItem(true))
				end

				--[[LocalPlayer():GetBackpack()
					:StackInfo(self:GetItem(true))]]
			end
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

	function hold:Fade()
		self:AlphaTo(120, 0.2, 0, 0.3)
		self:SetMouseInputEnabled(false)
	end

	function hold:Unfade()
		self:AlphaTo(255, 0.2, 0, 0.3)
		self:SetMouseInputEnabled(true)
	end

	hold.widths = {}

	function hold:PostPaint(w, h)
		local has_active = false

		for k,v in ipairs(self.Panels) do
			local it = v:GetItem(true)
			--if not it then continue end

			local pwNeed = it and it:GetTotalTransferCost() or 0
			local fr = it and math.Remap(ent.Status:Get(k, 0), 0, pwNeed, 0, 1) or 0
			local left = (pwNeed - ent.Status:Get(k, 0)) / ent:GetTransferRate() * BaseWars.Bases.PowerGrid.ThinkInterval
			local txt = it and ("%d%% (%s)"):format(
				fr * 100, string.FormattedTime(left, "%01d:%02d")
			) or "0%"

			surface.SetFont("MR16")
			local tw, th = surface.GetTextSize(txt)
			self.widths[k] = self.widths[k] or tw
			self:MemberLerp(self.widths, k, tw, 0.2, 0, 0.3)

			draw.SimpleText2(txt, nil,
				v.X + v:GetWide() / 2 - self.widths[k] / 2, v.Y + v:GetTall(),
				has_active and Colors.Gray or Colors.LighterGray)

			if fr < 1 then
				has_active = true
			end
		end
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
	itQ:SetZPos(fromVt:GetZPos() - 1)
	-- inv:DoAnim()

	vt:MakePopup()
	vt.Inventory = inv
	vt:SetRetractedSize(0)

	inv:SetRetractedSize(0)
	Inventory.MatterDigitizerPanel = vt

	inv:SetDraggable(false)
	vt:SetDraggable(false)

	local hgtCol = Color(90, 220, 90)

	function vt:FadeQueue(b)
		if b then
			itQ:Fade()
		else
			itQ:Unfade()
		end
	end

	function vt:Unhighlight()
		self:AlphaTo(255, 0.2)
		self:LerpColor(self:GetInventoryPanel().GradColor, color_black, 0.2, 0, 0.3)
		self:SetMouseInputEnabled(true)
		itQ:Dehighlight()
	end

	function vt:Highlight()
		inv:AlphaTo(255, 0.2)
		self:LerpColor(self:GetInventoryPanel().GradColor, hgtCol, 0.1, 0, 0.3)
		self:SetMouseInputEnabled(true)
	end

	function vt:Fade()
		self:AlphaTo(100, 0.1)
		self:LerpColor(self:GetInventoryPanel().GradColor, color_black, 0.2, 0, 0.3)
		self:SetMouseInputEnabled(false)
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

	-- backpack -> digitizer
	inv:GetInventoryPanel():On("Click", "Transfer", function(_, ifr, slot, itm)
		local sl = ent.InVault:GetFreeSlot()
		if not sl or not input.IsControlDown() then return end

		ent:SendItem(sl, itm)
	end)

	vt:GetInventoryPanel():On("Click", "Transfer", function(vtInv, ifr, slot, itm)
		local sl = LocalPlayer():GetBackpack():GetFreeSlot()
		if not sl or not input.IsControlDown() then return end

		LocalPlayer():GetBackpack()
			:RequestPickup(itm)

		--vtInv:MoveItem(inv:GetInventoryPanel():GetSlot(sl), ifr, itm)

		--[[local ok = itm:GetInventory()
			:RequestCrossInventoryMove(itm, LocalPlayer():GetBackpack(), sl)]]
	end)

	vt:On("ItemDropFrom", "Send", function(_, itmPnl, invPnl, item)
		if not invPnl:GetInventory() then return false end
		if invPnl:GetInventory() ~= vt:GetInventory() and not invPnl:GetInventory().IsBackpack then
			return false
		end
	end)
end


net.Receive("mdigitizer", function()
	local e = net.ReadEntity()
	e:OpenMenu()
end)