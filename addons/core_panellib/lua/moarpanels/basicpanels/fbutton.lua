--[[-------------------------------------------------------------------------
-- 	FButton
---------------------------------------------------------------------------]]

local RED = Color(255, 0, 0)
local DIM = Color(30, 30, 30, 210)

local button = {}
button.RBRadius = 8

local sharedScaleVec = Vector(1, 1)
local sharedTranslVec = Vector(0, 0)
local mx = Matrix()

ChainAccessor(button, "Font", "Font")
ChainAccessor(button, "Label", "Text") -- yeet


function button:Init()
	self.Color = Colors.Button:Copy()
	self.drawColor = Colors.Button:Copy()
	self.DisabledColor = Colors.Button:Copy()
	-- self.Random = math.random()

	vgui.GetControlTable("DButton").SetText(self, "")
	self:SetFont("OS24")

	self:SetDoubleClickingEnabled(false)
	self.Font = "OS24"
	self.DrawShadow = true
	self.HovMult = 1.2

	self.Shadow = {
		MaxSpread = 0.6,
		Intensity = 2,

		OnHover = true,	--should the internal shadow logic be applied when the button gets hovered?
		HoverSpeed = 0.3,
		UnhoverSpeed = 0.3,

		HoverEase = 0.1,
		UnhoverEase = 0.1
	}

	self.LabelColor = Color(255, 255, 255)
	self.DisabledLabelColor = Color(255, 255, 255, 150)

	self.HoverColor = nil
	self.HoverColorGenerated = nil
	self._Icon = nil
	self.MxScale = 1
end

function button:SetIcon(url, name, w, h, col, rot)
	if IsIcon(url) then self._Icon = url return self._Icon end

	local t = self._Icon or Icon(url, name)
	self._Icon = t

	t:SetSize(w, h)
	if IsColor(col) then t:SetColor(col) end
	t._Rotation = rot

	return t
end

function button:SetColor(col, g, b, a)
	if IsColor(col) then
		self.Color:Set(col)
		if g then 	--if 2nd arg, that means apply now
			self.drawColor = col:Copy()
		end
		return
	end

	local c = self.Color
	c.r = col or 70
	c.g = g or 70
	c.b = b or 70
	c.a = a or 255
end

function button:SetTextColor(col, g, b, a)

	if IsColor(col) then
		self.LabelColor = col
		self.DisabledLabelColor = col:Copy()
		self.DisabledLabelColor.a = 150
		return
	end

	local c = self.LabelColor
	c.r = col or 255
	c.g = g or 255
	c.b = b or 255
	c.a = a or 255

	self.DisabledLabelColor = c:Copy()
	self.DisabledLabelColor.a = 150
end

local b = bench("wtf", 2000)

function button:HoverLogic(dis, w, h)

	local t = self:GetTable()
	local shadow = t.Shadow

	if self:IsDown() then
		local min = math.max(w, h)
		local scaleFrac = math.min(6, min * 0.12) / min -- minimum between 12% and 6px
		self:To("MxScale", t.MxScaleDown or (1 - scaleFrac), 0.05, 0, 0.2)
	elseif self.MxScale ~= 1 then
		self:To("MxScale", 1, 0.1, 0, 0.3)
	end

	if (self:IsHovered() or t.ForceHovered) and not dis then

		hov = true
		local hm = t.HovMult

		local bg = t.Color

		local fr = math.min(bg.r*hm, 255)
		local fg = math.min(bg.g*hm, 255)
		local fb = math.min(bg.b*hm, 255)


		local hovcol = t.HoverColor or Color(fr, fg, fb)
		local hovGen = t.HoverColorGenerated

		t.HoverColor = hovcol


		if hovGen ~= bg then
			t.HoverColor:Set(fr, fg, fb)
			if hovGen then
				hovGen:Set(bg:Unpack())
			else
				t.HoverColorGenerated = t.Color:Copy()
			end
		end

		LC(t.drawColor, t.HoverColor, 10) --this just looks better, idfk
		--self:LerpColor(self.drawColor, self.HoverColor, 1.1, 0, 0.2)

		if shadow.OnHover then
			local spr = shadow.MaxSpread
			self:MemberLerp(shadow, "Spread", spr, shadow.HoverSpeed, 0, shadow.HoverEase)
		end

		if not self._IsHovered then
			t._IsHovered = true
			self:OnHover()
		end

		self:ThinkHovered()
	else

		local bg = dis and t.DisabledColor or t.Color

		--self:LerpColor(self.drawColor, bg, 0.4, 0, 0.8)
		LC(t.drawColor, bg)

		if shadow.OnHover and shadow.Spread ~= 0 then
			self:MemberLerp(shadow, "Spread", 0, shadow.UnhoverSpeed, 0, shadow.UnhoverEase)
		end

		if t._IsHovered then
			t._IsHovered = false
			self:OnUnhover()
		end
	end

end

function button:SetLabel(txt)
	self.Label = txt
end

function button:ThinkHovered()

end

function button:OnHover()

end

function button:OnUnhover()

end

local function dRB(rad, x, y, w, h, dc, ex)

	if ex then
		local r = ex

		local tl = (r.tl == nil and true) or r.tl
		local tr = (r.tr == nil and true) or r.tr

		local bl = (r.bl == nil and true) or r.bl
		local br = (r.br == nil and true) or r.br

		draw.RoundedBoxEx(rad, x, y, w, h, dc, tl, tr, bl, br)
	else
		draw.RoundedBox(rad, x, y, w, h, dc)
	end

end

-- draw the background
function button:DrawButton(x, y, w, h)
	local rad = self.RBRadius

	local bg = self.drawColor or self.Color or RED

	local rbinfo = self.RBEx
	-- bg.a = 255 - math.abs(math.sin(CurTime()) * 250)

	local w2, h2 = w, h
	local x2, y2 = x, y

	if self.Border then
		local bordercol = self.Border.col or self.BorderColor or RED
		local bw, bh = self.Border.w or 2, self.Border.h or 2
		if bw > 0 or bh > 0 then
			dRB(rad, x, y, w, h, bordercol, rbinfo)

			w2, h2 = w - bw*2, h - bh*2
			x2, y2 = x + bw, y + bh
		end
	end

	dRB(rad, x2, y2, w2, h2, bg, rbinfo)

end

--draw the text on the button
function button:DrawLabel(x, y, w, h, label)

end

function button:PaintIcon(x, y)
	if not IsIcon(self._Icon) then return end

	local ic = self._Icon

	local iW, iH = ic:GetSize()

	local lblCol = self:GetDisabled() and self.DisabledLabelColor or self.LabelColor

	local col = ic.IconColor or lblCol or color_white
	surface.SetDrawColor(col.r, col.g, col.b, col.a)
	local xoff = (self.Label and 1) or 0.5

	local iX = x
	local iY = y


	ic:Paint(iX, iY, iW, iH, ic._Rotation)


	--[[
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)

		if ic.IconMat then
			surface.SetMaterial(ic.IconMat)
			surface.DrawTexturedRect(iX, iY, iW, iH)
		elseif ic.IconURL then
			surface.DrawMaterial(ic.IconURL, ic.IconName, iX, iY, iW, iH, ic.IconRotation)
		end

	render.PopFilterMin()
	]]

end

local AYToTextY = {
	[0] = 4,
	[1] = 1,
	[2] = 5
}
--mostly shadow logic and caller for Draw* functions

function button:Draw(w, h)
	local t = self:GetTable()

	local shadow = t.Shadow
	local disabled = self:GetDisabled()

	local x, y = 0, 0

	self:HoverLogic(disabled, w, h)

	local spr = shadow.Spread or 0
	local label = t.Label or nil
	-- spr = self.Random > 0.5 and 1 or spr

	if not t.NoDraw then

		if (t.DrawShadow and spr > 0) or t.AlwaysDrawShadow then
			BSHADOWS.BeginShadow()
			x, y = self:LocalToScreen(0, 0)

			if t.ActiveMatrix then
				cam.PushModelMatrix(t.ActiveMatrix, true)
			end

		end

			self:DrawButton(x, y, w, h)

		if (t.DrawShadow and spr > 0) or t.AlwaysDrawShadow then
			local int = shadow.Intensity
			local blur = shadow.Blur
			local a = shadow.Alpha or math.min(self:GetAlpha(),
				self.drawColor and self.drawColor.a or 255,
				self.Color.a)

			if t.AlwaysDrawShadow then
				--int = 3
				spr = math.max(shadow.MinSpread or 0.3, spr)
				--blur = 1
			end

			if t.MxScale < 1 then
				spr = spr * (1 / t.MxScale ^ 6)
			end
			if spr < 0.2 then
				a = a * (spr / 0.2)
			end

			if t.ActiveMatrix then
				cam.PopModelMatrix()
			end

			BSHADOWS.EndShadow(int, spr, blur or 2, a, shadow.Dir, shadow.Distance, nil, shadow.Color, shadow.Color2)


		end

	end

	local ic = t._Icon
	local iW, iH = 0, 0

	if ic then
		iW, iH = ic:GetSize()
	end

	if not t.NoDrawText and label then

		label = tostring(label)

		local tx = t.TextX or w / 2
		local ty = t.TextY or h / 2

		local ax = t.TextAX or 1
		local ay = t.TextAY or 1

		local lblCol = disabled and t.DisabledLabelColor or t.LabelColor
		local newlines = amtNewlines(label)

		local iconX = ic and (ic.IconX or 4) or 0

		self:PreLabelPaint(w, h)

		if newlines > 0 then
			surface.SetFont(t.Font)
			surface.SetTextColor(lblCol:Unpack())

			local lines = newlines + 1
			local lH, lY

			local tWMax = 0

			for s, num in eachNewline(label) do
				s = s:gsub("^%s+", "")
				local tW, tH = surface.GetTextSize(s)
				tWMax = math.max(tWMax, tW)
				tH = t.TextHeight or tH

				if not lH then
					lH = tH * lines
					lY = ty - lH * (ay / 2)
				end

				surface.SetTextPos(tx - tW * (ax / 2) + (iW + iconX) / 2, lY + tH * (num - 1))
				surface.DrawText(s)
			end

			local iX = math.Round(tx - (iW + iconX) / 2 - tWMax * (ax / 2))
			local iY = math.Round(lY + lH / 2 - iH / 2)

			--White()
			--surface.DrawOutlinedRect(iX, iY, tWMax + iW + iconX, 32)

			t.PaintIcon(self, iX, iY)
			--local tw = draw.DrawText(label, self.Font, tx, ty, lblCol, ax)
		else

			surface.SetFont(t.Font)
			local tW, tH = surface.GetTextSize(label)

			local fullW = iW + iconX + tW

			local iX = math.Round(tx - tW * (ax / 2) - (iW + iconX) / 2)
			local iY = math.Round(ty - iH * (ay / 2))

			t.PaintIcon(self, iX, iY)

			local tX = math.Round(iX + iconX + iW)
			local tY = math.Round(ty - tH * (ay / 2))

			surface.SetTextPos(tX, tY)
			surface.SetTextColor(lblCol:Unpack())
			surface.DrawText(label)
		end
		return
	end

	t.PaintIcon(self, w/2 - iW / 2, h/2 - iH / 2)
end

function button:PostPaint(w, h)

end

function button:PrePaint(w, h)

end

function button:PreLabelPaint(w, h)

end

function button:GetMatrixScale()
	return self.MxScale
end

fbuttonLeakingMatrices = 0	--failsafe
fbuttonMatrices = {}

local function popMatrix(self, w, h)
	local scale = self.MxScale

	if scale ~= 1 and self.ActiveMatrix then
		cam.PopModelMatrix()
		self.ActiveMatrix = nil
		mx:Reset()

		fbuttonLeakingMatrices = fbuttonLeakingMatrices - 1
		fbuttonMatrices[self] = nil
		draw.DisableFilters(true)
	end
end

function button:ApplyMatrix()
	if self.ActiveMatrix then
		cam.PushModelMatrix(self.ActiveMatrix, true)
	end
end

function button:PopMatrix()
	if self.ActiveMatrix then
		cam.PopModelMatrix()
	end
end


function button:PaintOver(w, h)
	if self.Dim then
		draw.RoundedBox(self.RBRadius, 0, 0, w, h, DIM)
	end

	popMatrix(self, w, h)
end

function button:OnRemove()
	popMatrix(self, w, h)
end

function button:Paint(w, h)
	local scale = self.MxScale

	if scale ~= 1 then
		sharedScaleVec[1] = scale
		sharedScaleVec[2] = scale

		local xf, yf = self.MxScaleCenterX or w / 2, self.MxScaleCenterY or h / 2
		local x, y = self:LocalToScreen(xf, yf)

		sharedTranslVec[1], sharedTranslVec[2] = x, y

		mx:Translate(sharedTranslVec)
			mx:SetScale(sharedScaleVec)
		mx:Translate(-sharedTranslVec)
		draw.EnableFilters(true)

		cam.PushModelMatrix(mx, true)

		self.ActiveMatrix = mx
		fbuttonMatrices[self] = mx
		fbuttonLeakingMatrices = fbuttonLeakingMatrices + 1
	end

	self:PrePaint(w,h)
	self:Draw(w, h)
	self:PostPaint(w,h)

	if not self:IsValid() then
		popMatrix(self, w, h) -- yes this can happen
	end
end

vgui.Register("FButton", button, "DButton")


hook.Add("PostRender", "UnleakMatrices", function()
	if fbuttonLeakingMatrices > 0 then
		-- removing an fbutton and leaking a matrix this way is "acceptable" (kinda)
		local num = 0
		local amt = fbuttonLeakingMatrices

		for k,v in pairs(fbuttonMatrices) do
			if not k:IsValid() then
				cam.PopModelMatrix()
				draw.DisableFilters(true)

				amt = amt - 1
				num = num + 1
				fbuttonMatrices[k] = nil
			end
		end

		if num > 0 then
			clLog("MPMatrices", num, "remove before pop")
		end

		for i=1, amt do
			cam.PopModelMatrix()
			draw.DisableFilters(true)
		end

		fbuttonLeakingMatrices = 0

		if amt > 0 then
			clLog("MPMatrices", amt, "errors?")
			errorf("nice matrix leak: leaked %d matrices", amt)
		end
	end
end)