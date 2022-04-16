--[[-------------------------------------------------------------------------
--  FTextEntry
---------------------------------------------------------------------------]]

local TE = {}

function TE:Init()
	self:SetSize(256, 36)
	self:SetFont("OS24")
	self:SetEditable(true)
	self:SetKeyboardInputEnabled(true)
	self:AllowInput(true)

	self.BGColor = Color(40, 40, 40)
	self.TextColor = color_white:Copy()
	self.HTextColor = Colors.LightGray:Copy()
	self.CursorColor = color_white:Copy()
	self.PHTextColor = color_white:Copy()
	self.PHTextAlpha = 50
	self.GradColor = Color(10, 10, 10, 180)
	self.PHTextFrac = 1
	self.RBRadius = 6

	self.GradBorder = true

	hook.Object("OnTextEntryLoseFocus", self, function(self, pnl)
		if self ~= pnl then return end
		self:OnLoseFocus()
	end)

	self:On("GetFocus", function()
		self.Focus = true
	end)

	self:On("LoseFocus", function()
		self.Focus = false
	end)
end

ChainAccessor(TE, "MaxChars", "MaxChars")
ChainAccessor(TE, "MaxChars", "MaxCharacters")
ChainAccessor(TE, "MaxChars", "MaxLength")

function TE:OnChange()
	self:Emit("Change")
end

function TE:SetColor(col)

	if not IsColor(col) then error('FTextEntry: SetColor arg must be a color!') return end
	self.BGColor = col

end


function TE:SetTextColor(col)

	if not IsColor(col) then error('FTextEntry: SetTextColor must be a color!') return end
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

function TE:OnGetFocus()
	self:Emit("GetFocus")
end

function TE:OnLoseFocus()
	self:Emit("LoseFocus")
end

-- yes i had to split it up into 3 functions, stfu

function TE:DrawGradBorder(w, h)
	surface.SetDrawColor(self.GradColor:Unpack())
	self:DrawGradientBorder(w, h, 3, 3)
end

function TE:DrawBG(w, h)
	surface.SetDrawColor(self.BGColor:Unpack())
	surface.DrawRect(0, 0, w, h)
	if self.GradBorder then
		self:DrawGradBorder(w, h)
	end
end

function TE:Paint(w, h)

	if not self.NoDrawBG then
		self:DrawBG(w, h)
	end

	self:DrawTextEntryText(self.TextColor, self.HTextColor, self.CursorColor)

	if self:GetPlaceholderText() and #self:GetText() == 0 then
		self.PHTextColor = (self.PHTextColorGen == self.TextColor and self.PHTextColor) or ColorAlpha(self.TextColor, 125)
		self.PHTextColorGen = self.TextColor

		self:To("PHTextFrac", (self.Focus and 0) or 1, 0.2, 0, 0.15)
		self.PHTextColor.a = self.PHTextAlpha * self.PHTextFrac

		draw.SimpleText(self:GetPlaceholderText(), self:GetFont(), 4, h/2, self.PHTextColor, 0, 1)
	end

	self:Emit("PostPaint", w, h)
end


function TE:AllowInput(val)
	local mx = self:GetMaxChars()
	if mx and mx ~= 0 and #self:GetValue() > mx then return true end
end

vgui.Register("FTextEntry", TE, "DTextEntry")