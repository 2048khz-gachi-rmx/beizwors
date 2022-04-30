--[[

FIconLayout
	this barely works; don't use it
]]

local FIC = {}

function FIC:Init()
	self.UseDockProperties = false

	self.PadX = 4 -- distance between the bounds and the insides
	self.PadY = 8

	self.AutoPad = true
	self.AutoResize = true

	self.MarginX = 4 -- distance between panels inside
	self.MarginY = 8

	self.IncompleteCenter = true

	self.Rows = {}				-- [num] = {curW, curH}
	self.Panels = {}

	self.CurRow = 1

	self.NoDrawBG = false

	self.Color = Color(40, 40, 40)
end

ChainAccessor(FIC, "MarginX", "MarginX")
ChainAccessor(FIC, "MarginX", "SpaceX")

ChainAccessor(FIC, "MarginY", "MarginY")
ChainAccessor(FIC, "MarginY", "SpaceY")

function FIC:SetBorder(n)
	self.PadX, self.PadY = n, n
end

function FIC:ShiftPanel(pnl, x, y)
	if pnl.X == x and pnl.Y == y then return end -- avoid infinite layouts
	if self:Emit("ShiftPanel", pnl, x, y) ~= nil then return end

	pnl:SetPos(x, y)
end

function FIC:OnRowShift(row, curX, w)

	row.PnlW = row.PnlW - self.MarginX
	local pad = (w - row.PnlW) / 2
	local x = self.AutoPad and pad or self.PadX
	row.PadX = x

	for _, pnl in ipairs(row) do
		row.Positions[pnl][1] = x
		self:ShiftPanel(pnl, x, row.Positions[pnl][2])

		x = x + row.Sizes[pnl][1] + self.MarginX
	end

end

function FIC:_CreateRow(n)
	local row = {
		MaxH = 0,
		PnlW = 0,
		Full = false,
		Sizes = {},
		Positions = {}
	}

	self.Rows[n] = row

	return row
end

function FIC:UpdateSize(w, h)
	local l, t, r, b = self:GetDockPadding()

	local padX = self.UseDockProperties and l or self.PadX
	local padY = self.UseDockProperties and t or self.PadY

	local curX = padX
	local curY = padY

	local panels = self.ToLayout or self.Panels

	table.Filter(panels, IsValid)

	self:InvalidateRows()
	self:Emit("UpdateSize")
	local curRow = self.CurRow

	for k,v in ipairs( panels ) do
		local row = self.Rows[curRow] or self:_CreateRow(curRow)

		local vW, vH = v:GetSize()

		if curX > w - padX - vW then
			row.Full = true
			self:OnRowShift(row, curX, w)

			curX = padX
			curY = curY + row.MaxH + self.MarginY

			self.CurRow = self.CurRow + 1
			curRow = self.CurRow
			row = self.Rows[curRow] or self:_CreateRow(curRow)
		end

		row.Sizes[v] = {vW, vH}
		row.Positions[v] = {0, curY}

		row.PnlW = row.PnlW + vW + self.MarginX
		row.MaxH = math.max(row.MaxH, vH)

		row[#row + 1] = v
		curX = curX + vW + self.MarginX

	end

	local lastRow = self.Rows[curRow]

	if lastRow and not lastRow.Full then
		-- incomplete row
		if self.IncompleteCenter then
			self:OnRowShift(lastRow, curX, w)
		else
			local preRow = self.Rows[curRow - 1]
			local x = (preRow and preRow.PadX) or padX

			for _, pnl in ipairs(lastRow) do
				local y = lastRow.Positions[pnl][2]
				lastRow.Positions[pnl][1] = x
				self:ShiftPanel(pnl, x, y)

				x = x + pnl:GetWide() + self.MarginX
			end

		end
	end

	if self.AutoResize then
		local curH = self.ThinkingH or self:GetTall()
		local newH = curY + (lastRow and lastRow.MaxH or 8) +
			(self.UseDockProperties and b or padY) --math.max(curY + (lastRow and lastRow.MaxH or 8), curH)

		if newH ~= curH then
			local ret = self:Emit("LayoutResize", newH)
			if ret ~= nil then
				if isnumber(ret) then self.ThinkingH = ret end
				return
			end

			self:SetTall(newH)
		end
	end
end

FIC.Reshuffle = FIC.UpdateSize

function FIC:InvalidateRows()
	self.Rows = {}
	self.CurRow = 1
end

function FIC:PerformLayout(w, h)
	self:UpdateSize(w, h)
end

function FIC:Add(name)

	local p

	if isstring(name) then
		p = vgui.Create(name, self)
	elseif ispanel(name) then
		p = name
		p:SetParent(self)
	end

	self.Panels[#self.Panels + 1] = p

	return p
end

vgui.Register("FIconLayout", FIC, "GradPanel")


--[[if IsValid(_Pn) then _Pn:Remove() end

local f = vgui.Create("FFrame")
_Pn = f
f:SetSize(700, 500)
f:Center()
f:MakePopup()
f.Shadow = {}

local ic = vgui.Create("FIconLayout", f)
ic:Dock(FILL)

for i=1, 40 do
	local b = ic:Add("FButton")
	b:SetSize(80, 80)
	b.Label = "Btn #" .. i
end

local bn = bench()

f:InvalidateLayout(true)
local w, h = ic:GetSize()
local x, y = ic:GetPos()
ic:Dock(NODOCK)

ic:SetPos(x, y)
ic:SetSize(w, h)
ic.AutoPad = true
f:On("Think", function()
	ic:SetWide(w + math.sin(CurTime() * 3) * 50)
end)

ic:On("ShiftPanel", function(self, pnl, x, y)
	local dur = math.abs(pnl.X - x) / 1000
	local an = pnl:GetTo("X") or pnl:To("X", x, dur, 0, 0.3)
	if an then an.ToVal = x end

	pnl:To("Y", y, 0.7, 0, 0.3)

	return true
end)]]