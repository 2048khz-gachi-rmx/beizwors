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
	size = 28,
	weight = 600,
	antialias = true,
})

local c = Material("vgui/circle")
c:SetInt("$alpha", 1)
c:Recompute()

local plyFrameSize = 48

function CreatePlayerFrame(sb, ply)
	local f = vgui.Create("EButton", sb)

	f:SetTall(plyFrameSize)
	f.DrawShadow = false
	f.ExpandTo = 48
	f.RBRadius = 8

	function f:OnClick()
		for k,v in pairs(sb.plys) do
			if v ~= self and IsValid(v) then v:RetractBtn() end
		end
	end

	f:On("ExpandChanged", "fuck", function()
		sb:UpdateSize()
	end)

	local av = vgui.Create("CircularAvatar", f)
	av:SetPlayer(ply, 64)
	av:SetSize(40, 40)
	av.HovSize = 48
	av.X = 8
	av.Rounding = 8
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
		mute:SetSize(80, 32)
		mute:SetColor(190, 50, 50)

		mute.Label = "Mute"
		mute.Font = "OS24"
		mute:Dock(RIGHT)
		mute:DockMargin(4, 8, 16, 8)
		local muted = ply:IsMuted()

		function mute:PrePaint(w,h)
			if IsValid(ply) then muted = ply:IsMuted() end
			self.Label = muted and "Unmute" or "Mute"
		end

		function mute:DoClick()
			ply:SetMuted(not ply:IsMuted())
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
	local ping = ply:Ping()
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

	local dim = Color(0, 0, 0)

	function f:PostPaint(w, h)
		dim:Set(col)
		BW.DimColor(dim, 0.6, 0.7)
		self:SetColor(dim, true)

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
			ping = ply:Ping()
		end

		local newSz = Lerp(av.HovFrac or 0, avSz, av.HovSize)
		av.X = 4 - (newSz - avSz) / 2
		av.Rounding = Lerp(av.HovFrac or 0, 8, 0)
		av:SetSize(newSz, newSz)
		-- centervertical wont work properly due to expand button
		av.Y = h / 2 - av:GetTall() / 2

		local textCol = BW.PickContrast(dim, 0.5)
		local _, nh = draw.SimpleText(lastnick .. " ", "EXM32", av.X + av:GetWide() + 8, 2 - 32 * 0.2, textCol)

		local infoFont = "OS20"
		local lines = 2
		local lHgt = draw.GetFontHeight(infoFont) * lines

		local y = h / 2 - lHgt / 2

		local _, th = draw.SimpleText(Language.Money(mon), "OS20", av.X + av:GetWide() + 16, nh * 0.75, textCol)

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

		_, th = draw.SimpleText(str, "OS20", w - 32, y, textCol, 2, 5)
		y = y + th

		local aW, aH = av:GetSize()
		local x, y = av.X, av.Y

		col.a = 255

		--[[draw.BeginMask()

			surface.SetDrawColor(color_white)
			draw.Circle(x + aW/2, y + aH/2, aW / 2 - 2, 16)

		draw.DrawOp()
			av:SetAlpha(255)
			av:PaintManual()

		draw.DisableMask()]]
		av:PaintManual()

		--[[surface.SetDrawColor(ColorAlpha(col, self:GetAlpha()))
		surface.DrawMaterial("https://i.imgur.com/VMZue2h.png",
			"circle_outline.png", x, y, aW, aH)]]


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
	sb:SetSize(ww, sh * 0.92)
	sb:Center()

	sb:DockPadding(8, sb.HeaderSize, 8, 12)

	sb:PopIn(0.04)

	local head = vgui.Create("InvisPanel", sb)
	head:Dock(TOP)
	head:SetTall(56)

	local ftext = "Lodestar Basewars"
	local font1 = "OSB36"

	local ftx2 = "Currently housing %d/%d players"
	local font2 = "EX24"

	local icSz = head:GetTall() * 0.8
	local ic = Icons.Lodestar:Copy()

	function head:PostPaint(w, h)
		local text = ftext
		local tx2 = ftx2:format(player.GetCount(), game.MaxPlayers())

		local tw1, th1 = surface.GetTextSizeQuick(text, font1)
		local tw2, th2 = surface.GetTextSizeQuick(tx2, font2)

		local rw, rh = ic:RatioSize(icSz, icSz)
		local ix = w / 2 - math.max(tw1, tw2) / 2 - rw / 2 - 8
		local iy = h / 2 - rh / 2

		ic:Paint(ix, iy, rw, rh)

		local x = ix + rw + 16
		draw.SimpleText(text, font1, x, 2, color_white)
		draw.SimpleText(tx2, font2, x + tw1 / 2 - tw2 / 2, h - th2 - 2, color_white)
	end

	local frs = {}
	local scr

	if GetConVar("developer"):GetInt() > 0 then
		local saveme = vgui.Create("FButton", sb)
		saveme:Dock(BOTTOM)
		saveme:SetTall(50)
		saveme.Label = "SAVE ME (debug)"

		function saveme:DoClick()
			sb:SetSize(60, 40)
		end
	end

	local function NewPlayerFrame(ply, col, parTo)
		local f = CreatePlayerFrame(parTo, ply)

		f:InvalidateParent(true)

		f.TeamColor = col --if col isnt provided it'll update

		f:Dock(TOP)
		f:DockMargin(16, 0, 24, 6)

		--py = py + f:GetTall() + 8

		frs[ply] = f
		return f
	end

	local teamFrames = {}

	function sb:Think()

		if input.IsMouseDown(MOUSE_RIGHT) and not self.PoppedUp then
			self:MakePopup()
			self:SetKeyBoardInputEnabled(false)
			self.PoppedUp = true
		end

		for k,v in ipairs(player.GetAll()) do
			if not frs[v] and v:Team() and IsValid(teamFrames[v:Team()]) then
				teamFrames[v:Team()]:AddPlayer(v)
			end
		end
	end


	scr = vgui.Create("FScrollPanel", sb)

	scr:Dock(FILL)
	scr.BackgroundColor = Color(0, 0, 0, 110)
	scr:GetCanvas():DockPadding(16, 4, 16, 8)

	local vbar = scr:GetVBar()
	vbar:SetEnabled(true)	--goddamnit garry

	scr:On("ScrollbarAppear", "aaa", function()
		scr:GetCanvas():DockPadding(16, 4, vbar:IsVisible() and 16 - vbar:GetWide() or 16, 8)
	end)

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
		local dim = BW.DimmedColor(col, 0.35, 0.5, true)
		local name = teaminfo[k].Name
		local tn = vgui.Create("InvisPanel", scr)
		local bgCol = Colors.Button

		function tn:Paint(w, h)
			local bord = 2
			draw.RoundedBox(8, 0, 0, w, h, col)
			draw.RoundedBox(8, bord, bord, w - bord * 2, h - bord * 2, dim)
			draw.SimpleText(name, "SB_TeamName", 16, 2, col)
		end

		tn.plys = {}
		function tn:AddPlayer(ply)
			if not IsValid(ply) then errorNHf("what %s", ply) return end
			if self.plys[ply] then return end

			self.plys[ply] = NewPlayerFrame(ply, col, self)
			self:SetTall(28 + 2 * 2 +
				table.Count(self.plys) * (plyFrameSize + 6) - 6
				+ 8
			)
		end

		function tn:UpdateSize()
			local h = 28 + 2 * 2

			for k,v in pairs(self.plys) do
				h = h + (v.Expand and v.ExpandTo or 0) + v:GetRealH() + 8
			end

			self:SizeTo(self:GetWide(), h, 0.3, 0, 0.3)
		end

		teamFrames[k] = tn

		tn:Dock(TOP)
		tn:DockMargin(0, 4, 18, 4)
		tn:DockPadding(0, 32, 0, 8)

		for num, ply in pairs(v) do
			tn:AddPlayer(ply)
		end

		--ty = ty + py + 24
	end

	vbar:SetEnabled(false)
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

	local ft = FrameTime()

	col.r = Lerp(ft * v, col.r, r)
	col.g = Lerp(ft * v, col.g, g)
	col.b = Lerp(ft * v, col.b, b)

	if a and a ~= col.a then
		col.a = Lerp(ft * v, col.a, a)
	end

	return col
end

function L(s,d,v,pnl)
	if not v then v = 5 end
	if not s then s = 0 end
	local res = Lerp(FrameTime() * v, s, d)
	if pnl then
		local choose = (res > s and "ceil") or "floor"
		res = math[choose](res)
	end
	return res
end

local MIDISuccess = false
function MIDIRequire()
	if file.Exists("lua/bin/gmcl_midi_win32.dll", "MOD") or
		file.Exists("lua/bin/gmcl_midi_win64.dll", "MOD") or
		file.Exists("lua/bin/gmcl_midi_linux.dll", "MOD") then
		require("midi")
		MIDISuccess = true
	else
		print("No MIDI module; not including")
		return
	end

	timer.Simple(3, function()
		if not MIDISuccess then print("did not find MIDI module") return end
		if MIDISuccess == true and (not midi or not midi.Open) then
			error("required MIDI module successfully(?) but midi table was not created!")
			return
		end

		midi.Open()
		--credits to DerModMaster for this V V V
		local MIDIKeys = {
				[36] = { Sound = "a1"  }, -- C
				[37] = { Sound = "b1"  },
				[38] = { Sound = "a2"  },
				[39] = { Sound = "b2"  },
				[40] = { Sound = "a3"  },
				[41] = { Sound = "a4"  },
				[42] = { Sound = "b3"  },
				[43] = { Sound = "a5"  },
				[44] = { Sound = "b4"  },
				[45] = { Sound = "a6"  },
				[46] = { Sound = "b5"  },
				[47] = { Sound = "a7"  },
				[48] = { Sound = "a8"  }, -- c
				[49] = { Sound = "b6"  },
				[50] = { Sound = "a9"  },
				[51] = { Sound = "b7"  },
				[52] = { Sound = "a10" },
				[53] = { Sound = "a11" },
				[54] = { Sound = "b8"  },
				[55] = { Sound = "a12" },
				[56] = { Sound = "b9"  },
				[57] = { Sound = "a13" },
				[58] = { Sound = "b10" },
				[59] = { Sound = "a14" },
				[60] = { Sound = "a15" }, -- c'
				[61] = { Sound = "b11" },
				[62] = { Sound = "a16" },
				[63] = { Sound = "b12" },
				[64] = { Sound = "a17" },
				[65] = { Sound = "a18" },
				[66] = { Sound = "b13" },
				[67] = { Sound = "a19" },
				[68] = { Sound = "b14" },
				[69] = { Sound = "a20" },
				[70] = { Sound = "b15" },
				[71] = { Sound = "a21" },
				[72] = { Sound = "a22" }, -- c''
				[73] = { Sound = "b16" },
				[74] = { Sound = "a23" },
				[75] = { Sound = "b17" },
				[76] = { Sound = "a24" },
				[77] = { Sound = "a25" },
				[78] = { Sound = "b18" },
				[79] = { Sound = "a26" },
				[80] = { Sound = "b19" },
				[81] = { Sound = "a27" },
				[82] = { Sound = "b20" },
				[83] = { Sound = "a28" },
				[84] = { Sound = "a29" }, -- c'''
				[85] = { Sound = "b21" },
				[86] = { Sound = "a30" },
				[87] = { Sound = "b22" },
				[88] = { Sound = "a31" },
				[89] = { Sound = "a32" },
				[90] = { Sound = "b23" },
				[91] = { Sound = "a33" },
				[92] = { Sound = "b24" },
				[93] = { Sound = "a34" },
				[94] = { Sound = "b25" },
				[95] = { Sound = "a35" },
				[96] = { Sound = "a36" },
			}

			concommand.Add("MIDIPorts", function()
				if midi and midi.GetPorts then
					PrintTable(midi.GetPorts())
				else
					print("MIDI module did not load!")
				end
			end)

			hook.Add("MIDI", "playablePiano", function(time, command, note, velocity)
				local instrument = LocalPlayer().Instrument
				if not IsValid( instrument ) then return end

				-- Zero velocity NOTE_ON substitutes NOTE_OFF
				if not midi or midi.GetCommandName( command ) ~= "NOTE_ON" or velocity == 0 or not MIDIKeys or not MIDIKeys[note] then return end

				instrument:OnRegisteredKeyPlayed(MIDIKeys[note].Sound)

				net.Start("InstrumentNetwork")
					net.WriteEntity(instrument)
					net.WriteInt(INSTNET_PLAY, 3)
					net.WriteString(MIDIKeys[note].Sound)
				net.SendToServer()
			end)
	end)
end

MIDIRequire()