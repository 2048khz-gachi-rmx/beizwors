InteractWheel = Animatable:extend()
local wheel = InteractWheel
wheel.Matrix = Matrix()
wheel.Options = {}

local vec = Vector()
wheel.Frac = 0

function wheel:Initialize()
	self.Frac = 0

	self.BlurAmount = 2
	self.Dim = 0.5
end


local requireCertainty = 0.3

-- animation settings:
local wheelAppearTime = 0.2
local wheelDisappearTime = 0.15

-- mouse radius:
local wheelInnerRadius = 12
local wheelOuterRadius = 48

-- options radius:
local optionInnerRadius, optionOuterRadius


local function resize()
	local sw, sh = ScrW(), ScrH()

	-- / 2 because its a radius, not a diameter
	optionInnerRadius = math.min(sw * 0.45 / 2, sh * 0.45 / 2)
	optionOuterRadius = math.min(sw * 0.7 / 2, sh * 0.7 / 2)
end

hook.Add("OnScreenSizeChanged", "InteractWheelResize", resize)
resize()

local unselectedColor = Color(0, 0, 0, 157)
local selectedColor = Color(60, 120, 220, 77)
local arrowColor = Color(250, 250, 250, 180)

local function normalize(x, y)
	local len = math.sqrt(x^2 + y^2)
	return x / len, y / len
end

local function angXY(x, y)
	return math.atan2(y, x)
end

function wheel:_PaintPanel(wheel, w, h)
	-- self = panel
	local fr = wheel.Frac
	surface.SetDrawColor(0, 0, 0, wheel.Dim * 255 * fr)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(0, 0, 0, 255)	-- if no dim was given then drawcolor alpha might be 0, which
										-- will result in no-ops on circle stencils and blur
	draw.ScuffedBlur(self, fr * wheel.BlurAmount, 0, 0, w, h)


	local ang = self.Angle
	local options = wheel.Options

	local mtrx = wheel.Matrix
		mtrx:TranslateNumber(w/2, h/2)
		local scale = 0.3 + fr * 0.7
		mtrx:SetScaleNumber(scale, scale)
		mtrx:TranslateNumber(-w/2, -h/2)

	BSHADOWS.BeginShadow()

	

	render.ClearStencil()
	draw.BeginMask()

	cam.PushModelMatrix(mtrx)

		-- draw the inner circle for the stencil

		self.InnerCircle:Paint(w/2, h/2)

		draw.DrawOp()
		render.SetStencilReferenceValue(1)
		-- draw every option

		for i=1, #options do
			local opt = options[i]
			draw.SetMaterialCircle(optionOuterRadius)
			opt:_Paint(w/2, h/2, w, h, mtrx, self.InnerCircle)
		end

		draw.FinishMask()
				
		-- draw selection arrow

		local origin = self.MouseOrigin
		local cur = self.Panel.CurrentMouse
		local ox, oy = cur[1] - origin[1], cur[2] - origin[2]
		local nx, ny = normalize(ox, oy)

		local certainty = self.OptionPercentage

		local arad = (optionInnerRadius - 16) * (0.8 + (certainty) * 0.2)

		local ax = origin[1] + nx * arad
		local ay = origin[2] + ny * arad

		local aw = 32 * (certainty ^ 0.5)
		local ah = 52 * (certainty ^ 0.2)

		draw.EnableFilters()

			surface.SetDrawColor(arrowColor:Unpack())
			surface.DrawMaterial("https://i.imgur.com/jFHSu7s.png", "arr_right.png", 
				ax, ay, aw, ah, -self.Angle + 90)

		draw.DisableFilters()

	cam.PopModelMatrix(mtrx)

	BSHADOWS.EndShadow(2, 2, 3)

end

function wheel:_OnMousePressed(wheel, mouse)
	local curhov = self._CurHovered
	if curhov then
		for k, opt in ipairs(wheel.Options) do
			if opt ~= curhov then
				opt:_Hide(true)
			end
		end

		curhov:_Select()
		wheel:Hide(0.2)
	end
end

function wheel:_BoundCursor(wheel)
	-- self = panel

	local mx, my = input.GetCursorPos()

	local origin = self.MouseOrigin
	local ox, oy = origin[1], origin[2]

	local cur = self.Panel.CurrentMouse
	local curx, cury = cur[1], cur[2]

	local ocx, ocy = ox - mx, oy - my 	-- off-center mousepos

	local cdist = math.sqrt(ocx^2 + ocy^2)
	

	if cdist <= wheelInnerRadius then
		self.OptionPercentage = 0
	else

		local len = math.sqrt(ocx^2 + ocy^2)

		-- bound the mouse to the outer wheel if necessary

		-- by adding some radius we give wiggling room for diagonal moving
		-- it doesn't hurt to add it since the only reason we're doing this is window bounds
		-- and lets be real, they're probably not running the game @ 128x128
		if cdist > wheelOuterRadius + 8 then
			

			-- normalize XY and multiply by outer radius
			local nmx = ocx / len * wheelOuterRadius
			local nmy = ocy / len * wheelOuterRadius

			ocx, ocy = math.floor(ox + nmx), math.floor(oy + nmy)
			gui.SetMousePos(ox - nmx, oy - nmy)

			cur[1], cur[2] = ox - nmx, oy - nmy

			self.Angle = math.deg( -math.atan2(nmy, nmx) + math.pi / 2 )
			if self.Angle > 0 then
				self.Angle = 90 + (270 - self.Angle)
			end
			self.Angle = math.abs(self.Angle)
			self.SelectionFrac = self.Angle / 360
		else
			if len > wheelOuterRadius then
				ocx = ocx / len * wheelOuterRadius
				ocy = ocy / len * wheelOuterRadius
			end

			cur[1], cur[2] = ox - ocx, oy - ocy
			self.Angle = math.deg( -math.atan2(ocy, ocx) + math.pi / 2 )
			if self.Angle > 0 then
				self.Angle = 90 + (270 - self.Angle)
			end
			self.Angle = math.abs(self.Angle)
			self.SelectionFrac = self.Angle / 360
		end

		self.OptionPercentage = math.min( (len - wheelInnerRadius) / (wheelOuterRadius - wheelInnerRadius), 1 )
	end
end

local function isSelected(fr, bottom, upper, sel)
	local inArea = false

	if sel then
		-- expand selection area by either 1% of the wheel or 5% of the option,
		-- whichever one will result in a smaller expansion
		local total = upper - bottom
		bottom = bottom - math.min(total * 0.05, 0.01)
		upper = upper + math.min(total * 0.05, 0.01)

		local aboveBottom, belowTop

		aboveBottom = fr > bottom
		belowTop = fr < upper

		if upper > 1 then
			aboveBottom = aboveBottom or fr < (upper - 1)
		end
		if bottom < 0 then
			belowTop = belowTop or fr > (1 + bottom)
		end

		inArea = aboveBottom and belowTop
	else
		inArea = fr >= bottom and fr < upper 	-- frac can be 0 (0deg) but it can't be 1 (360deg -> 0deg)
	end

	return inArea
end

function wheel:_ThinkPanel(wheel)
	-- self = panel
	local fr = wheel.Frac
	local min = self:IsMouseInputEnabled()
	if not min then return end

	self:SetAlpha(fr * 255)

	wheel._BoundCursor(self, wheel)

	local options = wheel.Options
	local len = #options

	local optAng = 360 / len

	local sel = self.SelectionFrac
	local curSel = self._CurHovered
	local gotSel = false		-- got a selection already

	if curSel then
		local i = curSel:GetOptionNumber()
		local bottomBound = (1 / len) * (i - 1)
		local upperBound = (1 / len) * i

		if self.OptionPercentage > requireCertainty and
			isSelected(sel, bottomBound, upperBound, true) then
			gotSel = true
		else
			curSel = false
		end
	end

	for i=1, len do
		local opt = options[i]

		-- we already have a selection which is still hovered;
		-- this can't be the selected option
		if curSel then
			if opt ~= curSel and opt:GetHovered() then
				opt:_Unhover()
			end

			continue
		end

		local bottomBound = (1 / len) * (i - 1)
		local upperBound = (1 / len) * i

		if self.OptionPercentage > requireCertainty and not gotSel and
			isSelected(sel, bottomBound, upperBound, false) then
			
			gotSel = opt
			if not opt:GetHovered() then
				self._CurHovered = opt
				opt:_Hover()
			end
		else
			if opt:GetHovered() then
				if self._CurHovered == opt then
					self._CurHovered = nil
					curSel = nil
				end
				opt:_Unhover()
			end
		end
	end

end

function wheel:Show()
	self:To("Frac", 1, wheelAppearTime, 0, 0.3)

	if not self.Panel then
		self.Panel = vgui.Create("InvisPanel")
	else
		self.Panel:AlphaTo(255, wheelAppearTime, 0, 0.3)
	end

	local pnl = self.Panel

	pnl:SetSize(ScrW(), ScrH())
	pnl:SetCursor("blank")

	pnl.SelectionCircle = LibItUp.Circle()
	pnl.InnerCircle = LibItUp.Circle()

	pnl:MakePopup()
	pnl:SetKeyBoardInputEnabled(false)

	pnl.CursorDelta = {0, 0}
	pnl.MouseOrigin = {ScrW() / 2, ScrH() / 2}
	pnl.CurrentMouse = {ScrW() / 2, ScrH() / 2}
	pnl.OptionPercentage = 1

	pnl.Angle = 0

	pnl.Paint = function(pnl, w, h) 	InteractWheel._PaintPanel(pnl, self, w, h) 	end
	pnl.Think = function(pnl) 		InteractWheel._ThinkPanel(pnl, self) 		end
	pnl.OnMousePressed = function(pnl, ...) InteractWheel._OnMousePressed(pnl, self, ...) end

	local options = self.Options
	local segAng = 360 / #options

	local selcirc = pnl.SelectionCircle
		selcirc:SetSegments(50)

	local incirc = pnl.InnerCircle
		incirc:SetSegments(50)
		incirc:SetRadius(8)
		incirc:To("Radius", optionInnerRadius, wheelAppearTime + 0.1, 0, 0.2)

	for i=1, #options do
		local opt = options[i]
		opt:_Setup(i, segAng)
	end

end

function wheel:Hide(delay)
	local anim, new = self:To("Frac", 0, wheelDisappearTime, 0, 0.3)

	if self.Panel then

		self.Panel:AlphaTo(0, wheelDisappearTime, delay or 0, function(anim, pnl)
			pnl:Remove()
			if pnl == self.Panel then self.Panel = nil end
		end, 1.4)

		self.Panel:SetMouseInputEnabled(false)
		self.Panel:SetKeyBoardInputEnabled(false)
	end

	local options = self.Options

	for i=1, #options do
		local opt = options[i]
		opt:_Hide()
	end
end

InteractWheelOption = Emitter:extend()
InteractWheelOption.Matrix = Matrix()

function InteractWheelOption:Initialize(name, desc, icon, cb)
	self.Title = name or "Unnamed"
	self.Description = desc

	self.DescriptionFont = "OS20"
	self.TitleFont = "OSB32"

	self.Icon = icon

	self.HoveredFrac = 0

	self.Circle = LibItUp.Circle()
		self.Circle:SetSegments(50)
		self.Circle.UnselectedColor = unselectedColor:Copy()
		self.Circle.SelectedColor = selectedColor:Copy()

	if isfunction(cb) then
		self:On("Select", "InitCallback", cb)
	end
end

ChainAccessor(InteractWheelOption, "Wheel", "Wheel")
ChainAccessor(InteractWheelOption, "Disabled", "Disabled")
ChainAccessor(InteractWheelOption, "OptionNumber", "OptionNumber")

function InteractWheelOption:_Setup(num, ang)
	-- called when the wheel is generated, so that
	-- the options can setup properties and whatnot

	-- the methods will figure out whether wrapping is actually necessary or nah
	self:_WrapTitle()
	self:_WrapDescription()


	self.Circle:StopAnimations()

	self.HoveredFrac = 0
	self.SelectedFrac = 0
	self._AlphaOverride = 1	-- used for fading out non-selected options manually for when an option is selected

	local circ = self.Circle
	circ:SetRadius(optionOuterRadius)

	circ:SetStartAngle(ang * (num - 1))
	circ:SetEndAngle(ang * num)

	-- used in selection circle expanding
	circ._OriginalStartAngle = circ:GetStartAngle()
	circ._OriginalEndAngle = circ:GetEndAngle()

	if circ.Color then
		circ.Color:Set(circ.UnselectedColor)
	else
		circ.Color = circ.UnselectedColor:Copy()
	end
end

function InteractWheelOption:_WrapDescription()
	

	if isstring(self.Description) and not self._WrappedDescription then
		self._WrappedDescription = true
		self.Description = string.WordWrap2(self.Description, (optionInnerRadius * 2) - 16, self.DescriptionFont)
	end
end

function InteractWheelOption:_WrapTitle()
	

	if isstring(self.Title) and not self._WrappedTitle then
		self._WrappedTitle = true
		self.Title = string.WordWrap2(self.Title, (optionInnerRadius * 2) - 32, self.TitleFont)
	end
end

function InteractWheelOption:SetTitleFont(f)
	self.TitleFont = f
	self:_WrapTitle()
	self._WrappedTitle = false
end

function InteractWheelOption:SetTitle(s)
	self.Title = s
	self:_WrapTitle()
	self._WrappedTitle = false
end

function InteractWheelOption:SetDescriptionFont(f)
	self.DescriptionFont = f
	self:_WrapDescription()
	self._WrappedDescription = false
end

function InteractWheelOption:SetDescription(s)
	self.Description = s
	self:_WrapDescription()
	self._WrappedDescription = false
end

local optionSelectedScaleMult = 0.15

function InteractWheelOption:_Select()
	-- we'll have to draw a new stenciled circle in order to have the
	-- selected option arc not be huge: https://i.imgur.com/hq6sY8Z.png

	self._InnerCircle = LibItUp.Circle()

	local dur, ease = 0.2, 0.3

	local incirc = self._InnerCircle
		incirc:SetSegments(50)
		incirc:SetRadius(optionInnerRadius)
		incirc:To("Radius", optionInnerRadius + optionInnerRadius * optionSelectedScaleMult,
			dur, 0, ease)

	self.Circle:MemberLerp(self, "SelectedFrac", 1, dur, 0, ease)
	self:Emit("Select")
end

function InteractWheelOption:_Hover()
	self.Circle:MemberLerp(self, "HoveredFrac", 1, 0.2, 0, 0.3)
	self.Circle:LerpColor(self.Circle.Color, selectedColor, 0.1, 0, 0.3)

	self._Hovered = true
	self:Emit("Hovered")
end

function InteractWheelOption:_Unhover()
	self.Circle:MemberLerp(self, "HoveredFrac", 0, 0.1, 0, 0.2)
	local anim, new = self.Circle:LerpColor(self.Circle.Color, unselectedColor, 0.1, 0, 0.3)

	self._Hovered = false
	self:Emit("Unhovered")
end

function InteractWheelOption:_Hide(sel)
	local circ = self.Circle

	circ:MemberLerp(self, "HoveredFrac", 0, 0.1, 0, 0.2)

	if sel then -- if we're hiding because an option was selected, override our own alpha manually
		circ:MemberLerp(self, "_AlphaOverride", 0, wheelDisappearTime, 0, 0.2)
	end

	--circ:To("Radius", optionOuterRadius - 16, wheelDisappearTime, 0, 0.4)
end

ChainAccessor(InteractWheelOption, "_Hovered", "Hovered")

local sqrt2 = math.sqrt(2)

local ic2 = Icon("https://i.imgur.com/z3SWemE.png", "dbutt_icon.png")

function InteractWheelOption:_Paint(x, y, w, h, prevMatrix, innerCircle)
	local circ = self.Circle

	-- Get the segment's middle as XY
	-- This will come in handy in icon size manipulation and
	-- selection matrix modifying

	local segMid = circ:GetStartAngle() + (circ:GetEndAngle() - circ:GetStartAngle()) / 2 - 90
	local segMidRad = math.rad(segMid)

	local rad = (optionOuterRadius + optionInnerRadius) / 2

	local smX, smY = math.floor(math.cos(segMidRad) * rad), math.floor(math.sin(segMidRad) * rad) -- relative to 0, 0

	--[[
		Draw segment & segment icon
	]]

	-- If we're selected, push a selection matrix to create a
	-- option-popping-out animation
	local pushed = false
	if self.SelectedFrac > 0 then
		cam.PopModelMatrix()	-- pop the old matrix; we don't obey the wheel's scaling matrix
								-- we'll also have to disable the parent's stencil, draw our own,
								-- and then restore the old stencil ; bit fucky but i can't come up with a better solution

		surface.SetDrawColor(0, 0, 0, 255)

		render.ClearStencil() -- set every pixel to 0
		-- put our own circle
		draw.BeginMask()	

		self._InnerCircle:Paint(w/2, h/2)	-- this sets ref value to 1

		draw.DrawOp()			-- this will draw where value is 1, however, for our case it's more advantageous to
								-- draw where it's NOT 1, and since the op is NOTEQUAL we'll just compare against != 1 
		render.SetStencilReferenceValue(1)
		

		local trX, trY = x, y
		local fr = self.SelectedFrac
		local easedfr = fr ^ 0.7

		local mtrx = self.Matrix
			mtrx:Reset()
			mtrx:TranslateNumber(trX, trY)
			local scale = 1 + easedfr * optionSelectedScaleMult
			mtrx:SetScaleNumber(scale, scale)
			mtrx:TranslateNumber(-trX, -trY)

		cam.PushModelMatrix(mtrx, true)
		pushed = true
		local osa, oea = circ._OriginalStartAngle, circ._OriginalEndAngle
		local diff = oea - osa
		circ:SetStartAngle(osa - diff * easedfr * 0.4)
		circ:SetEndAngle(oea + diff * easedfr * 0.4)
	end

	local prevAlpha, curAlpha

	if self._AlphaOverride ~= 1 then
		prevAlpha = surface.GetAlphaMultiplier()
		curAlpha = prevAlpha * self._AlphaOverride
		surface.SetAlphaMultiplier(curAlpha)
	end

	-- Segment (duh)
	surface.SetDrawColor(circ.Color:Unpack())
	--surface.SetDrawColor(Colors.Red)
	circ:Paint(x, y)

	
	-- Icon:
	local ic = self.Icon

	

	-- 2. Calculate the W, H of box we can draw our icon in
		-- This is ass

	local rdiff = (optionOuterRadius - optionInnerRadius) / 2
	local ang = angXY(smX, smY)

	local closeAng = math.max(math.pi / 2 - math.abs(segMidRad) % (math.pi / 2), math.abs(segMidRad) % (math.pi / 2))
	local close = math.sin(closeAng)
	local far = math.sin(math.pi / 4)

	local sqr = math.Round(far * rdiff + close * rdiff)

	local ang = -segMid
	local flip = 1

	if math.abs(ang) > 90 then
		flip = -1
	end

	if ic then

		if flip < 0 then
			render.CullMode(1)
		end

			local rx, ry = x + smX, y + smY
			local icang = ang

			if flip < 0 then
				icang = math.Clamp(icang, -180 - 45, -180 + 15)
			else
				icang = math.Clamp(icang, -15, 45)
			end

			local iw, ih = ic:GetSize()

			-- the maximum of these will be 1
			local ratio_w = 1
			local ratio_h = 1

			if iw and ih then
				if iw >= ih then
					ratio_h = ih / iw
				else
					ratio_w = iw / ih
				end
			end

			render.SetStencilEnable(false)
				ic:Paint(rx, ry, sqr * ratio_w, sqr * flip * ratio_h, icang)
			render.SetStencilEnable(true)

		if flip < 0 then
			render.CullMode(0)
		end

	end


	if pushed then
		if prevAlpha then surface.SetAlphaMultiplier(prevAlpha) end

		cam.PopModelMatrix()
		cam.PushModelMatrix(prevMatrix)

		-- after reinstating previous matrix we also need to reinstate previous stencil

		render.ClearStencil() -- here we go again

		draw.BeginMask()	
			innerCircle:Paint(x, y)	-- re-draw the parent circle

		draw.DrawOp()
		render.SetStencilReferenceValue(1)
	end

	local fr = self.HoveredFrac
	if fr == 0 then 
		if prevAlpha then surface.SetAlphaMultiplier(prevAlpha) end
		return
	end

	--[[
		Calculate total infobox height so we can center it
			1. Get the icon's height, if present
			2. Calculate wrapped title height, if present
			3. Calculate wrapped description height, if present
	]]

	local infoH = 0, 0
	local iconMargin = 8
	local titleMargin = 4
	

	if ic then
		local iw, ih = ic:GetSize()
		infoH = infoH + ih
	end

	local title = self.Title
	if title then
		local nls = amtNewlines(title) + 1
		local hgt = nls * draw.GetFontHeight(self.TitleFont)
		infoH = infoH + (ic and iconMargin or 0) + hgt
	end

	local desc = self.Description
	if desc then
		local nls = amtNewlines(desc) + 1
		local hgt = nls * draw.GetFontHeight(self.DescriptionFont)
		infoH = infoH + hgt
		if title then
			infoH = infoH + titleMargin
		elseif ic then
			infoH = infoH + iconMargin
		end
	end

	--[[
		Setup alpha and matrix for scaling + move-out effects
	]]

	local amult = surface.GetAlphaMultiplier()
	surface.SetAlphaMultiplier(fr ^ 0.3 * amult)

	-- Translation depends on hoverfrac: the closer to 1, the less this translation is

	local mtrxMiddleX = math.floor(math.cos(segMidRad) * (optionInnerRadius * 0.9))
	local mtrxMiddleY = math.floor(math.sin(segMidRad) * (optionInnerRadius * 0.9))

	local trX, trY = x + mtrxMiddleX * (1 - fr), y + mtrxMiddleY * (1 - fr)

	-- Scale and translate the matrix
	local mtrx = self.Matrix
		mtrx:Reset()
		mtrx:TranslateNumber(trX, trY)
		local scale = 0.3 + (fr ^ 0.7) * 0.7
		mtrx:SetScaleNumber(scale, scale)
		mtrx:TranslateNumber(-trX, -trY)

	--[[
		Render the infobox
	]]

	-- Disable the inner-circle stencil
	render.SetStencilEnable(false)

	cam.PushModelMatrix(mtrx, true)

		local cy = y - infoH / 2 - (ic and select(2, ic:GetSize()) / 2 or 0)
		local cy2 = cy

		if ic then
			local iw, ih = ic:GetSize()
			ic:Paint(x - iw/2, cy, iw, ih)
			cy = cy + ih + iconMargin
		end

		if title then
			surface.SetFont(self.TitleFont)
			surface.SetDrawColor(color_white)
			local hgt = draw.GetFontHeight(self.TitleFont)

			for s, line in eachNewline(title) do
				draw.SimpleText(s, self.TitleFont, x, cy, color_white, 1, 5)
				cy = cy + hgt
			end

		end

		if desc then

			surface.SetFont(self.DescriptionFont)
			surface.SetDrawColor(color_white)
			local hgt = draw.GetFontHeight(self.DescriptionFont)

			for s, line in eachNewline(desc) do
				draw.SimpleText(s, self.DescriptionFont, x, cy, color_white, 1, 5)
				cy = cy + hgt
			end

		end

	cam.PopModelMatrix()

	-- bring back the inner circle stencil and restore alpha multiplier
	render.SetStencilEnable(true)
	if prevAlpha then
		surface.SetAlphaMultiplier(prevAlpha)
	else
		surface.SetAlphaMultiplier(amult)
	end
end

function InteractWheelOption:Remove()
	self.Wheel:RemoveOption(self)
end

function wheel:AddOption(name, desc, icon, cb)
	local option = InteractWheelOption:new(name, desc, icon, cb)
		option:SetWheel(self)
		option:SetOptionNumber(#wheel.Options + 1)
	wheel.Options[option:GetOptionNumber()] = option

	return option
end

function InteractWheelOption:__tostring()
	return "[IWheelOption: " .. (self.Title or "<no title>") .. "]"
end

--- test

if _TestWheel then _TestWheel:Hide() end

_TestWheel = InteractWheel:new()
local wh = _TestWheel

wh:AddOption("Icon + description", "Yes funny description description veri funny mm yes veri funi",
	Icon("https://i.imgur.com/z3SWemE.png", "dbutt_icon.png"):SetSize(64, 72))

for i=1, 10 do
	wh:AddOption("Option " .. i, "Some description " .. ("some description "):rep(i - 1):Trim(),
		Icon("https://i.imgur.com/z3SWemE.png", "dbutt_icon.png"):SetSize(64, 72))
end

wh:AddOption("NaM VERYLONGTITLESPAM NaM", "NaM NAM THE WEEBS AWAY NaM NAM THE WEEBS AWAY NaM NAM THE WEEBS AWAY NaM NAM THE WEEBS AWAY ",
	Icon("https://i.imgur.com/z3SWemE.png", "dbutt_icon.png"):SetSize(64, 72))

local bnd = Bind("wheel")
bnd:SetDefaultKey(KEY_G)
bnd:SetDefaultMethod(BINDS_HOLD)
bnd:CreateConcommands()

bnd:On("Activate", 1, function(self, ply)
	wh:Show()
end)

bnd:On("Deactivate", 1, function(self, ply)
	wh:Hide()
end)