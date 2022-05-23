--
local MAP = {}

local CanvasSize = 2048
local CanvasMaxZoom = 1
local CellSize = 80
local PerkSize = 72

local DefaultZoom = 0.75

function MAP:Init()
	self.Scroll:Hide() -- we use searchlayout for the search bar only
	self.SearchBar:SetPlaceholderText("not implemented")

	local main = self

	local map = vgui.Create("DPanel", self)
	map:Dock(FILL)

	map.Paint = MAP.PaintMap
	--map.OnMouseReleased = MAP.OnMapReleased
	map.Think = MAP.MapThink


	local canv = vgui.Create("DPanel", map)
	canv:SetSize(CanvasSize, CanvasSize)

	canv:Center()

	canv.Paint = MAP.PaintCanvas
	canv.OnMousePressed = MAP.OnCanvasPressed
	canv.OnMouseWheeled = MAP.OnCanvasWheeled

	canv.Zoom = DefaultZoom
	canv.NeedZoom = DefaultZoom

	map.Cam = { canv:GetPos() }
	map.Mouse = { 0, 0 }


	local reset = vgui.Create("FButton", map)
	reset:SetSize(32, 32)
	reset:MoveToFront()
	reset:SetIcon(Icon("https://i.imgur.com/Kr2xpAj.png", "swap_inv.png"):SetSize(24, 24))

	map.Canvas = canv
	map.Main = self
	canv.Map = map
	canv.Main = self

	self.TreeButtons = {}

	self.Map = map
	self.Canvas = canv

	self.ResetBtn = reset
	reset:SetAlpha(50)

	function reset:OnHover()
		local cl = self:AddCloud("res", "Reset View")

		cl.ToY = 4

		cl.OffsetX = self:GetWide() / 2
		cl.OffsetY = self:GetTall() + 4

		cl.YAlign = 0
		self:AlphaTo(255, 0.2, 0, 0.3)
	end

	function reset:OnUnhover()
		self:RemoveCloud("res")
		self:AlphaTo(50, 1.3, 0, 2.6)
	end

	function reset:DoClick()
		-- todo: animate this
		main:ResetView(true)
	end

end

function MAP:ResetView(an)
	self:SetZoom(DefaultZoom)

	local x, y = -CanvasSize * DefaultZoom / 2 + self.Map:GetWide() / 2,
		-CanvasSize * DefaultZoom / 2 + self.Map:GetTall() / 2

	local cx, cy = self.Canvas:GetPos()

	if an then
		local anim, new = self.Canvas:To("ResetFr", 1, 0.3, 0, 0.3, true)

		if new then
			anim:Then(function()
				self:Offset(x, y, true)
				self:SetZoom(DefaultZoom, true)
			end)

			anim:On("Think", "upCam", function(_, fr)
				self:Offset(Lerp(fr, cx, x), Lerp(fr, cy, y), true)
			end)
		end
	else
		self.Canvas:SetPos(x, y)
		self.Map.Cam[1], self.Map.Cam[2] = x, y
	end
end

function MAP:Populate()
	self:InvalidateLayout(true)
	local w, h = self.Canvas:GetSize()

	self:ResetView()
end

local function onZoom(self)
	local cl = self:GetCloud("perkDesc")
	if cl then
		cl:SetRelPos(self:GetWide() / 2, -4)
	end
end

function MAP:SetComputer(ent)
	self._comp = ent
end

function MAP:OnCreatePerk(btn)
	local lvl = btn.Level

	local map = self.Map
	local main = self

	function btn:OnHover()
		local cl, new = self:AddCloud("perkDesc", lvl:GetName())
		if new then
			cl:SetRelPos(self:GetWide() / 2, -4)
			cl.ToY = -8
			cl.MaxW = 500
		end
	end

	function btn:OnUnhover()
		self:RemoveCloud("perkDesc", lvl:GetName())
	end

	if IsValid(self.ActiveBtn) then
		self.ActiveBtn:Deselect()
		self.ActiveBtn = nil
	end

	btn:On("Deselect", 	"Forward", function(btn, lvl, another)
		self:Emit("DeselectedPerk", btn, lvl, another)
		self.ActiveBtn = nil
	end)

	btn:On("Select", 	"Forward", function(btn, lvl)
		if IsValid(self.ActiveBtn) then self.ActiveBtn:Deselect(true) end
		self.ActiveBtn = btn
		self:Emit("SelectedPerk", btn, lvl)
	end)

	btn:On("Zoom", "cloud", onZoom)

	if lvl:IsResearched(CachedLocalPlayer()) then
		btn.bgColor = Colors.Sky:Copy():MulHSV(1, 0.8, 0.8)
	elseif lvl:PrereqsSatisified() then
		if lvl:CanResearch(CachedLocalPlayer(), self._comp) then
			btn.bgColor = Colors.Yellowish:Copy():MulHSV(1, 0.7, 0.5)
		else
			btn.bgColor = Colors.Reddish:Copy():MulHSV(1, 0.8, 0.7)
		end
	else
		btn.bgColor = Color(62, 62, 62)
	end
end

function MAP:SetTree(tree)
	if self.TreeButtons[self.ActiveTree] then
		for k,v in pairs(self.TreeButtons[self.ActiveTree]) do
			v:PopOutHide()
		end
	end

	self.ActiveTree = tree

	if self.TreeButtons[tree] then
		for k,v in pairs(self.TreeButtons[tree]) do
			v:PopInShow()
		end
		return
	end

	self.TreeButtons[tree] = {}
	local perks = tree:GetPerks()

	local cx, cy = self.Canvas:GetWide() / 2, self.Canvas:GetTall() / 2

	local dels = {}

	for id, dat in pairs(perks) do
		for ln, lv in ipairs(dat:GetLevels()) do
			local x, y = lv:GetPos()
			x, y = x * CellSize, y * CellSize

			local btn = vgui.Create("ResearchPerk", self.Canvas)
			btn:SetSize(PerkSize, PerkSize)
			btn:SetPos(cx + x - PerkSize / 2, cy + y - PerkSize / 2)
			btn.OrigSize = { PerkSize, PerkSize }

			btn.Anchor = {
				btn.X / CanvasSize,
				btn.Y / CanvasSize
			}

			btn.SizeAnchor = PerkSize / CanvasSize / 2

			btn.OrigAnchor = table.Copy(btn.Anchor)

			btn:SetLevel(lv)
			table.insert(self.TreeButtons[tree], btn)
			dels[btn] = true --ln * 0.06

			self:OnCreatePerk(btn)
		end
	end

	self:SetZoom(self.Canvas.Zoom, true)

	local mv = 12

	local function move(an, fr)
		local mvX, mvY = an.Parent.MvX, an.Parent.MvY

		-- egh
		an.Parent.Anchor[1] = Lerp(fr,
			an.Parent.OrigAnchor[1] - (mvX / CanvasSize / self.Canvas.Zoom),
			an.Parent.OrigAnchor[1])

		an.Parent.Anchor[2] = Lerp(fr,
			an.Parent.OrigAnchor[2] - (mvY / CanvasSize / self.Canvas.Zoom),
			an.Parent.OrigAnchor[2])

		an.pool = an.pool or mvY
		an.lx = an.lx or 0
		an.ly = an.ly or 0
		an.storex = an.storex or 0
		an.storey = an.storey or 0

		local mvBy = (mvY * fr - mvY * an.ly)
		an.ly = fr
		local addy, storey = math.modf(an.storey + mvBy)
		an.storey = storey

		local mvBx = (mvX * fr - mvX * an.lx)
		an.lx = fr
		local addx, storex = math.modf(an.storex + mvBx)
		an.storex = storex

		if math.abs(addy) < 1 and math.abs(addx) < 1 then return end

		an.Parent.X = an.Parent.X + addx
		an.Parent.Y = an.Parent.Y + addy
	end

	local function off(an)
		local mvX, mvY = an.Parent.MvX, an.Parent.MvY
		an.Parent.X = an.Parent.X - mvX
		an.Parent.Y = an.Parent.Y - mvY

		an.Parent.Anchor[1] = an.Parent.Anchor[1] -
			(mvX / CanvasSize / self.Canvas.Zoom)

		an.Parent.Anchor[2] = an.Parent.Anchor[2] -
			(mvY / CanvasSize / self.Canvas.Zoom)
	end

	for btn, del in pairs(dels) do
		local center = CanvasSize / 2 * self.Canvas.Zoom

		local ax, ay = btn.Anchor[1] + btn.SizeAnchor - 0.5,
			btn.Anchor[2] + btn.SizeAnchor - 0.5

		local dist = math.sqrt( ax ^ 2 + ay ^ 2 )

		del = dist / 0.5 -- 50% of the map covered in a second

		local rad = 24

		btn.MvX = ax / dist * rad
		btn.MvY = ay / dist * rad

		if dist == 0 then
			btn.MvX, btn.MvY = 0, 0
		end

		local an = btn:PopIn(0.2, del)
		an:On("Start", "a", off)

		local an = btn:To("PopInFr", 1, 0.5, del, 0.3, true)

		an:On("Think", "a", move)
		an:Then(function() self:SetZoom(self.Canvas.Zoom, true) end)
	end
end

function MAP:PerformLayout()
	self.ResetBtn:SetPos(self.Map:GetWide() - 36, self.Map:GetTall() - 36)
end

function MAP:Paint(w, h)
	surface.SetDrawColor(self:GetColor():Unpack())
	surface.DrawRect(0, 0, w, self.SearchPanel.Y * 2 + self.SearchPanel:GetTall())
end

function MAP:OnCanvasPressed(mmb)
	if mmb ~= MOUSE_RIGHT then return end
	self.Pressed = true

	self.Map.Mouse[1], self.Map.Mouse[2] = gui.MousePos()
end

function MAP:Offset(x, y, abs)
	x = x or 0
	y = y or 0

	local newX = abs and x or self.Map.Cam[1] + x
	local newY = abs and y or self.Map.Cam[2] + y

	self.Map.Cam[1] = math.Clamp(newX, -(CanvasSize * self.Canvas.Zoom - self:GetWide()), 0)
	self.Map.Cam[2] = math.Clamp(newY, -(CanvasSize * self.Canvas.Zoom - self:GetTall()), 0)

	local cx, cy = unpack(self.Map.Cam)
	self.Canvas:SetPos(cx, cy)
end

local fl = math.floor

function MAP:SetZoom(newZoom, now)
	local canv = self.Canvas

	newZoom = math.Clamp(newZoom, canv.Map:GetWide() / CanvasSize * 1.5, CanvasMaxZoom)

	local delta = newZoom - canv.Zoom
	canv.NeedZoom = newZoom

	local mx, my = canv.Map:ScreenToLocal(gui.MousePos())

	local cx = (-mx + canv.Map.Cam[1]) / canv.Zoom * delta
	local cy = (-my + canv.Map.Cam[2]) / canv.Zoom * delta

	if now then
		canv.Zoom = newZoom

		local cw, ch = canv:GetSize()

		for k,v in pairs(canv:GetChildren()) do
			v:SetSize(
				math.floor(v.OrigSize[1] * canv.Zoom),
				math.floor(v.OrigSize[2] * canv.Zoom)
			)

			v:SetPos(
				math.floor(v.Anchor[1] * canv.Zoom * cw),
				math.floor(v.Anchor[2] * canv.Zoom * ch)
			)

			v:Emit("Zoom", canv.Zoom)
		end

	else
		local an, new = canv:To("Zoom", newZoom, 0.3, 0, 0.3)
		if new then
			local lfr = 0
			local cw, ch = canv:GetSize()

			local children = canv:GetChildren()

			an:On("Think", "off", function(_, fr)
				local dx, dy = fl(cx * fr) - fl(cx * lfr), fl(cy * fr) - fl(cy * lfr)
				lfr = fr
				self:Offset(dx, dy)

				for k,v in ipairs(children) do
					v:SetSize(v.OrigSize[1] * canv.Zoom, v.OrigSize[2] * canv.Zoom)
					v:SetPos(v.Anchor[1] * canv.Zoom * cw, v.Anchor[2] * canv.Zoom * ch)
					v:Emit("Zoom", canv.Zoom)
				end
			end)
		end
	end
end

function MAP:OnCanvasWheeled(w)
	local newZoom = math.Clamp(self.NeedZoom + w / 4, self.Map:GetWide() / (CanvasSize - 64), CanvasMaxZoom)
	self.Main:SetZoom(newZoom)
end

function MAP:MapThink()
	self.Canvas.Pressed = self.Canvas.Pressed and input.IsMouseDown(MOUSE_RIGHT)

	if self.Canvas.Pressed then
		local mx, my = gui.MousePos()
		local dx, dy = mx - self.Mouse[1], my - self.Mouse[2]

		self.Mouse[1], self.Mouse[2] = mx, my

		self.Main:Offset(dx, dy)
	end
end

function MAP:PaintMap(w, h)
	surface.SetDrawColor(Colors.DarkGray)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(0, 0, 0)
	self:DrawGradientBorder(w, h, 3, 3, nil, false)
end

local col = {}

function MAP:PaintCanvas()
	local w, h = CanvasSize, CanvasSize

	local gridPeriod = 128
	local u2 = w / gridPeriod / self.Zoom
	local v2 = h / gridPeriod / self.Zoom

	surface.SetDrawColor(200, 200, 200, 2)
	surface.DrawUVMaterial("https://i.imgur.com/UVOE9B2.png", "grid.png",
		0, 0, w, h,
		0, 0, u2, v2)

	w, h = w * self.Zoom, h * self.Zoom
	surface.SetDrawColor(255, 200, 200, 50)
	surface.DrawLine(0, h / 2, w, h / 2)
	surface.DrawLine(w / 2, 0, w / 2, h)

	if not self.CENTER then return end
	surface.DrawRect(self.CENTER - 2, self.CENTER - 2, 4, 4)
end

vgui.Register("ResearchMap", MAP, "SearchLayout")