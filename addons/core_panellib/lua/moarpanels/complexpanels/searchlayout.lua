
local SL = {}
vgui.ColorSetters(SL)

function SL:Init()
	local srchPanel = vgui.Create("EditablePanel", self) -- ewww cant offset entry text, hafta do this
	self.SearchPanel = srchPanel
	srchPanel:Dock(TOP)
	srchPanel:SetTall(28)
	srchPanel:DockMargin(4, 4, 4, 4)

	local srch = vgui.Create("FTextEntry", srchPanel)

	function srchPanel:Paint(w, h)
		srch:DrawBG(w, h)
			surface.SetDrawColor(Colors.Button:Copy())
			surface.DrawRect(0, 0, 28, 28)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawMaterial("https://i.imgur.com/Q8Vdlhq.png", "mag32_1.png", 4, 4, 20, 20)
		srch:DrawGradBorder(w, h)
	end

	self.SearchBar = srch
	srch:Dock(FILL)
	srch:DockMargin(28, 0, 0, 0)
	srch.NoDrawBG = true
	srch.GradBorder = false

	local scr = vgui.Create("FScrollPanel", self)
	scr:Dock(FILL)

	local ic = vgui.Create("FIconLayout")
	scr:Add(ic)

	self.IconLayout = ic

	ic:On("ShiftPanel", function(_, pnl, x, y)
		if self.ChangedStates[pnl] ~= nil then
			local dur = math.min( (math.abs(pnl.X - x) / 1000 + math.abs(pnl.Y - y) / 1000) ^ 0.7, 0.3)

			local anX, new = pnl:To("X", x, dur, 0, 0.3, true)
			local anY, new2 = pnl:To("Y", y, dur, 0, 0.3, true)

			self.ChangedStates[pnl] = nil

			return true
		end
	end)

	self.PatternsEnabled = false

	srch:On("Change", "Search", function()
		local tx = srch:GetValue()

		local dhCopy = self.Dehighlighted
		self.Dehighlighted = {}

		if #tx == 0 then
			for k,v in pairs(dhCopy) do
				local a = k:Emit("Highlight")
				if a == nil then
					k:AlphaTo(255, 0.3, 0, nil, 0.3)
				end
				self.ChangedStates[k] = true
			end

			self:Resort()
			return
		end

		for pnl, name in pairs(self.Names) do
			if self:Emit("CustomSearch", pnl, tx, name, not self.PatternsEnabled) == true then
				continue
			end

			if not name:lower():find(tx, nil, not self.PatternsEnabled) then
				self.Dehighlighted[pnl] = true
			end
		end

		for k,v in pairs(self.Dehighlighted) do
			if k:IsValid() and not dhCopy[k] then
				local a = k:Emit("Dehighlight")
				if a == nil then
					k:AlphaTo(50, 0.3, 0, nil, 0.3)
				end
				self.ChangedStates[k] = false
			end
		end

		for k,v in pairs(dhCopy) do
			if k:IsValid() and not self.Dehighlighted[k] then
				local a = k:Emit("Highlight")
				if a == nil then
					k:AlphaTo(255, 0.3, 0, nil, 0.3)
				end

				self.ChangedStates[k] = true
			end
		end

		self:Resort()
	end)

	self.Color = Colors.Button:Copy()

	self.Names = {}
	self.OriginalOrder = {}
	self.Dehighlighted = {}
	self.ChangedStates = {} -- [pnl] = newState (false = dehighlighted)
end

function SL:Resort()
	local oldPos = table.Copy(self.IconLayout.Panels)

	table.sort(self.IconLayout.Panels, function(a, b)
		local dh1 = self.Dehighlighted[a]
		local dh2 = self.Dehighlighted[b]

		if dh1 == dh2 then
			return self.OriginalOrder[a] < self.OriginalOrder[b]
		else
			return dh2
		end
	end)

	local changes = false

	for k,v in ipairs(self.IconLayout.Panels) do
		if oldPos[k] ~= v then
			self.ChangedStates[v] = not not self.Dehighlighted[v]
			changes = true
		end
	end

	if changes then
		self.IconLayout:UpdateSize(self.IconLayout:GetSize())
	end
end

function SL:Paint(w, h)
	draw.RoundedBox(8, 0, 0, w, h, self:GetColor())
end

function SL:IsHighlighted()

end

function SL:PerformLayout(w, h)
	self:Resort()
	self.IconLayout:SetWide(self:GetWide())
end

function SL:OnChildAdded(p)
	--self:Add(p)
end

function SL:SetName(pnl, name)
	self.Names[pnl] = isstring(name) and name
end

function SL:Add(p, name)
	if not isstring(name) then ErrorNoHalt("SearchLayout requires a name on panels!") return end

	local pnl = self.IconLayout:Add(p)

	self.Names[pnl] = isstring(name) and name
	self.OriginalOrder[pnl] = #self.IconLayout.Panels

	return pnl
end

vgui.Register("SearchLayout", SL, "Panel")


--[[if IsValid(_Pn) then _Pn:Remove() end

local f = vgui.Create("FFrame")
_Pn = f
f:SetSize(700, 500)
f:Center()
f:MakePopup()
f.Shadow = {}

local ic = vgui.Create("SearchLayout", f)
ic:Dock(FILL)

local names = {
	"Button",
	"Booton",
	"Peeton",
	"Python"
}

for i=1, 40 do
	local name = names[math.ceil(i / 10)]
	local b = ic:Add("FButton", name .. " #" .. i)
	b:SetSize(80, 48)
	b.Label = name .. " #" .. i
	b.Font = "OS18"
	b:On("Dehighlight", function()
		b:AlphaTo(50, 0.3, 0, nil, 0.3)
	end)

	b:On("Highlight", function()
		b:AlphaTo(255, 0.3, 0, nil, 0.3)
	end)
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
	ic:SetWide(w + math.sin(CurTime() * 0.6) * 50)
end)

ic:On("ShiftPanel", function(self, pnl, x, y)
	local dur = math.abs(pnl.X - x) / 1000
	local an = pnl:GetTo("X") or pnl:To("X", x, dur, 0, 0.3)
	if an then an.ToVal = x end

	pnl:To("Y", y, 0.7, 0, 0.3)

	return true
end)]]