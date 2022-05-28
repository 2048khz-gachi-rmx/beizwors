--

local CAT = {}
CAT.ExpandTime = 0.3
CAT.ExpandEase = 0.2
CAT.ButtonHeight = 24

ChainAccessor(CAT, "ExpandEase", "ExpandEase")
ChainAccessor(CAT, "ExpandTime", "ExpandTime")
ChainAccessor(CAT, "Expanded", "Expanded")
ChainAccessor(CAT, "ExpandHeight", "ExpandHeight")

ChainAccessor(CAT, "_btn", "Button")
ChainAccessor(CAT, "_canv", "Canvas")

function CAT:Init()
	self._btn = vgui.Create("FButton", self)
	local b = self._btn
	b._par = self

	self:SetupButton(b)

	self._canv = vgui.Create("GradPanel", self)
	self._canv.GradSize = 2
	self._canv:SetColor(Colors.DarkGray)
	self._canv:DockPadding(4, 4, 4, 4)

	self.Expanded = false

	self:SetTall(self.ButtonHeight)
	b:SetTall(self.ButtonHeight)
	b:Dock(TOP)
end

function CAT:PerformLayout()
	self._canv:SetPos(0, self:GetButton():GetTall())

	local ch = self._canv:GetChildren()
	local my = 0

	local dp = self._canv:GetDockPadding()

	if not self:GetExpandHeight() then
		for k,v in ipairs(ch) do
			my = math.max(my, v.Y + v:GetTall() + dp)
		end
	else
		my = self:GetExpandHeight()
	end

	self._canv:SetSize(self:GetWide(), my)
end

function CAT:SetupButton(b)
	b.DoClick = self.ButtonClicked
	b.RBRadius = 4
	b:SetMaxRaise(0)
	b.DrawShadow = false
	b.DownSize = 2
	b:SetColor(Colors.Sky:Copy():MulHSV(1, 0.8, 0.8), true)
	b.TextX = 16
	b.TextAX = 0
	b:SetFont("EX24")

	b.RBEx = {}
end

function CAT:SetName(tx)
	self:GetButton():SetText(tx)
end
CAT.SetText = CAT.SetName

function CAT:SetExpanded(b)
	local an, new = self:To("ExpandFrac", b and 1 or 0, self:GetExpandTime(), 0, self:GetExpandEase())
	if new then
		local b, c = self:GetButton(), self:GetCanvas()
		an:On("Think", "THINKMARK", function()
			self:SetTall(Lerp(self.ExpandFrac, b:GetTall(), b:GetTall() + c:GetTall()))
		end)
	end

	self.Expanded = b

	self:Emit("ExpandChanged", b)
	self:Emit(b and "Expanded" or "Retracted")

	self:GetButton().RBEx.bl = not b
	self:GetButton().RBEx.br = not b
	self:GetButton().DownSize = b and 0 or 2
end

function CAT.ButtonClicked(btn)
	local self = btn._par
	self:SetExpanded(not self:GetExpanded())
	self:Emit("Clicked")
end

function CAT:OnChildAdded(ch)
	ch:SetParent(self:GetCanvas())
end

function CAT:Add(name)
	local p

	if isstring(name) then
		p = vgui.Create(name, self:GetCanvas())
	elseif ispanel(name) then
		p = name
		p:SetParent(self:GetCanvas())
	end

	return p
end

vgui.Register("FCategory", CAT, "InvisPanel")

local TESTING = false

if IsValid(_Pn) then _Pn:Remove() end
if not TESTING then return end

local f = vgui.Create("FFrame")
_Pn = f
f:SetSize(700, 500)
f:Center()
f:MakePopup()
f.Shadow = {}

local scr = vgui.Create("FScrollPanel", f)
scr:Dock(FILL)

for i=1, 5 do
	local col = vgui.Create("FCategory", scr)
	col:Dock(TOP)
	col:DockMargin(4, 4, 4, 0)
	col:SetText("Category #" .. i)

	for i2 = 1, 10 do
		local b = col:Add("FButton")
		b:SetText("Button #" .. i2)
		b:Dock(TOP)
		b:DockMargin(0, 0, 0, 4)
		b:SetTall(28)
		-- b:CacheShadow(4, {1, 4}, 2)
	end
end