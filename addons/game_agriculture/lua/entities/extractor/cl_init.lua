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
end

local scale3d = 0.03

function ENT:GetDisplaySize()
	return math.floor(286 * (0.05 / scale3d)), math.floor(323 * (0.05 / scale3d))
end


function ENT:DrawDisplay(a, dist)
	local w, h = self:GetDisplaySize()

	--[[surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(30, 30, 30, 150)
	surface.DrawRect(2, 2, w - 4, h - 4)]]

	if a == 0 then return end

end

local pt = Vector(19.82, -7.100080, 51.3)
local ptFuck = Vector(pt)
local ptAng = Angle("0.000 90.000 59.310")

local axis = Vector()

function ENT:Draw()
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
	local slotIn, slotOut

	if invIn then
		slotIn = vgui.Create("ItemFrame", invIn, "ItemFrame: InGrow")
		invIn:TrackItemSlot(slotIn, i)
		slotIn:BindInventory(self.In, i)
	end

	if invOut then
		slotOut = vgui.Create("ItemFrame", invOut, "ItemFrame: OutGrow")
		invOut:TrackItemSlot(slotOut, i)
		slotOut:BindInventory(self.Out, i)
	end

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

	nav:AddDockPadding(4, 0, 4, 0)
	local canv, new = nav:ShowAutoCanvas("grow", nil, 0.1, 0.2)
	nav:PositionPanel(canv)

	if not new then
		return
	end

	local sIns, sOuts = {}, {}
	local slotSize, slotPad = scale(80), scale(8)

	local _, fsz = nav:GetPositioned()

	local invIn = vgui.Create("InventoryPanel", canv)
	invIn.NoPaint = true
	invIn:EnableName(false)
	--invIn:SetShouldPaint(false)
	invIn:SetInventory(self.In)

	local invOut = vgui.Create("InventoryPanel", canv)
	invOut.NoPaint = true
	invOut:EnableName(false)
	--invOut:SetShouldPaint(false)
	invOut:SetInventory(self.Out)


	for i=1, math.max(self.In.MaxItems, self.Out.MaxItems) do
		local sin, sout = ent:CreateSlot(i <= self.In.MaxItems and invIn, i <= self.Out.MaxItems and invOut, i)

		if sin then
			sin:SetSize(slotSize, slotSize)
			table.insert(sIns, sin)
		end

		if sout then
			sout:SetSize(slotSize, slotSize)
			table.insert(sOuts, sout)
		end
	end

	--local poses, tW = vgui.Position(slotPad, unpack(sIns, 1, 2))
	--invIn:SetSize(tW + slotPad * 2, tW + slotPad * 2)
	--invIn:CenterVertical()

	local mxX, mxY = 0, 0

	for a, b in steps(#sIns, 2, 1) do
		local step = getStep()

		local poses, tW = vgui.Position(slotPad, unpack(sIns, a, b))
		mxX = math.max(tW, mxX)

		for k,v in pairs(poses) do
			k:SetPos(v, step * (slotSize + slotPad))
		end

		mxY = math.max(step * (slotSize + slotPad) + slotSize, mxY)
	end

	invIn:SetSize(mxX, mxY)

	poses, tW = vgui.Position(slotPad, unpack(sOuts))
	invOut:SetSize(tW + slotPad * 2, slotSize)
	invOut:SetPos(0, invOut:GetParent():GetTall() - invOut:GetTall() - slotPad)

	for k,v in pairs(poses) do
		k:SetPos(v, 0)
	end

	local arr = Icons.Arrow:Copy()
	arr:SetAlignment(1)
	arr:SetColor(nil)

	local emptyCol = Color(20, 20, 20)

	canv:On("Paint", "Arrows", function()
		local w = 14
		local w1 = 8
		local x = invIn.X + invIn:GetWide() / 2 - w / 2
		local yBeg =  invIn.Y + invIn:GetTall() + 4
		local xSpace = 48
		local yConv = invIn.Y + invIn:GetTall() + 32

		local iSz = 48
		local arrOff = math.ceil(6 / 36 * iSz) -- the arrow png has blank space at the end

		local h = invOut.Y - yConv + arrOff - 4

		local sx, sy = canv:LocalToScreen(0, 0)

		local fr = self:GetProgress()

		Colors.DarkGray:SetDraw()
		surface.DrawRect(x - xSpace, yBeg, w1, yConv - yBeg)
		surface.DrawRect(x + xSpace, yBeg, w1, yConv - yBeg)
		surface.DrawRect(x - xSpace, yConv, xSpace * 2 + w1, w1)
		surface.DrawRect(x, yConv, w, h - iSz / 2)
		arr:Paint(x + w / 2, yConv + h - iSz / 2, iSz, iSz, -90)

		-- ideally the white would fill from split first, then horizontally into
		-- convergence, and then downwards, but i really cant be fucked to do that
		render.PushScissorRect(sx, sy + yBeg, sx + ScrW(), sy + Lerp(fr, yBeg, yConv + (h - arrOff)))
			White()
			surface.DrawRect(x - xSpace, yBeg, w1, yConv - yBeg)
			surface.DrawRect(x + xSpace, yBeg, w1, yConv - yBeg)
			surface.DrawRect(x - xSpace, yConv, xSpace * 2 + w1, w1)
			surface.DrawRect(x, yConv, w, h - iSz / 2)
			arr:Paint(x + w / 2, yConv + h - iSz / 2, iSz, iSz, -90)
		render.PopScissorRect()
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

	local h = math.max(inv:GetTall(), scale(450))

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