--
local MAP = {}

local CanvasSize = 2048
local CanvasMaxZoom = 1
local CellSize = 80
local PerkSize = 72

local DefaultZoom = 0.75

function MAP:Init()
	self.Scroll:Hide() -- we use searchlayout for the search bar only

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

	btn:On("Deselect", 	"Forward", function(btn, lvl)
		self:Emit("DeselectedPerk", btn, lvl)
	end)

	btn:On("Select", 	"Forward", function(btn, lvl)
		if IsValid(self.ActiveBtn) then self.ActiveBtn:Deselect() end
		self.ActiveBtn = btn
		self:Emit("SelectedPerk", btn, lvl)
	end)

	btn:On("Zoom", "cloud", onZoom)
end

function MAP:SetTree(tree)
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

			btn.OrigAnchor = {
				btn.X / CanvasSize,
				btn.Y / CanvasSize
			}

			btn:SetLevel(lv)

			dels[btn] = ln * 0.06

			self:OnCreatePerk(btn)
		end
	end

	self:SetZoom(self.Canvas.Zoom, true)

	local mv = 12

	local function move(an, fr)
		an.pool = an.pool or mv
		an.ly = an.ly or 0
		an.store = an.store or 0

		local mvBy = (mv * fr - mv * an.ly)
		an.ly = fr
		local add, store = math.modf(an.store + mvBy)
		an.store = store

		if add < 1 then return end

		an.Parent.Y = an.Parent.Y + add
		an.totalMove = (an.totalMove or 0) + add

		-- egh
		an.Parent.Anchor[2] = Lerp(fr, an.Parent.OrigAnchor[2] - (mv / CanvasSize / self.Canvas.Zoom), an.Parent.OrigAnchor[2])
	end

	local function off(an)
		an.Parent.Y = an.Parent.Y - mv
		an.Parent.Anchor[2] = an.Parent.Anchor[2] - (mv / CanvasSize / self.Canvas.Zoom)
	end

	for btn, del in pairs(dels) do
		btn:PopIn(0.2, del)
			:On("Start", "a", off)

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

	newZoom = math.Clamp(newZoom, canv.Map:GetWide() / (CanvasSize - 64), CanvasMaxZoom)

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
end

vgui.Register("ResearchMap", MAP, "SearchLayout")