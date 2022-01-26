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
		mup.Y =mup.IntendedY - 16
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

function PANEL:SetLevel(level)
	self:_AnimateTitle(level, self._Level)
	self:_AnimateDescription(level, self._Level)

	self._Level = level
end
PANEL.SetPerk = PANEL.SetLevel

vgui.Register("ResearchSidebar", PANEL, "DPanel")