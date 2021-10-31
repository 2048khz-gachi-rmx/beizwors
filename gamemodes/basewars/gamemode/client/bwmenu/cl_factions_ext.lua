local tab = {}
tab.Order = 100	-- always first
tab.IsDefault = true

tab.UsesFactions = true
tab.UsesFactionless = false

local fonts = BaseWars.Menu.Fonts
local createFactionActions --bwergh

BaseWars.Menu.Tabs["Factions"] = tab

--[[------------------------------]]
--	   	   	   Helpers
--[[------------------------------]]

local function removePanel(pnl, hide)
	if not IsValid(pnl.__selMove) then
		pnl.__selMove = pnl:MoveBy(16, 0, 0.2, 0, 1.4)
	end

	if hide then
		pnl:PopOutHide()
	else
		pnl:PopOut()
	end

end


local anim = Animatable("BWMenu")

-- dim the provided color
local dim = function(col, amt, sat, safe)
	local ch, cs, cv = col:ToHSV()
	cv = cv * (amt or 0.8)

	-- color is very close to Color(50, 50, 50) which is the scrollpanel color
	if safe and cs < 0.15 and (cv > 0.15 and cv < 0.25) then
		-- if it's sufficiently bright, make it gray
		-- otherwise, make it pitch black
		cv = (cv >= 0.2) and 0.35 or 0.05
	end

	draw.ColorModHSV(col, ch, cs * (sat or 0.9), cv)
end

-- return a dimmed copy of the color
local getDimmed = function(col, amt, sat, safe)
	col = col:Copy()
	dim(col, amt, sat)
	return col
end



--[[------------------------------]]
--	   	   Action Selection
--[[------------------------------]]

local function createActionCanvas(f, fac)
	local pnl = vgui.Create("FactionPanel", f)

	f.FactionFrame = pnl
	f:SetPanel(pnl)

	pnl:SetFaction(fac)

	return pnl
end


-- Your faction

local leavingProgressRed = Color(220, 100, 100)

local function createOwnFactionActions(f, fac, canv)
	if not canv then
		canv = createActionCanvas(f, fac)
	end

	local plyList = canv.MembersList


	local w, h = canv:GetSize()
	local leave = vgui.Create("FButton", canv.Main)
	canv.LeaveBtn = leave

	canv:AddElement("Exclusive", leave)

	leave:SetWide(w * 0.4)
	leave:SetTall(h * 0.08)

	leave:SetPos(w / 2 - leave:GetWide() / 2, plyList.FoldedY - leave:GetTall() - 8)

	leave.Color = Color(180, 60, 60)

	leave.HoldFrac = 0
	leave.LeaveTime = 0.8

	local x, y = leave:GetPos()
	local origX, origY = x, y

	local maxShake = 4

	plyList:On("Hovered", leave, function(_, is_hov, shiftby)
		if is_hov then
			leave:To("Y", origY - shiftby, 0.4, 0, 0.3)
			y = origY - shiftby
		else
			leave:To("Y", origY, 0.4, 0, 0.3)
			y = origY
		end
	end)

	function leave:Think()
		if self:IsDown() then
			self:To("HoldFrac", 1, self.LeaveTime, 0, 0.25)
		else
			self:To("HoldFrac", 0, self.LeaveTime / 2, 0.5, 0.2)
		end

		local shk = self.HoldFrac
		if shk > 0 and not self.NoShake then
			local sx, sy = math.random(shk * maxShake), math.random(shk * maxShake)

			sx = sx - maxShake / 2
			sy = sy - maxShake / 2

			self:SetPos(x + sx, y + sy)

			-- not == 1 because you can click it rapidly and easing won't make it reach 1
			-- do i care? Yes.
			if shk > 0.99 and not self.Wait0 then
				self:FullShake()
			elseif shk < 0.5 and self.Wait0 then
				self.Wait0 = nil
			end
		end
	end

	function leave:PostPaint(w, h)
		local sx, sy = self:LocalToScreen(0, 0)
		local fr = self.HoldFrac
		local scale = self:GetMatrixScale()

		local cOff = w * fr - w/2
		local barSX = sx + w * fr - cOff * (1 - scale)

		render.SetScissorRect(sx, sy, barSX, sy + h, true)
			draw.RoundedBox(self.RBRadius, 0, 0, w, h, leavingProgressRed)
		render.SetScissorRect(0, 0, 0, 0, false)

		draw.SimpleText("Leave Faction", self.Font, w/2, h/2, color_white, 1, 1)

	end

	function leave:Disappear()
		plyList:RemoveListeners("Hovered", leave)
		local an, new = self:To("Y", canv.Main:GetTall() + 8, 0.3, 0, 0.3)
		if new then
			an:Then(function()
				self:Hide()
			end)
		end
	end

	function leave:FullShake()
		if not fac then return end

		self.NoShake = true
		self.drawColor:Set(leavingProgressRed)

		local prom = Factions.RequestLeave()

		prom:Then(function()
			self:Disappear()

			createFactionActions(f, fac, canv)
			local pw, join = canv.PasswordEntry, canv.JoinBtn

			if IsValid(pw) then
				local pwY = pw.Y
				pw.Y = canv.Main:GetTall() + 4
				pw:To("Y", pwY, 0.3, 0.3, 0.2)
			end

			if IsValid(join) then
				local jnY = join.Y
				join.Y = canv.Main:GetTall() + 4
				join:To("Y", jnY, 0.3, pw and 0.4 or 0.3, 0.2)
			end
		end, function(_, err)
			chat.AddText(Colors.Error, "Couldn't leave faction!\n", tostring(err))
			if not IsValid(self) then return end
			self.NoShake = false
			self.Wait0 = true
			self.drawColor:Set(Color(180, 60, 60))
		end)
	end

end

local good = Color(50, 150, 50)
local bad = Colors.Button
local bad_red = Color(180, 80, 80)

local function canJoin(btn, ply, fac)
	local can, err = Factions.CanJoin(ply, fac)
	if not can then
		if btn:IsHovered() and not btn.Removing then
			local cl, new = btn:AddCloud("err")

			if cl and new then
				cl.Font = "OS20"
				cl.MaxW = 400
				cl.AlignLabel = 1

				cl:SetTextColor(bad_red)
				cl:SetRelPos(btn:GetWide() / 2)
				cl.ToY = -8

				cl:SetText(err)
			end
		else
			btn:RemoveCloud("err")
		end

	else
		btn:RemoveCloud("err")
	end

	return can
end

-- Someone's faction

-- (this is a predefined local)
function createFactionActions(f, fac, canv)
	local oldCanv = true
	if not canv then
		canv = createActionCanvas(f, fac)
		canv.Main.NoDrawBottomGradient = true
		oldCanv = false
	end

	local plyList = canv.MembersList

	if fac:HasPassword() then
		local te = vgui.Create("FTextEntry", canv.Main)
		canv:AddElement("Exclusive", te)
		if oldCanv then te:PopIn(nil, 0.1) end

		canv.PasswordEntry = te
		te:SetSize(canv.Main:GetWide() * 0.5, 32)
		te:SetPlaceholderText("Password...")
		te:SetPos(canv.Main:GetWide() / 2 - te:GetWide() / 2 - 18, canv.Main:GetTall() - 36)
		te:SetUpdateOnType(true)
		te.Shake = 0
		local teX = te.X
		local startShake = 0

		function te:Think()								-- 2.4 waves/s
			local x = math.sin((CurTime() - startShake) * 2.4 * 2*math.pi) * self.Shake * 12
			self.X = teX + x
		end

		function te:Disappear(delayed)
			canv.PasswordEntry = nil
			local where = te.Y + te:GetTall() + 12

			local an, new = self:To("Y", where, 0.2, delayed and 0.5 or 0, 2)
			te.Disappearing = true

			an:Then(function(s)
				self:Remove()
			end)

			return an
		end

		local join = vgui.Create("DButton", canv.Main)
		canv:AddElement("Exclusive", join)
		join:SetSize(32, 32)
		join:SetPos(te.X + 4 + te:GetWide(), te.Y)
		join.ArrX = 0
		join:SetText("")
		if oldCanv then join:PopIn(nil, 0.1) end

		canv.JoinBtn = join
		local y = te.Y

		plyList:On("Hovered", join, function(_, hov, amt)
			if join.Clicked then return end
			join:To("Y", y - (hov and amt or 0), 0.3, 0, 0.3)
			if not te.Disappearing then
				te:To("Y", y - (hov and amt or 0), 0.3, 0, 0.3)
			end
		end)

		local t = join:GetTable()

		local arrSize = join:GetWide() - 8

		local can = canJoin(join, LocalPlayer(), fac)

		local canCol = color_white
		local cantCol = Colors.LighterGray

		local col = can and canCol:Copy() or cantCol:Copy()

		function join:Paint(w, h)
			surface.SetDrawColor(col:Unpack())
			local x = t.ArrX

			surface.DrawMaterial("https://i.imgur.com/jFHSu7s.png", "arr_right.png", 4 + x, 4, arrSize, arrSize)

			if not self.Clicked then
				if self:IsHovered() then
					anim:MemberLerp(t, "ArrX", 4, 0.2, 0, 0.4)
				else
					anim:MemberLerp(t, "ArrX", 0, 0.2, 0, 0.4)
				end
			end

			local can = canJoin(self, LocalPlayer(), fac)

			if not can then
				self:LerpColor(col, cantCol, 0.4, 0, 0.3)
				self:SetDisabled(true)
			else
				self:LerpColor(col, canCol, 0.4, 0, 0.3)
				self:SetDisabled(false)
			end
		end

		function join:Disappear()
			plyList:RemoveListeners("Hovered", self)

			canv.JoinBtn = nil
			self:PopOut(0.3)
			self:To("Y", canv.Main:GetTall() + 4, 0.3, 0, 3):Then(function()
				self:Hide()
			end)

			self.Removing = true
		end

		function join:DoClick()

			local arrResume
			local arrResetNow = false -- if true, arrow animation will reset immediately
			local arrRemove

			Factions.RequestJoin(fac, te:GetValue()):Then(function()
				arrRemove = true

				te:LerpColor(te.TextColor, Color(30, 170, 30), 0.1, 0, 0.2)
				te:LerpColor(te.PHTextColor, Color(60, 160, 60), 0.1, 0, 0.2)
				te:LerpColor(te.HTextColor, Color(70, 160, 70), 0.1, 0, 0.2)
				te:LerpColor(te.BGColor, Color(40, 75, 40), 0.1, 0, 0.2)

				te:Disappear(true):Then(function()
					createOwnFactionActions(f, fac, canv)

					local prev = canv.LeaveBtn.Y
					canv.LeaveBtn:Show()
					canv.LeaveBtn.Y = plyList.FoldedY + 8
					canv.LeaveBtn:To("Y", prev, 0.3, 0, 0.3)
				end)

				join:SetInput(false)
				self:Disappear()
			end, function(_, err)

				local bad_pw = err == Factions.Errors.BadPassword

				if bad_pw then
					arrResetNow = true

					startShake = CurTime()

					local bad = Colors.DarkerRed
					local regular = color_white
						te:LerpColor(te.TextColor, bad, 0.1, 0, 0.2):Then(function()
							te:LerpColor(te.TextColor, regular, 0.3, 0.5, 0.3)
						end)

					local bad = Color(165, 10, 10)
					local regular = color_white
						te:LerpColor(te.PHTextColor, bad, 0.1, 0, 0.2):Then(function()
							te:LerpColor(te.PHTextColor, regular, 0.3, 0.5, 0.3)
						end)

					local bad = Color(75, 40, 40)
					local regular = Color(40, 40, 40)
						te:LerpColor(te.BGColor, bad, 0.1, 0, 0.2):Then(function()
							te:LerpColor(te.BGColor, regular, 0.3, 0.5, 0.3)
						end)

					local bad = Color(170, 80, 80)
					local regular = Colors.LightGray
						te:LerpColor(te.HTextColor, bad, 0.1, 0, 0.2):Then(function()
							te:LerpColor(te.HTextColor, regular, 0.3, 0.5, 0.3)
						end)

					te:To("Shake", 1, 0.2, 0, 0.3):Then(function()
						te:To("Shake", 0, 0.3, 0.3, 1):Then(coroutine.Resumer())
						coroutine.yield()
						arrResume()
						startShake = 0
					end)
				end

			end)

			local dur = math.max(LocalPlayer():Ping() / 1000, 0.1)

			arrAnim = anim:MemberLerp(t, "ArrX", join:GetWide() - 4, dur, 0, 3)

			if arrAnim then
				arrAnim:Then(function()
					if not arrResetNow then
						arrResume = coroutine.Resumer()
						coroutine.yield()
					end

					if arrRemove then join:Remove() return end
					t.ArrX = -arrSize - 4
					anim:MemberLerp(t, "ArrX", 0, 0.25, 0, 0.3)

					self.Clicked = false
				end)
			end

			self.Clicked = true
		end
	else
		local join = vgui.Create("FButton", canv.Main)
		canv:AddElement("Exclusive", join)
		join:SetSize(128, 36)
		join:SetPos(canv.Main:GetWide() / 2 - join:GetWide() / 2, plyList.FoldedY - join:GetTall() - 8)
		join:SetLabel("Join")
		join:SetColor(good)
		canv.JoinBtn = join

		if oldCanv then join:PopIn(nil, 0.1) end

		local origY = join.Y

		plyList:On("Hovered", join, function(_, is_hov, shiftby)
			if is_hov then
				join:To("Y", origY - shiftby, 0.4, 0, 0.3)
			else
				join:To("Y", origY, 0.4, 0, 0.3)
			end
		end)


		local lp = LocalPlayer()

		function join:Think()
			local can = canJoin(self, lp, fac)
			self:SetEnabled(can)
		end

		function join:Disappear()
			plyList:RemoveListeners("Hovered", self)

			canv.JoinBtn = nil
			local anim, new = self:To("Y", canv.Main:GetTall() + 4, 0.3, 0, 0.3)
			if new then
				anim:Then(function()
					self:Hide()
				end)
			end

			self.Removing = true
		end

		local where = join.Y + 52 + 4

		function join:DoClick()

			Factions.RequestJoin(fac):Then(function()
				self:Disappear()
				createOwnFactionActions(f, fac, canv)
				local prev = canv.LeaveBtn.Y
				canv.LeaveBtn:Show()
				canv.LeaveBtn.Y = plyList.FoldedY + 8
				canv.LeaveBtn:To("Y", prev, 0.3, 0.2, 0.3)
			end, function(_, err)
				chat.AddText(Color(180, 90, 90), "Something went wrong!\n", tostring(err))
			end)

		end
	end
end

-- Creating a new faction

local oldNewFac

local function createNewFaction(f)
	if IsValid(oldNewFac) then
		f:SetPanel(oldNewFac)
		return
	end

	local pnl = vgui.Create("Panel", f, "New Faction canvas")
	f:SetPanel(pnl)
	f:AddElement("Exclusive", pnl)

	function pnl:Disappear()
		removePanel(self, true)
	end

	oldNewFac = pnl
	pnl.IsNewFaction = true

	local name
	local pw
	local col

	local err

	function pnl:ValidateData()
		local nm = name:GetValue()
		local pw = pw:GetValue()

		local can, why = Factions.CanCreate(nm, pw, col:GetColor(), LocalPlayer())

		if not can then
			err = why
			return
		end

		-- we're all good
		err = nil
	end

	local errDT = DeltaText()
	errDT.AlignX = 1

	local txCol = Color(220, 65, 65)

	local fragNum

	local pieces = {}

	local bgCol = Colors.DarkGray:Copy()
	local gradCol = color_black:Copy()

	function pnl:Paint(w, h)
		-- bg
		surface.SetDrawColor(bgCol)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(gradCol)
		self:DrawGradientBorder(w, h, 3, 3)

		-- drawing faction name
		local tx = name:GetValue()
		surface.SetFont(fonts.BoldMedium)
		local newW, tH = surface.GetTextSize(tx)
		self:To("TextW", newW, 0.2, 0, 0.2)
		local tw = self.TextW or 0

		surface.SetTextPos(w/2 - tw/2, h * 0.1 - tH / 2)
		local txcol = col:GetColor():Copy()
		local th, ts, tv = txcol:ToHSV()
		if tv < 0.1 then
			ts = ts * tv / 0.1
		end
		draw.ColorModHSV(txcol, th, ts, math.Clamp(tv, 0.2, 0.8))

		surface.SetTextColor(txcol.r, txcol.g, txcol.b, txcol.a)
		surface.DrawText(tx)

		-- drawing errors

		self:ValidateData()

		local err = err and tostring(err) 

		if err then
			if pieces[err] then
				-- we had that error created; just activate it
				errDT:ActivateElement(pieces[err])
			else
				-- we never had an element for this error: create one
				local sizes = {12, 14, 16, 18, 20, 22, 24, 28, 32, 36, 48, 64, 72, 96, 128}
				local picked = "OSB18"

				for i=1, #sizes do
					surface.SetFont("OSB" .. sizes[i])
					local tw = surface.GetTextSize(err)

					if tw < w * 0.9 then
						picked = "OSB" .. sizes[i]
					else
						break
					end
				end

				local elem, num = errDT:AddText(err)
				elem:SetDropStrength(18)
				elem:SetLiftStrength(18)
				elem.Font = picked
				elem.Color = txCol
				pieces[err] = num
			end
		else
			if errDT:GetCurrentElement() then
				errDT:DisappearCurrentElement()
			end
		end

		errDT:Paint(w/2, h * 0.8)

		--draw.SimpleText(tx, fonts.BoldMedium, w/2, h * 0.1, col:GetColor(), 1, 1)
	end

	local entryCanvas = vgui.Create("InvisPanel", pnl)

	name = vgui.Create("FTextEntry", entryCanvas)
	name:SetSize(pnl:GetWide() * 0.8, 32)
	name:SetPlaceholderText("Faction name...")
	name:SetUpdateOnType(true)

	pw = vgui.Create("FTextEntry", entryCanvas)
	pw:SetSize(pnl:GetWide() * 0.7, 32)
	pw:SetPlaceholderText("Password...")

	pw.Y = name.Y + name:GetTall() + 8

	col = vgui.Create("DColorMixer", entryCanvas)
	col:SetPalette(false)
	col:SetAlphaBar(false)
	col:SetWangs(false)
	col.Y = pw.Y + pw:GetTall() + 8

	col:SetSize(pnl:GetWide() * 0.6, pnl:GetTall() * 0.4)

	local COLOR = FindMetaTable("Color") --roobat

	function col:ValueChanged(c)
		setmetatable(c, COLOR)

		gradCol:Set(c)
		local dimmed = getDimmed(c, 0.2, 0.5)
		bgCol:Set(dimmed)
	end

	local totalH = name:GetTall() + 8 + pw:GetTall() + 8 + col:GetTall()

	entryCanvas:SetSize(pnl:GetWide(), totalH)

	entryCanvas:Center()
	name:CenterHorizontal()
	pw:CenterHorizontal()
	col:CenterHorizontal()

	pnl:ValidateData()

	errDT:CycleNext()

	local doEet = vgui.Create("FButton", pnl)
	doEet:Dock(BOTTOM)
	doEet:SetTall(pnl:GetTall() * 0.075)
	doEet:DockMargin(pnl:GetWide() * 0.2, 0, pnl:GetWide() * 0.2, pnl:GetTall() * 0.02)

	local good = Color(70, 180, 80)
	local bad = Colors.Button:Copy()

	function doEet:Think()
		if err then
			self:SetColor(bad)
		else
			self:SetColor(good)
		end
	end

	function doEet:DoClick()
		if err then return end

		Factions.RequestCreate(name:GetValue(), pw:GetValue(), col:GetColor())

		hook.Add("FactionsUpdate", pnl, function()
			if Factions.Factions[name:GetValue()] then
				pnl:Remove()
			end
		end)
	end

	local isize = doEet:GetTall() * 0.6
	doEet:SetIcon("https://i.imgur.com/dO5eomW.png", "plus.png", isize, isize)
	doEet.Label = " Create"
end

local function onSelectAction(f, fac, new, reuseCanvas)
	local old = IsValid(f.FactionFrame) and f.FactionFrame
	local valid = old and old:IsValid() and old:IsVisible()

	if fac == Factions.NoFaction then
		f.FactionFrame:Disappear()
		return
	end

	if new then
		if not valid or not old.IsNewFaction then
			-- only create if the current panel isn't valid OR isn't the `new faction` panel
			createNewFaction(f)
		end
		return
	end

	if not new then
		if valid and old.Faction == fac and not reuseCanvas then return end -- don't create a new frame if it's the same fac as before

		if LocalPlayer():Team() ~= fac.id then
			createFactionActions(f, fac, reuseCanvas and old)
		else
			createOwnFactionActions(f, fac, reuseCanvas and old)
		end

	end

	if valid and not reuseCanvas then
		removePanel(old, true)
	end
end

local function createNewFactionButton(pnl, scr, noanim)

	local newFac = vgui.Create("FButton", scr)
	local newH = math.floor(pnl:GetTall() * 0.08 / 2) * 2 + 1

	newFac:Dock(BOTTOM)
	newFac:DockMargin(8, 0, 8, 4)
	newFac:SetSize(scr:GetWide() - 16, newH)

	newFac:SetColor(Color(60, 190, 60))

	local isize = math.floor(newFac:GetTall() * 0.5 / 2) * 2 + 1
	newFac:SetIcon("https://i.imgur.com/dO5eomW.png", "plus.png", isize, isize)
	newFac.Label = "Create a faction"
	newFac.Font = fonts.MediumSmall
	newFac.HovMult = 1.1
	newFac.DisabledColor = Color(85, 85, 85)

	pnl:AddElement("Exclusive", newFac)

	if not noanim then
		newFac:SizeTo(-1, newH, 0.3, 0, 0.3)
		newFac:SetTall(0)
	end

	function newFac:DoClick()
		if IsValid(pnl.FactionFrame) and pnl.FactionFrame:IsVisible() and pnl.FactionFrame.IsNewFaction then
			pnl.FactionFrame:Disappear()
		else
			onSelectAction(pnl, nil, true)
		end
	end

	function newFac:Think()
		self:SetDisabled(LocalPlayer():InFaction())
	end
	function newFac:Disappear()
		local p = self
		local l, t, r, b = p:GetDockMargin()

		self:SizeTo(self:GetWide(), 0, 0.3, 0, 0.3, function()
			self:Remove()
		end):On("Think", function(self, fr)
			p:SetAlpha(255 * (1 - fr^0.6))
			p:DockMargin(l, t * (1 - fr), r, b * (1 - fr))
		end)
		self:SetZPos(-10)
	end

	pnl.NewFaction = newFac
end

--[[------------------------------]]
--	   		Factions Tab
--[[------------------------------]]

local function onOpen(navpnl, tabbtn, _, noanim)

	local f = BaseWars.Menu.Frame
	local prev = f.FactionsPanel
	local pnl, scr

	if IsValid(prev) then
		pnl, scr = prev, prev:GetList()

		if not pnl:IsVisible() then
			if noanim then
				pnl:Show()
			else
				pnl:PopInShow(0.1, 0.2)
			end
		end

		f:PositionPanel(pnl)

		if IsValid(pnl.FactionFrame) then
			onSelectAction(pnl, pnl.FactionFrame.Faction, pnl.FactionFrame.IsNewFaction, true)
		end
	else
		pnl, scr = BaseWars.Menu.CreateFactionList(f)
		if not noanim then
			pnl:PopIn(0.1, 0.2)
		end
	end

	function pnl:FactionClicked(fac)
		onSelectAction(self, fac, false)
	end

	if IsValid(pnl.NewFaction) then pnl.NewFaction:Disappear() end

	createNewFactionButton(pnl, scr, noanim)

	tabbtn.Panel = pnl
	f.FactionsPanel = pnl

	return pnl, true, true 	-- 2nd arg = don't pop panels out automatically; we'll handle it
							-- 3rd arg = don't pop in the panel automatically; we'll handle it
end

local function onClose(navpnl, tabbtn, prevPnl, newTab)
	local pnl = tabbtn.Panel

	pnl:RemoveElements("Exclusive")
	if not newTab or not newTab.TabData.UsesFactions then
		pnl:PopOutHide()
	end

	if IsValid(pnl.FactionFrame) then
		pnl.FactionFrame:RemoveElements("Exclusive")
	end
end

local function onCreateTab(f, tab)
	local ic = tab:SetIcon("https://i.imgur.com/JzTfIuf.png", "faction_64.png", 55 / 64)
	tab:SetDescription("Team up with other players")
	ic:SetPreserveRatio(true)
	tab.DefaultIconSize = tab.DefaultIconSize * 1.1
end

tab[1] = onOpen
tab[2] = onClose
tab[3] = onCreateTab


hook.Add("GenerateFactionOptions", "BaseActions", function(faction, ply, mn)
	local ow = faction:GetLeader()
	if LocalPlayer() ~= ow then return end

	if ply ~= LocalPlayer() then
		local kick = mn:AddOption("Kick Member", function()
			Factions.RequestKick(ply)
		end)
		kick.Color = Color(150, 30, 30)
	end

	mn.WOverride = 250
end)