
--[[
	DeltaTextPiece: the object that holds the text and values for it.
]]


DeltaTextPiece = DeltaTextPiece or Object:extend()

local function hex(t)
	return ("%p"):format(t)
end

local function NewFragment(piece, text, col)
	local template = piece.FragmentTemplate and table.Copy(piece.FragmentTemplate) or {
		--Text = text,
		-- OffsetY = 0,
		-- OffsetX = 0,

		--AlignX = 0,
		--AlignY = 0,
		--AlignWholeHeight = false,	-- this makes AlignY work off the whole piece's height and not just this fragments'

		-- Alpha = 255,
		--Color = col,
	}

	template.Text = text
	template.Color = template.Color or col

	template.Alpha = template.Alpha or 255
	template.OffsetX = template.OffsetX or 0
	template.OffsetY = template.OffsetY or 0

	return template
end

local pmeta = DeltaTextPiece
pmeta.IsDeltaElement = true

function pmeta:Initialize(par, tx, font, key, rep)
	self.Text = tx
	--self.Font = font
	self.Key = key

	self.DropStrength = 16	--Text replacement animation: height to which text drops FROM the text
	self.LiftStrength = -12	--Text replacement animation: height to which text drops TO the text

	self.Parent = par 		--DeltaTextMain

	self.Color = color_white:Copy()
	self.Alpha = 0

	local aninfo = {}
	self.Animation = aninfo

	self.Offsets = {X = 0, Y = 0}

	self.Offsets.XAppear = 0
	self.Offsets.YAppear = -24

	self.Offsets.XDisappear = 0
	self.Offsets.YDisappear = 24

	aninfo.Length = 0.4
	aninfo.Ease = 0.4
	aninfo.Delay = 0
	aninfo.AnimationFunction = function(self, len, delay, ease, onend, think) return NewAnimation(len, delay, ease, onend) end

	self.Animations = {}	--Keeping track of existing animations for the ability to stop and run any animation, as long as you know the name

	--[[
		Text fragments.
		TODO: Make a text fragment into an object as well.
	]]

	self.Fragmented = false
	self.Fragments = {}

end

function pmeta:GetFontHeight()
	return draw.GetFontHeight(self:GetFont())
end

function pmeta:SetColor(col, g, b, a)
	self.Color:Set(col, g, b, a)
	return self
end

function pmeta:GetColor()
	return self.Color
end

function pmeta:StopAnimation(name)

	local an = self.Animations[name]

	if an then
		an:Stop()
		self.Animations[name] = nil
		return an
	end

end

function pmeta:SetChangeDirection(up, str)
	if up then
		self:SetDropStrength(-str)
		self:SetLiftStrength(str)
	else
		self:SetDropStrength(str)
		self:SetLiftStrength(-str)
	end
end

ChainAccessor(pmeta, "DropStrength", "DropStrength")
ChainAccessor(pmeta, "LiftStrength", "LiftStrength")

--ChainAccessor(pmeta, "Text", "Text") --custom GetText implemented
ChainAccessor(pmeta, "Font", "Font")
ChainAccessor(pmeta, "Parent", "Parent")

function pmeta:CreateAlphaAnimation(name, think, cb, len, del)
	local aninfo = self.Animation

	local anim, nooverride = aninfo.AnimationFunction(self, len or aninfo.Length, del or aninfo.Delay, aninfo.Ease, cb, think)

	if not nooverride then
		anim.Animate = think
	end

	self.Animations[name] = anim
end

function pmeta:GetAnimation(nm)
	return self.Animations[nm]
end

--[[
	Returning anything non-falsy in these functions will stop default animations from playing
]]

function pmeta:AppearAnimation(fr)

end

function pmeta:DisappearAnimation(fr)

end

--[[
	This is called by the Appear and Disappear animation(which, in turn, is created by :Appear() and :Disappear())
	Don't override it; use :AppearAnimation() and :DisappearAnimation callbacks instead
]]

function pmeta:AnimateAppearance(fr, a, rev, fromx, fromy)
	if self:AppearAnimation(fr) then return end

	self.Alpha = a + (255 - a) * fr

	local xo, yo

	if not rev then -- just a regular appear; start from default values
		xo, yo = self.Offsets.XAppear, self.Offsets.YAppear --self:GetLiftStrength()
	else -- we're reversing a disappear animation; take current values and go from them
		xo, yo = fromx, fromy --self.Offsets.X, self.Offsets.Y
	end

	self.Offsets.X = Lerp(fr, xo, 0)
	self.Offsets.Y = Lerp(fr, yo, 0)
	--self:AppearAnimation(fr)
end

function pmeta:AnimateDisappearance(fr, a, rev, x, y)
	if self:DisappearAnimation(fr) then return end

	self.Alpha = math.max(a - (fr ^ 0.5) * a, 0)

	local xo, yo = self.Offsets.XDisappear, rev and y - self:GetLiftStrength() or self:GetDropStrength()

	self.Offsets.X = Lerp(fr, x, xo)
	self.Offsets.Y = Lerp(fr, y, yo)

end


function pmeta:Disappear()
	local anim = self:StopAnimation("Appear")	--stop spazzing out

	local fromX, fromY = self.Offsets.X, self.Offsets.Y
	local wasAppearing = self.Appearing and anim and anim.Frac < 0.6
	local a = self.Alpha

	self:CreateAlphaAnimation("Disappear", function(fr)
		self:AnimateDisappearance(fr, a, wasAppearing, fromX, fromY)
	end, function()
		self.Disappeared = true
	end)

	self.Disappearing = true
	self.Appearing = false
end

function pmeta:Appear()
	local anim = self:StopAnimation("Disappear")

	local wasDisappearing = self.Disappearing and not self.Disappeared
							 and anim and anim.Frac < 0.6

	local a = self.Alpha
	local fx, fy = self.Offsets.X, self.Offsets.Y
	self.Appearing = true

	self:CreateAlphaAnimation("Appear", function(fr)
		self:AnimateAppearance(fr, a, wasDisappearing, fx, fy)
	end, function() 
		self.Appearing = false
	end)

	self.Disappearing = false
	self.Disappeared = false
end

--[[
	:CreateAnimation uses a regular NewAnimation function by default.


	By setting your own animation you can change what kind of animation it uses. The AnimationFunction gets called with these arguments:
	self, Length, Delay, Ease, onend, think

	For example,
	piece:SetAnimationFunction(function(self, len, del, ease, onend, think)
		return Animations.InElastic(len, del, think, onend, ease), true
	end)

	Don't forget to return true as the second arg, otherwise the Animate function will be replaced.
]]

function pmeta:SetAnimationFunction(func)
	self.AnimationFunction = func
end

function pmeta:GetWide()
	local curfont
	local parent = self.Parent
	local font = self.Font or parent.Font -- piece font takes priority over parent font

	if self.Fragmented then
		local x = 0

		local lerpnext = 1
		local lerpfrom = 0

		for k,v in ipairs(self.Fragments) do
			local font = v.Font or font -- fragment font takes priority over piece font

			if curfont ~= font then
				surface.SetFont(font)
				curfont = font
			end

			local tw, th = surface.GetTextSize(v.Text)
			if tw > 10 then
				--print(v.Text, tw, v.LerpNext, lerpnext, lerpfrom)
			end

			if v.LerpNext then --if lerpnext is active then this fragment's width will be calculated by the next fragment
				lerpnext = Ease(v.LerpNext, v.Ease or 0.6)
				lerpfrom = tw
			else
				x = x + Lerp(lerpnext, lerpfrom, tw)
				lerpnext = 1
				lerpfrom = 0
			end

		end

		return x
	else
		surface.SetFont(font)
		return (surface.GetTextSize(self.Text))
	end
end


function pmeta:DrawText(x, y, col, tx, frag) --Available for override
	surface.SetTextPos(x, y)
	surface.SetTextColor(col.r, col.g, col.b, col.a)
	surface.DrawText(tx)
end

function pmeta:Paint(x, y)
	local parent = self.Parent
	local font = self.Font or parent.Font -- piece font takes priority over parent font

	self.Color.a = self.Alpha

	if font ~= parent.LastFont then
		parent.LastFont = font
		surface.SetFont(font)
	end

	local curfont = self.Font

	if self.Fragmented then

		local x = x
		local totalW = 0
		local lastw = 0

		local lerpnext = 1
		local lerpfrom = 0

		local totalHeight = 0

		for k,v in ipairs(self.Fragments) do
			local font = v.Font or font -- fragment font takes priority over piece font
			local nxt = self.Fragments[k + 1]

			local alignX = v.AlignX or parent.AlignX or 0
			alignX = alignX / 2
			if (not v.Font and curfont ~= self.Font) or (v.Font and v.Font ~= curfont) then
				surface.SetFont(font)
				curfont = v.Font
			end

			local tw, th = surface.GetTextSize(v.Text)
			totalHeight = math.max(totalHeight, th)

			local twfr = v.LerpWidth or 1

			if v.LerpNext then --if lerpnext is active then this fragment's width will be calculated by the next fragment
				lerpnext = Ease(v.LerpNext, v.Ease or 0.6)
				lerpfrom = tw * alignX * twfr
			else
				local addW = Lerp(lerpnext, lerpfrom, tw * alignX * twfr)
				x = x - addW
				totalW = totalW + addW
				lerpnext = 1
				lerpfrom = 0
			end

			lastw = v.Fading and tw * twfr

		end

		lastw = 0

		for k,v in ipairs(self.Fragments) do
			local doDraw = v.Text ~= ""

			--if fragment doesn't have a custom font, and current font is not default font (for example, from last frag)
			--or fragment has a custom font and it's not the same one as the current,
			--change it

			local font = v.Font or font

			if curfont ~= font then
				surface.SetFont(font)
				curfont = font
			end

			local tw, th = surface.GetTextSize(v.Text)

			--local print = tostring(v.Text):match("(x0)") and print or BlankFunc

			--print(v.Color)
			local alpha = math.min(v.Alpha or 255, self.Alpha, v.Color and v.Color.a or 0)
			if alpha == 0 or not doDraw then goto textCalc end

			do
				local oldA = v.Color.a --we only want to change the alpha of the color temporarily, in case there's the same color being used for multiple fragments
				v.Color.a = alpha

				local alignX, alignY = v.AlignX or parent.AlignX or 0, v.AlignY or parent.AlignY or 0
				alignX, alignY = alignX / 2, alignY / 2

				--0 = left/top
				--1 = middle
				--2 = bottom/right

				--current x/y + fragment offset + parent offset + alignment

				local tX = x + v.OffsetX + self.Offsets.X -- alignX * tw
				local yOff = alignY * th + (v.AlignWholeHeight and alignY * totalHeight or 0)
				local tY = y + v.OffsetY + self.Offsets.Y + yOff

				self:DrawText(tX, tY, v.Color, v.Text, v)

				v.Color.a = oldA --reset the alpha to what it was
			end

			-- White()
			-- surface.DrawOutlinedRect(tX, tY, tw, th)
			::textCalc::

			local twfr = v.LerpWidth or 1
			tw = tw * twfr

			if not v.RewindTextPos then
				local nxt = self.Fragments[k + 1]
				if v.LerpFromLast then
					local fr = Ease(v.LerpFromLast, v.Ease or 0.6)
					x = x + Lerp(fr, lastw or tw, tw)
				elseif not v.Fading then
					x = x + tw
				end

			end

			lastw = v.Fading and tw
		end

		return totalW
	end

	local tw, th = surface.GetTextSize(self.Text)

	local alignX = self.AlignX or parent.AlignX or 0
	local alignY = self.AlignY or parent.AlignY or 0

	alignX, alignY = alignX / 2, alignY / 2

	local tX = x + self.Offsets.X - alignX * tw
	local tY = y + self.Offsets.Y + alignY * th

	self:DrawText(tX, tY, self.Color, self.Text)

	return tw
end

function pmeta:GetText(ignore_fading)
	if not self.Fragmented then
		return self.Text
	else

		local s = ""

		for k,v in pairs(self.Fragments) do
			if ignore_fading and v.RewindTextPos then continue end
			s = s .. v.Text
		end

		return s
	end
end
function pmeta:OnAppear()	--for override

end

--[[
	When the text appears or disappears due to cycling,
	it uses these offsets to animate from/to.
]]

function pmeta:SetOffsetDisappear(x, y)
	self.Offsets.XDisappear = x
	self.Offsets.YDisappear = y
end

function pmeta:SetOffsetAppear(x, y)
	self.Offsets.XAppear = x
	self.Offsets.YAppear = y
end

--[[
	TODO: Return fragment object.
]]
function pmeta:FragmentText(from, to)

	if not self.Fragmented then

		self.Fragmented = true

		local t = {}

		if from then
			to = to or from --same char

			local t1, t2, t3 = self.Text:sub(0, from-1), self.Text:sub(from, to), self.Text:sub(to+1, #self.Text)

			t[1] = NewFragment(self, t1, self.Color)
			t[1].ID = 1

			t[2] = NewFragment(self, t2, self.Color)
			t[2].ID = 2

			t[3] = NewFragment(self, t3, self.Color)
			t[3].ID = 3

			self.Fragments = t
		else
			t[1] = NewFragment(self, self.Text, self.Color)
			t[1].ID = 1

			self.Fragments = t
		end



		return t
	else

		local len = 0

		if from < 0 then
			from = #self.Text + from
		end

		for k,v in pairs(self.Fragments) do

			local txt = v.Text

			len = len + #txt

			if from < len and to <= len then
				local frag = {
					Text = txt:sub(from - len + #txt + 1, to - len + #txt),
					OffsetX = 0,
					OffsetY = 0,
					Color = self.Color,
				}

				local newtext = from - len + #txt --new text for the old frag length

				if newtext == 0 then --they didn't leave any text; just remove the frag
					table.remove(self.Fragments, k)
				else
					v.Text = txt:sub(0, newtext)
				end

				local where = table.insert(self.Fragments, k+1, frag)
				frag.ID = where

				return where

			end
		end

	end
end

function pmeta:SetFragmentFont(ind, font)
	if not self.Fragmented then error("Can't set font for unfragmented text piece!") return end
	if not self.Fragments[ind] then error("No fragment #" .. ind .. "!") return end

	self.Fragments[ind].Font = font
end

function pmeta:AddFragment(text, num, anim, onend)	--adds a fragment on top
	local newfrag = NewFragment(self, text, self.Color)

	if anim then
		newfrag.Alpha = 0
	end

	if not self.Fragmented then
		self:FragmentText()
	end

	if anim then
		local settings = istable(anim) and anim or {}

		self:CreateAlphaAnimation("AddFragText" .. hex(newfrag), function(fr)
			newfrag.OffsetY = 24 - (fr * 24)
			newfrag.Alpha = fr*255
		end, function()
			if onend then onend() end
		end, settings.Length, settings.Delay or 0)

	end

	local where

	if num then
		where = table.insert(self.Fragments, num, newfrag)
	else
		where = table.insert(self.Fragments, newfrag)
	end
	newfrag.ID = where

	return where, newfrag
end

--[[
	Having fragmented text isn't really nice, especially since it doesn't need to be after a reset(probably...)
	Either way, just re-fragment it if you really need it.

	Gets called after a cycle reset.
]]

function pmeta:OnReset()

end

function pmeta:Reset()
	if self:OnReset() then return end

	if self.Fragmented then
		local tx = self.Text
		self:CollectFragments()
		self.Text = tx
	end
end

function pmeta:RemoveFragment(num, now)
	local frag

	for k,v in pairs(self.Fragments) do --find the frag we'll be replacing
		if not v.Fading and v.ID == num then
			frag = v
			break
		end
	end

	if not frag then return false end

	for k,v in pairs(self.Fragments) do 	--shift every other ID down
		if not v.Fading and v ~= frag and v.ID > num then
			v.ID = v.ID - 1
		end
	end

	if now then
		-- delete now, no fancy anims
		for k,v in pairs(self.Fragments) do
			if v == frag then
				table.remove(self.Fragments, k)
				return
			end
		end
	end

	local dropstr = self:GetDropStrength()

	frag.RewindTextPos = true
	frag.Fading = true
	frag.LerpFromLast = 1

	frag.LerpNext = 0
	local a = frag.Alpha

	self:CreateAlphaAnimation(hex(frag) .. "SubText", function(fr)
		frag.OffsetY = fr * dropstr
		frag.Alpha = a - fr*a

		frag.LerpNext = fr

	end, function()

		for k,v in pairs(self.Fragments) do 	--this is done like this because the keys might change by the time the animation finishes
			if v == frag then
				table.remove(self.Fragments, k)
				break
			end
		end

	end)

	return frag
end

--[[
	The first argument is the number of a fragment you're going to be changing. Text MUST be fragmented for this!
	The second argument is the string you're going to be changing the fragment to.
	The third arg is optional and is a callback for when the text is inserted.

	Returns the new fragment which is inserted into the text object on success,
	or false if it failed(either because the fragment with this number doesn't exist or
	the text in the fragment is exactly the same as you're trying to change it to)
]]

function pmeta:ReplaceText(num, rep, onend, nolerp, anim)
	--newfrag.RewindTextPos = true

	local frag

	for k,v in pairs(self.Fragments) do --find the frag we'll be replacing
		if not v.Fading and v.ID == num then
			frag = v
			break
		end
	end

	if not frag then return false end
	if frag.Text == rep then return false end --its the same text

	local settings = istable(anim) and anim or {}

	frag.Fading = true

	local newfrag = NewFragment(self, rep, self.Color)

	newfrag.Alpha = 0
	newfrag.ID = num
	newfrag.LerpFromLast = nolerp and 1 or 0

	newfrag.AlignX = frag.AlignX
	newfrag.AlignY = frag.AlignY
	newfrag.Color = frag.Color
	newfrag.RewindTextPos = true

	self:StopAnimation(hex(frag) .. "AddText")	--in case it existed

	local dropstr = self:GetDropStrength()

	local a = frag.Alpha
	frag.LerpNext = 0
	--frag.RewindTextPos = true
	--frag.LerpFromLast = 1

	self:CreateAlphaAnimation(hex(frag) .. "SubText", function(fr)
		frag.RewindTextPos = true
		frag.LerpFromLast = 1
		frag.LerpNext = fr

		frag.OffsetY = nolerp and dropstr or fr * dropstr
		frag.Alpha = nolerp and 0 or a - fr*a

		frag.LerpNext = fr
		newfrag.LerpFromLast = fr --doing it in the fading _out_ looks better than doing it on fading _in_

	end, function()

		for k,v in pairs(self.Fragments) do 	--this is done like this because the keys might change by the time the animation finishes
			if v == frag then
				table.remove(self.Fragments, k)
				return
			end
		end

		newfrag.Finished = true
		--newfrag.LerpFromLast = 0
	end, nolerp and 0 or settings.Length, nolerp and 0 or settings.Delay)

	local appstr = self:GetLiftStrength()

	--newfrag.LerpWidth = 0
	--newfrag.LerpNext = 1

	self:CreateAlphaAnimation(hex(newfrag) .. "AddText", function(fr)
		newfrag.RewindTextPos = false
		--newfrag.LerpNext = 1 - fr
		--newfrag.LerpWidth = fr
		--[[newfrag.LerpMinWidth = frag]]

		newfrag.OffsetY = nolerp and 0 or appstr - (fr * appstr)
		newfrag.Alpha = nolerp and 255 or fr * 255
	end,

	function()
		if onend then onend() end
	end, nolerp and 0 or settings.Length, nolerp and 0 or settings.Delay)

	local inswhere = num+1

	for k,v in ipairs(self.Fragments) do 	--find latest fragment with this ID which is fading, to put the new frag after it
		if v.Fading and v.ID == num then 	--this is done for text X rewinding to work properly(ORDERRR!)
			inswhere = k+1
		end
	end

	local where = table.insert(self.Fragments, inswhere, newfrag)

	return where, newfrag
end

--[[
	Re-collects all fragments, and if an argument isn't provided,
	unites all text fragments into its' .Text member.

	Removes fragmentation entirely.
]]
function pmeta:CollectFragments(keeptxt)

	if not keeptxt then
		local s = ""

		for k,v in pairs(self.Fragments) do
			s = s .. v.Text
		end

		self.Text = s
	end

	self.Fragmented = false

	table.Empty(self.Fragments)
end