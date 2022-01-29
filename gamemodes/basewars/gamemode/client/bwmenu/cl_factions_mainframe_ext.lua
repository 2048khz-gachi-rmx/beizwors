-- yoinked my own code from bw18
-- this is not for the button, this is for the faction info
local pickFactionTextColor = function(h, s, v, fcol)
	return v > 0.4 and fcol or color_white
end

-- this is for the button
local pickFactionButtonTextColor = function(h, s, v)
	return v > 0.75 and color_black or color_white
end

local fonts = BaseWars.Menu.Fonts

--[[------------------------------]]
--	   	   Faction Buttons
--[[------------------------------]]

local function facBtnPrePaint(self, w, h)
	local max = Factions.MaxMembers
	local fac = self.Faction
	self.Shadow.Blur = 1

	if LocalPlayer():GetFaction() == fac then
		self.Shadow.Color = Colors.Money
		self.AlwaysDrawShadow = true
		self.Shadow.MaxSpread = 2
		self.Shadow.MinSpread = 1
		self.Shadow.Blur = 2
		self.Shadow.React = false
	else
		self.Shadow.Color = color_white
		self.Shadow.React = false
		self.AlwaysDrawShadow = false
		self.Shadow.MaxSpread = 1
	end

	local membs = fac:GetMembers()

	local frac = math.min(#membs / max, 1)
	self:To("MembFrac", frac, 0.4, 0, 0.3)
	frac = self.MembFrac or 0

	--draw.RoundedBox(self.RBRadius or 8, 0, 0, w, h, Colors.Gray)

	--render.SetScissorRect(x, y, x + w * frac, y + h, true)
end

local function facBtnPaint(self, w, h)

	local x, y = self:LocalToScreen(0, 0)
	local frac = self.MembFrac or 0
	local bgcol = self.FactionColor

	local scale = self:GetMatrixScale()

	local cOff = w * frac - w/2 -- god im good
	local barSX = x + w * frac - cOff * (1 - scale)

	render.SetScissorRect(x, y + self:GetRaise(), barSX, y + h, true)
		draw.RoundedBox(self.RBRadius or 8, 0, 0, w, h, bgcol)
		local fh, fs, fv = self.Faction:GetColor():ToHSV()
		local col = pickFactionButtonTextColor(fh, fs, fv)

		draw.Masked(function()
			draw.RoundedStencilBox(self.RBRadius or 8, 0, 0, w, h, color_white)
		end, function()
			local r, g, b = 20, 20, 20
			if fv < 0.2 then
				r, g, b = 40, 40, 40
			end
			surface.SetDrawColor(r, g, b, 100)
			local u = -CurTime() % 25 / 25
			surface.DrawUVMaterial("https://i.imgur.com/y9uYf4Y.png", "whitestripes.png",
				0, 0, w, h, u, 0, u + 0.5, 0.125)
		end)

	render.SetScissorRect(0, 0, 0, 0, false)

	draw.SimpleText(self.Faction.name, fonts.BoldTiny, w/2, 2, col, 1)

	frac = self.MembFrac or 0

	render.SetScissorRect(barSX, y, x + w, y + h, true)
		draw.SimpleText2(self.Faction.name, nil, w/2, 2, color_white, 1)
	render.SetScissorRect(0, 0, 0, 0, false)
end

local FACSCROLL = {}

function FACSCROLL:Init()
	self.GradBorder = true
	self.ScissorShadows = true

	self.Factions = {}

	self.FactionHeight = 36
	self.FactionPadding = 8

end

function FACSCROLL:GetList()
	return self:GetParent()
end

function FACSCROLL:FactionClicked(fac)
	self:Emit("FactionClicked", fac)
	self:GetParent():Emit("FactionClicked", fac)
end

function FACSCROLL:GetFactionY(num)
	local facPad, facHeight = self.FactionPadding, self.FactionHeight
	return facPad / 2 + (num - 1) * (facHeight + facPad)
end

function FACSCROLL:RemoveFactionless()
	if IsValid(self.FactionlessButton) then
		self.FactionlessButton:Disappear()
	end
end

function FACSCROLL:AddFactionless()
	if IsValid(self.FactionlessButton) then return self.FactionlessButton end

	local noFac = self:GetList():AddFaction(Factions.NoFaction)
	noFac:PopIn()
	self:AddElement("NoFaction", noFac)
	self.FactionlessButton = noFac

	return noFac
end

function FACSCROLL:AddButton(fac, num)
	local btn = vgui.Create("FButton", self)

	local facPad, facHeight = self.FactionPadding, self.FactionHeight
	num = num or (table.Count(self.Factions) + 1)

	btn:SetPos(8, self:GetFactionY(num))

	btn:SetSize(self:GetWide() - 16, facHeight)

	--btn.DrawShadow = false

	btn.Faction = fac

	-- dim the faction color a bit
	local dimmed = fac:GetColor():Copy()
	local ch, cs, cv = dimmed:ToHSV()
	cv = cv * 0.8

	-- color is very close to Color(50, 50, 50) which is the scrollpanel color
	if cs < 0.15 and (cv > 0.15 and cv < 0.25) then
		-- if it's sufficiently bright, make it gray
		-- otherwise, make it pitch black
		cv = (cv >= 0.2) and 0.35 or 0.05
	end

	draw.ColorModHSV(dimmed, ch, cs * 0.9, cv)

	btn:SetColor(Colors.Gray, true)
	btn.FactionColor = dimmed
	btn.PrePaint = facBtnPrePaint
	btn.PostPaint = facBtnPaint
	--btn.DrawButton = facBtnDraw

	self.Factions[fac:GetName()] = btn

	function btn.DoClick(btn)
		self:FactionClicked(btn.Faction)
		--pnl:SetFaction(self.Faction)
	end

	local scr = self

	function btn:Disappear()
		self:PopOut()
		scr.Factions[fac:GetName()] = nil
		self:SetMouseInputEnabled(false)
	end

	return btn, num
end

vgui.Register("FactionsScroll", FACSCROLL, "FScrollPanel")




local FAC = {}

function FAC:Init()
	local scr = vgui.Create("FactionsScroll", self)

	self.FactionScroll = scr

	local f = BaseWars.Menu.Frame

	scr:Dock(FILL)
	scr:DockMargin(4, 0, 4, 4)
	scr:InvalidateParent(true)
end

function FAC:PopulateFactions()
	local sorted = Factions.GetSortedFactions()

	for k,v in ipairs(sorted) do
		local fac = v[2]

		self.FactionScroll:AddButton(fac, k)
	end
end



function FAC:GetScroll()
	return self.FactionScroll
end


function FAC:AddFaction(fac, k)
	return self:GetScroll():AddButton(fac, k)
end

function FAC:GetFactions()
	return self:GetScroll().Factions
end

function FAC:AddFactionless()
	return self:GetScroll():AddFactionless()
end

function FAC:RemoveFactionless()
	return self:GetScroll():RemoveFactionless()
end

function FAC:Think()
	local scr = self.FactionScroll

	self:Emit("Think")
end

function FAC:PerformLayout()
	local facHeight = 24 + (self:GetTall() - 16) * 0.05
	local facPad = (self:GetTall() - 16) * 0.03

	self.FactionScroll.FactionHeight = facHeight
	self.FactionScroll.FactionPadding = facPad
end

vgui.Register("FactionsList", FAC, "Panel")




local function align(f, pnl)
	if pnl.__selMove then
		pnl.__selMove:Stop()
		pnl.__selMove = nil
	end

	pnl:SetPos(f.FactionScroll.X + f.FactionScroll:GetWide(), 0)
								--    V because it'll move to the right by 8px
	pnl:SetSize(f:GetWide() - pnl.X - 8, f:GetTall())

	pnl:SetAlpha(0)
	pnl:MoveBy(8, 0, 0.2, 0, 0.3)
	pnl:PopInShow()

	f.FactionFrame = pnl
end

local function removePanel(pnl, hide)
	pnl.__selMove = pnl:MoveBy(24, 0, 0.2, 0, 2.6)

	if hide then
		pnl:PopOutHide(0.2)
	else
		pnl:PopOut(0.2)
	end

end

function BaseWars.Menu.CreateFactionList(f, noanim)
	local pnl = vgui.Create("Panel", f, "Factions Canvas")
	f:PositionPanel(pnl)

	pnl.IsFactionsCanvas = true
	pnl.SetPanel = align

	--tab.Panel = pnl

	local scr = vgui.Create("FactionsList", pnl)
	scr:Dock(LEFT)
	scr:SetWide(pnl:GetWide() * 0.34)
	scr:DockMargin(0, 8, 0, 0)

	pnl.FactionScroll = scr

	function pnl:GetList()
		return scr
	end

	local me = LocalPlayer()

	hook.Add("FactionsUpdate", scr, function()
		local sorted = Factions.GetSortedFactions()
		local facs = scr:GetFactions()

		for k,v in pairs(facs) do
			v.Sorted = false
		end

		for k,v in ipairs(sorted) do
			-- compare currently existing factions vs. currently existing buttons
			-- every button that has an existing faction will have their .Sorted member set to true
			local name, fac = v[1], v[2]

			if IsValid(facs[name]) then
				facs[name].Sorted = true
				local desY = scr:GetScroll():GetFactionY(k)
				facs[name]:MoveTo(8, desY, 0.3, 0, 0.3)
			else
				local btn = scr:AddFaction(fac, k)
				btn:PopIn()
				btn.Sorted = true
				btn.FacNum = k
			end
		end

		local facless = scr:GetScroll().FactionlessButton

		if IsValid(facless) then
			-- factionless gets shifted after every faction, if valid
			local desY = scr:GetScroll():GetFactionY(#sorted + 1)
			facless:MoveTo(8, desY, 0.3, 0, 0.3)
		end

		for name, btn in pairs(facs) do
			if IsValid(btn) and not btn.Sorted and btn.Faction ~= Factions.NoFaction then
				-- if Sorted is false that means we didn't go over that button and, thus, the faction doesn't exist anymore

				local x, y = btn:GetPos()
				btn:Dock(NODOCK)
				btn:SetPos(x, y)
				removePanel(btn)
				facs[name] = nil
			end

		end

		if pnl.FactionFrame and pnl.FactionFrame:IsValid() then
			local ff = pnl.FactionFrame
			if ff.Faction and ff.Faction ~= Factions.NoFaction then
				for k,v in ipairs(sorted) do if ff.Faction == v[2] then return end end -- currently open faction still exists; everythings ok
				removePanel(ff) -- currently open faction does not exist anymore; yeet it
			end
		end

	end)

	pnl:InvalidateLayout(true)
	scr:InvalidateChildren(true)

	scr:PopulateFactions()

	pnl.FactionClicked = BlankFunc

	scr:On("FactionClicked", function(_, fac)
		pnl:FactionClicked(fac)
		--pnl:Emit("FactionClicked", fac)
	end)

	return pnl, scr
end