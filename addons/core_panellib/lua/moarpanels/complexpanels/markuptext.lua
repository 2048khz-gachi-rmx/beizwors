--
local Testing = false

local PANEL = {}

function PANEL:Init()
	self.Pieces = {}
	self:SetKeyboardInputEnabled(true)
	self:SetName("Markup Text")
end

function PANEL:PerformLayout()
	local h = 0
	for k,v in ipairs(self.Pieces) do
		h = h + v:GetTall()
	end

	self:SetTall(h)
end

function PANEL:Recalculate()
	for k,v in ipairs(self.Pieces) do
		v:Recalculate()
	end

	self:PerformLayout() -- ffs
end

function PANEL:_StartSelection(piece)

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

function PANEL:GetPieces()
	return self.Pieces
end
function PANEL:Add(p)
	if self.Scrollable then
		p:SetParent(self.ScrollPanel)
	else
		p:SetParent(self)
	end
	p:Dock(TOP)
end

function PANEL:AddPiece()
	local piece = vgui.Create("MarkupPiece", self)
	self:Add(piece)

	self.Pieces[#self.Pieces + 1] = piece
	return piece
end

vgui.Register("MarkupText", PANEL, "Panel")


if not Testing then return end
if IsValid(_FF) then _FF:Remove() end

_FF = vgui.Create("FFrame")
_FF:SetSize(600, 450)
_FF:Center()
_FF.Shadow = {}
_FF:MakePopup()

local scr = vgui.Create("FScrollPanel", _FF)
scr:Dock(FILL)

local tx = vgui.Create("MarkupText", scr)
tx:Dock(TOP)
tx:SetTall(60)

--local beemovie = "hellooo hellooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo"
local p = tx:AddPiece()

p:SetFont("OS24")
p:AddText("brabrabra epic text wow so many letters its amazing wait wtf it can wrap")
p:AddText(" like a mfin burrito yo what even across")
p:AddText(" multiple text-adds that's quite cool what happens if i add a")

p:AddObject(Color(0, 255, 0))

p:AddText(" COLOR or a few")
local trind = p:AddTag(MarkupTags("translate", function()
	return math.sin(CurTime() * 4) * 50 + 50
end, 0))

local hsvind = p:AddTag(MarkupTags("hsv", function()
	return CurTime() * 360
end))

p:AddText(" taAAaaaAAaags")

p:EndTag(trind)

p:AddText("rainbow but not moving", 100) --100px offset

p:EndTag(hsvind)

p:AddText(" ک گھ پھ ہے ں ٹ ڈ ڑ گھ پھ ہے ں ٹ ڈ ڑ گھ پ گھ پھ ہے ں ٹ ڈ ڑ")

local p2 = tx:AddPiece()
p2:SetFont("OS18")
p2:AddText("piece 2: different font, different line || ")

local hsvind = p2:AddTag(MarkupTags("hsv", function()
	return CurTime() * 360
end))

p2:AddText(beemovie)


p2:On("Layout", function()
	tx:SetTall(p2:GetTall())
end)
_FF:InvalidateLayout(true)
local t

function _FF:PostPaint()
	t = SysTime()
end

function _FF:PaintOver(w, h)
	local t2 = SysTime()
	local tx = p2:GetSelected()

	surface.DisableClipping(true)
		draw.DrawText(("markup render/think time: %.1fms"):format((t2 - t)*1000), "OSB48", w/2, h + 44, color_black, 1, 4)
		--local w, h = draw.DrawText(string.WordWrap2(("%q"):format(tx), w - 8, "OS18"), "OS18", w/2, h + 64, Colors.DarkerRed, 1, 4)
	surface.DisableClipping(false)
end
