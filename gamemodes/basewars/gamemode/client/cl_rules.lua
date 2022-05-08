
local emotes = {
	"NeptuneFastNod",
	"RalseiBoof"
}

local bsTimesOpened = 0

function ulx.showMotdMenu( steamid )
	bsTimesOpened = bsTimesOpened + 1

	local window = vgui.Create( "FFrame" )
	window:SetSize(450, 200)
	window:Center()
	window:MakePopup()
	window.Shadow = {}

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

	local bullshit = BaseWars.Tutorial.CurrentStep == "Complete" and math.random() < (2 + bsTimesOpened * 5) / 100

	local n = 0

	local rules
	local sizer = mup

	if bullshit then
		bsTimesOpened = 0
		window:SetWide(600)

		mup:DockMargin(0, 0, 0, 0)
		local par = vgui.Create("FScrollPanel", window)
		par:SetSize(window:GetWide() - 16, 400)
		par:Center()
		par.Y = lbl.Y + lbl:GetTall() + 8

		sizer = par
		mup:SetParent(par)

		rules = {
			"Don't cheat.",
			"Don't try to crash the server.",
			"No RDM.",
			"No NLR.",
			"Citizens aren't supposed to have guns.",
			"No propblocking.",
			"No FailRP.",
			"Max. 3 fading doors and 6 keypads.",
			"Flashing props aren't allowed.",
			"One-way props must only be used for view.",
			"World glow is not allowed.",
			"No one-ways allowed.",
			"No Fading Door Abuse.",
			"No Metagaming. (Don't abuse OOC)",
			"No RDA (random arrests)",
			"You must advert raids, mugs, terrors.",
			"Raids can only be done by Thief, Pro Thief, Pro++ Thief, Diamond VIP++ Pro Thief.",
			"Do not use /demote when an admin is on the server.",
			"Do not place hits on the same person more often than 10 minutes.",
			"No stacking props inside each other.",
			"No blocking the streets.",
			"Do not build while you are being raided.",
			"No invisible props.",
			"Hobos cannot own property.",
			"Max mug amount is 20,000$.",
			"Max kidnap ransom is 20,000$.",
			"Max ransom time is 15 minutes.",
			"Only the Maniac job is allowed to /advert Murder.",
			"Only the Terrorist job is allowed to /advert Terror.",
			"Scamming is not allowed.",
		}
	else
		rules = {
			"Don't cheat.",
			"Don't try to crash the server.",
		}
	end

	for k,v in ipairs(rules) do
		local p = mup:AddPiece()
		p:Dock(TOP)
		p:SetFont("OS22")
		p:AddText( k .. ". " .. v)
	end

	n = #rules

	local p = mup:AddPiece()
	p:Dock(TOP)
	p:SetFont("OSB28")
	p:AddText((n + 1) .. ".")
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
	p:On("RecalculateHeight", function() return 64 end)
	p:On("Newline", p, function() end)
	p.LineHeights[1] = 64 -- i hate myself


	-- http://vaati.net/Gachi/shared/672138980434772026.png

	local close = vgui.Create("FButton", window)
	close.Label = "okay fine"
	close:SetSize(180, 40)
	close:Center()

	window:InvalidateChildren(true)
	sizer:InvalidateLayout(true)

	window:SetTall(sizer.Y + sizer:GetTall() + close:GetTall() + 32)
	window:Center()
	window.Y = window.Y - 48
	window:MoveBy(0, 48, 0.3, 0, 0.3)
	window:CacheShadow(2, 4, 4)

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