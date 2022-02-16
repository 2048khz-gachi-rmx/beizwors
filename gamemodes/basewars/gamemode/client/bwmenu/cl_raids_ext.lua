local tab = {}
tab.Order = 99

tab.UsesFactions = true
tab.UsesFactionless = true

local fonts = BaseWars.Menu.Fonts

BaseWars.Menu.Tabs["Raids"] = tab

Colors.Raid = Color(180, 70, 70)
local bad_red = Color(180, 80, 80)

local function removePanel(pnl, hide)
	if pnl.__selMove then pnl.__selMove:Stop() end

	pnl.__selMove = pnl:MoveBy(16, 0, 0.2, 0, 1.4)

	if hide then
		pnl:PopOutHide()
	else
		pnl:PopOut()
	end

end

local function createActionCanvas(f, fac)
	local pnl = vgui.Create("FactionPanel", f, "Canvas for " .. tostring(fac))

	f.FactionFrame = pnl
	f:SetPanel(pnl)

	pnl:SetFaction(fac)

	return pnl
end

local flagIcon = Icons.Flag128:Copy()
flagIcon:SetSize(24, 24)
flagIcon.IconX = 4

local startIcon = Icon("https://i.imgur.com/xyrD9OM.png", "salilsawaarim.png")
startIcon:SetSize(24, 24)
startIcon.IconX = 4

local function createRaidActions(pnl, fac, canv)
	local old = true -- = the canvas already existed, aka they switched from faction tab to raid tab

	if not canv or canv.Faction ~= fac then
		old = false
		canv = createActionCanvas(pnl, fac)
	end

	local can = false

	if fac == LocalPlayer():GetFaction() then return end

	local mn = canv.Main

	local raid = vgui.Create("FButton", mn)
	raid:SetSize(mn:GetWide() * 0.4, 36)
	raid:Center()
	raid.Label = "Start raid!"

	if old then
		local old = mn:GetTall() - 44
		raid.Y = mn:GetTall() + 8
		raid:To("Y", old, 0.3, 0, 0.3)
	else
		raid.Y = mn:GetTall() - 44
	end

	raid:SetColor(Colors.Raid, true)

	raid:SetIcon(startIcon)
	raid.NotLaidOut = true

	function raid:Disappear()
		local mn = canv.Main

		self:PopOut(0.2)
		self:To("Y", mn:GetTall() + 8, 0.25, 0, 3):Then(function()
			self:Remove()
		end)
	end

	function raid:Think()
		local ic

		local curRd = LocalPlayer():InRaid()

		if curRd and curRd:IsRaider(LocalPlayer()) then
			self.Label = "Concede Raid"
			ic = self:SetIcon(flagIcon)
			self:SetColor(Colors.Raid)
			self:SetEnabled(true)
		else
			local can, why = BaseWars.Raid.CanGenerallyRaid(LocalPlayer(), false)

			if can then
				can, why = BaseWars.Raid.CanRaidFaction(LocalPlayer(), fac)
			end

			self.Label = "Start raid!"
			ic = self:SetIcon(startIcon)
			self:SetColor(Colors.Golden)

			if why then
				if self:IsHovered() then
					local cl, new = self:AddCloud("err")

					if cl and new then
						cl.Font = "OS20"
						cl.MaxW = 250
						cl.AlignLabel = 1

						cl:SetTextColor(bad_red)
						cl:SetRelPos(self:GetWide() / 2)
						cl.ToY = -32

						cl.DisappearTime = 0.2
						cl.DisappearEase = 2.3

						cl:SetText(why)
					end
				else
					self:RemoveCloud("err")
				end

				self.Label = "Start raid!"
				ic = self:SetIcon(startIcon)
				self:SetEnabled(false)
			else
				self:SetEnabled(true)
				self:RemoveCloud("err")
			end
		end

		surface.SetFont(self:GetFont())
		local tw, th = surface.GetTextSize(self:GetText())

		local sz = tw + ic:GetWide() + ic.IconX + self.RBRadius * 2

		if self.NotLaidOut then
			self.NotLaidOut = false
			self:SetWide(sz)
			self.AnimWidth = sz
			self:CenterHorizontal()
		end

		local an, new = self:To("AnimWidth", sz, 0.3, 0, 0.3)

		if new then
			an:On("Think", function()
				self:SetWide(self.AnimWidth)
				self:CenterHorizontal()
			end)
		end
	end

	local errPnl = vgui.Create("Cloud", mn)
	errPnl.AlignLabel = 1
	errPnl.YAlign = 1
	errPnl.MaxW = 250
	errPnl.Middle = 1
	errPnl.Font = "OS20"

	errPnl:SetTextColor(200, 60, 60)
	errPnl:SetRelPos(raid.X + 8, raid.Y + raid:GetTall() / 2)
	errPnl.ToY = -32

	errPnl.DisappearTime = 0.2
	errPnl.DisappearEase = 2.3

	raid.A = 1

	function raid:DoClick()
		local rd = LocalPlayer():InRaid()
		if rd and rd:IsRaider(LocalPlayer()) then
			local pr = Raids.ConcedeRaid()

			pr:Then(function(...)
				print("cl - conceded successfully", ...)
			end, function(...)
				print("cl - couldnt concede? wtf", net.ReadString())
			end)

			return
		end

		local pr = Raids.CallRaid(fac, true)
		self:To("A", 0, 0.1, 0, 0.3)

		pr:Then(function()
			self:To("A", 1, 0.1, 0, 0.3)
		end, function()
			local why = net.ReadString()
			self:To("A", 1, 0.1, 0, 0.3)

			errPnl:SetText(why)
			errPnl:Popup(true)
			errPnl:SetRelPos(raid.X + raid:GetWide() / 2, raid.Y)

			errPnl.ToX = 0
			errPnl.ToY = -32
			errPnl.Middle = 0.5

			local time = why:CountWords() * 0.5
			if time > 1 then
				time = time ^ 0.6
			end

			time = math.max(time, 1.3)

			errPnl.DisappearTime = 0.2
			errPnl.DisappearEase = 2.3

			errPnl:Timer("raidErr", time, function()
				errPnl:Popup(false)
			end)
		end)
	end
	canv:AddElement("Exclusive", raid)
end

local function createFactionlessOption(pnl, scr, num, ply)
	local canv = pnl.NoFactionRaidCanvas

	local p = vgui.Create("GradPanel", scr, "PlayerFrame for " .. tostring(ply))
	p.GradSize = 2

	local hgt = 64 * BaseWars.Menu.Scale

	local y = 0

	for i=1, num - 1 do
		local p = scr.PlayerFrames[i]
		if p.Disappearing then continue end
		y = y + p:GetTall()
	end

	p.Y = y
	p:SetSize(scr:GetWide(), hgt)
	p:SetColor(Colors.DarkGray)

	local av = vgui.Create("CircularAvatar", p)
	av:Dock(LEFT)
	av:DockMargin(hgt / 12, hgt / 12, 0, hgt / 12)

	function av:Resize()
		av:InvalidateParent(true)
		av:SetWide(av:GetTall())
							-- pick best size
		av:SetPlayer( ply, (av:GetTall() <= 64 and 64 or 128) )
	end

	av:Resize()
	av.Rounding = 8 * BaseWars.Menu.Scale

	p.Avatar = av

	local nm = ply:Nick()
	local lastnm = ply:Nick()

	p.Money = 0 -- ply:GetMoney()
	p.Level = 0 -- ply:GetLevel()

	function p:Disappear()
		if self.Disappearing then return end

		self.Disappearing = self:PopOut():Then(function()
			self:Emit("Disappear")
		end)
	end

	function p:Think()
		if ply:IsValid() then
			nm = ply:Nick()
			self:To("Money", ply:GetMoney(), 0.6, 0, 0.2)
			-- it doesn't really make sense to lerp levels, but might as well, right?
			self:To("Level", ply:GetLevel(), 0.6, 0, 0.2)
			if ply:GetFaction() then
				self:Disappear()
			end
		else
			self:Disappear()
		end
	end

	--local lvCol = (ply:GetLevel() > 75 and Colors.LighterGray or Colors.DarkerRed):Copy()

	p:On("Paint", "DrawName", function(self, w, h)
		local tW, tH = draw.SimpleText(nm, BaseWars.Menu.Fonts.MediumSmall, av.X + av:GetWide() + 6, av.Y, color_white, 0, 5)

		if ply == LocalPlayer() then
			draw.SimpleText("  (" .. Language.You():lower() .. "!)", BaseWars.Menu.Fonts.Small,
				av.X + av:GetWide() + 6 + tW, av.Y + tH * 0.875, Colors.LightGray, 0, 4)
			return
		end


		local _, moneyH = draw.SimpleText(Language("Price", self.Money), BaseWars.Menu.Fonts.Small, av.X + av:GetWide() + 6,
			av.Y + tH * 0.75 + 2, Colors.LightGray, 0, 5)

		--[[self:LerpColor(lvCol, self.Level > 75 and Colors.LighterGray or Colors.DarkerRed, 0.3, 0, 0.3)
		draw.SimpleText(Language("Level", self.Level), BaseWars.Menu.Fonts.Small, av.X + av:GetWide() + 6,
			av.Y + tH * 0.75 + 2 + moneyH * 0.875, lvCol, 0, 5)]]
	end)

	function p:Shuffle(newID, now)
		local y = 0

		for i=1, newID - 1 do
			local p = scr.PlayerFrames[i]
			if p.Disappearing then continue end
			y = y + p:GetTall()
		end

		if now then
			self.Y = y
		else
			self:To("Y", y, 0.3, 0, 0.3)
		end
	end

	if ply == LocalPlayer() then return p end

	local raid = vgui.Create("FButton", p)
	raid:Dock(RIGHT)
	raid:DockMargin(8, 4, 8, 4)
	raid:InvalidateParent(true)
	raid:SetWide(raid:GetTall())

	function raid:Think()
		local raid = LocalPlayer():InRaid()
		if not ply:IsValid() then return end

		if not raid then
			local can, why = ply:IsRaidable()

			if self:IsHovered() and why then
				local cl, new = self:AddCloud("err")

				if cl and new then
					cl.Font = "OS20"
					cl.MaxW = 250
					cl.AlignLabel = 2
					cl.YAlign = 1
					cl.Middle = 1

					cl:SetTextColor(bad_red)
					cl:SetRelPos(0, self:GetTall() / 2)
					cl.ToY = 0
					cl.ToX = -16

					cl.DisappearTime = 0.2
					cl.DisappearEase = 2.3

					cl:SetText(why)
				end
			else
				self:RemoveCloud("err")
			end

			self:SetDisabled(not can)
			self:SetColor(can and Colors.Raid or Colors.Button)
		else
			self:SetColor(Colors.Golden)
		end
	end

	local errPnl = vgui.Create("Cloud", p)
	errPnl.AlignLabel = 1
	errPnl.YAlign = 1
	errPnl.MaxW = 256
	errPnl.Middle = 1
	errPnl.Font = "OS20"

	errPnl:SetTextColor(200, 60, 60)
	errPnl:SetRelPos(raid.X + 8, raid.Y + raid:GetTall() / 2)
	errPnl.ToX = -16

	--errPnl:
	raid.A = 1
	local col = color_white:Copy()


	function raid:PostPaint(w, h)
		surface.SetDrawColor(255, 255, 255, self.A * 255)

		local raid = LocalPlayer():InRaid()
		if raid and raid:IsRaider(LocalPlayer()) then
			flagIcon:Paint(12, 12, w - 24, w - 24)
		else
			startIcon:Paint(12, 12, w - 24, w - 24)
		end

		--surface.DrawMaterial("https://i.imgur.com/xyrD9OM.png", "salilsawaarim.png", 12, 12, w - 24, w - 24)

		local rev = 1 - self.A

		if rev > 0 then
			col.a = rev * 250
			draw.DrawLoading(self, w/2, h/2, 36 + 8 * rev, 36 + 8 * rev, col)
		end
	end

	function raid:DoClick()
		local curRd = LocalPlayer():InRaid()
		if curRd and curRd:IsRaider(LocalPlayer()) then
			local pr = Raids.ConcedeRaid()

			pr:Then(function(...)
				print("cl - conceded successfully", ...)
			end, function(...)
				print("cl - couldnt concede? wtf", net.ReadString())
			end)

			return
		end

		local pr = Raids.CallRaid(ply, false)
		self:To("A", 0, 0.1, 0, 0.3)

		pr:Then(function()
			self:To("A", 1, 0.1, 0, 0.3)
		end, function()
			local why = net.ReadString()
			self:To("A", 1, 0.1, 0, 0.3)

			errPnl:SetText(why)
			errPnl:Popup(true)
			errPnl:SetRelPos(raid.X + raid:GetWide() / 2, raid.Y)

			errPnl.ToX = 0
			errPnl.ToY = -32
			errPnl.Middle = 0.5

			local time = why:CountWords() * 0.3
			if time > 1 then
				time = time ^ 0.6
			end

			errPnl.DisappearTime = 0.2
			errPnl.DisappearEase = 2.3

			errPnl:Timer("raidErr", time, function()
				errPnl:Popup(false)
			end)
		end)
	end

	return p
end


local function createFactionlessActions(pnl, fac, scr, scrollPlayer)

	local canv = pnl.NoFactionRaidCanvas


	if IsValid(canv) then
		canv:PopInShow()
		canv:Emit("Reappear")
		pnl:SetPanel(canv)
		return
	end

	canv = createActionCanvas(pnl, fac)
	scr:AddElement("NoFaction", canv)
	pnl.NoFactionRaidCanvas = canv
	pnl:SetPanel(canv)

	canv:InvalidateLayout(true)

	local scr = vgui.Create("FScrollPanel", canv)
	scr:Dock(FILL)
	scr.BackgroundColor = Color(30, 30, 30)

	scr:DockMargin(8,
		canv:GetTall() * 0.07 + BaseWars.Menu.Fonts.BoldSizes.Medium, 8, 8)

	canv:InvalidateLayout(true)

	local plyFrames = {}  -- [num] = frame
	local plyToFrame = {} -- [ply] = frame
	local plys = {}
	scr.PlayerFrames = plyFrames

	local function frRemove(ply)
		local fr = plyToFrame[ply]
		if IsValid(fr) then fr:Remove() end

		table.RemoveByValue(plyFrames, fr)
		plyToFrame[ply] = nil
	end

	local function plyValid(ply)
		if not ply:IsValid() or not IsValid(plyToFrame[ply]) then
			frRemove(ply)
		end
	end

	local function getFrame(ply)
		if IsValid(plyToFrame[ply]) then
			return plyToFrame[ply]
		end
	end

	local function reshuffle()
		local existed = {}

		local i = 0

		for k,v in ipairs(plys) do
			existed[v] = true

			if getFrame(v) and not getFrame(v).Disappearing then
				i = i + 1
				getFrame(v):Shuffle(i)
				plyFrames[k] = getFrame(v)
			end
		end

		return existed
	end

	local function sortPlayers()
		plys = {}

		for k, ply in ipairs(player.GetAll()) do
			-- dont use teams because those are engine = uncontrollable
			-- whereas faction system is controlled by me =>
			-- if the player left the faction, :GetFaction() will return false 100%
			if not ply:GetFaction() then
				plys[#plys + 1] = ply
			end
		end

		table.Filter(plys, IsValid)

		table.sort(plys, function(a, b)
			local m1, m2 = a:GetMoney(), b:GetMoney()

			if m1 == m2 then
				return a:Nick() < b:Nick() --alphabetical
			end

			return m1 > m2
		end)
	end

	sortPlayers()

	local function createPlyFrame(k, ply)
		local p = createFactionlessOption(pnl, scr, k, ply)
		plyFrames[k] = p
		plyToFrame[ply] = p

		if ply == LocalPlayer() then
			p:SetTall(p:GetTall() * 0.75)
			p.Avatar:Resize()
		end

		p:On("Disappear", function(self)
			frRemove(ply)
			sortPlayers()
			reshuffle()
		end)
	end


	local function validateFrames()
		for k,v in ipairs(plys) do
			plyValid(v)
		end
	end

	sortPlayers()

	for k, v in ipairs(plys) do
		createPlyFrame(k, v)
	end

	reshuffle()

	function canv:UpdatePlayers()
		if not canv:IsValid() then return end
		sortPlayers()
		validateFrames()

		for k,v in ipairs(plys) do
			if not getFrame(v) then
				createPlyFrame(k, v)
			end
		end

		reshuffle()
	end

	hook.NHAdd("PlayerJoined", canv, canv.UpdatePlayers)
	hook.NHAdd("FactionsUpdate", canv, canv.UpdatePlayers)
	hook.NHAdd("PlayerLeftFaction", canv, canv.UpdatePlayers)

	hook.NHAdd("MoneyChanged", canv, function(_, pinfo, old, new)
		canv:UpdatePlayers()
	end)

	canv:On("Reappear", "RetrackPlayers", canv.UpdatePlayers)

	function canv:Disappear()
		removePanel(self, true)
	end

	if scrollPlayer then
		local btn = plyToFrame[scrollPlayer]
		if btn then
			scr:ScrollToChild(btn)
		end
	end
end

local function onOpen(navpnl, tabbtn, _, noanim)
	local f = BaseWars.Menu.Frame

	local pnl = f.FactionsPanel	-- pnl is the canvas (holds everything), scr is the FactionsList
	local scr = IsValid(pnl) and pnl:GetList()

	if IsValid(pnl) then

		if not pnl:IsVisible() then
			if noanim then
				pnl:Show()
			else
				pnl:PopInShow(0.1, 0.2)
			end
			if IsValid(pnl.NewFaction) then
				pnl.NewFaction:Remove()
			end
		end

		f:PositionPanel(pnl)

		if IsValid(pnl.FactionFrame) then
			if pnl.FactionFrame == pnl.NoFactionRaidCanvas then
				createFactionlessActions(pnl, pnl.FactionFrame.Faction, scr)
			else
				createRaidActions(pnl, pnl.FactionFrame.Faction, pnl.FactionFrame)
			end
		end
	else
		pnl, scr = BaseWars.Menu.CreateFactionList(f)
		if not noanim then
			pnl:PopIn(0.1, 0.2)
		end
	end

	-- add a custom NoFaction button
	local noFac = scr:AddFactionless()

	function pnl:FactionClicked(fac, ...)
		local old = IsValid(pnl.FactionFrame) and pnl.FactionFrame

		if old and old.Faction == fac then return end
		if old and old.Faction ~= fac then
			removePanel(old, true)
		end

		if fac:GetID() == -1 then
			createFactionlessActions(pnl, fac, scr, ...)
			return
		end

		createRaidActions(pnl, fac, pnl.FactionFrame)
	end

	tabbtn.Panel = pnl

	local cur = vgui.Create("FButton", scr)
	local newH = math.floor(scr:GetTall() * 0.08 / 2) * 2 + 1

	cur:Dock(BOTTOM)
	cur:DockMargin(8, 0, 8, 4)
	cur:SetSize(scr:GetWide() - 16, newH)

	cur.Label = "Your current raid"
	cur.Font = fonts.MediumSmall
	local isize = math.floor(cur:GetTall() * 0.5 / 2) * 2 + 1
	local ic = cur:SetIcon("https://i.imgur.com/xyrD9OM.png", "salilsawaarim.png", isize, isize)
	ic.IconX = 8
	cur:SizeTo(-1, newH, 0.3, 0, 0.3)
	cur:SetTall(0)

	pnl:AddElement("Exclusive", cur)

	function cur:Disappear()
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

	cur:SetColor(Raids.MyRaid and Colors.Raid or Colors.Button, true)

	function cur:Think()
		self:SetColor(Raids.MyRaid and Colors.Raid or Colors.Button)
		self:SetDisabled(Raids.MyRaid == nil)
	end

	function cur:DoClick()
		local rd = Raids.MyRaid
		local rder, rded, isFac = rd:GetSides()
		local lp = LocalPlayer()

		if isFac then
			local other = (rder == lp:GetFaction() and rded) or rder
			pnl:FactionClicked(other)
		else
			local other = (rder == lp and rded) or rder
			pnl:FactionClicked(Factions.NoFaction, other)
		end
	end

	return pnl, true, true
end

local function onClose(navpnl, tabbtn, prevPnl, newTab)
	local pnl = tabbtn.Panel
	--pnl.FactionScroll.FactionScroll:RemoveElements("NoFaction")

	local f = BaseWars.Menu.Frame
	local prev = f.FactionsPanel	-- factions canvas

	prev:RemoveElements("Exclusive")
	prev:GetList():RemoveElements("Exclusive")

	if newTab then
		if not newTab.TabData.UsesFactionless then
			prev:GetList():RemoveFactionless()
		end

		if not newTab.TabData.UsesFactions then
			pnl:PopOutHide()
		end
	end

	if IsValid(pnl.FactionFrame) then
		pnl.FactionFrame:RemoveElements("Exclusive")
		pnl.FactionFrame:RemoveElements("Exclusive")
	end
end

local function onCreateTab(f, tab)
	local ic = tab:SetIcon("https://i.imgur.com/xyrD9OM.png", "salilsawaarim.png")
	tab:SetDescription("Scan and raid others")

	tab.UsesFactions = true
end


tab[1] = onOpen
tab[2] = onClose
tab[3] = onCreateTab