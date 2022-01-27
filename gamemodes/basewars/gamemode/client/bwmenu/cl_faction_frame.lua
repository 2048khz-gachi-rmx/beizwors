local FAC = {}
Factions = Factions or {}

--[[------------------------------]]
--	   	   	   Helpers
--[[------------------------------]]

-- dim the provided color
local dim = function(col, amt, sat, safe)
	local ch, cs, cv = col:ToHSV()
	cv = cv * (amt or 0.8)

	-- color is very close to Color(50, 50, 50) which is the scrollpanel color
	if safe and cs < 0.15 and (cv > 0.15 and cv < 0.25) then
		-- if it's sufficiently bright, make it gray
		-- otherwise, make it pitch black
		cv = (cv >= 0.2) and 0.35 or 0.05
	end

	draw.ColorModHSV(col, ch, cs * (sat or 0.9), cv)
end

-- return a dimmed copy of the color
local getDimmed = function(col, amt, sat, safe)
	col = col:Copy()
	dim(col, amt, sat)
	return col
end

local gu = Material("vgui/gradient-u")
local gd = Material("vgui/gradient-d")
local gr = Material("vgui/gradient-r")
local gl = Material("vgui/gradient-l")

local fonts = BaseWars.Menu.Fonts

-- the faction frame consists of two panels: the colored canvas at the top
-- and the player list at the bottom


function FAC:CanvasPaint(w, h)
	-- this is used by the canvas, not by the faction panel itself

	-- disabling clipping because otherwise when the panel fades to the right
	-- the right edge will be invisible

	-- this just looks better

	self.MaxHeight = math.max(self.MaxHeight or 0, h)
	h = self.MaxHeight

	local col, bordCol = self.MainColor, self.BorderColor
	local fac = self.Faction

	surface.DisableClipping(true)
		surface.SetDrawColor(col:Unpack())
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(bordCol:Unpack())

		-- inlined DrawGradientBorder
		local gw, gh = 3, 3

		surface.SetMaterial(gu)
		surface.DrawTexturedRect(0, 0, w, gh)

		if not self.NoDrawBottomGradient then
			surface.SetMaterial(gd)
			surface.DrawTexturedRect(0, h - gh, w, gh)
		end


		surface.SetMaterial(gr)
		surface.DrawTexturedRect(w - gw, 0, gw, h)

		surface.SetMaterial(gl)
		surface.DrawTexturedRect(0, 0, gw, h)

		--self:DrawGradientBorder(w, h, 3, 3)
	surface.DisableClipping(false)

	draw.SimpleText2(fac:GetName(), fonts.BoldMedium, w/2, h * 0.05, fac:GetColor(), 1)
end

function FAC:Init()
	local bord = vgui.Create("Panel", self)
	bord:Dock(FILL)

	self.Main = bord
	bord.NoDrawBottomGradient = true
	self:On("FactionSet", "Canvas", function(_, fac)

		local col = getDimmed(fac:GetColor(), 0.2, 0.3, true)
			local h, s, v = col:ToHSV()
			draw.ColorModHSV(col, h, s, math.max(v, 0.15))

		local bordCol = fac:GetColor():Copy()
			h, s, v = bordCol:ToHSV()
			draw.ColorModHSV(bordCol, h, s, (v < 0.3 and s < 0.1) and 0.06 or v)

		bord.MainColor = col
		bord.BorderColor = bordCol
		bord.Paint = self.CanvasPaint
	end)

end


local hovHeight = 16 -- members list will expand by (hovHeight)px up when a member is hovered
Factions.HoverMembersList = 16

function FAC:CreateMemberList()
	if self.Faction == Factions.NoFaction then return end -- nuh-uh, that one's custom

	local facPnl = self
	local fac = self.Faction

	local plyList = vgui.Create("Panel", self)
	plyList:Dock(BOTTOM)
	plyList:SetTall(self:GetTall() * 0.15)
	plyList:InvalidateParent(true)
	plyList:InvalidateLayout(true)
	plyList.FoldedY = self:GetTall() - plyList:GetTall()

	local col = Colors.DarkGray
	local pX, pY = plyList:LocalToScreen(0, 0)

	function plyList:Paint(w, h)
		surface.DisableClipping(true)
			surface.SetDrawColor(col:Unpack())
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(color_black:Unpack())
			self:DrawGradientBorder(w, h, 3, 3)
		surface.DisableClipping(false)

		pX, pY = self:LocalToScreen(0, 0)
	end


	function plyList:PaintOver(w, h)
		local hov = 0
		for k,v in ipairs(self.Players) do
			v:Emit("plyListPaintOver", v:GetSize())
			hov = math.max(hov, v.HovFrac)
		end

		self:SetTall(facPnl:GetTall() * 0.15 + hov * hovHeight)
	end

	plyList.Players = {} -- actually player avatars

	local plys = plyList.Players
	local amt = #fac:GetMembersInfo()

	local avSize, fullW, x, y
	avSize = plyList:GetTall() * 0.7 -- the panels are square

	local function recalculate()
		amt = #fac:GetMembersInfo()

		fullW = (avSize + 8) * amt - 8

		x = plyList:GetWide() / 2 - fullW / 2
		y = plyList:GetTall() - avSize * 0.6

		for _, av in ipairs(plys) do
			av:To("X", x, 0.3, 0.1, 0.3)
			x = x + avSize + 8
		end
	end

	recalculate()

	local blk = Color(20, 20, 20)
	local wht = color_white:Copy()
	local gold = Colors.Golden:Copy()
	local hov

	local cur_mn

	----------------------------------------------

	local function createPlayer(pin)
		local ply = pin:GetPlayer()
		local av = vgui.Create("DButton", plyList)
		local real_av = vgui.Create("CircularAvatar", av)
		local curX, curY = x, y

		av:SetSize(avSize, avSize)
		av:SetPos(x, y)

		av.Player = ply
		av.PInfo = pin
		av.CurX, av.CurY = curX, curY

		real_av:Dock(FILL)

		if ply then
			real_av:SetPlayer(ply, 64)
		end

		av.HovFrac = 0
		av.Size = avSize
		av.MY = y
		av.Alpha = 255
		av.Faction = fac
		av:SetText("")

		real_av:SetMouseInputEnabled(false)

		local name = pin:GetNick()
		local col = wht

		hook.Add("PlayerLeftFaction", av, function(_, _, _, leftpin)
			if leftpin ~= pin then return end
			av:MoveBy(0, 16, 0.3, 0, 0.3)
			av:PopOut()

			for k,v in ipairs(plys) do
				if v == av then
					table.remove(plys, k)
					break
				end
			end
			recalculate()
		end)

		function av:DoClick()
			local mn = vgui.Create("FMenu")
			mn:SetPos(gui.MouseX() - 8, gui.MouseY() + 1)
			mn:MoveBy(8, 0, 0.3, 0, 0.4)
			mn:PopIn()

			hook.Run("GenerateFactionOptions", self.Faction, ply, mn)
			if table.IsEmpty(mn.Options) then mn:Remove() return end

			mn:Open()

			cur_mn = mn
			mn.SelButton = self

			BaseWars.Menu.Frame:On("Disappear", mn, function()
				mn:SetMouseInputEnabled(false)
				mn:SetKeyboardInputEnabled(false)
				mn:PopOut()
			end)
		end

		function av:Paint()
			name = pin:GetNick()
			if not ply then
				name = name .. " [left]"
			end

			if not ply and pin:GetPlayer() then
				-- player became valid
				real_av:SetPlayer(pin:GetPlayer(), 64)
				av.Player = pin:GetPlayer()
				ply = pin:GetPlayer()
			end
		end

		real_av:On("PreDemaskPaint", function(self, w, h)

			local ow = fac:GetLeaderInfo()
			render.SetStencilCompareFunction(STENCIL_EQUAL)

			if ow == pin then
				col = gold
				render.SetScissorRect(pX, pY, plyList:GetWide() + pX, plyList:GetTall() + pY, true)
					DisableClipping(true)
						draw.RoundedBox(self.Rounding,
							-2, -2, w + 4, h + 4, Colors.Golden)
					DisableClipping(false)
				render.SetScissorRect(0, 0, 0, 0, false)

				av.Owner = true
			else
				col = wht

				av.Owner = false
			end
		end)

		av:On("plyListPaintOver", function(self, w, h)
			local mx, my = plyList:ScreenToLocal(gui.MousePos())
			local X, Y = self.X, self.Y
			local y = plyList:GetTall() - avSize * 0.6

			local valid = cur_mn and cur_mn:IsValid()
			local is_sel = valid and cur_mn.SelButton == self

			curX, curY = self:GetPos()

			if is_sel or (not valid and math.PointIn2DBox(mx, my, curX, Y, avSize, plyList:GetTall() - Y)) then
				local anim, new = self:To("HovFrac", 1, 0.2, 0, 0.3)
				hov = self
				if new then plyList:Emit("Hovered", true, hovHeight) end
			else
				local anim, new = self:To("HovFrac", 0, 0.2, 0, 0.3)
				if hov == self then hov = nil end
				if new then plyList:Emit("Hovered", false, hovHeight) end
			end

			self.Rounding = 16 - 8 * self.HovFrac

			self.Y = math.ceil(y - (avSize * 0.5 + 4) * self.HovFrac)
			--self.X = curX

			if hov and hov ~= self and hov:IsValid() or not ply then
				self:To("Alpha", 70, 0.3, 0, 0.2)
			else
				self:To("Alpha", 255, 0.3, 0, 0.2)
			end

			self:SetAlpha(self.Alpha)

			if self.HovFrac > 0 then
				blk.a = self.HovFrac * 230
				col.a = self.HovFrac * 255

				render.SetScissorRect(pX, pY, plyList:GetWide() + pX, plyList:GetTall() + pY, true)
					DisableClipping(true)
						surface.SetFont("OS18")
						local tw, th = surface.GetTextSize(name)

						local tX = X + w/2 - tw/2
						local tY = math.Round(Y + -12 + 8 * self.HovFrac - th - (self.Owner and 2 or 0))
						surface.SetTextPos(tX, tY)
						surface.SetTextColor(col:Unpack())

						draw.RoundedBox(4, tX - 2, tY - 1, tw + 4, th + 2, blk)
						surface.DrawText(name)
						--draw.SimpleText2(name, "OS18", w/2, -12 + 8 * self.HovFrac, wht, 1, 4)
					DisableClipping(false)
				render.SetScissorRect(0, 0, 0, 0, false)
			end
		end)
		x = x + avSize + 8

		plys[#plys + 1] = av
	end

	----------------------------------------------

	fac:On("JoinedPlayer", plyList, function(fac, ply, pin)
		createPlayer(pin)
		recalculate()
	end)

	for k, pin in ipairs(fac:GetMembersInfo()) do
		createPlayer(pin)
	end

	self.MembersList = plyList
end

function FAC:SetFaction(fac)
	self.Faction = fac
	self.Main.Faction = fac

	self:CreateMemberList()
	self:Emit("FactionSet", fac)
end

vgui.Register("FactionPanel", FAC, "Panel")