--

local function openDiscord()
	local f = vgui.Create("FFrame")
		f:SetSize(400, 200)
		f:Center()

	local col = Color(86, 100, 247)

		f.Y = f.Y - 32
		f:MoveBy(0, 32, 0.3, 0, 0.3)
		f:PopIn()
		f:MakePopup()
		f.HeaderColor = col:Copy():MulHSV(1, 0.7, 1)

	local ty = f.HeaderSize + 24 + draw.GetFontHeight("OS32") + 4

	local dt = DeltaText()
		:SetFont("OSB32")

	dt.AlignX = 1

	local doit = dt:AddText("Open lodestar discord server?")
	dt:ActivateElement(doit)

	local done = dt:AddText("Check your discord window!")
	done:SetColor(col:Copy():MulHSV(1, 0.8, 1))

	function f:PostPaint(w, h)
		dt:Paint(w / 2, self.HeaderSize + 24)
	end

	local btn = vgui.Create("FButton", f)
	btn:SetWide(f:GetWide() * 0.75)
	btn:SetTall( (f:GetTall() - ty) / 2 )
	btn:CenterHorizontal()
	btn.Y = (f:GetTall() - ty)
	btn:SetColor(col)
	btn:SetText("yes please")

	function btn:DoClick()
		dt:ActivateElement(done)
		self:SetEnabled(false)
		f:Timer("goaway", 5, 1, function()
			f:PopOut(0.2, 0.1)
			f:MoveBy(0, 32, 0.3, 0, 2.7)
			f:SetInput(false)
		end)

		local dh = vgui.Create("DHTML", f)
			dh:SetSize(1, 1)
			dh:OpenURL(BaseWars.Config.DiscordLink)
	end
end

local function openContent()
	gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=2662165222")
end

local numToFunc = {
	openDiscord,
	openContent,
}

net.Receive("CommandThing", function()
	local id = net.ReadUInt(4) + 1
	numToFunc[id] ()
end)