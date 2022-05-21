setfenv(1, _G)

BaseWars.Spawnmenu = BaseWars.Spawnmenu or {}
BaseWars.SpawnMenu = BaseWars.Spawnmenu
BaseWars.SpawnMenu.Highlight = BaseWars.SpawnMenu.Highlight or {}

local sm = BaseWars.Spawnmenu

local function IsGroup(ply, group)
	if not ply.CheckGroup then error("what the fuck where's ULX") return end
	if not IsValid(ply) or not ply:IsPlayer() then return end

	if (group == "vip" or group == "trusted") and ply:IsAdmin() then
		return true
	end

	if ply:CheckGroup(string.lower(group)) or ply:IsSuperAdmin() then
		return true
	end

	return false
end

local tohide = {}

hook.Add("OnSpawnMenuClose", "RemoveClouds", function()	--grrrrrrrrrr

	for k,v in pairs(tohide) do
		if not IsValid(v) then tohide[k] = nil continue end

		v:Remove()
	end

end)

--local b = bench("btns", 600)

function sm.MakeHeader(pnl)
	local hd, ics = pnl.Header, pnl.Icons
	local dat = pnl.Data

	if table.Count(dat.Tiers) <= 1 then return end

	local tierX = pnl:GetWide() / 2 + pnl.HeaderW / 2 + 16

	local tBtns = {}
	pnl.ActiveCat = "All"
	pnl.SwitchedCat = false

	local function makeTier(n)
		local tBtn = vgui.Create("FButton", hd)
		local key = #tBtns + 1
		tBtns[key] = tBtn

		tBtn:SetTall(hd:GetTall() * 0.8)
		tBtn:SetWide(tBtn:GetTall())
		tBtn:CenterVertical()
		tBtn.X = tierX + (key - 1) * (tBtn:GetWide() + 4)
		tBtn.RBRadius = 4
		tBtn.Shadow.Intensity = 1
		tBtn.Shadow.MaxSpread = 0.2
		tBtn.Cat = n

		function tBtn:Activate()
			pnl.ActiveCat = n
			pnl.SwitchedCat = true
			pnl:SetTier(self.Cat)
		end

		function tBtn:DoClick()
			if pnl.ActiveCat == self.Cat then return end
			self:Activate()
		end

		function tBtn:Think()
			if self.Cat == pnl.ActiveCat then
				self:SetColor(Colors.Sky)
			else
				self:SetColor(Colors.Button)
			end
		end

		return tBtn
	end

	local tAll = makeTier("All")
	tAll:SetIcon(Icons.Star)

	for k,v in pairs(dat.Tiers) do
		local tier = makeTier(k)
		tier:SetText("T" .. k)
	end
end

local function makeComingSoon(par)
	local pnl = vgui.Create("DPanel", par)
	pnl:SetWide(par:GetWide())
	pnl:SetTall(96)

	local col = Color(0, 0, 0, 180)
	local c2 = Color(0, 0, 0, 210)

	local font, text = "BSL36", "coming soon™"
	local tw, th = surface.GetTextSizeQuick(text, font)

	function pnl:Paint(w, h)
		draw.RoundedBoxEx(8, 0, 0, w, h, col, false, false, true, true)

		local u = -(CurTime() / 16) / 4 % 1
		local v = -(CurTime() / 24) / 4 % 1
		local u1 = u + w / 768
		local v1 = v + h / 512

		surface.DrawUVMaterial("https://i.imgur.com/y9uYf4Y.png", "whitestripes.png",
			0, 0, w, h, u, v, u1, v1)

		c2:SetDraw()

		local recEx = math.ceil(w * 0.05)
		local x = math.ceil(w / 2 - tw / 2 - recEx)
		surface.DrawRect(x, 0, tw + recEx * 2, h)

		local gradSz = math.ceil(w * 0.15)
		surface.SetMaterial(MoarPanelsMats.gl)
		surface.DrawTexturedRect(x + tw + recEx * 2, 0, gradSz, h)

		surface.SetMaterial(MoarPanelsMats.gr)
		surface.DrawTexturedRect(x - gradSz, 0, gradSz, h)

		draw.SimpleText(text, font, w / 2, h / 2, color_white, 1, 1)
	end

	par:On("Bruh", "aa", function()
		-- thx docking engine
		pnl:SetWide(par:GetWide())
	end)

	return pnl
end

local function createSubCategory(canv, cat_name, subcat_name, data)
	local items = data.Items

	local pnl = vgui.Create("InvisPanel", canv) --holder for diconlayout
	pnl.Category = cat_name
	pnl.Subcategory = subcat_name
	pnl.Data = data

	pnl:Dock(TOP)
	pnl:DockMargin(0, 8, 0, 4)
	pnl:SetWide(canv:GetWide())
	pnl:SetTall(5000)

	local headerSize = 32

	local hd = vgui.Create("InvisPanel", pnl)
	hd:Dock(TOP)
	hd:SetTall(headerSize)
	pnl.Header = hd

	local pnlcol = Colors.Gray:Copy()
	pnlcol.a = 160

	local ics = vgui.Create("FIconLayout", pnl)
	pnl.Icons = ics

	ics:Dock(BOTTOM)
	ics:DockMargin(4, 0, 4, 4)

	ics:SetSpaceX(4)
	ics:SetSpaceY(4)
	ics:SetBorder(4)

	ics.IncompleteCenter = false
	ics.AutoPad = false

	ics:On("ShiftPanel", "groovy", function(self, btn, x, y)
		local om = pnl.SwitchedCat and not btn._NoMove and btn._Moving

		btn._Moving = {x, y}
		btn._NoMove = false
		if not om then return end -- first layout, dont move em

		if om[1] == x and om[2] == y then return false end

		local data = btn.Data

		local leftX = -ics:GetWide() + btn.X
		local rightX

		local dist = ics:GetWide() -- - btn:GetWide()

		local xyeet = -dist
		local xfrom = -ics:GetWide() + x - btn:GetWide()

		if y ~= btn.Y and y ~= om[2] then
			local anim = btn:MoveTo(xyeet, btn.Y, math.min(dist / 350, 0.2), 0, 1.8)

			if anim then
				anim:Then(function()
					btn:SetPos(xfrom, y)
					btn:MoveTo(x, y, 0.25, 0, 0.2)
				end)
			else
				btn:SetPos(xfrom, y)
				btn:MoveTo(x, y, 0.25, 0, 0.2)
			end
		else
			btn:MoveTo(x, y, 0.2, 0, 0.3)
		end

		return false
	end)

	ics:On("LayoutResize", "groovy", function(self, newh)
		if not pnl.SwitchedCat then return end
		local delay = newh > self:GetTall() and 0 or 0.2
		self:SizeTo(-1, newh, 0.3, delay, 0.3)
		return newh
	end)

	local icscol = Color(240, 240, 240, 60)

	local bSz = 1
	local hdFont = "EX28"
	local hdHgt = draw.GetFontHeight(hdFont)
	local halfHgt = math.ceil(hdHgt / 2)
	local fontOffset = 0.125 -- I HATE TEXT RENDERING!!!
	local onefO = 1 - fontOffset

	local tw, th = surface.GetTextSizeQuick(subcat_name, hdFont)
	local iw = data.Icon and (data.Icon:GetWide() + 4) or 0
	tw = tw + iw

	pnl.HeaderW = tw

	sm.MakeHeader(pnl)

	function ics:Paint(w, h)
		draw.RoundedBox(8, 0, 0, w, h, icscol)
	end
	ics.PaintOver = nil
	local boksCol = Colors.LightGray:Copy()
	boksCol.a = 200

	function pnl:Paint(w, h)
		--DisableClipping(true)
		draw.BeginMask()

		--draw.DeMask()

			draw.RoundedStencilBox(8, bSz, bSz + halfHgt, w - bSz * 2, h - bSz * 2 - halfHgt, color_white)

			draw.SetMaskDraw(true)
			draw.RoundedBox(8, w / 2 - tw / 2 - halfHgt, 0, tw + halfHgt * 2, hdHgt * onefO, boksCol)
			draw.SimpleText2(subcat_name, hdFont, w / 2, -hdHgt * fontOffset, color_white, 1, nil, -iw)

			if data.Icon then
				data.Icon:Paint(w / 2 - (tw - iw) / 2 - iw / 2, 0, nil, hdHgt * onefO)
			end

			--surface.DrawOutlinedRect(w / 2 - tw / 2, 0, tw, th)
			draw.SetMaskDraw(false)
			--surface.DrawRect(w / 2 - tw / 2 - 8, 0, tw + 16, hdHgt)
		draw.DrawOp(1)
			draw.RoundedBox(8, 0, halfHgt, w, h - halfHgt, pnlcol)
		draw.FinishMask()

		--DisableClipping(false)

		draw.EnableFilters()
	end

	function pnl:PaintOver()
		draw.DisableFilters()
	end

	pnl.Items = {}

	if items[1] and items[1].Name == "soon" then
		local child = makeComingSoon(pnl)
		pnl:SetTall(child:GetTall() + 4 + headerSize)

		pnl:On("Bruh", "par", function()
			child.Y = headerSize - 4
			child:SetTall(pnl:GetTall() - child.Y)
		end)
	end

	local its = table.Copy(items)

	table.sort(its, function(a, b)
		--if a.Level == b.Level then
			return a.Price < b.Price
		--else
		--	return a.Level < b.Level
		--end
	end)

	function pnl:SetTier(t)
		if t == "All" then
			ics.ToLayout = nil
			ics:InvalidateLayout()

			for _, dat in ipairs(its) do
				local btn = pnl.Items[dat]
				btn:PopInShow(0.1, 0.05, nil, true)
				btn._NoMove = btn._FilteredOut
				btn._FilteredOut = false
			end

			return
		end

		local keep = {}
		local keepBtns = {}
		ics.ToLayout = keepBtns

		for _, dat in ipairs(its) do
			if dat.Tier == t then
				-- keeping this button in
				keep[dat] = true
				local btn = pnl.Items[dat]
				btn:PopInShow(0.1, 0.05, nil, true)
				btn._NoMove = btn._FilteredOut
				btn._FilteredOut = false
				keepBtns[#keepBtns + 1] = btn
			end
		end

		local i = 0

		for _, dat in ipairs(its) do
			if keep[dat] then i = i + 1 continue end

			-- removing this button
			local btn = pnl.Items[dat]
			btn._FilteredOut = true
			local anim = btn:PopOutHide(nil, 0.05)
			if anim then
				anim:Then(function()
					btn._NoMove = true
				end)
			end

		end

		ics:InvalidateLayout(true)
	end

	local ply = LocalPlayer()

	local ply_money = ply:GetMoney() -- , ply_level = ply:GetMoney(), ply:GetLevel()
	local bclass = baseclass.Get("FButton")
	function pnl:Think()
		--ply_money, ply_level = ply:GetMoney(), ply:GetLevel()
		ply_money = ply:GetMoney()
		bclass = baseclass.Get("FButton")
	end

	local enoughColor = Color(100, 200, 100, 180)
	local notEnoughColor = Color(220, 50, 50, 150)
	local wayEnoughColor = Color(75, 125, 235, 180)
	local barelyEnoughColor = Color(200, 180, 110, 150)

	local lockOuter = Colors.Yellowish:Copy():MulHSV(1, 0.8, 0.6):SetAlpha(200)
	local lockInner = Colors.Warning:Copy():MulHSV(1, 0.6, 0.75):SetAlpha(200)
	--local notEvenCloseColor = Color(85, 85, 85)

	local drawBtn = bclass.DrawButton

	for _, dat in ipairs(its) do
		local name, lv, price = dat.Name, dat.Level, dat.Price
		if name == "soon" then continue end

		local mdl = dat.Model
		local btn = ics:Add("FButton")
		btn:SetSize(76, 76)
		btn.RaiseHeight = 2
		btn.DownSize = 0

		pnl.Items[dat] = btn
		btn.Data = dat

		btn.Shadow.MaxSpread = 1.1
		btn.Shadow.Alpha = 150
		btn.Shadow.Intensity = 2
		btn.Shadow.HoverSpeed = 0.1
		btn.Shadow.UnhoverSpeed = 0.1
		btn.Shadow.UnhoverEase = 1.2

		btn.HoverFrac = 0

		hook.Add("OnSpawnMenuClose", btn, function()
			btn:RemoveCloud("description")
		end)

		btn:SetDoubleClickingEnabled(false)

		btn.Shadow.Color = color_white:Copy()

		local sic = btn:Add("SpawnIcon")
		sic:SetModel(mdl)
		sic:SetSize(60, 60)
		sic:SetPos(6, 16)

		sic:SetMouseInputEnabled(false)

		function btn:Demask(x, y, w, h)
			surface.PushAlphaMult(999)
			draw.RoundedStencilBox(8, x + 3, y + 3, w - 6, h - 6, color_white)
			surface.PopAlphaMult()
		end

		function btn:Mask(x, y, w, h)
			surface.PushAlphaMult(999)
			draw.RoundedStencilBox(8, x, y, w, h, color_white)
			surface.PopAlphaMult()
		end

		function btn:DrawLockedStripes(x, y, w, h, col)
			if self.CanBuy then return end

			col:SetDraw()
			local u = (-CurTime() / 90) % 1
			local v = (-CurTime() / 90) % 1
			local u1, v1 = u + 0.3, v - 0.15
			draw.Stripes(x, y, w, h, u, v, u1, v1)
		end

		function btn:DrawButton(x, y, w, h)
			local w, h = self:GetSize()

			draw.BeginMask()
			-- 1: mask
				self:Mask(x, y, w, h)
			-- 2: demask
			render.SetStencilReferenceValue(2)
				self:Demask(x, y, w, h)

			-- only draw @ mask (borders)
			draw.DrawOp(1)
			render.SetStencilCompareFunction(STENCIL_EQUAL)
				drawBtn(self, x, y, w, h)
				--self:DrawLockedStripes(x, y, w, h, lockOuter)

			-- only draw @ unmask (center)
			render.SetStencilReferenceValue(2)
				self:DrawLockedStripes(x, y, w, h, lockInner)
			draw.FinishMask()
		end

		local moneytxCol = notEnoughColor:Copy()
		local leveltxCol = Colors.Level:Copy()
		local curCol = Colors.Red:Copy()

		local shortName = name

		surface.SetFont("BS14")

		for i=1, #name do
			local nm = name:sub(1, i)
			local tW = surface.GetTextSize(nm)

			if tW > btn:GetWide() - 8 then
				shortName = nm:sub(1, -4) .. "..."
				break
			end
		end

		local lastHovFrac = nil
		local lastUpd = 0

		btn.CanBuy = BaseWars.CanPurchase(CLP(), cat_name, dat.CatID)

		function btn:Think()
			if self.HoverFrac ~= lastHovFrac then
				local sz = 60 + 8 * self.HoverFrac
				sic:SetSize(sz, sz)
				sic:CenterHorizontal()
				sic.Y = self:GetTall() - sic:GetTall() - 4
				lastHovFrac = self.HoverFrac
			end

			if CurTime() - lastUpd > 0.5 then
				lastUpd = CurTime()
				self.CanBuy = BaseWars.CanPurchase(CLP(), cat_name, dat.CatID)
			end

			if self:IsDown() and self.CanBuy then
				self:SetColor(color_white, true)
			else
				self:LerpColor(self.Color, Colors.Button, 0.3, 0.07, 0.2, true)
			end
		end

		function btn:OnHover()
			self:To("HoverFrac", 1, 0.2, 0, 0.2)
			local cl, new = self:AddCloud("description")

			if new then
				cl.Font = "OS22"
				cl.MaxW = 450
				cl.AlignLabel = 1
				cl:AddSeparator(nil, 8, {2, 4})
				moneytxCol.a = 255
				cl:AddFormattedText(Language("Price", price), moneytxCol, "OSB20", 18, nil, 1)

				if dat.GenerateCloudInfo then
					dat.GenerateCloudInfo(cl, btn)
				end

				--cl:AddFormattedText(Language("Level", lv), leveltxCol, "OSB20", nil, nil, 1)
				cl:SetRelPos(self:GetWide() / 2)
				cl.ToY = -8

				cl:SetText(name)
			end
		end

		local shortNameCol = color_white:Copy()
		local shortNameShadow = color_black:Copy()

		function btn:PaintOver(w, h)
			shortNameCol.a = (1 - self.HoverFrac) * 255
			shortNameShadow.a = (1 - self.HoverFrac) * 255

			draw.SimpleText(shortName, "BS14",
				w/2 + 1, 4 - 22 * self.HoverFrac + 1,
				shortNameShadow, 1)

			draw.SimpleText(shortName, "BS14",
				w/2, 4 - 22 * self.HoverFrac,
				shortNameCol, 1)

			bclass.PaintOver(self, w, h)

			if not self.CanBuy then
				self.RaiseHeight = 0
				self.Shadow.MaxSpread = 0
				draw.RoundedBox(self.RBRadius, 0, 0, w, h, Colors.DarkGray:IAlpha(200))
			else
				self.RaiseHeight = 2
				self.Shadow.MaxSpread = 1.1
			end
		end


		function btn:ColorThink()
			local enough = ply_money >= price
			local way_enough = ply_money > price * 50
			local barely_enough = ply_money < price * 3

			local col, txcol

			if enough then
				txcol = Colors.Money

				if way_enough then
					col = wayEnoughColor
				elseif barely_enough then
					col = barelyEnoughColor
					txcol = barelyEnoughColor
				else
					col = enoughColor
				end

			else
				col = notEnoughColor
				txcol = notEnoughColor
			end

			return col, txcol
		end

		do
			local col, txcol = btn:ColorThink()
			moneytxCol:Set(txcol or col)
			curCol:Set(col)
		end

		function btn:PrePaint(w, h)
			--b:Open()

			if BaseWars.SpawnMenu.Highlight[dat.ClassName] then
				local fr = 1 - ((SysTime() / 1.3) % 1)
				draw.LerpColor(fr, self.drawColor,
					Colors.Purpleish, Colors.Button)
			end

			local col, txcol = self:ColorThink()

			self:LerpColor(moneytxCol, txcol or col, 0.3, 0, 0.3)
			self:LerpColor(curCol, col, 0.3, 0, 0.3)

			draw.RoundedBox(8, 2, 2, w - 4, h - 4, curCol)
		end

		function btn:OnUnhover()
			self:To("HoverFrac", 0, 0.2, 0, 0.2)
			self:RemoveCloud("description")
		end

		function btn:DoClick()
			BaseWars.SpawnMenu.Highlight[dat.ClassName] = nil

			if self.CanBuy then
				self.Shadow.MaxSpread = 1.7
				self.Shadow.Alpha = 255

				self:LerpColor(self.Color, Colors.Button, 0.3, 0.07, 0.2, true)
				self:LerpColor(self.drawColor, Colors.Button, 0.3, 0.07, 0.2, true)
				self:MemberLerp(self.Shadow, "MaxSpread", 1.1, 0.4, 0.13, 0.2, true)
			end

			RunConsoleCommand("basewars_spawn", cat_name, dat.CatID)
			--self:LerpColor(self.drawColor, Colors.Button, 0.3, 0.15, 0.3)
		end
	end

	local perf_layout = ics.PerformLayout --BWERGH

	function ics:PerformLayout(w, h)
		perf_layout(self, w, h)
		pnl:Emit("Bruh")

		local new_h = ics:GetTall() + 4 + headerSize
		if pnl:GetTall() ~= new_h then
			pnl:SetTall(new_h)
		end
	end
end

local function openCategory(pnl, btn)
	local cat = btn.Category
	if not BaseWars.SpawnList[cat] then
		errorf("attempt to open unknown basewars spawnlist category: %s", cat)
		return
	end

	if IsValid(pnl.OpenCategory) and pnl.OpenCategory.Category == cat then return end

	local canv = vgui.Create("FScrollPanel", pnl)
	canv:SetSize(pnl:GetSize())

	pnl:On("PerformLayout", canv, function(self, w, h)
		canv:SetSize(w, h)
	end)

	local boxHeight = 36

	canv.NoDraw = true
	canv:GetCanvas():DockPadding(8, boxHeight + 8, 8, 4)
	canv.Category = cat

	pnl.OpenCategory = canv

	local boxcol = Colors.Gray:Copy()
	boxcol.a = 210

	local titleCol = color_white:Copy()
	local h, s, v = titleCol:ToHSV()
	draw.ColorModHSV(titleCol, h, s - 0.1, v - 0.1)

	local iconCol = draw.ColorModHSV(titleCol:Copy(), h, s, v + 0.1)
	local ic = IsIcon(btn.Icon) and btn.Icon:Copy()

	local iconPadding = 4
	local boxPadding = 12
	

	if ic then
		ic:SetColor(iconCol)
		ic:SetAlignment(4)
	end

	canv:GetCanvas().Paint = function(self, w, h)
		surface.SetFont("EX40")

		local tw, th = surface.GetTextSize(cat)
		local tx = w/2 - tw/2

		if ic then
			tw = tw + (ic:GetSize()) + iconPadding
			tx = w/2 - tw/2 + (ic:GetSize()) + iconPadding
		end

		draw.RoundedBoxEx(16, w/2 - tw/2 - boxPadding, 0, tw + boxPadding * 2, boxHeight, boxcol, false, false, true, true)

		if ic then
			ic:Paint(w/2 - tw/2, boxHeight / 2)
		end

		surface.SetTextPos(tx, boxHeight - th)
		surface.SetTextColor(titleCol)
		surface.DrawText(cat)
	end

	pnl:AddCatCanvas(canv)

	for subname, data in SortedPairsByMemberValue(BaseWars.SpawnList[cat].Subcategories, "Priority", true) do
		createSubCategory(canv, cat, subname, data)
	end

	return canv
end

local function MakeSpawnList()
	local pnl = vgui.Create("InvisPanel")	-- main canvas for the entire basewars tab
	pnl:Dock(FILL)
	SpawnlistCanvas = pnl

	local its -- items list on the right; predefined

	local cats = vgui.Create("FScrollPanel", pnl)
	cats:GetCanvas():DockPadding(0, 4, 0, 4)
	cats:Dock(LEFT)
	cats:SetWide(192)
	cats:DockMargin(0, 0, 16, 0)
	cats.GradBorder = true
	cats.BackgroundColor = Color(200, 200, 200, 200)
	cats.Categories = {}

	local active

	function pnl:Fill()
		local catsArr = {}
		for k,v in pairs(BaseWars.SpawnList) do catsArr[#catsArr + 1] = v end

		table.sort(catsArr, function(a, b)
			local ao, bo = a.Order or 0, b.Order or 0
			if ao == bo then return a.Name < b.Name end

			return ao > bo
		end)

		for k,v in ipairs(catsArr) do
			local catName = v.Name
			k = catName

			if cats.Categories[v.Name] then
				cats.Categories[v.Name]:Remove()
			end

			local tab = vgui.Create("FButton", cats)
			tab.RaiseHeight = 0
			tab:Dock(TOP)
			tab:SetTall(32)
			tab:DockMargin(0, 0, 0, 4)
			tab.NoDraw = true
			tab.Category = v.Name
			tab.Icon = v.Icon
			tab:SetZPos(k)
			cats.Categories[v.Name] = tab

			local ic = IsIcon(v.Icon) and v.Icon

			local col = Colors.LightGray:Copy()
			local sel_col = Color(35, 120, 220)

			local unsel_X = 6
			local sel_X = 20

			local ic_tx_padding = 4

			local font = "EX32"

			tab.IconX = unsel_X

			if IsIcon(v.Icon) then
				ic = v.Icon:Copy()
				ic:AssignColor(col)
				ic:SetFilter(true)
			end

			local box_col = Colors.LightGray:Copy()
			box_col.a = 120

			local fullW = 0

			surface.SetFont(font)
			local txW = surface.GetTextSize(v.Name)
			local icW = ic and ((ic:GetSize()) + ic_tx_padding) or 0

			fullW = txW + icW

			function tab:PostPaint(w, h)
				--draw.RoundedBox(8, self.IconX - box_padding, 0, fullW + box_padding*2, h, box_col)
				self:To("HovFrac", self:IsHovered(), 0.3, 0, 0.3)
				if active == self then
					self:To("IconX", sel_X, 0.2, 0, 0.15)
					self:LerpColor(col, sel_col, 0.3, 0, 0.3)
				else
					self:To("IconX", unsel_X, 0.2, 0, 0.2)
					self:LerpColor(col, Colors.LightGray, 0.3, 0, 0.3)

					for k,v in pairs(BaseWars.SpawnMenu.Highlight) do
						local dat = BaseWars.Catalogue[k]
						if not dat then continue end

						local cat = dat.Category
						if cat ~= catName then continue end

						local fr = 1 - ((SysTime() / 1.3) % 1)
						draw.LerpColor(Lerp(fr, 0.2, 0.7), col,
							Colors.Purpleish, Colors.LightGray)
					end

				end

				local x = math.Round(self.IconX)

				if IsIcon(ic) then
					local iw, ih = ic:GetSize()
					ic:Paint(x, h/2 - ih/2)
					x = x + iw + ic_tx_padding
				end

				local tw, th = draw.SimpleText(v.Name, font, x, h/2, col, 0, 1)

				self.MxScaleCenterX = tw / 2 + x
			end

			function tab:DoClick()
				local new = openCategory(its, tab)
				if new then
					active = self
				end
			end
		end
	end

	hook.Add("BW_CatalogueFilled", pnl, pnl.Fill)

	if BaseWars.SpawnList then
		pnl:Fill()
	end

	its = vgui.Create("GradPanel", pnl)
	its:Dock(FILL)
	its:SetColor(Color(110, 110, 110, 150))

	local base = vgui.GetControlTable("GradPanel")

	function its:PostPaint(w, h)
		spawnmenu.BaseWarsOpened = true -- kinda ugly but aight
		local x, y = self:LocalToScreen(0, 0)
		BSHADOWS.SetScissor(x, y, w, h)
	end

	function its:PaintOver(w, h)
		BSHADOWS.SetScissor()
		base.PaintOver(self, w, h)
	end

	function its:PerformLayout(w, h)
		self:Emit("PerformLayout", w, h)
	end

	function its:AddCatCanvas(new)
		if IsValid(self.oldCanvas) then
			self.oldCanvas:To("X", 16, 0.2, 0, 1.6)
			self.oldCanvas:PopOut(0.15, 0.05)
			self.oldCanvas:SetZPos(-15)
		end

		self.oldCanvas = new
		new:PopIn(0.15, 0.05)
		new.X = new.X - 16
		new:To("X", 0, 0.3, 0, 0.3)
	end

	return pnl

end

local spawnMenuTabs = {}

local function RemoveTabs()

	local ply = LocalPlayer()
	if not ply or not IsValid(ply) then return end

	--local Admin = ply:IsAdmin()

	function spawnmenu.Reload()
		for k,v in pairs(spawnMenuTabs) do
			spawnmenu.AddCreationTab(k, v.Function, v.Icon, v.Order)
		end
		RunConsoleCommand("spawnmenu_reload")

	end


	function spawnmenu.RemoveCreationTab(blah)
		spawnMenuTabs[blah] = spawnmenu.GetCreationTabs()[blah]
		spawnmenu.GetCreationTabs()[blah] = nil

	end

	spawnmenu.RemoveCreationTab("#spawnmenu.category.saves")
	spawnmenu.RemoveCreationTab("#spawnmenu.category.dupes")
	spawnmenu.RemoveCreationTab("#spawnmenu.category.postprocess")

	--if not Admin then

		spawnmenu.RemoveCreationTab("#spawnmenu.category.vehicles")
		spawnmenu.RemoveCreationTab("#spawnmenu.category.weapons")
		spawnmenu.RemoveCreationTab("#spawnmenu.category.npcs")
		--spawnmenu.RemoveCreationTab("#spawnmenu.category.entities")

	--end

	spawnmenu.Reload()

end


language.Add("spawnmenu.category.basewars", "BaseWars")
spawnmenu.AddCreationTab("#spawnmenu.category.basewars", MakeSpawnList, "icon16/building.png",
	BaseWars.Config.RestrictProps and -100 or 2)

if GetConVar("developer"):GetInt() < 1 then
	hook.Add("InitPostEntity", "BaseWars.SpawnMenu.RemoveTabs", RemoveTabs)
	RemoveTabs()
else

	hook.Remove("InitPostEntity", "BaseWars.SpawnMenu.RemoveTabs")
	RunConsoleCommand("spawnmenu_reload")
end
