--
local MAP = {}

CanvasSize = 2048
CanvasMaxZoom = 1

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

	canv.Zoom = 1
	canv.NeedZoom = 1

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
		canv:Center()
		map.Cam[1], map.Cam[2] = canv:GetPos()

		main:SetZoom(1, true)
	end

end

function MAP:ResetView()
	self.Canvas:Center()
	self.Map.Cam = { self.Canvas:GetPos() }
	self:SetZoom(1, true)
end

function MAP:Populate()
	self:InvalidateLayout(true)
	local w, h = self.Canvas:GetSize()

	for x = 1, w, 128 do
		for y = 1, h, 128 do
			local btn = vgui.Create("FButton", self.Canvas)
			btn:SetSize(32, 32)
			btn:SetPos(x, y)
			btn:SetColor(ColorRand())

			btn.Anchor = { (x + 16) / w, (y + 16) / h }
			btn.OrigSize = { 32, 32 }
		end
	end

	self:ResetView()
end

function MAP:SetTree(tree)

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

function MAP:Offset(x, y)
	x = x or 0
	y = y or 0

	self.Map.Cam[1] = math.Clamp(self.Map.Cam[1] + x, -(CanvasSize * self.Canvas.Zoom - self:GetWide()), 0)
	self.Map.Cam[2] = math.Clamp(self.Map.Cam[2] + y, -(CanvasSize * self.Canvas.Zoom - self:GetTall()), 0)

	local cx, cy = unpack(self.Map.Cam)
	self.Canvas:SetPos(cx, cy)
end

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
			v:SetSize(v.OrigSize[1] * canv.Zoom, v.OrigSize[2] * canv.Zoom)
			v:SetPos(v.Anchor[1] * canv.Zoom * cw, v.Anchor[2] * canv.Zoom * ch)
		end

	else
		local an, new = canv:To("Zoom", newZoom, 0.3, 0, 0.3)
		if new then
			local lfr = 0
			local cw, ch = canv:GetSize()

			local children = canv:GetChildren()

			an:On("Think", "off", function(_, fr)
				local dx, dy = cx * fr - cx * lfr, cy * fr - cy * lfr
				lfr = fr
				self:Offset(dx, dy)

				for k,v in ipairs(children) do
					v:SetSize(v.OrigSize[1] * canv.Zoom, v.OrigSize[2] * canv.Zoom)
					v:SetPos(v.Anchor[1] * canv.Zoom * cw, v.Anchor[2] * canv.Zoom * ch)
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

	surface.SetDrawColor(255, 200, 200, 50)
	surface.DrawRect(w - 8, h - 8, 8, 8)

	--[[local i = 0

	for x = 1, w * self.Zoom, 64 * self.Zoom do
		for y = 1, h * self.Zoom, 64 * self.Zoom do
			i = i + 1
			local c = col[i] or ColorRand()
			col[i] = c
			surface.SetDrawColor(c:Unpack())
			surface.DrawRect(x, y, 8 * self.Zoom, 8 * self.Zoom)
		end
	end]]
end

vgui.Register("ResearchMap", MAP, "SearchLayout")