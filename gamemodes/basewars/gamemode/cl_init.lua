include("include.lua")

GM.Name 		= "BaseWars"
GM.Author 		= "gachirmx"


local PLAYER = debug.getregistry().Player

function GM:GetGameDescription()
	return self.Name
end

ScoreBoard = ScoreBoard or nil

surface.CreateFont("SB_TeamName", {
	font = "Open Sans SemiBold",
	size = 36,
	weight = 600,
	antialias = true,
})

local scale = 1

local render = render
local c = Material("vgui/circle")
c:SetInt("$alpha", 1)
c:Recompute()
function CreatePlayerFrame(sb, ply)

	local f = vgui.Create("EButton", sb)

	f:SetTall(64)
	f.DrawShadow = false
	f.ExpandTo = 64
	f:SetColor(Color(50, 50, 50), true)

	function f:OnClick()
		for k,v in pairs(sb.Frs) do
			if v ~= self and IsValid(v) then v:RetractBtn() end
		end
	end

	local av = vgui.Create("AvatarImage", f)
	av:SetPlayer(ply, 64)
	av:SetSize(48, 48)
	av.HovSize = 56
	av.X = 12
	av:CenterVertical()

	av:SetPaintedManually(true)
	av:SetMouseInputEnabled(true)

	local avbtn = vgui.Create("FButton", av)
	avbtn:Dock(FILL)
	avbtn.NoDraw = true

	function avbtn:DoClick()
		ply:ShowProfile()
	end

	local sidcol = Color(150, 150, 150)

	local sid = vgui.Create("DLabel", f.ExpandPanel)
	sid:SetPos(16, 4)

	local sidnum = (IsPlayer(ply) and not ply:IsBot() and ply:SteamID()) or ((IsValid(ply) and ply:IsBot()) and "(BOT)") or "[NONE?]"
	local sidstr = ("SteamID: %s"):format(sidnum)
	sid:SetFont("OS24")
	sid:SetText(sidstr)
	sid:SizeToContents()
	sid:SetSize(sid:GetWide() + 8, sid:GetTall()) --no unclickable margins between label and button, but still an 8px visible margin
	sid:SetMouseInputEnabled(true)
	function sid:Paint(w, h)
		self:SetTextColor(sidcol)
	end

	local copy = vgui.Create("DButton", f.ExpandPanel)
	copy:SetPos(sid.X + sid:GetWide(), 3)
	copy:SetSize(24, 24)
	copy:SetText("")

	local txs = {}

	function copy:Paint(w, h)
		if self:IsHovered() or sid:IsHovered() then
			sidcol = LC(sidcol, color_white, 15)
		else
			sidcol = LC(sidcol, Color(150, 150, 150), 15)
		end

		surface.DisableClipping(true)

			for k,v in pairs(txs) do
				v.x = L(v.x, 20, 7)
				if v.x >= 16 then
					v.a = L(v.a, 0, 10)
				else
					v.a = L(v.a, 255, 15, true)
				end

				if v.a <= 0.2 then
					table.remove(txs, k)
				end
				draw.SimpleText("SteamID copied to clipboard!", "OS24", w + v.x, h/2, ColorAlpha(color_white, v.a), 0, 1)
			end

		surface.DisableClipping(false)

		surface.SetDrawColor(color_white)
		surface.DrawMaterial("https://i.imgur.com/VFTGo4c.png", "copy.png", 0, 0, w, h)
	end

	function copy:DoClick()
		if #txs <= 2 then
			txs[#txs + 1] = {x = 0, a = 2}
		end
		SetClipboardText(sidnum)
	end

	sid.DoClick = copy.DoClick
	--copy:SetDoubleClickingEnabled(false)
	if ply ~= LocalPlayer() then

		local mute = vgui.Create("FButton", f.ExpandPanel)
		mute.DrawShadow = false
		mute:SetSize(64, 32)
		mute:SetColor(190, 50, 50)

		mute.Label = "Mute"
		mute.Font = "OS24"
		mute:Dock(RIGHT)
		mute:DockMargin(4, 8, 16, 8)
		local muted = ply:IsMuted()
		function mute:PrePaint(w,h)
			if IsValid(ply) then muted = ply:IsMuted() end
			if muted ~= 0 then
					self.Label = "Unmute"
				return
			end
			self.Label = "Mute"
		end

		local pm = vgui.Create("FButton", f.ExpandPanel)
		pm.DrawShadow = false
		pm:SetSize(64, 32)
		pm:SetColor(50, 130, 230)

		pm.Label = "PM"
		pm.Font = "OSB24"
		pm:Dock(RIGHT)
		pm:DockMargin(4, 8, 4, 8)
		function pm:DoClick()
			local pf = vgui.Create("FFrame")
			pf:SetPos(gui.MouseX() - 300, gui.MouseY() + 2)
			pf:SetSize(600, 160)
			pf.Label = "PM " .. ply:Nick()
			pf:MakePopup()
			pf.Shadow = {}
			pf:PopIn()

			local triedtoshift = false
			local sha = 255
			local shy = 0
			function pf:PrePaint(w,h)
				if triedtoshift then
					surface.DisableClipping(true)
						draw.SimpleText("SHIFT+Enter again to send the text", "OSB24", w/2, h+shy, Color(230, 70, 70, sha), 1, 4)
					surface.DisableClipping(false)
					if CurTime() - triedtoshift > 1.5 then
						sha = L(sha, 0, 10, true)
					end

					shy = L(shy, 35, 7)
				end
			end
			local col = color_white:Copy()

			local te = vgui.Create("FTextEntry", pf)
			te:SetFont("OS24")
			te:Dock(FILL)
			te:DockMargin(8, 16, 8, 24)
			te:SetEnterAllowed(true)
			function te:OnEnter()
				if input.IsKeyDown(KEY_LSHIFT) and not triedtoshift then
					triedtoshift = CurTime()
					return
				end
				net.Start("PrivateMessage")
					net.WriteString(te:GetValue())
					net.WriteEntity(ply)
				net.SendToServer()
				pf:PopOut()
			end

			function pf:PostPaint(w,h)
				col = LC(col, (#te:GetValue() < 300 and color_white) or Color(200, 100, 100), 15)
				draw.SimpleText(#te:GetValue() .. "/300", "OS24", w/2, h - 2, col, 1, 4)
			end

		end

	end

	local prof = vgui.Create("FButton", f.ExpandPanel)
	prof:SetSize(64, 16)
	prof:Dock(RIGHT)
	prof:DockMargin(4, 8, 8, 8)

	prof.Label = "Profile"
	prof:SetColor(Color(80, 80, 80))

	function prof:DoClick()
		ply:ShowProfile()
	end

	local lastnick = ply:Nick()
	local lv = ply:GetLevel()
	local mon = ply:GetMoney()
	local time = ply:GetPlayTime()
	local col = f.TeamColor

	local cloud = vgui.Create("Cloud")

	cloud:Bond(f)
	cloud:SetText("View Profile")
	cloud:Popup(false)


	function avbtn:OnHover()
		f.ForceHovered = true

		cloud:Popup(true)
		cloud:MoveAbove(self)
		av:To("HovFrac", 1, 0.3, 0, 0.3)
	end

	function avbtn:OnUnhover()
		f.ForceHovered = false

		cloud:Popup(false)
		av:To("HovFrac", 0, 0.3, 0, 0.3)
	end

	local avSz = av:GetSize()

	function f:PostPaint(w, h)

		if not IsValid(ply) then --ok bye bye
			if not self.ByeBye then
				self:PopOut()
				self:MoveBy(600, 0, 0.4, 0, 2)
				self.ByeBye = true
			end
		else
			lastnick = ply:Nick()
			lv = ply:GetLevel()

			mon = ply:GetMoney()
			mon = BaseWars.NumberFormat(mon or 0)
			time = ply:GetPlayTime()
			col = col or team.GetColor(ply:Team())
		end

		local newSz = Lerp(av.HovFrac or 0, avSz, av.HovSize)
		av.X = 16 - (newSz - avSz) / 2

		av:SetSize(newSz, newSz)
		-- centervertical wont work properly due to expand button
		av.Y = h / 2 - av:GetTall() / 2 

		draw.SimpleText(lastnick .. " ", "TW32", 88, 2, color_white)

		local infoFont = "OS20"
		local lines = 2
		local lHgt = draw.GetFontHeight(infoFont) * lines

		local y = h / 2 - lHgt / 2

		local _, th = draw.SimpleText(Language.Currency .. mon, "OS20",
			w - 32, y, color_white, 2, 5)
		y = y + th

		local time = string.FormattedTime(time)
		local str = "%s%s%s"

		local hrs = ""
		local mins = ""
		local secs = ""

		if time.h then
			hrs = ("%sh. "):format(time.h)
		end

		if time.m then
			mins = ("%sm. "):format(time.m)
		end

		secs = ("%ss."):format(time.s)
		str = str:format(hrs, mins, secs)

		_, th = draw.SimpleText(str, "OS20", w - 32, y, color_white, 2, 5)
		y = y + th

		local aW, aH = av:GetSize()
		local x, y = av.X, av.Y

		col.a = 255

		draw.BeginMask()

			surface.SetDrawColor(color_white)
			draw.Circle(x + aW/2, y + aH/2, aW / 2 - 2, 16)

		draw.DrawOp()
			av:SetAlpha(255)
			av:PaintManual()

		draw.DisableMask()

		surface.SetDrawColor(ColorAlpha(col, self:GetAlpha()))
		surface.DrawMaterial("https://i.imgur.com/VMZue2h.png",
			"circle_outline.png", x, y, aW, aH)


	end


	return f
end


function GM:ScoreboardShow()
	if ScoreBoard and IsValid(ScoreBoard) then return end --???

	ScoreBoard = vgui.Create("FFrame")

	local sb = ScoreBoard
	sb.BackgroundColor.a = 240

	scale = ScrW()/1920

	local sw, sh = ScrW(), ScrH()

	local ww = math.min(sw*0.8, 900)
	sb:SetSize(ww, sh * 0.7)
	sb:Center()

	sb:DockPadding(8, sb.HeaderSize + 16, 8, 12)

	sb:PopIn(0.04)

	local frs = {}
	local scr

	local saveme = vgui.Create("FButton", sb)
	saveme:Dock(BOTTOM)
	saveme:SetTall(50)
	saveme.Label = "SAVE ME (debug)"

	function saveme:DoClick()
		sb:SetSize(60, 40)
	end

	local function NewPlayerFrame(ply, col)
		local f = CreatePlayerFrame(scr, ply)

		f:InvalidateParent(true)

		f.TeamColor = col --if col isnt provided it'll update

		f:Dock(TOP)
		f:DockMargin(16, 6, 24, 6)

		--py = py + f:GetTall() + 8

		frs[ply] = f
		return f
	end

	function sb:Think()

		if input.IsMouseDown(MOUSE_RIGHT) and not self.PoppedUp then
			self:MakePopup()
			self:SetKeyBoardInputEnabled(false)
			self.PoppedUp = true
		end

		for k,v in ipairs(player.GetAll()) do
			if not frs[v] then
				local f = NewPlayerFrame(v)
				f:PopIn()
			end
		end
	end


	scr = vgui.Create("FScrollPanel", sb)

	scr:Dock(FILL)
	scr.BackgroundColor = Color(0, 0, 0, 110)
	scr:GetCanvas():DockPadding(16, 4, 16, 8)

	local v = scr:GetVBar()

	v:SetEnabled(true)	--goddamnit garry

	local pteams = {}

	for k,v in ipairs(player.GetAll()) do
		if not pteams[v:Team()] then pteams[v:Team()] = {} end

		local team = pteams[v:Team()]
		team[#team+1] = v
	end
	local teaminfo = team.GetAllTeams()

	local ty = 0



	for k,v in pairs(pteams) do
		if not teaminfo[k] then print('the fuck?') continue end

		local col = teaminfo[k].Color
		local name = teaminfo[k].Name
		local tn = vgui.Create("InvisPanel", scr)
		local bgCol = Colors.Button

		function tn:Paint(w,h)
			draw.RoundedBox(8, 0, 0, w, h, bgCol)
			draw.SimpleText(name, "SB_TeamName", 16, h/2, col, 0, 1)

		end
		tn:Dock(TOP)
		tn:DockMargin(0, 4, 18, 4)
		tn:SetTall(48)

		for num, ply in pairs(v) do
			NewPlayerFrame(ply, col)
		end

		--ty = ty + py + 24
	end
	v:SetEnabled(false)
	scr.Frs = frs
end

function GM:ScoreboardHide()

	if ScoreBoard and IsValid(ScoreBoard) then ScoreBoard:PopOut(0.04) ScoreBoard = nil return end --???

end

local Lerp = Lerp
local math = math

function LC(col, dest, vel)
	local v = vel or 10
	if not IsColor(col) or not IsColor(dest) then return end

	col.r = Lerp(FrameTime()*v, col.r, dest.r)
	col.g = Lerp(FrameTime()*v, col.g, dest.g)
	col.b = Lerp(FrameTime()*v, col.b, dest.b)

	if dest.a ~= col.a then
		col.a = Lerp(FrameTime()*v, col.a, dest.a)
	end

	return col
end

function LCC(col, r, g, b, a, vel)
	local v = vel or 10


	col.r = Lerp(FrameTime()*v, col.r, r)
	col.g = Lerp(FrameTime()*v, col.g, g)
	col.b = Lerp(FrameTime()*v, col.b, b)

	if a and a ~= col.a then
		col.a = Lerp(FrameTime()*v, col.a, a)
	end

	return col
end

function L(s,d,v,pnl)
	if not v then v = 5 end
	if not s then s = 0 end
	local res = Lerp(FrameTime()*v, s, d)
	if pnl then
		local choose = (res>s and "ceil") or "floor"
		res = math[choose](res)
	end
	return res
end