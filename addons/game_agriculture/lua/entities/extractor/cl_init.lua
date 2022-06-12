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

-- dear god.
function ENT:Bucket()
	if IsValid(self._bukkit) then return self._bukkit end

	local b = ClientsideModel("models/craphead_scripts/the_cocaine_factory/utility/bucket.mdl",
		RENDERGROUP_OPAQUE)
	b:SetNoDraw(true)
	b:SetBodygroup(1, 1)
	b:SetParent(self)
	self._bukkit = b

	return b
end

local scale3d = 0.03

function ENT:GetDisplaySize()
	return math.floor(286 * (0.05 / scale3d)), math.floor(323 * (0.05 / scale3d))
end

local pt = Vector(19.82, -7.100080, 51.3)
local bucketPos = Vector(11, 17.4, 27.003067016602)

local ptFuck = Vector(pt)
local ptAng = Angle("0.000 90.000 59.310")

local axis = Vector()

function ENT:Draw()
	self:FrameAdvance()

	local bk = self:Bucket()
	local fr = self:GetCocainerFr() + self:GetProgress() * 10

	bk:SetPos(self:LocalToWorld(bucketPos))
	bk:SetAngles(self:GetAngles())
	bk:SetNoDraw(false)
	bk:DrawModel()
	bk:SetNoDraw(true)
	bk:SetPoseParameter("cocaine", fr)

	local pp = self:GetPoseParameter("gauge") * 100
	self:SetPoseParameter("gauge", fr)

	local from = self:GetWorking() and 0 or 1
	local to = 1 - from
	local switchFr = Ease(math.RemapClamp(CurTime(), self:GetWorkChanged(), self:GetWorkChanged() + 0.2, from, to) or 0, 3)
	self:SetPoseParameter("switch", switchFr * 100)

	if fr - pp > 5 then -- server/client diff because server doesnt handle poseparams
		self:InvalidateBoneCache()
	end

	self:DrawModel()
	self:DrawInit()
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
	invIn:SetShouldPaint(false)
	invIn:SetInventory(self.In)

	local invOut = vgui.Create("InventoryPanel", canv)
	invOut.NoPaint = true
	invOut:EnableName(false)
	invOut:SetShouldPaint(false)
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
	invOut:SetPos(invIn:GetWide() / 2 - invOut:GetWide() / 2, invOut:GetParent():GetTall() - invOut:GetTall() - slotPad)

	for k,v in pairs(poses) do
		k:Center()
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

	for k,v in pairs(sIns) do
		v:On("FastAction", "Send", function(self, why)
			local itm = self:GetItem(true)
			if not itm or not itm:GetBase() then return end

			LocalPlayer():GetBackpack()
				:RequestPickup(itm)
		end)
	end

	for k,v in pairs(sOuts) do
		v:On("FastAction", "Send", function(self, why)
			local itm = self:GetItem(true)
			if not itm or not itm:GetBase() then return end

			LocalPlayer():GetBackpack()
				:RequestPickup(itm)
		end)
	end

	for k,v in pairs(inv:GetSlots()) do
		v:On("FastAction", "Send", function(self, why)
			local itm = self:GetItem(true)
			if not itm or not itm:GetBase() or itm:GetBase():GetItemName() ~= ent.IngredientTakes then return end

			local amt = itm:GetAmount()
			local mx = itm:GetMaxStack()
			local slots = 4

			local toStk = {}
			local its = {}

			for i=1, 4 do
				its[i] = sIns[i]:GetItem()
			end

			for i=1, amt do -- THIS SUCKS
				local min, sel = math.huge, 0
				for s=1, slots do
					local cur = (its[s] and its[s]:GetAmount() or 0) + (toStk[s] or 0)
					if cur < min then
						min = cur
						sel = s
					end
				end

				if min >= mx then break end

				local cItm = its[sel]
				local can

				if not cItm then
					toStk[sel] = (toStk[sel] or 0) + 1
					continue
				end

				can = cItm:CanStack(itm, 1)
				if not can then return end -- if we can't stack into min then we cant stack into any; its just that simple,,,

				toStk[sel] = (toStk[sel] or 0) + 1
			end

			for i=1, 4 do
				if not toStk[i] then continue end

				if not its[i] then
					inv:GetInventoryPanel():SplitItem(sIns[i], self, itm,
						toStk[i])
				else
					inv:GetInventoryPanel():GetInventory():RequestStack(itm, its[i], toStk[i])
				end
			end
		end)
	end

	local resCanv = vgui.Create("InvisPanel", canv)
	resCanv:SetPos(invIn:GetWide(), invIn.Y)
	resCanv:SetSize(canv:GetWide() - resCanv.X, canv:GetTall() - resCanv.Y)

	local txt = "Put 4 coca leaves in the slots to the left."
	local wrap = string.WrapCache()

	local font = "EX24"
	local col = Colors.DarkerWhite:Copy()

	function resCanv:Paint(w, h)
		local a = self._a or 255
		local tx, tw = wrap:Wrap(txt, w * 0.66, font)
		for s, l in eachNewline(tx) do
			draw.SimpleText(s, font, w / 2, 4 + l * 20, col:IAlpha(a), 1)
		end
	end

	local show = false

	for k,v in pairs(sIns) do
		if not v:GetItem() or not v:GetItem():GetTypeID() then continue end
		show = true
		break
	end

	resCanv._a = show and 0 or 255

	local mups = {}

	local dontRecalc = function(self, buf, h)
		self:SetTall(h + 1)
		return true
	end

	local ints
	local first = not show

	function resCanv:Think()
		local its = {}
		for k,v in pairs(sIns) do
			if not v:GetItem() or not v:GetItem():GetTypeID() then continue end
			its[#its + 1] = v:GetItem()
		end

		resCanv:To("_a", table.IsEmpty(its) and 255 or 0, 0.2, first and 0 or 0.15, 0.3)

		local cints = ent:GetResult(its, true)
		ints = cints

		for k,v in pairs(mups) do
			if not ints[k] then
				v:SizeTo(v:GetWide(), 0, 0.2, 0, 0.3)
				v:PopOut()
				mups[k] = nil
			else
				v:Upd()
			end
		end

		for k,v in pairs(ints) do
			if mups[k] then continue end

			local mup = vgui.Create("MarkupText", resCanv)
			mup:Dock(TOP)
			mup:DockMargin(12, 0, 12, 0)
			if not show then
				mup:PopIn(nil, first and 0.15 or 0)
			end
			mups[k] = mup

			local dat = Agriculture.CocaineTypes[k]
			-- name piece
			local dpc
			local pc = mup:AddPiece()
				pc:SetAlignment(0)
				pc:SetFont("BSSB22")
				pc:AddText(([["%s": ]]):format(dat.Result, v * 100))
				local perc = pc:AddText(([[%.1f%%]]):format(v * 100))
				pc:On("RecaclulateHeight", dontRecalc)
				pc:SetColor(dat.TextColor or dat.Color)

			if dat.Description or dat.Markup then
				dpc = mup:AddPiece()
					dpc:SetAlignment(0)
					dpc:SetFont("BS18")

					dpc:On("RecaclulateHeight", dontRecalc)
					dpc:DockMargin(16, -2, 0, 0)
					dpc:SetColor(Colors.LighterGray)

					if dat.Markup then
						dat.Markup(mup, dpc, v)
					else
						dpc:AddText(dat.Description)
					end

					function dpc:UpdateTyp()
						if dat.UpdateMarkup then
							dat.UpdateMarkup(mup, self, v)
						end
					end

					dpc:UpdateTyp()
			end

			mup.perc = v
			function mup:Upd()
				self:To("perc", ints[k], 0.6, 0, 0.3)

				if self.perc ~= v then
					v = self.perc
					perc.text = ([[%.1f%%]]):format(v * 100)
					pc:Recalculate()
					if dpc then dpc:UpdateTyp() end
				end
			end
		end

		first = table.IsEmpty(its)
	end

	resCanv:Think()
	show = false
end

function ENT:Think()
	
end

function ENT:Used()
	local scale, scaleW = Scaler(1600, 900, true)
	local menu = vgui.Create("FFrame")

	local inv = Inventory.Panels.CreateInventory(
		Inventory.GetTemporaryInventory(LocalPlayer()),
		nil, {
			SlotSize = scaleW(72)
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
	menu:CacheShadow(2, 3, 4)
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