local PANEL = {}
vgui.ToPrePostPaint(PANEL)

ChainAccessor(PANEL, "_Perk", "Perk")
ChainAccessor(PANEL, "_Perk", "Level")

local TitleY = 8

function PANEL:Init()
	local dt = DeltaText()
		:SetFont("EXSB36")

	dt.DefaultColor = Colors.Sky:Copy():MulHSV(1, 0.6, 2)

	dt.AlignX = 1

	self.Title = dt

	TITLE = dt

	self.PDT = {}
	self.MUps = {}
	self._Reqs = {}
	self._Btns = {}
end

function PANEL:Draw(w, h)
	surface.SetDrawColor(Colors.Gray)
	surface.DrawRect(0, 0, w, h)

	self.Title:Paint(w / 2, TitleY)
end

function PANEL:_AnimateTitle(level, old)
	if not level then
		self.Title:DisappearCurrentElement()
		return
	end

	local perk = level:GetPerk()
	local num = self.PDT[perk]

	if not num then
		local elem, num2 = self.Title:AddText("")
		elem:SetColor(level:GetColor() or perk:GetColor() or self.Title.DefaultColor)
		local nmFr = level:GetNameFragments()

		for i=1, #nmFr do
			elem:AddFragment(nmFr[i])
		end

		self.PDT[perk] = num2

		num = num2
	else
		local elem = self.Title:GetElement(num)
		local nmFr = level:GetNameFragments()

		for i=1, #nmFr do
			if elem.Fragments[i + 1] then
				elem:ReplaceText(i + 1, nmFr[i], nil, self.Title:GetCurrentElement() ~= elem)
			else
				elem:AddFragment(nmFr[i])
			end
		end

		for i = #nmFr + 1, #elem.Fragments do
			elem:RemoveFragment(i + 1)
		end
	end

	self.Title:ActivateElement(num)
end

local colors = {
	["$"] = Colors.Money,
	["^"] = Colors.Sky,
	["#"] = Colors.Golden,
	["@"] = Colors.Red,
	["*"] = color_white,
	["&"] = Colors.Blue
}

function PANEL:_AnimateDescription(level, old)
	local mups = self.MUps

	if mups[old] then
		mups[old]:PopOutHide()
	end

	if not level then return end

	local perk = level:GetPerk()
	local mup = mups[level]

	local delay = old and old:GetPerk() == perk and 0.1 or 0.2

	if not mup then
		mup = vgui.Create("MarkupText", self)
		mup:SetPos(0, draw.GetFontHeight(self.Title:GetFont()) + TitleY * 2)
		mup.IntendedY = mup.Y
		mup.Y = mup.IntendedY - 16
		mup:SetWide(self:GetWide() * 0.9)
		mup:CenterHorizontal()
		mup:MoveBy(0, 16, 0.6, delay, 0.3)
		mup:PopIn(0.2, delay)

		local ret = eval(level:GetDescription(), self, mup)

		if isstring(ret) then
			local t = {}
			local cols = {}

			local i = 0
			local pattern = "[%" .. table.concat(string.Prefixes, "%") .. "]"

			for s, match in eachMatch(ret, pattern .. "%d+") do
				i = i + 2
				t[i - 1] = s
				t[i] = match and match:sub(2)
				cols[#cols + 1] = match and colors[match:sub(1, 1)] or Colors.Error
			end

			local pc = mup:AddPiece()
			pc:SetFont("BS20")
			pc:SetAlignment(1)
			pc:SetColor(160, 160, 160)

			local n = 0
			for i=1, #t, 2 do
				pc:AddText(t[i])
				if t[i + 1] then
					n = n + 1
					local num = pc:AddText(t[i + 1])
					num.color = cols[n] or Colors.Error
				end
			end
		end

		mups[level] = mup
	else
		mup:Stop()
		mup.Y = mup.IntendedY - 16
		mup:MoveBy(0, 16, 0.6, delay, 0.3)
		mup:PopInShow(0.2, delay)
	end
end

function PANEL:GetDescPanel(lv)
	return self.MUps[lv]
end

local check, cross = "✓", "✕"

function PANEL:_AnimateRequirements(level, old)
	local oldReq = self._Reqs[old]
	if oldReq or not level then
		oldReq:PopOutHide()
	end

	if not level then return end

	local req = self._Reqs[level]
	if req then
		req:PopInShow(0.2, 0.2)
		req.Y = req.IntendedY - 8
		req:MoveBy(0, 8, 0.6, 0.2, 0.3)
	else
		req = vgui.Create("InvisPanel", self)
		self._Reqs[level] = req
		local desc = self:GetDescPanel(level)
		req:PopIn(0.2, 0.4)
		req:SetSize(self:GetWide(), 64)
		req.IntendedY = desc.IntendedY + desc:GetTall() + 32
		req.Y = req.IntendedY - 8
		req:MoveBy(0, 8, 0.6, 0.4, 0.3)

		local apFrs = {}
		local reqFrs = {}

		local col = Color(0, 0, 0)

		local reqs = level:GetRequirements()

		local items = {}

		if reqs.Items then
			for id, amt in pairs(reqs.Items) do
				items[#items + 1] = {id, amt}
			end
		end

		table.sort(items, function(a, b)
			local b1, b2 = Inventory.Util.GetBase(a[1]), Inventory.Util.GetBase(b[1])
			local r1, r2 = b1 and b1:GetRarity(), b2 and b2:GetRarity()

			if not b1 or (not r1 and r2) then return false end
			if not b2 or (r1 and not r2) then return true end
			if not r1 and not r2 then return false end

			return r1:GetRarity() < r2:GetRarity()
		end)

		local rqs = {}
		local lvpqs = level:GetPrereqs()

		if lvpqs then
			for id, _ in pairs(lvpqs) do
				rqs[#rqs + 1] = id
			end
		end

		table.sort(rqs, function(a, b)
			if not Research.IsPerkLevel(a) then return false end
			if not Research.IsPerkLevel(b) then return true end

			return a:GetLevel() < b:GetLevel()
		end)

		function req:Paint(w, h)
			local reqs = level:GetRequirements()

			local _, titleH = draw.SimpleText("Requirements:", "BSSB32", w / 2, 0, color_white, 1)

			local y = titleH + 4

			local del = 0.3

			--[==================================[
				prerequisites
			--]==================================]
			self:To("ReqsLblFr", 1, 0.5, del, 0.3)
			local rfr = self.ReqsLblFr or 0

			col:Set(color_white)
			col.a = rfr * 255

			if #rqs > 0 then
				local lW, lH = draw.SimpleText("Prerequisites:", "EX28",
					8 - 8 * (1 - rfr), y, col)
				y = y + lH

				del = del + .2

				for k, lv in ipairs(rqs) do
					self:MemberLerp(reqFrs, k, 1, 0.9, del, 0.15)
					del = del + .1

					local fr = reqFrs[k] or 0

					local name

					if Research.IsPerkLevel(lv) then
						name = lv:GetName()
						local good = level:PrereqSatisfied(lv, CachedLocalPlayer())
						col:Set(good and Colors.Sky or Colors.Reddish)
						col.a = fr * 255

						name = (good and check or cross) .. " " .. name
					else
						name = Language[lv] and Language[lv] (lvpqs[lv])
						col:Set(210, 210, 210, fr * 255)
					end

					local tw, th = draw.SimpleText(name,
						"BSL20", math.Round(32 - 16 * (1 - fr)), y, col)

					y = y + th
				end

				y = y + 16
			end

			--[==================================[
				requirements: items
			--]==================================]
			del = 0.3

			self:To("ItemLblFr", 1, 0.5, del, 0.3)
			local tfr = self.ItemLblFr or 0

			col:Set(color_white)
			col.a = tfr * 255

			if #items > 0 then
				local lW, lH = draw.SimpleText("Items:", "EX28",
					8 - 8 * (1 - tfr), y, col)
				y = y + lH

				del = del + .2

				for i, dat in ipairs(items) do
					local id, amt = dat[1], dat[2]
					local base = Inventory.Util.GetBase(id)

					self:MemberLerp(apFrs, id, 1, 0.9, del, 0.15)
					del = del + .1

					local fr = apFrs[id] or 0

					col:Set(base and base:GetColor() or color_white)
					col.a = fr * 255

					local tw, th = Inventory.Draw.DrawItemAmount(id, amt,
						"BSL20", math.Round(32 - 16 * (1 - fr)), y, col)

					y = y + th
				end
			end
			
			self:SetTall(math.max(h, y))
		end


	end
end


function PANEL:_AnimateButton(level, old)
	local main = self
	local ent = self._comp

	local oldBtn = self._Btns[old]
	if oldBtn or not level then
		oldBtn:PopOutHide()
	end

	if not level then return end

	local btn = self._Btns[level]

	if btn then
		btn:PopInShow(0.2, 0.2)
	else
		btn = vgui.Create("FButton", self)
		self._Btns[level] = btn

		btn:SetSize(self:GetWide() * 0.8, scale(56))
		btn.IntendedY = self:GetTall() - btn:GetTall() - 16
		btn:CenterHorizontal()

		btn.Y = btn.IntendedY + 8
		btn:MoveBy(0, -8, 0.7, 0.75, 0.15)

		btn:PopIn(0.1, 0.75)
		btn:SetColor(Colors.Sky)
		btn.Label = "Begin Research"
		btn:SetFont("OS28")
		btn:SetIcon(Icons.MagnifyingGlass128:Copy()
			:SetSize(scale(28), scale(28))
			:SetFilter(true)
		)

		function btn:Think()
			ent = main._comp
			local can, why = level:CanResearch(CachedLocalPlayer(), ent)
			if not can then
				self:SetEnabled(false)

				if self:IsHovered() then
					local cl, new = self:AddCloud("why", why)
					if new then
						cl:SetFont("OS20")
						cl:SetTextColor(Colors.Reddish)
						cl:SetRelPos(self:GetWide() / 2, self:GetTall())
						cl.ToY = 8
						cl.YAlign = 0
					end
				else
					self:RemoveCloud("why")
				end

				return
			end

			self:RemoveCloud("why")
			self:SetEnabled(true)
		end
	end
end

function PANEL:SetComputer(ent)
	self._comp = ent
end

function PANEL:SetLevel(level)
	self:_AnimateTitle(level, self._Level)
	self:_AnimateDescription(level, self._Level)
	self:_AnimateRequirements(level, self._Level)
	self:_AnimateButton(level, self._Level)

	self._Level = level
end
PANEL.SetPerk = PANEL.SetLevel

vgui.Register("ResearchSidebar", PANEL, "DPanel")