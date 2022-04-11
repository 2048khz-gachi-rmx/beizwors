
local bw = BaseWars.Bases
local bnd = Bind("areamark_baseselect")
local TOOL = BaseWars.Bases.MarkTool


--[[
	https://i.imgur.com/GsHXv4T.png
	https://i.imgur.com/GsHXv4T.png
	https://i.imgur.com/GsHXv4T.png
	https://i.imgur.com/GsHXv4T.png
	https://i.imgur.com/GsHXv4T.png
	https://i.imgur.com/GsHXv4T.png
	https://i.imgur.com/GsHXv4T.png
]]


function TOOL:OpenBaseGUI(base)
	if IsValid(bw.BaseGUI) then
		bw.BaseGUI:Remove()
	end

	local tool = self
	local pnl = self:CreateTemplateGUI()

	local scale = pnl:GetWide() / 544

	pnl.NameEntry:SetValue(base:GetName())

	local zCanvas = vgui.Create("InvisPanel", pnl)
	pnl:InvalidateLayout(true)
	--zCanvas:Debug()
	zCanvas:SetPos(pnl.NameEntry.X, pnl.NameEntry.Y + pnl.NameEntry:GetTall() + 16)
	zCanvas:SetSize(pnl:GetWide() - pnl.NameEntry.X * 2, pnl:GetTall() - zCanvas.Y - 8 - 32)

	local zscr = vgui.Create("FScrollPanel", zCanvas)
	zscr:Dock(LEFT)
	zscr:SetWide(pnl:GetWide() * 0.6)
	zscr:InvalidateLayout(true)

	local zp = vgui.Create("FIconLayout", zscr)
	zp.IncompleteCenter = true
	zp.MarginX = 8
	zp.PaddingX = 16

	--zp:Dock(FILL) -- docking is cringe with resizing
	zp:SetSize(zscr:GetSize())

	local selectedZone
	local font = "OS20"

	surface.SetFont(font)
	local dotw = surface.GetTextSize("...")

	local all_zones = {}

	local function makePainted(z)
		z:On("ShouldPaint", zCanvas, TrueFunc)
		z:UpdatePainted()
	end

	local function addZone(z, new)


		local zb = vgui.Create("FButton", zscr)
		all_zones[#all_zones + 1] = zb

		zb:SetSize(128, 36)
		zb.Font = font



		function zb:SetZName(n)
			local fits = string.MaxFits(n, self:GetWide() - 4, self.Font)
			if fits ~= n then
				fits = string.MaxFits(n, self:GetWide() - 8 - dotw, self.Font) .. "..."
			end

			self.Label = fits
			self._ActualLabel = n
		end

		zb:SetZName(z:GetName())
		zb.Zone = z


		local ms, mx = z:GetBounds()

		zb.ZoneCopy = {	-- only stores data to send to the server, not any methods or anything like that
			Name = z:GetName(),
			BaseID = base:GetID(),
			Mins = ms,
			Maxs = mx,
		}

		zb.New = new

		zp:Add(zb)

		zb.Border = {
			w = new and 2 or 0,
			h = new and 2 or 0
		}

		zb.Border.col = new and Colors.Greenish or Colors.Golden
		zb.Unsaved = {}

		local selcol = Colors.Sky:Copy():ModHSV(0, 0, -0.1)

		function zb:Select(b)
			if b then
				self:SetColor(selcol)
			else
				self:SetColor(Colors.Button)
			end
		end

		function zb:DoClick()
			if selectedZone then
				selectedZone:Select(false)
				zCanvas:Emit("DeselectZone", selectedZone)
			else
				zCanvas:Emit("FirstSelect", self)
			end

			if selectedZone == self then
				selectedZone = nil
				zCanvas:Emit("FullDeselect", self)
				return
			end

			zCanvas:Emit("SelectZone", self, selectedZone)

			selectedZone = self
			self:Select(true)
		end

		local white = zb.LabelColor:Copy()
		local change = Colors.Warning:Copy()

		function zb:UpdateLabelColor()
			if self._ActualLabel ~= self.Zone:GetName() then
				self:LerpColor(self.LabelColor, change, 0.3, 0, 0.3)
				self.Unsaved["Name"] = true
			else
				self:LerpColor(self.LabelColor, white, 0.3, 0, 0.3)
				self.Unsaved["Name"] = nil
			end
		end

		function zb:Think()
			if next(self.Unsaved) or self.New then
				self:MemberLerp(self.Border, "w", 3, 0.2, 0, 0.2)
				self:MemberLerp(self.Border, "h", 3, 0.2, 0, 0.2)
			else
				self:MemberLerp(self.Border, "w", 0, 0.2, 0, 0.2)
				self:MemberLerp(self.Border, "h", 0, 0.2, 0, 0.2)
			end

			self:UpdateLabelColor()
		end

		return zb
	end

	for k,v in ipairs(base:GetZones()) do
		addZone(v)
	end

	zCanvas:InvalidateLayout(true)

	local zoneTE_Y = 0
	local zoneTE_H = 32

	local zoneTE

	-- each button's settings
	local btnHeight = 36 * scale
	local amtButtons = 2
	local btnPad = 6

	-- will be used to center all icons in a row
	local buttonsHeight = btnHeight * amtButtons + btnPad * (amtButtons - 1)

	local center = (zCanvas:GetTall() - zoneTE_Y - zoneTE_H) / 2 + zoneTE_Y + zoneTE_H

	local addBtn, yeetZone
	local edit, save

	addBtn = vgui.Create("FButton", zCanvas)
		addBtn.X = zscr.X + zscr:GetWide() + 8
		addBtn:SetSize(btnHeight, btnHeight)
		addBtn.Y = center - buttonsHeight / 2
		addBtn:SetColor(Colors.Greenish)
		addBtn:SetIcon(Icons.Plus:Copy():SetSize(btnHeight - 12, btnHeight - 12))

	function addBtn:DoClick()
		local fake = bw.Zone(-1)
		fake:SetName("Zone #" .. #all_zones + 1)
		addZone(fake, true)
	end

	yeetZone = vgui.Create("FButton", zCanvas)
		yeetZone.X = zscr.X + zscr:GetWide() + 8
		yeetZone:SetSize(btnHeight, btnHeight)
		yeetZone.Y = center - buttonsHeight / 2 + btnHeight + btnPad
		yeetZone:SetColor(Colors.Reddish)
		yeetZone:SetDisabled(true)
		yeetZone:SetIcon(Icons.TrashCan:Copy():SetSize(btnHeight - 12, btnHeight - 12))

	function yeetZone:DoClick()
		local z, zb = selectedZone.Zone, selectedZone

		if z:GetID() < 0 then
			self:SetDisabled(true)
			zb:DoClick()
			zb:Remove()
			z:Remove()
			return
		end

		local pr = bw.RequestZoneYeet(z:GetID())

		pr:Then(function()
			if selectedZone == zb then
				zb:DoClick()
			end

			z:Remove()
			zb:Remove()
		end, function()
			local why = net.ReadCompressedString()
			pnl:AddError(why)
		end)
	end

	edit = vgui.Create("FButton", zCanvas)
		edit.X = addBtn.X + addBtn:GetWide() + 8
		edit.Y = addBtn.Y
		edit:SetColor(Colors.Golden:Copy():ModHSV(0, 0, -0.1))
		edit:SetSize(addBtn:GetSize())
		edit:SetIcon(Icons.Edit:Copy():SetSize(btnHeight - 12, btnHeight - 12))
		edit:SetDisabled(true)

	function edit:DoClick()
		tool:SetZone(selectedZone.Zone)

		local pnl = bw.BaseGUI

		local x, y = pnl:GetPos()

		bw.BaseGUI:AlphaTo(125, 0.2, 0)
		bw.BaseGUI:MoveTo(bw.BaseGUI.X, ScrH() - bw.BaseGUI:GetTall() * 0.2, 0.3, 0, 0.3)
		bw.BaseGUI:SetMouseInputEnabled(false)
		bw.BaseGUI:SetKeyboardInputEnabled(false)
		bw.BaseGUI:SetDraggable(false)

		local sel = selectedZone

		tool:On("ZoneConfirmed", "RepopBaseGUI", function(self, zone, mins, maxs)
			if not IsValid(bw.BaseGUI) then return end

			local zc = sel.ZoneCopy

			zc.Mins = mins
			zc.Maxs = maxs
			zc.MinMaxsChanged = true

			bw.BaseGUI:MoveTo(bw.BaseGUI.X, y, 0.3, 0, 0.3)
			bw.BaseGUI:AlphaTo(255, 0.2, 0)
			bw.BaseGUI:SetMouseInputEnabled(true)
			bw.BaseGUI:SetKeyboardInputEnabled(true)
			bw.BaseGUI:SetDraggable(true)

			if sel:IsValid() then sel.Unsaved["Bounds"] = true end
		end)

		tool:On("ZoneCancelled", "RepopBaseGUI", function()
			if not IsValid(bw.BaseGUI) then return end

			bw.BaseGUI:MoveTo(bw.BaseGUI.X, y, 0.3, 0, 0.3)
			bw.BaseGUI:AlphaTo(255, 0.2, 0)
			bw.BaseGUI:SetMouseInputEnabled(true)
			bw.BaseGUI:SetKeyboardInputEnabled(true)
			bw.BaseGUI:SetDraggable(true)
		end)
	end

	save = vgui.Create("FButton", zCanvas)
		save.X = yeetZone.X + yeetZone:GetWide() + 8
		save.Y = yeetZone.Y
		local savecol = Colors.Sky:Copy():ModHSV(0, 0, -0.1)
		save:SetColor(savecol, true)
		save:SetSize(yeetZone:GetSize())
		save:SetIcon(Icons.Save:Copy():SetSize(btnHeight - 12, btnHeight - 12))
		save:SetDisabled(true)

	function save:DoClick()
		local zname = zoneTE:GetValue()

		local dat = selectedZone.ZoneCopy
		local zone = selectedZone.Zone
		local sel = selectedZone

		local mins, maxs = dat.Mins, dat.Maxs
		OrderVectors(mins, maxs)

		if not sel.New then

			local pr = bw.RequestZoneEdit(zone:GetID(), zname, mins, maxs)

			pr:Then(function()
				zone:SetName(zname)
				zone:SetBounds(mins, maxs)
				sel:SetZName(zname)

				if sel:IsValid() then
					sel.Unsaved = {}
					sel.ZoneCopy.MinMaxsChanged = false
				end
			end, function()
				local why = net.ReadCompressedString()
				pnl:AddError(why)
			end)
		else
			local pr = bw.RequestZoneCreation(zname, base:GetID(), mins, maxs)

			pr:Then(function()
				local zID = net.ReadUInt(bw.NW.SZ.zone)

				zone:SetID(zID)
				zone:SetName(zname)
				zone:SetBounds(mins, maxs)
				zone:Validate()

				base:AddZone(zone)

				makePainted(zone)
				if sel:IsValid() then sel.Unsaved = {} sel.New = false end
			end, function()
				local why = net.ReadCompressedString()
				pnl:AddError(why)
			end)
		end
	end

	local function disable(b, why)
		save:SetDisabled(b)
		save.Why = why
	end

	local oh, os, ov = savecol:ToHSV()

	function save:Think()

		if self:GetDisabled() and self:IsHovered() and self.Why then
			local cl, new = self:AddCloud("err", self.Why)
			if new then
				cl:SetFont("OS22")
				cl:SetRelPos(save:GetWide() / 2, save:GetTall())
				cl.ToY = 8
				cl.YAlign = 0
				cl:SetTextColor(Colors.DarkerRed:Copy():ModHSV(0, -0.15, -0.1))
			end
		else
			self:RemoveCloud("err")
		end

		if not self:GetDisabled() then
			savecol:SetHSV(oh, os, ov - 0.1 + math.sin(SysTime() * 8) * 0.1)
			self:SetColor(savecol, true)
		end

		local dis = false



		if not zoneTE or not selectedZone then disable(true) return end

		local cur = selectedZone.Zone
		local mins, maxs = cur:GetBounds()
		local copy = selectedZone.ZoneCopy
		if not (copy.Mins and copy.Maxs) then disable(true, "No bounds selected") return end

		local v1, v2 = zoneTE:GetValue(), cur:GetName()

		if v1 ~= v2 then disable(false) return end
		if copy.MinMaxsChanged then
			disable(false)
			return
		end

		disable(true, "no changes...")
	end

	local function removeZoneTE()
		zoneTE:SetPos(zoneTE:GetPos())
		zoneTE:Dock(NODOCK)
		zoneTE:MoveBy(0, 24, 0.2, 0, 2)
		zoneTE:SetZPos(-255)
		zoneTE:AlphaTo(0, 0.2, 0, 1.5, function(_, self) self:Remove() end)

		zoneTE = nil
	end

	local limgood = Color(130, 130, 130)
	local limbad = Colors.Reddish:Copy()
	local curlim = limgood:Copy()

	local function createZoneTE(z, btn)
		if IsValid(zoneTE) then removeZoneTE() end

		zoneTE = vgui.Create("FTextEntry", zCanvas)
		zoneTE:Dock(TOP)
		zoneTE:DockMargin(8, zoneTE_Y, 0, 0)
		zoneTE:SetTall(zoneTE_H)
		zoneTE:SetPlaceholderText("Zone Name")
		zoneTE:SetValue(btn.ZoneCopy.Name)

		zoneTE:PopIn()
		zoneTE:InvalidateParent(true)
		zoneTE:Dock(NODOCK)
		zoneTE:SetMaxChars(bw.MaxZoneNameLength)

		zoneTE.Y = zoneTE.Y - zoneTE:GetTall()
		zoneTE:MoveBy(0, zoneTE:GetTall(), 0.2, 0.1, 0.3)

		zoneTE:On("PostPaint", function(self, w, h)
			local cur = #self:GetValue()
			local can = bw.MaxZoneNameLength
			-- long zone names are not advised
			self:LerpColor(curlim, cur >= can / 2 and limbad or limgood, 0.2, 0, 0.3)
			DisableClipping(true)
				draw.SimpleText(cur .. "/" .. can, "OS20", w, h, curlim, 2, 5)
			DisableClipping(false)
		end)

		function zoneTE:OnChange(t)
			btn:SetZName(self:GetValue())
			btn.ZoneCopy.Name = self:GetValue()

			btn:UpdateLabelColor()
		end
	end

	function zCanvas:CreateZoneControls(zb)
		yeetZone:SetDisabled(false)
		save:SetDisabled(false)
		edit:SetDisabled(false)
		createZoneTE(zb.Zone, zb)


	end

	function zCanvas:RemoveZoneControls(zb)
		yeetZone:SetDisabled(true)
		save:SetDisabled(true)
		edit:SetDisabled(true)
		removeZoneTE()
	end

	function zCanvas:SwitchZone(to, from)
		local zto = to.Zone
		local zfrom = from and from.Zone

		createZoneTE(zto, to)

		GlobalAnimatable:LerpColor(zto:GetColor(), zto.PreviewColor, 0.3, 0, 0.3)
	end

	function zCanvas:DeselectZone(btn)
		GlobalAnimatable:LerpColor(btn.Zone:GetColor(), btn.Zone:GetDefaultColor(), 0.2, 0, 0.3)
	end

	zCanvas:On("FirstSelect", "A", zCanvas.CreateZoneControls)
	zCanvas:On("FullDeselect", "AAA", zCanvas.RemoveZoneControls)
	zCanvas:On("SelectZone", "AAAAA", zCanvas.SwitchZone)
	zCanvas:On("DeselectZone", "AAAAA", zCanvas.DeselectZone)

	for k,v in pairs(all_zones) do
		makePainted(v.Zone)
	end

	function zCanvas:OnRemove()
		for k,v in pairs(all_zones) do
			if not v:IsValid() then continue end
			GlobalAnimatable:LerpColor(v.Zone:GetColor(), v.Zone:GetDefaultColor(), 0.3, 0, 0.3)
		end
	end

	zscr:InvalidateParent(true)

	--[[-------------------------------------------------------------------------
		Bottom buttons (delete base/save base/put base core)
	---------------------------------------------------------------------------]]
	local btns = 3
	local pad = 8
	local btnW = (pnl:GetWide() - zCanvas.X * 2 - (btns - 1) * pad) / btns

	local yeetBase = vgui.Create("FButton", pnl)
	yeetBase.X = zCanvas.X
	yeetBase.Y = pnl:GetTall() - 32 - 4
	yeetBase:SetSize(btnW, 32)
	yeetBase.Label = "YEET BASE"
	yeetBase:SetColor(Colors.Red:Copy():ModHSV(0, 0, -0.4))
	yeetBase.MxScaleDown = 1
	yeetBase:SetIcon(Icons.TrashCan:Copy():SetSize(24, 24))
	yeetBase.DelFrac = 0

	function yeetBase:Yeet()
		if self.Yeeting then return end

		self.Yeeting = true

		local pr = bw.RequestBaseYeet(base:GetID())
		pnl:AlphaTo(120, 0.3, 0, 0.3)
		pnl:MoveBy(0, -48, 0.6, 0, 0.2)
		local was = pnl.Y
		pnl:SetMouseInputEnabled(false)
		pnl:SetKeyBoardInputEnabled(false)

		pr:Then(function()
			pnl:PopOut()
			base:Remove()
		end, function()
			local why = net.ReadCompressedString()
			pnl:AddError(why)

			pnl:Stop()
			pnl:AlphaTo(255, 0.2, 0, 0.3)
			pnl:MoveTo(pnl.X, was, 0.3, 0, 0.3)
			pnl:SetMouseInputEnabled(true)
			pnl:SetKeyBoardInputEnabled(true)

			self.To0 = true
			self.Yeeting = false
		end)
	end

	function yeetBase:Think()
		if self:IsDown() and not self.Yeeting and not self.To0 then
			self:To("DelFrac", 1, 1.5, 0, 0.3)
		elseif not self.Yeeting or self.To0 then
			self:To("DelFrac", 0, 0.4, 0.7, 0.3)
		end

		if self.DelFrac == 0 and self.To0 then self.To0 = nil end
		if self.DelFrac == 1 and not self.Yeeting and not self.To0 then
			self:Yeet()
		end
	end

	local red = Colors.Red:Copy():ModHSV(0, -0.1, -0.1)
	function yeetBase:PreLabelPaint(w, h)
		local x, y = self:LocalToScreen(0, 0)
		render.SetScissorRect(x, y, x + w * self.DelFrac, y + h, true)
			draw.RoundedBox(8, 0, 0, w, h, red)
		render.SetScissorRect(0, 0, 0, 0, false)
	end


	local saveBase = vgui.Create("FButton", pnl)
	saveBase.X = yeetBase.X + yeetBase:GetWide() + 8
	saveBase.Y = pnl:GetTall() - 32 - 4
	saveBase:SetSize(btnW, 32)
	saveBase.Label = "Edit name"
	saveBase:SetColor(Colors.Greenish)
	saveBase:SetIcon(Icons.Edit:Copy():SetSize(24, 24))
	saveBase:SetDisabled(true)

	local ne = pnl.NameEntry

	function ne:OnChange()

		saveBase:SetDisabled(
			self:GetValue() == base:GetName()
			or #self:GetValue() < bw.MinBaseNameLength
			or #self:GetValue() > bw.MaxBaseNameLength
		)

	end

	function saveBase:DoClick()
		local name = ne:GetValue()
		local pr = bw.RequestBaseEdit(base:GetID(), name)
		pr:Then(function()
			base:SetName(name)
			if IsValid(ne) then ne:OnChange() end
		end, function()
			local why = net.ReadCompressedString()
			pnl:AddError(why)
		end)
	end

	local putCore = vgui.Create("FButton", pnl)
		putCore.X = saveBase.X + saveBase:GetWide() + 8
		putCore.Y = saveBase.Y
		local putCoreCol = Color(0, 205, 123)
		putCore:SetSize(btnW, 32)
		putCore.Label = "Edit base core"
		putCore:SetColor(putCoreCol)
		putCore:SetIcon(Icons.Plus:Copy():SetSize(20, 20))
		--putCore:SetDisabled(true)

	function putCore:DoClick()
		local hasCore = self:HasCore()

		if hasCore then
			local pr = bw.RequestBaseCoreSave(base:GetID(), base.NewCoreIndex)
			pr:Then(function()
				base.NewCoreIndex = nil
			end, function()
				local why = net.ReadCompressedString()
				pnl:AddError(why)
			end)
		else
			local pr = bw.RequestBaseCoreCreation(base:GetID())
			pr:Then(function()
				local eid = net.ReadUInt(16)
				base.NewCoreIndex = eid
			end, function()
				local why = net.ReadCompressedString()
				pnl:AddError(why)
			end)
		end
	end

	function putCore:HasCore()
		if not base.NewCoreIndex or not IsValid(Entity(base.NewCoreIndex)) then return false end
		return true
	end

	function putCore:Think()
		local hasCore = self:HasCore()
		putCore.Label = (hasCore and "Save" or "Make") .. " base core"
	end

	function putCore:OnHover()
		local hasCore = self:HasCore()
		if hasCore then
			local cl, new = self:AddCloud("warn", "Remove the core prop to put down a new one, if you want.")

			if new then
				cl:SetFont("OS22")
				cl:SetTextColor(Colors.Reddish)
				cl:SetRelPos(self:GetWide() / 2, self:GetTall())
				cl.ToY = 12
				cl.YAlign = 0
				cl.MaxW = 500
			end
		end
	end

	function putCore:OnUnhover()
		self:RemoveCloud("warn")
	end

	pnl._TriedToExit = 0
	function pnl:OnClose()
		if SysTime() - self._TriedToExit < 3 then
			return
		end

		self._TriedToExit = SysTime()

		local unsaved = false
		for k,v in pairs(all_zones) do
			if not v:IsValid() then continue end

			if v.New and v.ZoneCopy.MinMaxsChanged then
				unsaved = true
				break
			end

			if v._ActualLabel ~= v.Zone:GetName() then
				unsaved = true
				break
			end
		end

		if unsaved then
			local cb = self.m_bCloseButton
			local cl, new = cb:AddCloud("warn", "Unsaved changes will be lost!")

			if new then
				cl:SetFont("OS22")
				cl:SetTextColor(Colors.Reddish)
				cl:SetRelPos(cb:GetWide() / 2, 0)
				cl.ToY = -12
				cl.MaxW = 500
			end

			self:Timer("aaa", 2.5, function()
				cb:RemoveCloud("warn")
			end)

			return false
		end
	end

end

function TOOL:OpenNewBaseGUI()
	if IsValid(bw.BaseGUI) then -- two base GUIs shouldn't be open
		bw.BaseGUI:Remove()
	end

	local tool = self
	local pnl = self:CreateTemplateGUI()

	local btn = vgui.Create("FButton", pnl)
	btn.Label = "-REPLACEME-"
	btn:Dock(BOTTOM)

	local w, h = pnl:GetSize()

	btn:SetTall(h * 0.15)
	btn:DockMargin(w * 0.25, h * 0.1, w * 0.25, h * 0.03)
	btn:SetDisabled(true)
	btn:SetColor(Colors.Greenish, true)

	function btn:Think()
		local n = pnl.NameEntry:GetValue()
		if self.AwaitingReply then
			self:SetDisabled(true)
		else
			self:SetDisabled( not (#n < bw.MaxBaseNameLength and #n > bw.MinBaseNameLength) )
		end
	end

	btn:SetIcon(Icons.Plus)
	btn.Label = "Create new base"

	function btn:DoClick()
		local name = pnl.NameEntry:GetValue()
		local pr = bw.RequestBaseCreation(name)
		self.AwaitingReply = true
		pnl:AlphaTo(120, 0.3, 0, 0.3)

		pr:Then(function()
			self.AwaitingReply = false
			pnl:PopOut()
			local id = net.ReadUInt(bw.NW.SZ.base)

			if bw.GetBase(id) then
				tool:OpenBaseGUI(bw.GetBase(id))
			else
				bw:On("ReadBases", "WaitFor" .. id, function(_, new)
					if bw.GetBase(id) then
						tool:OpenBaseGUI(bw.GetBase(id))
						bw:RemoveListener("ReadBases", "WaitFor" .. id)
					end
				end)
			end

		end, function()
			self.AwaitingReply = false
			pnl:AlphaTo(255, 0.3, 0, 0.3)
			local why = net.ReadCompressedString()

			pnl:AddError(why)
		end)

	end
end

function TOOL:CreateTemplateGUI()
	local ff = vgui.Create("FFrame")
	bw.BaseGUI = ff

	local ratio = 5 / 3
	local min = math.min(ScrW() * 0.4 / ratio, ScrH() * 0.6)

	ff:SetSize(min * ratio, min)
	local w, h = min * ratio, min

	ff:Center()
	local x = ff.X
	ff.X = (ff.X + self.BaseSelection.X) / 2
	ff:To("X", x, 0.6, 0, 0.1)
	ff:MakePopup()
	ff:PopIn()

	local te = vgui.Create("FTextEntry", ff)
	ff.NameEntry = te
	te:Dock(TOP)
	te:DockMargin(w * 0.05, h * 0.1, w * 0.05, 0)
	te:SetPlaceholderText("Base name")


	local lastErr
	local wrapErr

	local col = Colors.Error:Copy()
	local boxcol = Colors.Gray:Copy()

	local txH = 28

	function ff:AddError(err)
		self.Error = err

		self:Timer("deerr", math.max(1.25, err:CountWords() * 0.1), 1, function()
			self.Error = nil
		end)
	end

	local errFont = "OS24"

	function ff:PrePaint(w, h)
		self:To("ErrFrac", self.Error and 1 or 0, 0.3, 0, self.Error and 0.3 or 2.4)

		if not lastErr and not self.Error or self.ErrFrac == 0 then return end

		if self.Error and lastErr ~= self.Error then
			wrapErr = string.WordWrap2(self.Error, w * 0.8, errFont)
		end

		lastErr = self.Error or lastErr

		col.a = 255 * self.ErrFrac
		boxcol.a = 255 * self.ErrFrac

		local textH = (amtNewlines(wrapErr) + 1) * txH
		local rev = 1 - self.ErrFrac
		local cy = h - textH * rev + 8 * self.ErrFrac

		local longest = 0
		surface.SetFont(errFont)
		for s, line in eachNewline(wrapErr) do
			longest = math.max(longest, (surface.GetTextSize(s)))
		end

		DisableClipping(true)
			draw.RoundedBox(8, w/2 - longest/2 - 4, cy - 4, longest + 8, textH + 8, boxcol)

			for s, line in eachNewline(wrapErr) do
				draw.SimpleText(s, errFont, w/2, cy, col, 1, 5)
				cy = cy + txH
			end
		DisableClipping(false)
	end

	return ff
end

TOOL:Finish()