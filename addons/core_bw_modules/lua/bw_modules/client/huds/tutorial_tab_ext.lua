local tab = {}
tab.Order = -10

local fonts = BaseWars.Menu.Fonts

BaseWars.Menu.Tabs["Tutorial"] = tab

local GFH = draw.GetFontHeight

local function onOpen(navpnl, tabbtn, prevPnl)
	local f = BaseWars.Menu.Frame
	local scale = BaseWars.Menu.Scale

	if IsValid(prevPnl) then
		prevPnl:PopInShow(0.1, 0.2)
		f:PositionPanel(prevPnl)
		prevPnl.noThoughtsHeadEmpty = false
		return prevPnl, true
	end

	local pnl = vgui.Create("Panel", f, "Settings Canvas")
	f:PositionPanel(pnl)
	pnl:PopIn(0.1, 0.2)
	pnl:DockPadding(scale * 16, scale * 64, scale * 16, scale * 64)

	tab.Panel = pnl

	local titleFont = fonts.BoldBig
	local txtFont = fonts.Medium

	local titleH, lineH = GFH(titleFont), GFH(txtFont) * 2
	local totalSpace =
		titleH + scale * 16 + 		-- title + space
		lineH + scale * 8 +			-- text lines + space
		scale * 80 + scale * 8 +	-- accept button
		scale * 64 					-- decline button

	local txCol = Color(140, 140, 140)

	local function mkLbl()
		local lbl = vgui.Create("DLabel", pnl)
		lbl:Dock(TOP)
		lbl:SetContentAlignment(5)
		return lbl
	end

	local lbl = mkLbl()
	lbl:SetFont(titleFont)
	lbl:SetText("Tutorial available!")
	lbl:SetColor(color_white)
	lbl:SizeToContents()

	local tx1 = "Would you like to go through it?"
	local in_tx1 = "You already have a tutorial active!"

	local tx2 = "You can come back to it anytime later."
	local in_tx2 = "If you changed your mind, you can just skip it."

	local lbl = mkLbl()
	lbl:SetFont(txtFont)
	lbl:SetText(tx1)
	lbl:SetColor(txCol)
	lbl:SizeToContents()

	local lbl2 = mkLbl()
	lbl2:SetFont(txtFont)
	lbl2:SetText(tx2)
	lbl2:SetColor(txCol)
	lbl2:SizeToContents()

	local l, t, r, b = pnl:GetDockPadding()

	local nah = vgui.Create("FButton", pnl)
	nah:SetFont(fonts.Medium)
	nah:SetSize(pnl:GetWide() * 0.5, scale * 48)
	nah:SetPos(0, pnl:GetTall() - b - nah:GetTall())
	nah:CenterHorizontal()

	pnl.noThoughtsHeadEmpty = false

	function nah:Think()
		if pnl.noThoughtsHeadEmpty then return end

		local step = BaseWars.Tutorial.CurrentStep
		if step ~= "Complete" and step ~= "Notify" then
			self:SetText("Skip tutorial")
			lbl:SetText(in_tx1)
			lbl2:SetText(in_tx2)
		else
			self:SetText("Nah")
			lbl:SetText(tx1)
			lbl2:SetText(tx2)
		end
	end

	local function doFumo()
		pnl.noThoughtsHeadEmpty = true
		navpnl:Disappear()
		navpnl:On("Appear", "unfumo", function()
			pnl.noThoughtsHeadEmpty = false
		end)
	end

	function nah:DoClick()
		cookie.Set("BW_TutorialComplete", "1")
		BaseWars.Tutorial.CurrentStep = "Complete"

		doFumo()
		hook.Run("BW_TutorialSkip")
	end

	local yea = vgui.Create("FButton", pnl)
	yea:SetText("yea less go")
	yea:SetFont(fonts.BoldMedium)
	yea:SetSize(pnl:GetWide() * 0.6, scale * 56)
	yea:SetPos(0, nah.Y - scale * 16 - yea:GetTall())
	yea:CenterHorizontal()
	yea:SetColor(Colors.Sky)

	function yea:Think()
		if pnl.noThoughtsHeadEmpty then return end

		local step = BaseWars.Tutorial.CurrentStep
		if step ~= "Complete" and step ~= "Notify" then
			self:SetEnabled(false)
		else
			self:SetEnabled(true)
		end
	end

	function yea:DoClick()
		BaseWars.Tutorial.CurrentStep = "The Basics"
		doFumo()
		hook.Run("BW_TutorialBegin")
	end

	return pnl, true
end

local function onClose(navpnl, tabbtn, prevPnl)
	tab.Panel:PopOutHide()
end

local blinkCol = Colors.Purpleish:Copy()

local function onCreateTab(f, tab)
	local ic = tab:SetIcon("https://i.imgur.com/b6ccSpJ.png", "book64.png")

	tab:SetDescription("y'know... if you want.")

	function tab:Paint(w, h)
		local needBlink = cookie.GetNumber("BW_TutorialComplete", 0) == 0
		if needBlink then
			local fr = 1 - (SysTime() * (1 / 1.4)) % 1
			fr = Ease(fr, 0.6)
			blinkCol.a = fr * 100 * (1 - self.ActiveFrac)
			surface.SetDrawColor(blinkCol)
			surface.DrawRect(0, 0, w, h)
		end
		self:Draw(w, h)
	end
end


tab[1] = onOpen
tab[2] = onClose
tab[3] = onCreateTab