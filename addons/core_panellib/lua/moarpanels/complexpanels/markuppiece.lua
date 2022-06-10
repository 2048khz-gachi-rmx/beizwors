--internal; do not use!

local PANEL = {}

function PANEL:Init()
	self.Elements = {}
	self.Lines = {}			-- [lineNum] = startX
	self.LineWidths = {}	-- [lineNum] = textWidth
	self.LineHeights = {}

	self.DrawQueue = {}
	self.Texts = {}

	self.ActiveTags = {}
	self.ExecutePerChar = {} --table of tags that need to be executed per each character

	self.Buffer = MarkupBuffer(self:GetWide())
		:SetFont("OS24")
		:SetTextColor(color_white)

	self.Buffer:On("Reset", self, function(buf)
		buf:SetTextColor(self.Color)
		buf:SetFont(self.Font)
	end)

	self.Buffer:On("Newline", self, function(buf, y, l)
		self.LineHeights[l] = y
	end)

	self.Font = "OS24"

	self.curX = 0
	self.curY = 0
	self._halign = 0

	self.Selectable = false
	self.Color = color_white:Copy()
	self.IgnoreVisibility = true

	self:SetName("Markup Piece")
end

function PANEL:GetCurPos()

end

function PANEL:SetColor(col, g, b, a)
	if IsColor(col) then
		self.Color = col
		return
	end

	local c = self.Color
	c.r = col or 70
	c.g = g or 70
	c.b = b or 70
	c.a = a or 255
end

function PANEL:SetSelectable(b)
	self.Selectable = b
end

function PANEL:RecacheBounds()
	if self.IgnoreVisibility then return end

	local par = self:GetParent()
	local miny = select(2, par:LocalToScreen(0, 0))
	local maxy = miny + par:GetTall()

	par = par:GetParent()
	while par and par:IsValid() do
		if par.IsCloud then self.IgnoreVisibility = true return end -- fuck you

		local par_miny = select(2, par:LocalToScreen(0, 0))
		local par_maxy = par_miny + par:GetTall()

		miny = math.max(miny, par_miny)
		maxy = math.min(maxy, par_maxy)

		par = par:GetParent()
	end

	self._LastRecache = SysTime()

	local _, lminy = self:ScreenToLocal(0, miny)
	local _, lmaxy = self:ScreenToLocal(0, maxy)

	self._Bounds = {lminy, lmaxy}
end

function PANEL:RecacheBounds_Often(timed)
	--[[if timed and (not self._LastRecache or SysTime() - self._LastRecache > 0.2) then
		self:RecacheBounds()
	end]]

	local x, y = self:GetPos()

	if self._BoundLastX ~= x or self._BoundLastY ~= y then
		self._BoundLastX = x
		self._BoundLastY = y
		self:RecacheBounds()
	end
end

function PANEL:IsTextVisible(text)
	if self.IgnoreVisibility then return true end
	if not self._Bounds then self:RecacheBounds() end

	local ty = text.y

	if ty > self._Bounds[2] or ty + text.h < self._Bounds[1] then
		--self:RecacheBounds_Often(true)
		return false
	end

	return true
end

function PANEL:CalculateTextSize(dat)
	return self.Buffer:WrapText(dat.text,
		self.AllowedWidth or self:GetWide(),
		dat.font or self.Font,
		dat.WrapData)
end

function PANEL:_GetDatSize(str, dat)
	local wd = dat.WrapData
	local tw, th = surface.GetTextSize(str)
	if wd and wd.ScaleW then tw = tw * wd.ScaleW end
	if wd and wd.ScaleH then th = th * wd.ScaleH end

	return tw, th
end

function PANEL:SetAlignment(al)
	self.Buffer:SetAlignment(al)
end

function PANEL:GetAlignment(al)
	return self.Buffer:GetAlignment()
end

function PANEL:SetHAlignment(al) -- experimental
	self._halign = al
end

function PANEL:Recalculate()
	table.Empty(self.DrawQueue)
	table.Empty(self.Texts)

	local maxH = 0 --self:GetTall() - 1
	local buf = self.Buffer

	--maxH = buf.y + buf:GetTextHeight()

	buf:Reset()

	local res = self:Emit("ShouldRecalculateHeight", buf)
	if res ~= nil then return end

	surface.SetFont(self.Font)
	local ownWide = self:GetWide()
	buf.width = ownWide
	local curLineWidth = 0
	local curLine = 1
	local align = self:GetAlignment()

	local maxX = 0

	for k,v in ipairs(self.Elements) do

		if v.isText then
			local off = v.offset or 0

			buf.x = buf.x + off

			-- im not sure this is supposed to happen?
			if buf.x > ownWide then
				buf.x = 0
				buf.y = buf.y + buf:GetTextHeight()
			end

			local curX, curY = buf.x, buf.y
			local wrapped, tw, th, times = self:CalculateTextSize(v)

			local t = table.ShallowCopy(v)
			t.text = wrapped
			t.segments = {}

			local wm = v.WrapData and v.WrapData.ScaleW or 1

			t.x, t.y = curX, curY
			t.endX, t.endY = buf.x, buf.y

			maxX = math.max(maxX, curX + tw)

			t.w, t.h = tw, th
			t.line = curLine

			local segs = t.segments
			v.drawInfo = t

			local iter = 0

			for s, line in eachNewline(wrapped) do
				iter = iter + 1
				local tw, th = self:_GetDatSize(s, v)

				if line > 1 then
					self.Lines[curLine] = ownWide * (align / 2) - curLineWidth * (align / 2)
					self.LineWidths[curLine] = curLineWidth
					curLine = curLine + 1
					curLineWidth = 0
					buf.x = tw
				end

				curLineWidth = curLineWidth + tw

				segs[#segs + 1] = {
					w = tw,
					h = th + 1,

					x = (line == 1 and curX) or 0,
					y = curY + (line - 1) * th,
					line = curLine,

					text = s,

					-- used for selection logic
					sizes = surface.CharSizes(s, self.Font, true),
					selStart = nil, selEnd = nil
				}

			end

			-- edge case: newline we haven't iterated over
			-- (probably because there's no text after it)
			-- carry line

			if iter < amtNewlines(wrapped) + 1 then
				self.Lines[curLine] = ownWide * (align / 2) - curLineWidth * (align / 2)
				self.LineWidths[curLine] = curLineWidth
				curLine = curLine + 1
				curLineWidth = 0
				buf.x = tw
			end

			maxH = math.max(maxH, t.y + t.h)
			self.DrawQueue[#self.DrawQueue + 1] = t
			self.Texts[#self.Texts + 1] = t
		elseif ispanel(v) then
			--unimplemented; untested

			self:CalculatePanelSize(v)

			self.DrawQueue[#self.DrawQueue + 1] = {
				markupExec = function(self, buf)
					if not IsValid(v) then return end
					buf:Offset(v:GetSize())
				end
			}

		elseif IsTag(v) then
			v:RunModify(buf)
			self.DrawQueue[#self.DrawQueue + 1] = v --no custom handler; just add it
		end

	end

	self.Lines[curLine] = ownWide * (align / 2) - curLineWidth * (align / 2)
	self.LineWidths[curLine] = curLineWidth

	if align > 0 then
		-- second pass; change X of text segments to align with the whole line

		local lastW = 0
		local lastLine = 0

		for k, tx in ipairs(self.Texts) do
			if not tx.isText then continue end

			tx.x = self.Lines[tx.line] + lastW

			for k, seg in ipairs(tx.segments) do
				if lastLine ~= seg.line then
					lastW = 0
					lastLine = seg.line
				end

				seg.x = self.Lines[seg.line] + lastW
				lastW = lastW + seg.w
			end

			tx.endX = self.Lines[lastLine] + lastW
		end
	end

	local res = self:Emit("RecalculateHeight", buf, maxH)
	if res ~= nil and not isnumber(res) then
		if res == false then
			self:GetParent():SetTall(math.max(self:GetParent():GetTall(), (res or maxH) + 1))
		end

		return
	end

	res = res or maxH

	self:SetTall(res + 1)
	self:GetParent():SetTall(math.max(self:GetParent():GetTall(), res + 1))
end

function PANEL:RewrapWidth(to)
	assert(isnumber(to))
	self.AllowedWidth = math.max(self:GetWide(), to)
	self:Recalculate()
	self.AllowedWidth = nil

	local maxW = 0
	for k,v in ipairs(self.LineWidths) do
		maxW = math.max(maxW, v)
	end

	self:SetWide(maxW)
	self:InvalidateLayout()
	return maxW
end

function PANEL:OnKeyCodePressed(key)

	if input.IsControlDown() and key == KEY_C then
		for k,v in ipairs(self.Pieces) do
			local tx = v:GetSelected()

			if #tx > 0 then
				SetClipboardText(tx)
				break
			end
		end
	end

end

function PANEL:OnMousePressed()
	if not self.Selectable then return end

	self.MouseHeld = true
	local ms = {}
	self.Mouse = ms

	ms.x, ms.y = self:ScreenToLocal(gui.MousePos())

	hook.Once("VGUIMousePressed", self, function(_, pnl, key)
		if pnl ~= self and pnl ~= self:GetParent() then
			self:ResetSelection()
		end
	end)
end

function PANEL:ResetSelection()
	for k, tx in ipairs(self.Texts) do
		for _, v in ipairs(tx.segments) do
			v.selStart = nil
			v.selEnd = nil
		end
	end

	self.SelectedText = nil
end

function PANEL:OnMouseReleased_butlikeactual()
	if not self.Selectable then return end

	self.MouseHeld = false
	self.Mouse = nil

	--[[for k,v in ipairs(self.Texts) do
		for k,v in ipairs(v.segments) do
			v.selStart, v.selEnd = nil, nil
		end
	end]]

end

function PANEL:OnMouseReleased()
	self:OnMouseReleased_butlikeactual()
end

function PANEL:Think()
	if self.MouseHeld then
		if not input.IsMouseDown(MOUSE_LEFT) then
			self:OnMouseReleased_butlikeactual()
			goto emit -- retarded garry
		end

		local mx, my = self:ScreenToLocal(gui.MousePos())
		local sx, sy = self.Mouse.x, self.Mouse.y

		local minx, miny = mx, my
		local maxx, maxy = sx, sy

		local tempx, tempy = maxx, maxy

		maxx, maxy = math.max(maxx, minx), math.max(maxy, miny)
		minx, miny = math.min(tempx, minx), math.min(tempy, miny)

		self.SelectedText = ""

		for _, tx in ipairs(self.Texts) do
			if not self:IsTextVisible(tx) then continue end

			for _, seg in ipairs(tx.segments) do --oh lord

				local x, y, w, h = seg.x, seg.y, seg.w, seg.h
				local szs = seg.sizes

				local in_line = (my >= y and my <= y+h)
				local above_line = my <= y
				local below_line = my >= y+h

				local st_in_line = (sy >= y and sy <= y+h)
				local st_above_line = sy <= y
				local st_below_line = sy >= y+h

				if (above_line and st_below_line) or (below_line and st_above_line) then
					seg.selStart = 0
					seg.selEnd = #seg.text
					self.SelectedText = self.SelectedText .. seg.text
					continue
				elseif (st_above_line and above_line) or (st_below_line and below_line) then
					seg.selStart = nil
					seg.selEnd = nil
					continue
				end

				local selstart, selend

				local cursz = 0

				for i=1, #szs do
					local sz = szs[i]
					cursz = cursz + sz

					if not selstart and (((st_in_line and not in_line and sx) or (not st_in_line and in_line and mx) or minx) < x + cursz - sz/2) then selstart = i end
					if (((st_in_line and not in_line and sx) or (not st_in_line and in_line and mx) or maxx) >= x + cursz - sz/2) then selend = i end

				end

				if st_in_line then
					if above_line then selstart = 0 end
					if below_line then selend = #seg.text end
				end

				if in_line then
					if st_below_line then selend = #seg.text end
					if st_above_line then selstart = 0 end
				end

				if not selend then selstart = nil end

				if selstart and selend then self.SelectedText = self.SelectedText .. seg.text:sub(selstart, selend) end
				seg.selStart = selstart
				seg.selEnd = selend

			end
		end
	end

	::emit::
	self:Emit("Think")
end

function PANEL:GetSelected()
	return self.SelectedText or ""
end

function PANEL:SetFont(font)
	self.Buffer:SetFont(font)
	self.Font = font
end


function PANEL:PaintText(dat, buf, col)
	local h = self.LineHeights[dat.line] or dat.h

	surface.SetTextPos(dat.x, (h - dat.h) * self._halign / 2 + dat.y)
	if col then
		surface.SetTextColor(col)
	end

	if #self.ExecutePerChar > 0 then

		for i=1, #dat.text do
			local char = string.sub(dat.text, i, i)
			for k,v in ipairs(self.ExecutePerChar) do
				self:ExecuteTag(v, buf, char, i)
			end
			surface.DrawText(char)
			for k,v in ipairs(self.ExecutePerChar) do
				if not v.Ended and not v.HasEnder and not v.ender then v:End(buf) end
			end
		end

	else
		surface.DrawText(dat.text)
	end

	if col then
		surface.SetTextColor(buf:GetTextColor():Unpack())
	end

end

function PANEL:ExecuteTag(tag, buf, ...)
	tag:Run(buf, ...)
end

function PANEL:OnKeyCodePressed()

end

function PANEL:_PaintTextElement(w, h, buf, el)
	buf:SetPos(el.x, el.y)
	buf:SetFont(el.font)
	surface.SetFont(buf:GetFont())
	surface.SetTextColor(buf:GetTextColor():Unpack())
	--print("drawing text", el.text)
	--self:PaintText(el, buf)

	for k, seg in ipairs(el.segments) do
		if not self:IsTextVisible(seg) then continue end
		--surface.SetDrawColor(color_white)
		--surface.DrawOutlinedRect(v.x, v.y, v.w, v.h)
		self:PaintText(seg, buf, el.color)

		if seg.selStart then
			surface.SetDrawColor(Colors.Red)
			local sx = seg.x
			for i=1, seg.selStart-1 do
				sx = sx + seg.sizes[i]
			end

			local ex = 0

			for i=seg.selStart, seg.selEnd do
				if not seg.sizes[i] then continue end
				ex = ex + seg.sizes[i]
			end

			surface.DrawOutlinedRect(sx, seg.y, ex, seg.h)
		end
	end

	buf:SetPos(el.endX, el.endY)
end

function PANEL:Paint(w, h)
	self:RecacheBounds_Often()

	draw.EnableFilters()

	local sx, sy = self:LocalToScreen(0, 0)
	render.PushScissorRect(sx, sy, sx + w, sy + h)
	local clip
	if self.IgnoreVisibility then
		clip = DisableClipping(true)
	end

	self:Emit("PrePaint", w, h)
	local buf = self.Buffer
	buf:Reset()
	buf:SetPos(self.Lines[1])

	--draw.RoundedBox(8, 0, 0, w, h, Colors.DarkerRed)

	for k,v in ipairs(self.DrawQueue) do

		if v.isText then
			self:_PaintTextElement(w, h, buf, v)
		elseif IsTag(v) then
			local base = v:GetBaseTag()
			if base and not base.ExecutePerChar then self:ExecuteTag(v, buf) end

			self.ActiveTags[#self.ActiveTags + 1] = v
			if base and base.ExecutePerChar then
				self.ExecutePerChar[#self.ExecutePerChar + 1] = v
			end

		elseif IsColor(v) then
			buf:SetTextColor(v)

		elseif v.markupExec then
			v:markupExec(buf)

		end

	end

	for k,v in ipairs(self.ActiveTags) do
		--end tags so we don't leak shit off to rendering (matrices, next frame rendering, etc.)
		if not v.Ended and not v.HasEnder and not v.ender then v:End(buf) end
	end

	table.Empty(self.ActiveTags)
	table.Empty(self.ExecutePerChar)

	self.LastFont = ""
	self:Emit("PostPaint", w, h)
	if self.IgnoreVisibility then
		DisableClipping(clip)
	end

	draw.DisableFilters()
end

function PANEL:PaintOver()
	--draw.DisableFilters()
	render.PopScissorRect()
end

function PANEL:PerformLayout()
	self:Recalculate()
	self:Emit("Layout")
	self:InvalidateParent(true)	-- i don't know why this is here?
	self:RecacheBounds()
end

function PANEL:AddTag(tag)
	if not IsTag(tag) then error("Tried to add a non-tag to MarkupPiece!") return end
	tag:SetPanel(self)
	self.Elements[#self.Elements + 1] = tag

	self:InvalidateLayout()

	return #self.Elements
end

function PANEL:EndTag(num)
	local tag = self.Elements[num]
	if not num or not tag or not IsTag(tag) then errorf("Tried to end a non-existent tag @ key %s!", num) return end
	local base = tag.GetBaseTag and tag:GetBaseTag()

	if base then

		if not base.ExecutePerChar then

			local ender = tag:GetEnder()
			self.Elements[#self.Elements + 1] = ender
			ender.Ends = num
			tag.HasEnder = true
		else

			self.Elements[#self.Elements + 1] = {markupExec = function()  --hardcode a ExecutePerChar remover for this tag
				for k,v in pairs(self.ExecutePerChar) do
					if v == tag then
						table.remove(self.ExecutePerChar, k)
					end
				end
			end}

		end

	end

end

function PANEL:AddText(tx, offset)
	if not tx or not tostring(tx) then return end

	local t = {
		isText = true,
		text = tx,
		font = self.Font,
		offset = offset,
		segments = {}
	}

	self.Elements[#self.Elements + 1] = t
	self:InvalidateLayout()
	return t
end

function PANEL:AddObject(obj) 					--no guarantees it will work :)
	self.Elements[#self.Elements + 1] = obj		--requires a obj:markupExec(buf) function
	self:InvalidateLayout()
	return self
end

function PANEL:AddPanel(pnl)
	self.Elements[#self.Elements + 1] = pnl
	self:InvalidateLayout()
	return self
end

vgui.Register("MarkupPiece", PANEL, "Panel")