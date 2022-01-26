setfenv(1, _G)
--[[-------------------------------------------------------------------------
--  Pop-up Cloud (It's crappy)

	Cloud:SetLabel(txt)
	Cloud.SetText = Cloud.SetLabel

	Cloud:SetColor(col, g, b, a)
	Cloud:SetTextColor(col, g, b, a)

	Cloud:AddFormattedText(txt, col, font, overy, num, align)	

		--	num: index for tbl(can replace texts);
			overy = y offset for the next text (yes, next, not prev) (leave nil to default)
			align = 1/2 - 1 for mid, 2 for right
	
	Cloud:AddSeparator(col, offx, offy, num)
	Cloud:ClearFormattedText()

	Cloud:SetAbsPos(x, y)
	Cloud:SetRelPos(x, y)

	Cloud:FullInit()
	Cloud:Popup(bool)

	Cloud:Bond(pnl) 	--if the panel is gone, so is the cloud

	Stuff you can modify:

		Cloud.Font
		Cloud.DescFont

		Cloud.Label
		Cloud.HOffset
		Cloud.Speed -- popup speed
		Cloud.Color
		Cloud.TextColor

		Cloud.AlignLabel = 1/2 -- 1 for middle, 2 for right

		Cloud.Middle 	-- 0-1 (or less/more for full zane)

		Cloud.YAlign	-- like text aligns, except the cloud aligns there : 0/1/2
						-- by default it's 2 which means align by bottom (because it's a cloud)

		Cloud.ToX = 0	-- by how much XY cloud will move when it's popped up
		Cloud.ToY = 0	-- use these to make s w e e t pop-in animations

		Cloud.Shadow = {}

		Cloud.Min/MaxW

---------------------------------------------------------------------------]]

local ShadowHandle


local function getShadowHandle()
	if ShadowHandle then return ShadowHandle end

	ShadowHandle = BSHADOWS.GenerateCache("CloudShadow", 256, 256)
	ShadowHandle:SetGenerator(function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, color_white)
	end)

	ShadowHandle:CacheShadow(4, 4, 4)

	return ShadowHandle
end

CLOUDS = CLOUDS or {}

function CLOUDS:RemoveAll()
	for k,v in ipairs(self) do
		if IsValid(v) then v:Remove() end
		self[k] = nil
	end
end

local Cloud = {}

function Cloud:Init()

	self.Font = "OS24"
	self.DescFont = "OSL18"
	self.IsCloud = true

	self:SetSize(2,2)
	self:SetPos(2,2)

	self:SetAlpha(0)
	self.Frac = 0 --don't make it disappear instantly

	self:SetMouseInputEnabled(false)

	self.Label = "No label!"
	self.LabelWidth = 64

	timer.Simple(0, function()
		if not IsValid(self) or self.FullInitted then return end
		self:FullInit()
	end)

	self.HOffset = 0

	self.ToX = 0
	self.ToY = 0

	self.AlignLabel = 1

	self.AppearTime = 0.2
	self.DisappearTime = 0.2

	self.AppearEase = 0.4
	self.DisappearEase = 0.2
	--self.Speed = 25

	self.Color = Color(40, 40, 40)
	self.TextColor = color_white:Copy()
	self:SetDrawOnTop(true)

	self.HOverride = nil

	self.FormattedText = {}
	self.DoneText = {}
	self.LatestKey = nil

	self.Middle = 0.5

	self.YAlign = 2

	self.wwrapped = {}

	self.Separators = {}
	self.SepH = 0

	self.MinW = 0
	self.MaxW = 192

	self._MaxWidth = 0 --internal; the maximum registered width

	self.Shadow = {}
	self.DrawShadow = true

	self.ScreenClamp = true

	CLOUDS[#CLOUDS + 1] = self
end

function Cloud:OnRemove()
	self:Emit("Remove")
end

function Cloud:GetCurWidth()
	return math.min(math.max(self._MaxWidth, self.LabelWidth + 16, self.MinW), self.MaxW)
end

function Cloud:MoveAbove(pnl, px)
	local x, y = pnl:LocalToScreen(pnl:GetWide() / 2, 0)

	self:SetAbsPos(x, y - (px or 8))
end

function Cloud:SetMaxW(w)
	self.MaxW = w
	self:RecalculateLabel()
end

function Cloud:GetMaxW(w)
	return self.MaxW
end

function Cloud:GetPieces()
	return self.DoneText
end

function Cloud:RecalculateLabel()
	if not self.Label then return end

	surface.SetFont(self.Font)
	local origW = (surface.GetTextSize(self.Label))
	local w = origW
	local wrapped = self.Label

	if origW > self.MaxW then -- uh oh time to wordwrap
		wrapped = string.WordWrap2(self.Label, self.MaxW - 16)

		local maxW = 0
		for s, line in eachNewline(wrapped) do
			maxW = math.max(maxW, (surface.GetTextSize(s)))
		end

		w = maxW
	end

	self.wwrapped[self.Label] = wrapped
	self.LabelWidth = w
	self.UnwrappedWidth = origW
end

function Cloud:SetLabel(txt)
	self.Label = tostring(txt)
	self:RecalculateLabel()
end

Cloud.SetText = Cloud.SetLabel

function Cloud:SetColor(col, g, b, a)
	if IsColor(col) then self.Color = col return end
	self.Color = Color(col or 70, g or col or 70, b or col or 70, a or 255)
end

function Cloud:SetTextColor(col, g, b, a)
	if IsColor(col) then self.TextColor = col return end
	self.TextColor = Color(col or 70, g or col or 70, b or col or 70, a or 255)
end

function Cloud:SetFont(font)
	self.Font = font
	self:RecalculateLabel()
end

function Cloud:PostPaint()

end

function Cloud:PrePaint()

end

function Cloud:_DrawSeparator(sep, x, y, w)
	surface.SetDrawColor(sep.col)

	local sx = sep.offx
	local sy = sep.offy
	local preY, postY = sy, sy

	if istable(sy) then
		preY, postY = sy[1], sy[2]
	end

	surface.DrawLine(x + sx, y + preY, x + w - sx, y + preY)
	return preY + postY
end

function Cloud:Paint()

	if not self.FullInitted then return end
	if self.Bonded and (not self.Bonded:IsValid() or not self.Bonded:IsVisible()) then self:Remove() return end

	local prevent = self:PrePaint()
	if prevent == true then return end

	if self:GetAlpha() <= 1 then return end

	if self.LastThink ~= FrameNumber() then
		-- dumb issue where a hidden panel can paint but not think
		self:Think()
		if not self:IsValid() then return end -- could've been removed in those thinks
		self:AnimationThinkInternal()
		if not self:IsValid() then return end
	end

	local cw = math.min(math.max(self._MaxWidth, self.LabelWidth + 16, self.MinW, self:GetWide()), self.MaxW)
	local lab = self.wwrapped[self.Label] or "??"

	surface.SetFont(self.Font)

	local ch = 0

	local tw, th = surface.GetTextSize(lab)

	ch = self.HOverride or th

	local xoff = (self.OffsetX or 4) + self.ToX * self.Frac
	local yoff = (self.OffsetY or 0) + self.ToY * self.Frac

	local finY = 0

	local aY = -math.Clamp(self.YAlign, 0, 2) / 2

	local boxh = ch + 4 + self.SepH

	local lasttext = ""

	local doneText = self.DoneText
	local doneLen = #doneText

	for k = 1, doneLen do
		local v = doneText[k]

		if istable(v) then
			if not v.Continuation then
				lasttext = v.Text
			else
				lasttext = lasttext .. v.Text
			end

			boxh = boxh + v.YOff

			if v.Font then
				surface.SetFont(v.Font)
			else
				surface.SetFont(self.DescFont)
			end

		elseif ispanel(v) then
			boxh = boxh + v:GetTall()
		end

	end

	finY = yoff + boxh * aY

	if self.ScreenClamp then
		local glx, gty = self:ScreenToLocal(4, 4)
		local gby = gty + ScrH() - boxh - 4
		local grx = glx + ScrW() - cw - 8

		xoff = math.Clamp(xoff - cw*self.Middle, glx, grx) + cw*self.Middle
		finY = math.Clamp(yoff + boxh * aY, gty, gby)
	end


	local oldX, oldY = xoff, finY

	local handle = getShadowHandle()

	local am = surface.GetAlphaMultiplier()
	surface.SetAlphaMultiplier(self:GetAlpha() / 255)

	local clip = DisableClipping(true)

		if self.Shadow and self.DrawShadow then
			--BSHADOWS.BeginShadow()
			--xoff, finY = self:LocalToScreen(xoff, finY)
		end

		-- the box of the cloud
		local X = xoff - cw*self.Middle
		local Y = finY

		handle:Paint(X, Y, cw, boxh)
		draw.RoundedBox(4, X, Y, cw, boxh, self.Color)

		if self.Shadow then
			local int = self.Shadow.intensity or 3
			local spr = self.Shadow.spread or 1
			local blur = self.Shadow.blur or 1
			local alpha = self.Shadow.alpha or self.Shadow.opacity or 255
			local color = self.Shadow.color or nil

			--BSHADOWS.EndShadow(int, spr, blur, alpha, 0, 1, nil, color)

			xoff, finY = oldX, oldY

			X = xoff - cw*self.Middle
			Y = finY
		end

		-- draw the label
		local labX = X + 8

		if self.AlignLabel == 1 then
			labX = X + cw / 2
		elseif self.AlignLabel == 2 then
			labX = X + cw - 8
		end

		draw.DrawText(lab, self.Font, labX, Y + 2, self.TextColor, self.AlignLabel)

		local offy = finY + ch + 2

		--[[if self.ScreenClamp then
			offy = math.Clamp(offy, 4, ScrH() - boxh - 4)
		end]]

		-- there's (a) separator(s) at index 0 which means
		-- right after the label, not after a formatted text

		if self.Separators[0] then
			for _, sep in ipairs(self.Separators[0]) do
				local h = self:_DrawSeparator(sep, X, offy, cw)
				offy = offy + h
			end
		end

		-- now draw all the formatted text

		for k = 1, doneLen do--,v in ipairs(self.DoneText) do
			local v = doneText[k]

			if ispanel(v) then
				if not v.NoCloudFit and v:GetWide() ~= cw - v.X * 2 then
					v:SetWide(cw - v.X * 2)
				end
				local scrX, scrY = self:LocalToScreen(X, offy)
				v:PaintAt(scrX + v.X, scrY)
				offy = offy + v:GetTall()
			else

				local font = v.Font or self.DescFont
				local tx = xoff + (v.X or 8) - cw*self.Middle
				-- text first
				if v.Align == 1 then
					tx = X + cw / 2
				elseif v.Align == 2 then
					tx = X + cw - 8
				end

				draw.DrawText(v.Text, font, tx, offy, v.Color, v.Align or 0)

				offy = offy + v.YOff
			end

			-- check if this element had a separator after it
			if self.Separators[k] then
				local seps = self.Separators[k]
				for _, sep in ipairs(seps) do
					local h = self:_DrawSeparator(sep, X, offy, cw)
					offy = offy + h
				end
			end

		end

	DisableClipping(clip)
	surface.SetAlphaMultiplier(am)

	self:PostPaint()
end

function Cloud:AddFormattedText(txt, col, font, overy, num, align) --if you're updating the text, for example, you can use "num" to position it where you want it

	local wid = (self.MaxW or self._MaxWidth or self.MinW)
	local nd = string.WordWrap2(txt, wid, font or self.Font)

	local yo = 0

	surface.SetFont(font or self.DescFont)

	local wid, chary = surface.GetTextSize(nd)
	self._MaxWidth = math.Clamp(wid + 16, math.max(self.MinW, self._MaxWidth), self.MaxW)

	--overy allows you to override the Y offset

	yo = overy or chary

	local key = #self.DoneText + 1
	local tbl

	if num then
		for k,v in pairs(self.DoneText) do
			if v.prio == num then
				key = k
				tbl = v
				break
			end
		end
	end

	tbl = tbl or {}

	tbl.Text = nd
	tbl.Color = col
	tbl.YOff = yo
	tbl.Font = font
	tbl.prio = tonumber(num) or key

	if yo == 0 then --different colors but same string, happens
		tbl.Continuation = true
	end

	tbl.X = 8
	tbl.Align = align

	self.DoneText[key] = tbl

	table.sort(self.DoneText, function(a, b)
		return a.prio < b.prio
	end)

	self.LatestKey = key

	return #self.DoneText, tbl

end

function Cloud:AddSeparator(col, offx, offy, num)
	offx = offx or 4
	offy = offy or 2

	local preY, postY = offy, offy

	if istable(offy) then
		preY, postY = offy[1], offy[2]
	end

	local t = self.Separators[num or #self.DoneText] or {}

	self.Separators[num or #self.DoneText] = t
	t[#t + 1] =  {col = col or Color(70, 70, 70), offx = offx, offy = offy}

	self.SepH = self.SepH + preY + postY
end

function Cloud:ClearFormattedText()
	table.Empty(self.DoneText)
end

function Cloud:AddPanel(p, num)
	p:SetParent(self)
	p:SetPaintedManually(true)
	self._MaxWidth = math.Clamp(p:GetWide() + 16, math.max(self.MinW, self._MaxWidth), self.MaxW)
	p.IgnoreVisibility = true
	p.prio = num or (#self.DoneText + 1)
	self.DoneText[num or (#self.DoneText + 1)] = p

	return p
end

function Cloud:SetAbsPos(x, y)
	-- does not work properly
	print("reminder: Cloud:SetAbsPos does not work properly or something")
	local sx, sy = self:ScreenToLocal(x, y)

	self.OffsetX = sx
	self.OffsetY = sy
end

function Cloud:SetRelPos(x, y)
	local myx, myy = self:GetPos()

	local sx = x and x - myx
	local sy = y and y - myy

	self.OffsetX = sx or self.OffsetX
	self.OffsetY = sy or self.OffsetY

end

function Cloud:Think()
	self.LastThink = FrameNumber()

	if self.Active then
		self:To("Frac", 1, self.AppearTime, 0, self.AppearEase)
		self.Frac = math.max(self.Frac, 0.01) --prevent disappearing for this frame
	else
		self:To("Frac", 0, self.DisappearTime, 0, self.DisappearEase)
	end

	if self.Bonded and not self.Bonded:IsVisible() then
		self:SetAlpha(0)
	end

	if self.Frac == 0 and self.RemoveWhenDone then
		self:Remove()
		return
	end

	self:SetAlpha(self.Frac * 255)
end

function Cloud:FullInit()

	self.FullInitted = true

end

function Cloud:Popup(bool)

	self.Active = (bool == nil and true) or bool

end

function Cloud:Bond--[[age]](pnl)
	self.Bonded = pnl
end

vgui.Register("Cloud", Cloud, "Panel")