local tab = {}
tab.Order = -1
BaseWars.Menu.Tabs["Settings"] = tab

surface.CreateFont("Settings_Blur", {
	size = 36,
	font = "BreezeSans",
	blursize = 8,
	weight = 400
})

local function createTitle(scr, cat)
	local title = scr:Add("Panel", cat)
	local font = BaseWars.Menu.Fonts.BoldBig
	local blur = BaseWars.Menu.Fonts.BlurBig
	local hgt = draw.GetFontHeight(font)
	title:SetWide(scr:GetWide())
	title:SetTall(hgt)
	title:DockPadding(0, title:GetTall(), 0, 0)
	title.Settings = {}

	function title:Paint(w, h)
		for i=1, 2 do
			draw.SimpleText(cat, blur, w / 2, -hgt * 0.125, color_black, 1, 5)
		end

		draw.SimpleText(cat, font, w / 2, -hgt * 0.125, color_white, 1, 5)
	end

	--title:Dock(TOP)

	function title:PerformLayout()
		local h = hgt

		for k,v in ipairs(self:GetChildren()) do
			h = math.max(h, v.Y + v:GetTall())
		end

		self:SetTall(h)
	end

	return title
end

tab.Creators = {}

local function hovPaint(self, w, h)
	if self:IsHovered() then
		self:To("HovFrac", 1, 0.3, 0, 0.3)
	else
		self:To("HovFrac", 0, 0.5, 0, 0.3)
	end

	surface.SetDrawColor(0, 0, 0, 120 * self.HovFrac)
	surface.DrawRect(0, 0, w, h)
end

local col = Color(200, 200, 200)

local function lblPaint(self, w, h)
	local st = self.Setting
	local nm = st:GetName() or st:GetID()

	col.a = self.HovFrac * 50 + 200

	draw.SimpleText(nm, BaseWars.Menu.Fonts.MediumSmall,
		8, h / 2, col, 0, 1)
end

function tab.Creators:bool(st)
	local fntHgt = draw.GetFontHeight(BaseWars.Menu.Fonts.MediumSmall) * 1.25
	self:SetTall(math.Multiple(fntHgt + 8, 4))
	self.Setting = st
	self.ActiveFrac = st:GetValue(true) and 1 or 0

	function self:Paint(w, h)
		hovPaint(self, w, h)
		lblPaint(self, w, h)
		self:To("ActiveFrac", st:GetValue(true) and 1 or 0, 0.3, 0, 0.3)

		draw.OnOffSlider(self.ActiveFrac or 0, w * 0.88, h / 4,
			w * 0.09, h / 2)
	end

	function self:DoClick()
		st:SetValue(not st:GetValue(true))
	end
end

local function onOpen(navpnl, tabbtn, prevPnl)
	local f = BaseWars.Menu.Frame

	if IsValid(prevPnl) then
		prevPnl:PopInShow(0.1, 0.2)
		f:PositionPanel(prevPnl)
		return prevPnl, true
	end

	local pnl = vgui.Create("Panel", f, "Settings Canvas")
	f:PositionPanel(pnl)
	pnl:PopIn(0.1, 0.2)
	tab.Panel = pnl


	local scr = vgui.Create("SearchLayout", pnl)
	scr:DockMargin(0, 0, 0, 8)
	--scr:GetCanvas():DockPadding(0, 8, 0, 8)
	scr:Dock(FILL)
	scr.ScissorShadows = false
	pnl:InvalidateLayout(true)

	for cat, sts in pairs(Settings.Categories) do
		local title = createTitle(scr, cat)

		for id, st in pairs(sts) do
			title.Settings[id] = st

			local btn = vgui.Create("DButton", title)
			btn:Dock(TOP)
			btn.Paint = nil
			btn:SetText("")
			if tab.Creators[st:GetType()] then
				tab.Creators[st:GetType()] (btn, st)
			else
				printf("%q missing a setting creator.", st:GetType())
			end
		end
	end

	scr:On("CustomSearch", "MatchSubsettings", function(self, cp, qry, name, ptrn)
		local sts = cp.Settings

		for k,v in pairs(sts) do
			if k:lower():find(qry:lower(), nil, ptrn) then
				return true
			end
		end
	end)

	pnl:InvalidateLayout(true)

	return pnl, true
end

local function onClose(navpnl, tabbtn, prevPnl)
	tab.Panel:PopOutHide()
end

local function onCreateTab(f, tab)
	local ic = tab:SetIcon("https://i.imgur.com/ZDzJwTM.png", "gear64.png")
	ic.Size = tab:GetTall() * 0.7
	tab:SetDescription("Settings n stuff")
end


tab[1] = onOpen
tab[2] = onClose
tab[3] = onCreateTab