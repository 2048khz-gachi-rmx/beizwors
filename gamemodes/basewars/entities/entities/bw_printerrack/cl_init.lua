--easylua.StartEntity("bw_printerrack")
AddCSLuaFile()
include("shared.lua")


function ENT:CLInit()

	if not self.FontColor then self.FontColor = color_white:Copy() end
	if not self.BackColor then self.BackColor = color_black:Copy() end

	self.Printers = Networkable(("PrinterRack:%d"):format(self:EntIndex())):Bond(self)
	self.PowerRequired = 5
end

function ENT:GetMiscPos()

	local pos = self:GetPos()
	local ang = self:GetAngles()
	--Vector (17.3935546875, -11.271484375, -1.4185791015625)
	pos = pos + ang:Up() * 76.5
	pos = pos + ang:Forward() * -19.2
	pos = pos + ang:Right() * 17.6

	ang:RotateAroundAxis(ang:Forward(), 90)

	--ang:RotateAroundAxis(ang:Forward(), 90)
	return pos, ang, 0.05

end

local scaleH = { --bool = scaled down or not
	[false] = 72,
	[true] = 60
}

-- autorefresh
_RackFrames = _RackFrames or {}
for k,v in pairs(_RackFrames) do
	v:Remove()
end

local function CreateFrame(ent)

	local f =  vgui.Create("FFrame")
	_RackFrames[ent] = f

	f:SetPos(0,0)
	f:SetSize(750, 1500)
	f:SetDraggable(false)
	f:SetMouseInputEnabled(false)

	f.Buttons = {}
	f:SetCloseable(false, true)
	f.HeaderSize = 48

	f:DockPadding(16, 64, 16, 16)
	f.ScaleDown = ScrH() < 800
	f.Shadow = false

	local col = vgui.Create("FButton", f)
	col.UseSFX = true

	f:On("Think", function(self)
		if not IsValid(ent) then
			self:Remove()
			_RackFrames[ent] = nil
			return
		end --bruh
	end)

	local clip = false

	function f:PrePaint(w, h)
		clip = DisableClipping(true)
		draw.EnableFilters()
	end

	function f:PaintOver(w, h)
		draw.DisableFilters()
		if not clip then DisableClipping(false) end
	end

	function f:PostPaint(w,h)

		draw.SimpleText("Printer Rack", "EXSB48", w/2, 24, color_white, 1, 1)
		self.ScaleDown = ScrH() < 800

		local desH = scaleH[self.ScaleDown]

		for k,v in pairs(self.Buttons) do
			if v:GetTall() ~= desH and v.ExpandFrac == 0 then
				v:SetTall(desH)
			end
		end

		col:SetTall(desH * 1.5)
	end
	ent.Frame = f

	col:SetSize(450, 120)
	col:DockMargin(150, 24, 150, 24)
	col:Dock(TOP)
	col:SetZPos(32766)
	col.RaiseHeight = 4

	local color = Color(90, 180, 90)

	function col:Think()
		if not IsValid(ent) then return end
		if ent:BW_GetOwner() ~= LocalPlayer():GetPInfo() then
			self:SetColor(Colors.Button)
		else
			self:SetColor(color)
		end
	end

	function col:DoClick()
		net.Start("PrinterRack")
			net.WriteEntity(ent)
			net.WriteUInt(1, 2)
		net.SendToServer()
	end

	col.Label = "Collect"
	col.Font = "EXSB64"
	col.DrawShadow = false
	return f
end

function ENT:CreateButton(f, ent, entKey)
	local rack = self
	local entID = ent:EntIndex()

	f.Buttons[entKey] = vgui.Create("EButton", f)
	local fr = f.Buttons[entKey]
	fr.UseSFX = true
	
	fr:SetDoubleClickingEnabled(false)
	fr.DownSize = 0
	--fr:SetPos(50, -100 + f.HeaderSize + 16 + 100*i)
	local frH = scaleH[f.ScaleDown]

	fr:SetSize(375, frH)
	fr:Dock(TOP)
	fr:DockMargin(8, 8, 8, 0)
	fr.Border = {w = 2, h = 2, col = ent.FontColor or Color(255, 0, 0)}
	fr.ID = entKey

	function fr:IsHovered()
		return self.Hovered and not (self.Eject.Hovered or self.Upgrade.Hovered)
	end
	local dc = fr.DoClick

	function fr:DoClick()
		if not self:IsHovered() then return end

		for k,v in pairs(f.Buttons) do
			if v == self then continue end

			v:RetractBtn()
		end

		dc(self)
	end

	local tempCol = Color(0, 0, 0)

	fr.CapFr = 0

	function fr:PostPaint(w, h)
		if not IsValid(ent) or rack.Printers:GetNetworked()[entKey] ~= entID then
			self:Remove()
			return
		end

		h = self:GetDrawableHeight()

		local capFr = ent:GetMoneyFraction()
		if capFr < self.CapFr then
			-- only possible if withdrawn; just go to 0 and go to capFr afterwards
			self:To("CapFr", 0, 0.4, 0, 5)
		else
			self:To("CapFr", capFr, 0.5, 0, 0.3)
		end
		
		capFr = self.CapFr

		local txt = ("%s Lv. %s"):format(ent.PrintName, ent:GetLevel() or "What")
		local amt = ent.GetPrintAmount and
			("$%s/s."):format(BaseWars.NumberFormat(ent:GetPrintAmount())) or ""

		surface.SetFont("EXM36")
		local tw, th = surface.GetTextSize(txt)
		local tx, ty = 12, h / 2 - th / 2
		local borderSz = 4

		surface.SetFont("EX28")
		local amtW, amtH = surface.GetTextSize(amt)
		local amtx, amty = w - 12 - amtW, h / 2 - amtH / 2

		draw.BeginMask()
			surface.SetDrawColor(255, 255, 255)
			surface.DrawRect(0, 0, math.floor(w * capFr), h)
		draw.DeMask()
			draw.RoundedStencilBox(self.RBRadius, tx - borderSz, ty - borderSz,
				(amtx - tx + amtW) + borderSz * 2, th + borderSz * 2, color_white)
		draw.DrawOp()
		render.SetStencilCompareFunction( STENCIL_EQUAL )
			tempCol:Set(ent.FontColor)
			tempCol:MulHSV(1, 0.7, 0.6)

			draw.RoundedBoxEx(self.RBRadius, 0, 0, math.floor(w * capFr), h,
				tempCol, true, false, true, false)
		render.SetStencilCompareFunction( STENCIL_NOTEQUAL )
			draw.RoundedBoxEx(self.RBRadius, 0, 0, w, h,
				ent.FontColor, true, false, true, false)
		draw.EndMask()

		draw.SimpleText2(txt, "EXM36", tx, ty, color_white)


		if ent.GetPrintAmount then
			draw.SimpleText(amt, "EX28", amtx, amty,
				color_white, 0, 0)
		end
	end

	function fr.ExpandPanel:Paint(w, h)
						-- V only because 3d2d panels act wonky with clipping
		fr:ExpandPaint(w, fr:GetTall() - fr.FakeH)

		-- somehow makes upgrade/eject buttons clip properly??
		-- i ain't askin
		self:NoClipping(true)
	end

	function fr.ExpandPanel:PaintOver()
		self:NoClipping(false)
	end

	fr.Eject = vgui.Create("FButton", fr.ExpandPanel)
	local b = fr.Eject
	b.UseSFX = true

	b:Dock(FILL)
	b:DockMargin(400, 16, 100, 16)

	b:InvalidateParent(true)

	b:SetLabel("Eject")
	b.Font = "OS32"
	--b:SetPaintedManually(true)

	b.DoClick = function(s)
		net.Start("PrinterRack")
			net.WriteEntity(self)
			net.WriteUInt(0, 2) -- = eject
			net.WriteUInt(entKey, 8)
		net.SendToServer()

	end
	b:SetColor(90, 90, 90)
	b.DrawShadow = false

	function b:PostPaint(w, h)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawMaterial("https://i.imgur.com/8xUwtGR.png", "eject.png", 18, 13, 32, 32)
	end

	function b:IsHovered()
		return self.Hovered
	end

	fr.Upgrade = vgui.Create("FButton", fr.ExpandPanel)
	local b2 = fr.Upgrade
	b2.UseSFX = true

	b2:SetPos(100, 16)
	b2:SetSize(236, b:GetTall())

	b2:SetLabel("Upgrade")
	b2.Font = "OS32"
	--b:SetPaintedManually(true)

	b2:SetDoubleClickingEnabled(false)
	b2.TextAX = 0
	b2.TextX = 18 + 32 + 8

	function b2:PostPaint(w, h)
		if not ent:IsValid() then self:Remove() return end
		if ent:GetMaxLevel() == ent:GetLevel() then
			self:SetEnabled(false)
		end

		surface.SetDrawColor(255, 255, 255)
		surface.DrawMaterial("https://i.imgur.com/6CyUc0d.png", "upgrade.png", 18, 13, 32, 32)

		local lc = self.LabelColor

		if self:IsHovered() and self:IsEnabled() then
			lc.a = L(lc.a, 0, 30, true)
		else
			lc.a = L(lc.a, 255, 30, true)
		end

		local cost = BaseWars.NumberFormat(ent:GetUpgradeCost())
		draw.SimpleText("$" .. cost, "OS36", 18 + 32 + 8, h/2, ColorAlpha(color_white, 255 - lc.a), 0, 1)
	end

	b2.DoClick = function(self)
		net.Start("BW.Upgrade")
			net.WriteEntity(ent)
			net.WriteUInt(1, 8)
		net.SendToServer()
	end

	b2:SetColor(90, 90, 90)

	function b2:IsHovered()
		return self.Hovered
	end
	b2.DrawShadow = false

	return fr
end

function ENT:Draw()
	if halo.RenderedEntity() == self then return end

	self:DrawModel()

	local dist = LocalPlayer():GetPos():DistToSqr(self:GetPos())
	if dist > 65536 then return end

	local pos, ang, scale = self:GetMiscPos()

	if not IsValid(self.Frame) then
		CreateFrame(self)
	end
	local f = self.Frame

	local pr = self:GetPrinters()
	local t = self.Printers:GetNetworked()

	local i = 0

	for entKey, entID in pairs(t) do
		if IsValid(f.Buttons[entKey]) then continue end

		local ent = Entity(entID)
		if not IsValid(ent) then continue end

		self:CreateButton(f, ent, entKey)
	end

	for k,v in pairs(f.Buttons) do
		if not IsValid(v) then
			f.Buttons[k] = nil
			continue
		end

		if t[v.ID] == 0 then
			v:PopOut()
			f.Buttons[k] = nil
			continue
		end
	end

	vgui.Start3D2D( pos, ang, scale )
		self.Frame:Paint3D2D()
	vgui.End3D2D()
end

--easylua.EndEntity("bw_printerrack")