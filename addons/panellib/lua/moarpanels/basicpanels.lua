local PANEL = {}
local BLANK = {}
local BlankFunc = function() end 
local blankfunc = BlankFunc 

local gu = Material("vgui/gradient-u")
local gd = Material("vgui/gradient-d")
local gr = Material("vgui/gradient-r")
local gl = Material("vgui/gradient-l")



--[[-------------------------------------------------------------------------
-- 	FPanel
---------------------------------------------------------------------------]]


function PANEL:Init()

	self:SetSize(128, 128)
	self:Center()
	self:SetTitle("")
	self:ShowCloseButton(false)
	local w,h = self:GetSize()

	local b = vgui.Create("DButton", self)
	self.CloseButton = b 
	b:SetPos(w - 72, 2)
	b:SetSize(64, 24)
	b:SetText("")
	b.Color = Color(205, 50, 50)
	function b:Paint(w,h)
		b.Color = LC(b.Color, (self.PreventClosing and Color(80, 80, 80)) or (self:IsHovered() and Color(235, 90, 90)) or Color(205, 50, 50), 15)
		draw.RoundedBox(4, 0, 0, w, h, b.Color)
	end
	b.DoClick = function()
		if self.PreventClosing then return end 
		
		if self.OnClose then 
			local ret = self:OnClose()
			if ret==false then return end 
		end

		self:Remove()
	end
	self.m_bCloseButton = b
	self.Width, self.Height = w,h
	self.HeaderSize = 32
	self.BackgroundColor = Color(50, 50, 50)
	self.HeaderColor = Color(40, 40, 40)

	self:DockPadding(4, 32, 4, 4)
end


function PANEL:SetColor(r, g, b)

	if IsColor(r) then 
		self.BackgroundColor = r 
		local h, s, v = ColorToHSV(r)
		self.HeaderColor = HSVToColor(h, s*0.9, v*0.8)
	else
		local col = Color(r, g, b)
		self.BackgroundColor = col
		local h, s, v = ColorToHSV(col)
		self.HeaderColor = HSVToColor(h, s*0.9, v*0.8)

	end

end


function PANEL:SetCloseable(bool,remove)
	self.PreventClosing = not bool --shh
	if remove and IsValid(self.CloseButton) then 
		self.CloseButton:Remove()
	end
end

surface.CreateFont( "PanelLabel", {
	font = "Titillium Web SemiBold",
	size = 30,
	weight = 200,
	antialias = true,
} )
local ceil = math.ceil
function PANEL:OnChangedSize(w,h)

end

function PANEL:GetColor()
	return self.BackgroundColor 
end

function PANEL:OnSizeChanged(w,h)
	if IsValid(self.m_bCloseButton) then 
		self.m_bCloseButton:SetPos(w - 72, 2)
	end
	self.Width = w 
	self.Height = h
	self:OnChangedSize(w,h)

end


function PANEL.DrawHeaderPanel(self, w, h)

	local rad = self.RBRadius or 8
	local hc = self.HeaderColor or Color(255, 40, 40)
	local bg = self.BackgroundColor or Color(255, 50, 50)

	local label = self.Label or self.Title or nil

	local icon = (self.Icon and self.Icon.mat) or nil

	local x,y = 0, 0

	if self.Shadow then 
		--surface.DisableClipping(false)
		BSHADOWS.BeginShadow()
		x, y = self:LocalToScreen(0, 0)
	end

	local hh = self.HeaderSize
	local tops = true 

	if hh > 0 then
		draw.RoundedBoxEx(self.HRBRadius or rad, x, y, w, hh, hc, true, true)
		tops = false
	end
	draw.RoundedBoxEx(rad, x, y+hh, w, h-hh, bg, tops, tops, true, true)

	if label then
		local xoff = 12

		if icon and icon.IsError and not icon:IsError() then
			local w2, h2 = self.Icon.w or 16, self.Icon.h or 16
			xoff = xoff + w2 + 6
			surface.SetDrawColor(255,255,255, 255)
			surface.SetMaterial(icon)
			surface.DrawTexturedRect(x+8, y+(hh-h2)/2, w2, h2)

		end

		draw.SimpleText(label, "PanelLabel", x+xoff, y, Color(255,255,255), 0, 2)
	end

	if self.Shadow then 
		local int = self.Shadow.intensity or 2
		local spr = self.Shadow.spread or 2
		local blur = self.Shadow.blur or 2
		local alpha = self.Shadow.alpha or self.Shadow.opacity or 255
		local color = self.Shadow.color or nil

		BSHADOWS.EndShadow(int, spr, blur, alpha, nil, nil, nil, color)
		--surface.DisableClipping(true)
	end

end

PANEL.Draw = PANEL.DrawHeaderPanel

function PANEL:PostPaint(w,h)

end

function PANEL:PrePaint(w,h)

end

function PANEL:Paint(w, h)
	self:PrePaint(w, h)
	self:DrawHeaderPanel(w, h)
	self:PostPaint(w, h)
end

function PANEL:PaintOver(w,h)

	if self.Dim then 
		local rad = self.RBRadius or 8
		draw.RoundedBox(rad, 0, 0, w, h, Color(0, 0, 0, self.DimAlpha or 220))
	end

end
vgui.Register("FFrame", PANEL, "DFrame")

--[[-------------------------------------------------------------------------
-- 	FButton
---------------------------------------------------------------------------]]

local button = {}

function button:Init()
	self.Color = Color(70, 70, 70)
	self.drawColor = self.Color
	self:SetText("")

	self.Font = "PanelLabel"
	self.DrawShadow = true
	self.HovMult = 1.2

	self.Shadow = {
		MaxSpread = 0.6,
		Intensity = 2,
		OnHover = true,	--should the internal shadow logic be applied when the button gets hovered?
	}

	self.LabelColor = Color(255, 255, 255)
	self.RBRadius = 8
end

function button:SetColor(col, g, b, a)
	if IsColor(col) then self.Color = col self.drawColor = self.Color return end 
	self.Color = Color(col or 70, g or col or 70, b or col or 70, a or 255)
	--self.drawColor = self.Color
end
function button:SetLabel(txt)
	self.Label = txt
end

function button:Hovered()

end

function button:OnHover()

end

function button:OnUnhover()

end
local function dRB(rad, x, y, w, h, dc, ex)

	if ex then 
		local r = ex

		local tl = (r.tl==nil and true) or r.tl
		local tr = (r.tr==nil and true) or r.tr

		local bl = (r.bl==nil and true) or r.bl
		local br = (r.br==nil and true) or r.br

		draw.RoundedBoxEx(rad, x, y, w, h, dc, tl, tr, bl, br)
	else
		draw.RoundedBox(rad, x, y, w, h, dc)
	end

end
function button:Draw(w, h)

	local rad = self.RBRadius or 8
	local bg = self.drawColor or self.Color

	local shadow = self.Shadow 

	self.drawColor = self.drawColor or bg
	local hov = false 
	
	local x, y = 0, 0

	if self:IsHovered() then

		hov = true 
		local hovmult = self.HovMult 

		local bg = self.Color or Color(70,70,70)
		local fr = bg.r*hovmult
		local fg = bg.g*hovmult
		local fb = bg.b*hovmult
		self.drawColor = LC(self.drawColor, Color(fr,fg,fb))
		if shadow.OnHover then shadow.Spread = L(shadow.Spread, shadow.MaxSpread, 20) end

		if not self._IsHovered then 
			self._IsHovered = true 
			self:OnHover()
		end

	else

		local bg = self.Color or Color(70,70,70)
		self.drawColor = LC(self.drawColor, bg)
		if shadow.OnHover then shadow.Spread = L(shadow.Spread, 0, 50) end 

		if self._IsHovered then 
			self._IsHovered = false 
			self:OnUnhover()
		end
	end

	local spr = shadow.Spread or 0

	if not self.NoDraw then
		if (self.DrawShadow and spr>0.01) or self.AlwaysDrawShadow then 
			BSHADOWS.BeginShadow()
			x, y = self:LocalToScreen(0,0)
		end

		local label = self.Label or nil

		local w2, h2 = w, h 
		local x2, y2 = x, y

		if self.Border then 
			dRB(rad, x, y, w, h, self.borderColor or self.Color or Color(255,0,0), self.RBEx)
			local bw, bh = self.Border.w or 2, self.Border.h or 2
			w2, h2 = w - bw*2, h - bh*2
			x2, y2 = x + bw, y + bh
		end

		dRB(rad, x2, y2, w2, h2, self.drawColor or self.Color or Color(255,0,0), self.RBEx)


		

		if (self.DrawShadow and spr>0.01) or self.AlwaysDrawShadow then 
			local int = shadow.Intensity
			local blur = shadow.Blur

			if self.AlwaysDrawShadow then
				int = 3
				spr = 1
				blur = 1
			end

			BSHADOWS.EndShadow(int, spr, blur or 2, self.Shadow.Alpha, self.Shadow.Dir, self.Shadow.Distance, nil, self.Shadow.Color)
		end

		
		

		if label then 
			local label = tostring(label)
			if label:find("\n") then
				draw.DrawText(label, self.Font, self.TextX or w/2, self.TextY or h/2, self.LabelColor,  self.TextAX or 1)
			else
				draw.SimpleText(label,self.Font, self.TextX or w/2, self.TextY or h/2, self.LabelColor, self.TextAX or 1,  self.TextAY or 1)
			end
		end
	end

end

function button:PostPaint(w,h)

end

function button:PrePaint(w,h)

end
function button:PaintOver(w, h)
	if self.Dim then 
		draw.RoundedBox(self.RBRadius, 0, 0, w, h, Color(30, 30, 30, 180))
	end
end
function button:Paint(w, h)
	self:PrePaint(w,h)
	self:Draw(w, h)
	self:PostPaint(w,h)
end

vgui.Register("FButton", button, "DButton")



--[[-------------------------------------------------------------------------
-- 	TabbedPanel/Frame

	TabbedPanel:AddTab(name, onopen, onclose)
	TabbedPanel:SelectTab(name)
	TabbedPanel:GetWorkSize()
	TabbedPanel:GetWorkY()
	TabbedPanel:AlignPanel(pnl)

---------------------------------------------------------------------------]]

local TabbedPanel = {}

function TabbedPanel:Init()

	self.ActiveTab = ""
	self.OpenTabs = {}
	self.CloseTabs = {}
	self.TabColor = Color(54, 54, 54)
	self.TabFont = "OS24"
	self.Tabs = {}
	self:DockPadding(4, 30 + self.HeaderSize, 4, 4)
end

function TabbedPanel:AddTab(name, onopen, onclose)

	local tab = vgui.Create("DButton", self)

	self.Tabs[name] = tab

	local i = (self.Tabs and table.Count(self.Tabs)+1) or 1

	surface.SetFont(self.TabFont)
	local tx, ty = surface.GetTextSize(name or "")
	local x = (self.TabX or 0)

	tab:SetPos(x, 32)
	tab:SetSize(tx+24, 26)
	tab:SetText("")

	self.TabX = x + tx + 24

	self.OpenTabs[name] = onopen
	self.CloseTabs[name] = onclose
	tab.Col = Color(255, 255, 255)
	tab.GCol = Color(255, 255, 255)
	tab.Hov = 0
	function tab.Paint(me,w,h)
		me.Col = LC(me.Col, (self.ActiveTab == name and Color(70, 170, 255) ) or color_white, 15)
		draw.SimpleText(name, self.TabFont, w/2, h/2 - 1, me.Col, 1, 1)

		if me:IsHovered() then 
			me.Hov = L(me.Hov, 35, 15)
		else 
			me.Hov = L(me.Hov, 0, 15)
		end 
		if me.Hov > 1 then 
			surface.SetDrawColor(Color(255, 255, 255, me.Hov))
			self:DrawGradientBorder(w, h, 2, 3)
		end
	end

	function tab.DoClick()
		local curtab = self.ActiveTab
		if curtab==name then return end
		if isfunction(self.OpenTabs[name]) then 

			if curtab~="" and isfunction(self.CloseTabs[curtab]) then 	--if there was a tab open and close func is valid

				self.CloseTabs[curtab](self.OpenTabs[name])				--do that
			end 

			self.OpenTabs[name]()	--otherwise just run the open func

		end

		self.WentFrom = (self.Tabs[curtab] and self.Tabs[curtab].X) or 0
		self.ActiveTab = name

	end

	self:DockPadding(4, 30 + self.HeaderSize, 4, 4)
end

function TabbedPanel:SelectTab(name, dontanim)
	if not self.Tabs[name] then error("Tried opening a non-existent tab!") return end 
	self.OpenTabs[name]()
	self.ActiveTab = name
	if not dontanim then
		self.Tabs[name].SelW = self.Tabs[name]:GetWide()+20
	end

end

function TabbedPanel:GetWorkSize()
	local w,h = self:GetSize()
	return w, h - 26 - self.HeaderSize
end

function TabbedPanel:GetWorkY()
	return 26+self.HeaderSize
end

function TabbedPanel:AlignPanel(pnl)
	pnl:SetSize(self:GetWorkSize())
	pnl:SetPos(0, self:GetWorkY())
end

function TabbedPanel:Paint(w,h)
	self:DrawHeaderPanel(w, h)

	surface.SetDrawColor(self.TabColor)
	surface.DrawRect(0, self.HeaderSize, w, 26)

	local sel = self.Tabs[self.ActiveTab]
	if not sel then return end 
	
	local x, tw = sel.X, sel:GetWide()

	local dist = math.max(self.SelX or 0, x) - math.min(self.SelX or 0, x)
	
	local origdist = math.max(self.WentFrom or 0, self.SelX or 0) - math.min(self.WentFrom or 0, self.SelX or 0)

	local far = dist/origdist > 0.6

	self.SelW = L(self.SelW, (far and tw*0.8) or tw, 15, true)

	self.SelX = L(self.SelX, x, 15)

	surface.SetDrawColor(40, 140, 220)
	surface.DrawRect(self.SelX, self.HeaderSize + 23, self.SelW, 3)

end
vgui.Register("TabbedFrame", TabbedPanel, "FFrame")
vgui.Register("TabbedPanel", BLANK, "TabbedFrame")

local InvisPanel = {}
InvisPanel.Paint = function() end --shh


vgui.Register("InvisPanel", InvisPanel, "EditablePanel") --08.05 : changed from DPanel to EditablePanel
vgui.Register("InvisFrame", InvisPanel, "EditablePanel")

local FakePanel = {}
function FakePanel:Paint(w, h)

end

vgui.Register("FakeFrame", FakePanel, "DFrame")

--[[-------------------------------------------------------------------------
--  FScrollPanel
---------------------------------------------------------------------------]]

local FScrollPanel = {}

function FScrollPanel:Init()
	local scroll = self.VBar


	function scroll:Paint(w,h)
		draw.RoundedBox(4,0,0,w,h,Color(30,30,30))
		if self.ToWheel ~= 0 then 

			local wheel = L(self.ToWheel, 0, 25)
			self:OnMouseWheeled( wheel )
			self.ToWheel = wheel

		end
	end

	scroll:SetWide(10)

	local grip = scroll.btnGrip
	local up = scroll.btnUp 
	local down = scroll.btnDown

	function grip:Paint(w,h)
		draw.RoundedBox(4,0,0,w,h,Color(60,60,60))
	end

	function up:Paint(w,h)
		draw.RoundedBoxEx(4, 0, 0, w, h, Color(80,80,80), true, true)
	end

	function down:Paint(w,h)
		draw.RoundedBoxEx(4, 0, 0, w, h, Color(80,80,80), false, false, true, true)
	end
 	
 	self.Shadow = false --if used as a stand-alone panel 

	self.GradBorder = false 

	self.BorderColor = Color(20, 20, 20)
	self.RBRadius = 0

	self.BorderTH = 4
	self.BorderBH = 4
	self.BorderL = 4 
	self.BorderR = 4

	self.BorderW = 6

	self.Expand = false
	self.ExpandTH = 0
	self.ExpandBH = 0

	self.ExpandW = 6

	self.BackgroundColor = Color(40, 40, 40)
	self.ScrollPower = 1
end


function FScrollPanel:Draw(w, h)
	local ebh, eth = 0, 0

	local expw = 0
	local x, y = 0, 0

	if self.Shadow then 
		BSHADOWS.BeginShadow()
		x, y = self:LocalToScreen(0, 0)
	end

	if self.Expand then 
		expw, ebh, eth = self.ExpandW, self.ExpandBH, self.ExpandTH

		surface.DisableClipping(true)
	end

	draw.RoundedBox(self.RBRadius or 0, x - expw, y - eth, w + expw*2, h + ebh*2, self.BackgroundColor)

	if self.Expand then 
		surface.DisableClipping(false)
	end
	
	if self.Shadow then 

		local int = 2
		local spr = 2 
		local blur = 2 
		local alpha = 255
		local color

		if istable(self.Shadow) then
			int = self.Shadow.intensity or 2
			spr = self.Shadow.spread or 2
			blur = self.Shadow.blur or 2
			alpha = self.Shadow.alpha or self.Shadow.opacity or 255
			color = self.Shadow.color or nil
		end

		BSHADOWS.EndShadow(int, spr, blur, alpha, nil, nil, nil, color)
	end
	
end

function FScrollPanel:PostPaint(w, h)
end

function FScrollPanel:PrePaint(w, h)
end

function FScrollPanel:Paint(w, h)
	self:PrePaint(w, h)
	self:Draw(w,h)
	self:PostPaint(w, h)
end

function FScrollPanel:PaintOver(w,h) 
	if not self.GradBorder then return end 

	local ebh, eth = self.ExpandBH, self.ExpandTH

	local bth, bbh = self.BorderTH, self.BorderBH
	local bl, br = self.BorderL, self.BorderR

	local expw = self.ExpandW

	surface.DisableClipping(true)

		surface.SetDrawColor(self.BorderColor)
		
		surface.SetMaterial(gu)
		surface.DrawTexturedRect(0, -eth, w, self.BorderTH)

		surface.SetMaterial(gd)
		surface.DrawTexturedRect(0, h - self.BorderBH + ebh, w, self.BorderBH)

		surface.SetMaterial(gr)
		surface.DrawTexturedRect(w - self.BorderR, 0, self.BorderR, h)

		surface.SetMaterial(gl)
		surface.DrawTexturedRect(0, 0, self.BorderL, h)

	surface.DisableClipping(false)


end
function FScrollPanel:OnMouseWheeled( dlta )
	local scroll = self.VBar
	scroll.ToWheel = (scroll.ToWheel or 0) + (dlta / 2 * self.ScrollPower)

end

vgui.Register("FScrollPanel", FScrollPanel, "DScrollPanel")

--[[-------------------------------------------------------------------------
--  FCheckBox
---------------------------------------------------------------------------]]

local CB = {}

function CB:Init()
	self.Color = Color(35, 35, 35)
	self.CheckedColor = Color(55, 160, 255)
	self.Font = "TWB24"
	self.DescriptionFont = "TW24"
	self:SetSize(32, 32)
	self.DescPanel = nil
end

function CB:SetLabel(txt)

	self.Label = txt

end

function CB:Paint(w,h)

	local ch = self:GetChecked()
	draw.RoundedBox(4, 0, 0, w, h, self.Color)

	if ch then 
		draw.RoundedBox(4, 4, 4, w-8, h-8, self.CheckedColor)
	end
	surface.DisableClipping(true)
		if self.Label then 
			draw.DrawText(self.Label, self.Font, 36, 2, color_white, 0, 1)
		end
	surface.DisableClipping(false)

	local chX, chY = self:LocalToScreen(0, 0)

	if self:IsHovered() and self.Description and not IsValid(self.DescPanel) then 
		local d = vgui.Create("InvisPanel", self)
		d:SetSize(32, 32)
		d:SetPos(0, h-1)
		d:SetAlpha(0)
		d:SetMouseInputEnabled(false)

		surface.SetFont(self.DescriptionFont)
		local tX, tY = surface.GetTextSize(self.Description)
		local cw = math.max(100, tX+12)
		local ch = tY+8

		d:MoveTo(0, 0, 0.2, 0, 0.7)
		d:AlphaTo(255,0.2, 0)

		function d.Paint(me, w,h)

			if not IsValid(self) then me:Remove() return end
			surface.DisableClipping(true)


				draw.RoundedBox(4, -cw/2 + w/2, -40, cw, ch, Color(25, 25, 25))
				draw.SimpleText(self.Description, self.DescriptionFont, w/2, ch/2 - 40, ColorAlpha(color_white, me:GetAlpha()*0.7), 1, 1)


			surface.DisableClipping(false)
		end
		self.DescPanel = d
	elseif IsValid(self.DescPanel) and not self:IsHovered() then 
		self.DescPanel:MoveTo(0, 32, 0.2, 0, 0.7, function(tbl, self) if IsValid(self) then self:Remove() end end)
		self.DescPanel:AlphaTo(0,0.1, 0,function(tbl, self) if IsValid(self) then self:Remove() end end)
	end
end
function CB:Changed(var)

end
function CB:OnChange(var)
	if self.Sound then 
		local snd = self.Sound[var] or self.Sound[tonumber(var)] or (isstring(self.Sound) and self.Sound) or ""
		if snd~="" and isstring(snd) then 
			surface.PlaySound(snd)
		end
	end
	self:Changed(var)
end

vgui.Register("FCheckBox", CB, "DCheckBox")

--[[-------------------------------------------------------------------------
--  FTextEntry
---------------------------------------------------------------------------]]

local TE = {}

function TE:Init()
	--self:SetPlaceholderText("Some text")
	self:SetSize(256, 36)
	self:SetFont("A24")
	self:SetEditable(true)
	self:SetKeyBoardInputEnabled(true)
	self:AllowInput(true)

	self.BGColor = Color(40, 40, 40)
	self.TextColor = Color(255, 255, 255)
	self.HTextColor = Color(255, 255, 255)
	self.CursorColor = Color(255, 255, 255)

	self.RBRadius = 6

	self.GradBorder = true 

end

function TE:SetColor(col)

	if not IsColor(col) then error('FTextEntry: SetColor arg must be a color!') return end
	self.BGColor = col

end

function TE:SetTextColor(col)

	if not IsColor(col) then error('FTextEntry: SetTextcolor must be a color!') return end
	self.TextColor = col

end
function TE:SetHighlightedColor(col)

	if not IsColor(col) then error('FTextEntry: SetHighlightedColor must be a color!') return end
	self.HTextColor = col

end
function TE:SetCursorColor(col)

	if not IsColor(col) then error('FTextEntry: SetCursorColor must be a color!') return end
	self.CursorColor = col

end

function TE:Paint(w,h)

	surface.DisableClipping(false)

	if self.Ex then 
		local e = self.Ex
		draw.RoundedBoxEx(self.RBRadius, 0, 0, w, h, self.BGColor, e.tl, e.tr, e.bl, e.br)
	else
		draw.RoundedBox(self.RBRadius, 0, 0, w, h, self.BGColor)
	end

	if self.GradBorder then 
		surface.SetDrawColor(Color(10, 10, 10, 180))
		self:DrawGradientBorder(w, h, 3, 3)
	end 

	self:DrawTextEntryText(self.TextColor, self.HTextColor, self.CursorColor)

	if self:GetPlaceholderText() and #self:GetText() == 0 then 
		draw.SimpleText(self:GetPlaceholderText(), self:GetFont(), 4, h/2, ColorAlpha(self.TextColor, 75), 0, 1)
	end

end
function TE:AllowInput(val)
	if self.MaxChars and self.MaxChars~=0 and #self:GetValue() > self.MaxChars then return true end

end
function TE:SetMaxChars(num)
	self.MaxChars = num 
end
vgui.Register("FTextEntry", TE, "DTextEntry") 


--[[-------------------------------------------------------------------------
	Combo Box
---------------------------------------------------------------------------]]
local FCB = {}

function FCB:Init()
	self:SetSize(160, 24)
	self.Color = Color(50, 50, 50)

	self.Options = {}

	self:SetValue("")
	self.Font = "TWB24"
	self.OptionsFont = "TW24"
	self.OnCreateFuncs = {}
	self.Text = "self.Text = ???"

end

function FCB:SetDefaultValue(num)
	self:ChooseOption(num)
end

function FCB:AddChoice( value, data, select, icon, oncreate )

	local i = table.insert( self.Choices, value )

	if ( data ) then
		self.Data[ i ] = data --this data shit is useless
	end
	
	if ( icon ) then
		self.ChoiceIcons[ i ] = icon
	end

	if ( select ) then

		self:ChooseOption( value, i )

	end

	if oncreate then 

		self.OnCreateFuncs[i] = oncreate

	end

	return i

end

function FCB:OpenMenu( pControlOpener )

	if ( pControlOpener && pControlOpener == self.TextEntry ) then
		return
	end

	if ( #self.Choices == 0 ) then return end


	if ( IsValid( self.Menu ) ) then
		self.Menu:Remove()
		self.Menu = nil
	end

	self.Menu = vgui.Create("FMenu", self)
	local m = self.Menu 
	m:SetAlpha(0)

	if ( self:GetSortItems() ) then
		local sorted = {}

		for k, v in pairs( self.Choices ) do
			local val = tostring( v )
			if ( string.len( val ) > 1 && !tonumber( val ) && val:StartWith( "#" ) ) then val = language.GetPhrase( val:sub( 2 ) ) end
			table.insert( sorted, { id = k, data = v, label = val } )
		end

		for k, v in SortedPairsByMemberValue( sorted, "label" ) do
			local option = self.Menu:AddOption( v.data, function() self:ChooseOption( v.data, v.id ) end )
			option.DesHeight = 32
			if ( self.ChoiceIcons[ v.id ] ) then
				option.Icon = self.ChoiceIcons[ v.id ] 
				option.IconW = 24
				option.IconH = 24
				option.IconPad = 10
				option.Font = "TW24"
			end

			if self.OnCreateFuncs[v.id] then 

				self.OnCreateFuncs[v.id](self, option)
			
			end

		end
	else
		for k, v in pairs( self.Choices ) do
			local option = self.Menu:AddOption( v, function() self:ChooseOption( v, k ) end )
			if ( self.ChoiceIcons[ k ] ) then
				option.Icon =  self.ChoiceIcons[ k ] 
			end
		end
	end

	local x, y = self:LocalToScreen( 0, self:GetTall() )

	--self.Menu:SetMinimumWidth( self:GetWide() )
	m:SetSize(self:GetSize())
	m.Font = self.OptionsFont
	m.WOverride = (self:GetSize())

	local sx, sy = self.Menu:GetSize()

	self.Menu:Open( x, y - sy, nil, self )
	m:SetPos(x, y-8)
	m:MoveTo(x, y, 0.4, 0, 0.3)

	m:AlphaTo(255, 0.1)

end

function FCB:SetColor(col, g, b, a)
	if IsColor(col) then self.Color = col self.drawColor = self.Color return end 
	self.Color = Color(col or 60, g or col or 60, b or col or 60, a or 255)
end

function FCB:Paint(w,h)

	draw.RoundedBox(2, 0, 0, w, h, self.Color)
	local txo = 8

	if self.Icon then 
		surface.SetMaterial(self.Icon)
		local iw, ih = self.IconW or h-4, self.IconH or h-4
		surface.SetDrawColor(Color(255,255,255))
		surface.DrawTexturedRect(2, h/2-ih/2, iw, ih)
		txo = iw + self.IconPad or 8
	end

	--draw.SimpleText(self.Text, self.Font, txo, h/2, Color(255,255,255), 0, 1)
end

vgui.Register("FComboBox", FCB, "DComboBox")

--[[
	Icon

	Icon.Rotation = num
	Icon.Icon = mat
]]
local I = {}

function I:Init(w,h)
	self.Icon = Material("__error")
	self.Rotation = 0
end

function I:Paint(w,h)
	local mat = self.Icon 
	local rot = self.Rotation 
	surface.DrawTexturedRectRotated(w/2,h/2,w,h,self.Rotation)
end

vgui.Register("Icon", I, "InvisPanel")


local testing = true 
if not testing then return end 


if IsValid(TestingFrame) then TestingFrame:Remove() end 

TestingFrame = vgui.Create("FFrame")

local f = TestingFrame
f:SetSize(600, 400)
f:Center()
f:MakePopup()

local b1 = vgui.Create("FButton", f)
b1:SetPos(200, 300 - 64)
b1:SetSize(128, 128)

local b2 = vgui.Create("FButton", f)
b2:SetPos(400, 200 - 64)
b2:SetSize(128, 128)

function b2:Think()
	self:SetPos(200 + math.sin(CurTime()*2)*250, 200 + math.cos(CurTime()*2)*250)
end

b1:SetColor(Color(50, 50, 50, 50))
function b1:PrePaint(w, h)

	local x, y = 0, 0
	local x2, y2 = b2.X - b1.X, b2.Y - b1.Y

	local dx, dy = x2 - x, y2 - y


	local rad = -math.atan2(dy, dx)
	local deg = math.deg(rad)
    
	surface.SetDrawColor(200, 100, 100)
	draw.NoTexture()

	surface.DisableClipping(true)
		draw.RotatedBox(x+64, y+64, x2+64, y2+64, 5)
	surface.DisableClipping(false)
	--surface.DrawPoly(poly)
end