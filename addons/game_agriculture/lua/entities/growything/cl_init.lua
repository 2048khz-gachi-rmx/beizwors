include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:CLInit()
end

ENT.DrawInitialized = false -- for autorefresh
local an

function ENT:DrawInit()
	if self.DrawInitialized then return end
	an = an or Animatable("growy")

	self.DrawInitialized = true

	self.Rings = {
		LibItUp.Circle(), LibItUp.Circle()
	}

	for k,v in pairs(self.Rings) do
		v:SetOutlined(true)
		v:SetSegments(32)
	end

	self.Ring = LibItUp.Circle()
	self.Ring:SetOutlined(true)

	local w, h = self:GetDisplaySize()

	self.Ring:SetRadius(w * 0.75 / 2)
	self.Ring:SetOutlineRadius(w * 0.75 / 2 - 6)

	self.delta = DeltaText()
		:SetFont("MRM24")

	local dt = self.delta
	dt.AlignX = 1

	local piece, key = dt:AddText("Idle.")
	piece:SetFont("EX64")
	piece:SetColor(Colors.LighterGray)
	piece:SetLiftStrength(-24)
	piece:SetDropStrength(24)

	local piece, key2 = dt:AddText("Working.")
	piece:SetFont("EXSB64")
	piece:SetColor(Colors.Money)
	piece:SetLiftStrength(-24)
	piece:SetDropStrength(24)

	self.idleKey = key
	self.activeKey = key2

	dt:ActivateElement(key)
end

local scale3d = 0.03

function ENT:GetDisplaySize()
	return math.floor(286 * (0.05 / scale3d)), math.floor(323 * (0.05 / scale3d))
end

local b = bench("elden", 600)

function ENT:DrawDisplay(a, dist)
	local w, h = self:GetDisplaySize()

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(30, 30, 30, 150)
	surface.DrawRect(2, 2, w - 4, h - 4)

	if a == 0 then return end

	local work = self:IsWorking()
	local hdW, hdH = 0, 64

	self.delta:ActivateElement(work and self.activeKey or self.idleKey)
	self.delta:Paint(w / 2, 8)

	surface.SetDrawColor(255, 255, 255, 100 * a)
	draw.NoTexture()

	local rx, ry = w / 2, hdH + (h - hdH) / 2
	self.Ring:Paint(rx, ry)

	local y = ry - 48 * 4 / 2

	for i=1, 4 do
		draw.SimpleText(("%.1f%%"):format(self:GetProgress(i) * 100), "EXSB56", w / 2, y, color_white, 1)
		y = y + 48
	end

	an:MemberLerp(self, "_workA", work and 1 or 0, 2, 0, 1)

	-- todo: optimize
	if self._workA and self._workA > 0 then
		--b:Open()
		local del = 3
		local ct = CurTime()

		for i, ring in ipairs(self.Rings) do
			local pass = (ct + del / #self.Rings * (i - 1)) % del
			local fr = math.ease.InOutSine(math.RemapClamp(pass, 0, del, 0, 1), 0.3)

			ring:SetRadius( self.Ring:GetRadius() * Lerp(fr, 1, 0.5) )
			ring:SetOutlineRadius(ring:GetRadius() - 4)

			-- wonky hacky temp optimization
			if dist > 0x2000 or fr > 0.7 then
				ring:SetSegments(16)
			elseif dist < 2048 then
				ring:SetSegments(48)
			else
				ring:SetSegments(24)
			end

			local aMult = work and math.RemapClamp(self._workA, fr, 1, 0, 1) or Ease(math.RemapClamp(self._workA, 0, fr, 0, 1), 4)
			surface.SetDrawColor(255, 255, 255, math.sin((1 - fr) * math.pi) * 100 * aMult)
			ring:Paint(rx, ry)
		end
		--b:Close():print()
	end
end

local pt = Vector(19.82, -7.100080, 51.3)
local ptFuck = Vector(pt)
local ptAng = Angle("0.000 90.000 59.310")

local axis = Vector()

function ENT:Draw()
	self:FrameAdvance(0.001)
	self:SetAutomaticFrameAdvance(false)
	self:DrawModel()
	self:DrawInit()

	if halo.RenderedEntity() == self then return end

	local pos, ang = self:LocalToWorld(pt), self:LocalToWorldAngles(ptAng)
	local dist = EyePos():DistToSqr(pos)
	local a = self._a or 1

	if dist > 0x5000 then
		an:MemberLerp(self, "_a", 0, 0.3, 0, 3)
	else
		an:MemberLerp(self, "_a", 1, 0.2, 0, 0.5)
	end

	if dist > 0x1000 then
		pos:Add(ang:ToUp(axis):CMul(0.2))
	end

	cam.Start3D2D(pos, ang, scale3d)
		xpcall(self.DrawDisplay, GenerateErrorer("AgricultureGrower"), self, a, dist)
	cam.End3D2D()
end

function ENT:CreateSlot(invIn, invOut, i)
	local slotIn = vgui.Create("ItemFrame", invIn, "ItemFrame: InGrow")
	invIn:TrackItemSlot(slotIn, i)
	slotIn:BindInventory(self.In, i)

	local slotOut = vgui.Create("ItemFrame", invOut, "ItemFrame: OutGrow")
	invOut:TrackItemSlot(slotOut, i)
	slotOut:BindInventory(self.Out, i)

	return slotIn, slotOut
end

function ENT:DoGrowMenu(open, nav, inv)
	local scale, scaleW = Scaler(1600, 900, true)
	local ent = self

	if not open then
		local canv = nav:HideAutoCanvas("grow")

		for k, slot in ipairs(inv:GetSlots()) do
			slot:Highlight()
		end

		return
	end

	local canv, new = nav:ShowAutoCanvas("grow", nil, 0.1, 0.2)
	nav:PositionPanel(canv)

	if not new then
		return
	end

	local maxSlots = ent.Levels[#ent.Levels].Slots

	local sIns, sOuts = {}, {}
	local slotSize, slotPad = scaleW(80), scaleW(16)

	local invIn = vgui.Create("InventoryPanel", canv)
	invIn.NoPaint = true
	invIn:EnableName(false)
	invIn:SetShouldPaint(false)
	invIn:SetInventory(self.In)

	local invOut = vgui.Create("InventoryPanel", canv)
	invOut.NoPaint = true
	invOut:EnableName(false)
	invOut:SetShouldPaint(false)
	invOut:SetInventory(self.Out)

	for i=1, maxSlots do
		local sin, sout = ent:CreateSlot(invIn, invOut, i)
		sin:SetSize(slotSize, slotSize)
		sout:SetSize(slotSize, slotSize)

		table.insert(sIns, sin)
		table.insert(sOuts, sout)
	end

	local poses, tW = vgui.Position(slotPad, unpack(sIns))
	invIn:SetSize(tW + slotPad * 2, slotSize + slotPad * 2)
	invIn:CenterHorizontal()

	for k,v in pairs(poses) do
		k:SetPos(slotPad + v, k.Y)
		k:CenterVertical()
	end

	poses, tW = vgui.Position(slotPad, unpack(sOuts))
	invOut:SetSize(tW + slotPad * 2, slotSize + slotPad * 2)
	invOut:CenterHorizontal()
	invOut.Y = canv:GetTall() - invOut:GetTall()

	for k,v in pairs(poses) do
		k:SetPos(slotPad + v, k.Y)
		k:CenterVertical()
	end

	local arr = Icons.Arrow:Copy()
	arr:SetAlignment(1)
	arr:SetColor(nil)

	local emptyCol = Color(20, 20, 20)

	canv:On("Paint", "Arrows", function()
		local iSz = 36
		local arrOff = math.ceil(6 / 36 * iSz) -- the arrow png has blank space at the end

		local y = invIn.Y + invIn:GetTall()
		local w, h = 8, invOut.Y - y + arrOff

		local hx = invIn.X
		local sx, sy = canv:LocalToScreen(0, 0)

		for k,v in ipairs(sIns) do
			local x = v:GetPos()
			x = x + v:GetWide() / 2 - w / 2 + hx

			local fr = self:GetProgress(k)

			Colors.DarkGray:SetDraw()
			surface.DrawRect(x, y, w, h - iSz / 2)
			arr:Paint(x + w / 2, y + h - iSz / 2, iSz, iSz, -90)

			render.PushScissorRect(sx, sy + y, sx + ScrW(), sy + y + (h - arrOff) * fr)
				White()
				surface.DrawRect(x, y, w, h - iSz / 2)
				arr:Paint(x + w / 2, y + h - iSz / 2, iSz, iSz, -90)
			render.PopScissorRect()
		end
	end)

	
end

function ENT:Used()
	local scale, scaleW = Scaler(1600, 900, true)
	local menu = vgui.Create("FFrame")

	local inv = Inventory.Panels.CreateInventory(
		Inventory.GetTemporaryInventory(LocalPlayer()),
		nil, {
			SlotSize = scaleW(64)
		}
	)

	inv:ShrinkToFit()

	local h = math.max(inv:GetTall(), scale(352))

	inv:SetTall(h)
	menu:SetSize(scaleW(500), h)
	menu:PopIn()

	menu:Bond(inv)
	inv:Bond(menu)
	menu:Bond(self)

	local poses, tW = vgui.Position(8, menu, inv)
	inv:CenterVertical()

	for k,v in pairs(poses) do
		k:SetPos(ScrW() / 2 - tW / 2 + v, inv.Y)
	end

	inv:MakePopup()

	--[[local bpTab = menu:AddTab("Grow", function(_, _, pnl)
		self:DoGrowMenu(true, menu, inv)
	end, function()
		self:DoGrowMenu(false, menu, inv)
	end)

	bpTab:Select(true)]]

	self:DoGrowMenu(true, menu, inv)
end

net.Receive("growything", function()
	local e = net.ReadEntity()
	e:Used()
end)