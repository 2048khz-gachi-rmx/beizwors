--

function ENT:FillNamePanel(name, dropper)
	local nameDT = DeltaText()
		:SetFont("MRM32")

	nameDT.AlignY = 0
	nameDT.AlignX = 1

	name:SetTall(draw.GetFontHeight(nameDT:GetFont()))

	local piece, key = nameDT:AddText("")
	nameDT._piece = piece
	nameDT:CycleNext()

	local tr1 = piece:AddFragment("Tier ")
	local tr2 = piece:AddFragment("  ")
	local nm = piece:AddFragment("")
	local bp = piece:AddFragment(" Blueprint")

	local first = true

	function name:Paint(w, h)
		local itm = dropper.Blueprint
		if not itm then return end

		piece:ReplaceText(tr2, ("%d "):format(itm:GetTier()), nil, first)
		piece:ReplaceText(nm, ("%s"):format(itm:GetResultName()), nil, first, {Delay = 0.1, Length = 0.3})
		first = false

		DisableClipping(true)
			nameDT:Paint(w / 2, 0)
		DisableClipping(false)
	end

	name:SetTall(draw.GetFontHeight(nameDT:GetFont()))
end

local dtFont = "BS20"

local function diffTable(self, cur, master)
	local new, gone = {}, {}
	local have = {} -- lookup: [id] = amt

	for k,v in ipairs(master) do
		have[v[1]] = v[3]
		if not cur[v[1]] then
			gone[#gone + 1] = v -- entry is gone in current reqs
		else
			v[3] = cur[v[1]] -- update amount of existing entry
		end
	end

	for k,v in pairs(cur) do
		if not have[k] then
			local ret = self:GenerateDisplay(k, v)
			new[#new + 1] = {k, ret, v}
		end
	end

	for k,v in ipairs(new) do
		master[#master + 1] = v
		self:MemberLerp(v, 4, 1, 0.3, 0, 0.3)
	end

	for k,v in ipairs(gone) do

		local an = self:MemberLerp(v, 5, 1, 0.3, 0, 0.3)
		if an then
			an:Then(function()
				table.RemoveByValue(master, v)
				if self.RemoveDisplay then self:RemoveDisplay(v) end
			end)
		end
	end

	local y = 0
	table.sort(master, function(a, b) return a[1] < b[1] end)

	for k,v in ipairs(master) do
		self:MemberLerp(v, 6, y, 0.3, 0, 0.3)
		y = y + draw.GetFontHeight(dtFont)
	end
end

function ENT:FillReqsPanel(reqs, itm)

	local reqDTs = {}

	function reqs:GenerateDisplay(reqID, reqAmt)
		local lbl = vgui.Create("DPanel", self)
		lbl:Dock(TOP)
		lbl:DockMargin(2, 0, 0, 2)
		lbl:SetTall(draw.GetFontHeight(dtFont))
		lbl.Color = color_white:Copy()
		lbl.itemAmt = reqAmt
		lbl.iid = reqID

		local base = Inventory.Util.GetBase(reqID)

		function lbl:Paint(w, h)
			draw.SimpleText(base:GetName(), dtFont, 8, 0, base:GetColor() or Colors.Red,
				0, 0)

			surface.SetTextColor(255, 255, 255)
			surface.DrawText(": ")

			surface.SetTextColor(self.Color)
			surface.DrawText(eval(base.GetAmountString or "x" .. reqAmt, base, reqAmt))
		end
		--[[local dt = DeltaText():SetFont(dtFont)
		local base = Inventory.Util.GetBase(reqID)
		dt.piece = dt:AddText("")

		dt.pnameid, dt.pname = dt.piece:AddFragment(base:GetName())
		dt.pname.Color = base:GetColor() or Colors.Red

		dt.pfillerid = dt.piece:AddFragment(": ")
		dt.pamtid, dt.pamt = dt.piece:AddFragment("x" .. tostring(reqAmt))
		dt.itemAmt = reqAmt
		dt.iid = reqID

		dt.pamt.Color = dt.pamt.Color:Copy()

		dt.AlignY = 0
		dt:CycleNext()
		self:MemberLerp(dt, "inFr", 1, 0.3, 0, 0.3)]]

		return lbl
	end

	local itReqs = itm:GetRecipe()

	for k,v in pairs(itReqs) do
		reqDTs[#reqDTs + 1] = reqs:GenerateDisplay(k, v)
	end

	local iutil = Inventory.Util
	local invs = iutil.GetUsableInventories(LocalPlayer())

	function reqs:PaintReqs(w, h)
		--[[local reqs = itm:GetRecipe()

		local line_h = draw.GetFontHeight(dtFont)
		local total_h = 0

		for k,v in ipairs(reqDTs) do
			local here = v.inFr or 0
			total_h = total_h + line_h * here
		end

		local y = h / 2 - total_h / 2

		for k,v in ipairs(reqDTs) do
			local dt = v
			local here = v.inFr or 0

			dt.piece.Alpha = here * 255

			local amt = 0
			for _, inv in ipairs(invs) do
				amt = amt + iutil.GetItemCount(inv, v.iid)
			end

			local enough = amt >= v.itemAmt

			self:LerpColor(dt.pamt.Color, enough and color_white or Colors.Red, 0.3, 0, 0.3)

			dt:Paint(8, y)
			y = y + line_h * here
		end]]

		for k,v in ipairs(reqDTs) do
			local amt = 0
			for _, inv in ipairs(invs) do
				amt = amt + iutil.GetItemCount(inv, v.iid)
			end

			local enough = amt >= v.itemAmt
			self:LerpColor(v.Color, enough and color_white or Colors.Red, 0.3, 0, 0.3)
		end
	end

	function reqs:Paint(w, h)
		DisableClipping(true)
			surface.SetDrawColor(100, 100, 100)
			surface.DrawLine(w + 1, h * 0.2, w + 1, h * 0.8)
		DisableClipping(false)

		self:PaintReqs(w, h)
	end
end


function ENT:FillModsPanel(mods, bp)
	local itm = bp

	function mods:GenerateDisplay(modName, tier)
		local mup = vgui.Create("MarkupText", mods)
		mup:SetWide(mods:GetWide())
		mup:Dock(TOP)

		--mup:CenterHorizontal()
		mup.nm = modName
		--mup:Debug()

		local mod = Inventory.Modifiers.Get(modName)
		mod:GenerateMarkup(itm, mup, tier)

		return mup
	end

	--[[function mods:PaintMods(w, h, itm)
		local y = 4

		for k,v in ipairs(mods) do
			local mup = v[2]
			local here = v[4] or 0
			local gone = v[5] or 0

			mup:SetWide(self:GetWide())
			mup:SetAlpha( (here - gone) * 255 )
			mup:SetPos(0, y)
			y = y + (mup:GetTall() + 4) * (here - gone)
		end

		self:SetTall(y)
		self:GetParent():SetTall(y) -- WTF
	end]]

	function mods:Paint(w, h)
		local sx, sy = self:LocalToScreen(0, 0)
		render.PushScissorRect(sx, sy, sx + w, sy + h)
		--self:PaintMods(w, h, bp)
	end

	function mods:PaintOver()
		render.PopScissorRect()
	end

	for k,v in pairs(bp:GetModifiers()) do
		mods:GenerateDisplay(k, v)
	end
end

function ENT:CreateBlueprintInfo(bp, info, old)
	if old then
		local hide = info:HideAutoCanvas("BlueprintInfo:" .. old:GetNWID())
		if hide then
			print("hide called")
			hide:Dock(NODOCK)
			hide:MoveBy(32, 0, 0.2, 0, 2.7)
		end
	end

	local cv, new = info:GetAutoCanvas("BlueprintInfo:" .. bp:GetNWID(), "InvisPanel")
	if not new then
		cv:Dock(NODOCK)
		cv:PopInShow(0.2, 0.1)
		cv:MoveBy(-32, 0, 0.5, 0.1, 0.3):Then(function()
			cv:Dock(FILL)
		end)
		return
	end

	cv:Dock(FILL)
	cv:InvalidateParent(true)
	cv:Dock(NODOCK)

	cv:PopIn(0.3)
	cv.X = 32
	cv:MoveBy(-32, 0, 0.5, 0, 0.3)

	local reqs = vgui.Create("FScrollPanel", cv, "Reqs canvas")
	reqs:Dock(LEFT)
	reqs.NoDraw = true
	self:FillReqsPanel(reqs, bp)
	reqs:SetSize(cv:GetWide() * 0.4 - 2, cv:GetTall())

	local modScr = vgui.Create("FScrollPanel", cv, "Mods scroller")
	modScr:Dock(RIGHT)
	modScr.NoDraw = true
	modScr.X = reqs:GetWide() + 3
	modScr:SetSize(cv:GetWide() - reqs:GetWide() - 3, cv:GetTall())

	-- local mods = vgui.Create("InvisPanel", modScr, "Mods canvas")
	-- mods:Dock(FILL)

	function cv:PerformLayout()
		reqs:SetSize(cv:GetWide() * 0.4 - 2, cv:GetTall())
		modScr:SetSize(cv:GetWide() - reqs:GetWide() - 3, cv:GetTall())
		--mods:SetSize(modScr:GetWide(), modScr:GetTall())
	end

	--cv:PerformLayout()
	
	self:FillModsPanel(modScr:GetCanvas(), bp)
end

function ENT:CraftFromBlueprintMenu(open, main)
	local ent = self
	local inv = main.Inventory

	local CurItem

	if not open then
		local canv = main:HideAutoCanvas("bp")
		canv.Hidden = true
		canv:SetZPos(999)

		for k, slot in ipairs(inv:GetSlots()) do
			slot:Highlight()
		end

		return
	end

	local canvas, new = main:ShowAutoCanvas("bp", nil, 0.1, 0.2)
	canvas.Hidden = false
	canvas:SetZPos(0)
	--canvas:PopIn(0.1, 0.2)

	if new then main:PositionPanel(canvas) else return end

	for k, slot in ipairs(inv:GetSlots()) do

		slot:On("Think", canvas, function()
			if not canvas:IsVisible() or canvas.Hidden then return end

			local it = slot:GetItem()
			if not it then return end

			local should = it.IsBlueprint

			if not should and CurItem then
				local reqs = CurItem:GetRecipe()
				should = not not reqs[it:GetItemName()]
			end

			if not should then
				slot:Dehighlight()
			else
				slot:Highlight()
			end
		end)

	end

	local info = vgui.Create("InvisPanel", canvas)
	info:SetWide(canvas:GetTall())

	local dropper = vgui.Create("InvisPanel", canvas)
	dropper:SetSize(canvas:GetWide() * 0.95, canvas:GetTall() * 0.95)
	dropper:Center()

	dropper:Receiver("Item", function(self, pnls, drop)
		if not drop then return end

		local itm = pnls[1]:GetItem(true)

		if itm and itm.IsBlueprint then
			self:DropBlueprint(itm)
		end
	end)

	dropper.DropFrac = 0

	local dragBP = false
	local isHov = false

	hook.Add("InventoryItemDragStart", canvas, function(_, slot, item)
		if item.IsBlueprint then
			dragBP = item
		end
	end)

	hook.Add("InventoryItemDragStop", canvas, function(_, slot, item, rec)
		dragBP = false
	end)

	function info:Think()
		local bot = dropper.Y + dropper:GetTall()
		local h = canvas:GetTall() - bot

		if self:GetTall() ~= h then
			self:SetSize(canvas:GetWide(), h)
			self.Y = bot
		end
	end

	local desCol = Color(10, 10, 10)
	local curCol = Color(10, 10, 10)

	local ic = Icons.BlankBlueprint:Copy()
	ic:SetPreserveRatio(true)
	ic:SetSize(256, 192)

	local origW, origH = ic:GetSize()

	local dfs = {
		-- {frac, dropX, dropY, begoneFrac}
	}

	function dropper:BlueprintScale(w, h, sz)
		local iw, ih = ic:RatioSize(w * 0.9, h * 0.9)
		iw, ih = iw * sz, ih * sz

		return iw, ih
	end

	function dropper:DrawBlueprint(w, h, itm, dat)
		local df = dat[1]
		local lmx, lmy = unpack(dat, 2)

		local x, y = Lerp(df, lmx, w / 2), Lerp(df, lmy, h / 2)

		local sz = 0.75 + 0.25 * df
		local a = 120 + 135 * df

		if dat[4] then
			y = y + 32 * dat[4]
			a = a * (1 - dat[4])
			sz = 0.75 + (1 - dat[4]) * 0.25
		end

		local iw, ih = self:BlueprintScale(w, h, sz)

		surface.SetDrawColor(255, 255, 255, a)
		itm:PaintBlueprint(x - iw / 2, y - ih / 2, iw, ih, false, false)
	end

	function dropper:DrawGhostBlueprint(w, h, itm)
		local mx, my = self:ScreenToLocal(gui.MousePos())
		local iw, ih = self:BlueprintScale(w, h, 0.75)

		surface.SetDrawColor(255, 255, 255, 120)
		itm:PaintBlueprint(mx - iw / 2, my - ih / 2, iw, ih, false, false)
	end

	function dropper:DrawBlueprints(w, h)

		for itm, df in pairs(dfs) do
			self:DrawBlueprint(w, h, itm, df)
		end

		if dragBP and self.Blueprint ~= dragBP then
			self:DrawGhostBlueprint(w, h, dragBP)
		end
	end

	function dropper:Paint(w, h)
		surface.SetDrawColor(Colors.DarkGray:Unpack())
		surface.DrawRect(0, 0, w, h)

		isHov = self:IsHovered()

		local fr = self.DragFrac or 0

		local r = 10 + (dragBP and 1 or 0) * (isHov and 50 or 30)
		local g = 10 + (dragBP and 1 or 0) * (isHov and 160 or 90)
		local b = r

		desCol:Set(r, g, b)
		self:LerpColor(curCol, desCol, 0.3, 0, 0.3)

		self:To("HovFrac", isHov and 1 or 0, 0.3, 0, 0.3)
		self:To("DragFrac", dragBP and 1 or 0, 0.3, 0, 0.3)

		if not isHov and fr > 0 then
			self:To("GradSz", 2, 0.3, 0, 0.3)
		else
			self:To("GradSz", 0, 0.3, 0, 0.3)
		end

		local sz = self.GradSz or 0
		surface.SetDrawColor(curCol:Unpack())
		self:DrawGradientBorder(w, h, 3 + sz, 3 + sz)

		local rgb = 255
		local a

		if dragBP then
			a = 60 - self.HovFrac * 60
		else
			a = 60 + self.HovFrac * 60
		end

		if not self.Blueprint then
			surface.SetTextColor(rgb, rgb, rgb, a)
			draw.SimpleText2("Drop a blueprint here", "OS24", w/2, h/2, nil, 1, 1)
		end

		self:DrawBlueprints(w, h)

		self:Emit("Paint", w, h)
	end

	local btnCanv = vgui.Create("InvisPanel", info)
	btnCanv:Dock(BOTTOM)
	btnCanv:Hide()
	btnCanv:DockMargin(0, 4, 0, 4)

	info:Think()

	local name = vgui.Create("InvisPanel", info, "Name canvas")
	name:Dock(TOP)
	name:DockMargin(0, 4, 0, 4)
	self:FillNamePanel(name, dropper)
	info.NamePnl = name

	function dropper:DropBlueprint(itm)
		local old = self.Blueprint
		if self.Blueprint == itm then return end
		CurItem = itm

		local mx, my = self:ScreenToLocal(gui.MousePos())
		dfs[itm] = {0, mx, my}

		self:MemberLerp(dfs[itm], 1, 1, 0.4, 0, 0.2)

		if old then
			self:MemberLerp(dfs[old], 4, 1, 0.3, 0, 0.3):Then(function()
				dfs[old] = nil
			end)
		end

		self.Blueprint = itm

		local toW, toH = canvas:GetWide() * 0.6, canvas:GetTall() * 0.4
		self:SizeTo(toW, toH, 0.3, 0, 0.3)
		local an = self:MoveTo(canvas:GetWide() / 2 - toW / 2, self.Y, 0.3, 0, 0.3)

		if an and not old then
			an:Then(function()
				ent:CreateBlueprintInfo(itm, info, old)
			end)
		else
			ent:CreateBlueprintInfo(itm, info, old)
		end

		if not btnCanv:IsVisible() then
			btnCanv:Show()
			btnCanv:SetTall(0)
			btnCanv:SizeTo(-1, 48, 0.3, 0, 0.3)
		end
	end


	local doeet = vgui.Create("FButton", btnCanv)
	doeet:SetSize(info:GetWide() * 0.4)
	doeet.Label = "Create!"
	doeet:SetColor(Colors.Sky)
	info.Btn = doeet
	function btnCanv:PerformLayout()
		doeet:SetTall(self:GetTall() - 4)
		doeet:Center()
	end

	local iutil = Inventory.Util

	function doeet:Think()
		if not CurItem then self:SetEnabled(false) return end
		if not ent:BW_IsOwner(LocalPlayer()) then self:SetEnabled(false) return end

		local reqs = CurItem:GetRecipe()
		local invs = iutil.GetUsableInventories(LocalPlayer())

		local enough = true
		for id, need in pairs(reqs) do
			local amt = 0
			for _, inv in ipairs(invs) do
				amt = amt + iutil.GetItemCount(inv, id)
			end

			if amt < need then enough = false break end
		end

		self:SetEnabled(enough)
	end

	function doeet:DoClick()
		local ns = Inventory.Networking.Netstack()
		ns:WriteInventory(CurItem:GetInventory())
		ns:WriteItem(CurItem)

		local pr = net.StartPromise("Workbench")
			net.WriteEntity(ent)
			net.WriteBool(true)
			net.WriteNetStack(ns)
		net.SendToServer()

		pr:Then(function(...)
			print("client - crafting promise success")
			main:PopOut()
		end, function(...)
			local why = net.ReadString()
			print("client - crafting failure", why)
		end)
	end
end