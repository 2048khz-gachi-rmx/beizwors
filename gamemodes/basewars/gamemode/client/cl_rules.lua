
local emotes = {
	"NeptuneFastNod",
	"RalseiBoof"
}

function ulx.showMotdMenu( steamid )

	local window = vgui.Create( "FFrame" )
	window:SetSize(400, 250)
	window:Center()
	window:MakePopup()
	window.Shadow = {}

	window.Y = window.Y - 48
	window:MoveBy(0, 48, 0.3, 0, 0.3)
	window:PopIn()
	window:AddDockPadding(16, 8, 16, 0)
	local ruleFont = "OS20"
	local th = draw.GetFontHeight(ruleFont)

	local lbl = vgui.Create("DLabel", window)
	lbl:SetColor(color_white)
	lbl:SetFont("OSB36")
	lbl:Dock(TOP)
	lbl:SetText("Rules of the land:")
	lbl:SetContentAlignment(5)

	function window:PostPaint(w, h)
		--[[local y = self.HeaderSize
		local _, hth = draw.SimpleText(, "OSB36", w/2, y, color_white, 1, 5)
		y = y + hth

		draw.DrawText("1. Don't cheat.", ruleFont, 16, y, color_white, 0, 5)
		y = y + th

		draw.DrawText("2. Don't try to crash the server.", ruleFont, 16, y, color_white, 0, 5)
		y = y + th
		--draw.SimpleText("Thankssssssssssss", "OS18", 16, self.HeaderSize + 108, color_white, 0, 5)
		]]
	end

	local mup = vgui.Create("MarkupText", window)
	mup:DockMargin(0, 16, 0, 0)
	mup:Dock(TOP)
	mup:InvalidateParent(true)

	local p = mup:AddPiece()
	p:SetFont("OS22")
	p:AddText("1. Don't cheat.")

	local p = mup:AddPiece()
	p:SetFont("OS22")
	p:AddText("2. Don't try to crash the server.")

	local p = mup:AddPiece()
	p:Dock(TOP)
	p:SetFont("OSB28")
	p:AddText("3.")
	p:SetHAlignment(1)

	p:AddTag(MarkupTag("chartranslate", 0, function(char, i)
		if not i then return end -- layout pass
		return math.sin(CurTime() * 3 - i / 3) * 4
	end))

	p:AddTag(MarkupTag("hsv", function() return CurTime() * 45 end, 0.6))

	local emote = emotes[math.random(#emotes)]
	p:AddTag(MarkupTag("emote", emote, 64, 64))
	p:AddText("Have fun")
	p:AddTag(MarkupTag("emote", emote, 64, 64))
	p:AddText("\n")
	-- http://vaati.net/Gachi/shared/672138980434772026.png

	local close = vgui.Create("FButton", window)
	close.Label = "okay fine"
	close:SetSize(180, 40)
	close:Center()
	close.Y = window:GetTall() - close:GetTall() - 16
	close:SetColor(50, 150, 250)

	function window:OnClose()
		self:MoveBy(0, 48, 0.2, 0, 3.2)
		self:PopOut(0.2)
		self:SetInput(false)
		return false
	end

	close.DoClick = function()
		window:OnClose()
	end

end

function ulx.rcvMotd( mode_, data )
	--fuck off ulx
end