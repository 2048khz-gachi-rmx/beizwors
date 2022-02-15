--soon:tm:
AddCSLuaFile()
include("shared.lua")

local an
local tempCol = Color(0, 0, 0)

function ENT:DrawDisplay(aMult)
	an = an or Animatable("rescomp")

	local x, y = 32, 16
	local w, h = 738 - x * 2, 160 - y * 2

	surface.SetDrawColor(20, 20, 20, 200 * aMult)
	surface.DrawRect(x, y, w, h)

	local tx = "No research queued."

	local dots
	tempCol:Set(color_white)


	if self:GetRSPerk() ~= "" then
		local perk = Research.GetPerk(self:GetRSPerk())
		if not perk then
			tx = "WTF? " .. self:GetRSPerk()
		elseif self:GetResearchFrac() == 1 then
			tx = "Research complete!"
		else
			if self:IsPowered() then
				tx = "Researching " .. perk:GetName()
				dots = ("."):rep(CurTime() * 2 % 4)
			else
				tx = "No power"
				tempCol:Set(Colors.Red)
				tempCol.a = 40 + math.random() * 30
			end
		end
	end

	tempCol.a = tempCol.a * aMult

	local fr = self.ResFr or 0

	local fnt = Fonts.PickFont("EXSB", tx, w * 0.9 - (dots and dots:GetSize() or 0), h, 72)

	draw.SimpleText2(tx, fnt, x + w / 2, y + h / 2,
		tempCol, 1, 1)

	if dots then
		surface.DrawText(dots)
	end
end

local tcol = Color(0, 0, 0)

function ENT:DrawBar(aMult)
	tcol:Set(Colors.Sky)
	tcol:MulHSV(1, 0.7, 1)
	tcol.a = tempCol.a * aMult

	local a = 1
	local o = 0

	if not self:IsPowered() then
		a = math.random()
		o = 1
	end

	if self:GetRSPerk() ~= "" then
		an:MemberLerp(self, "ResFr", 1, 0.3, 0, 0.3)
	else
		an:MemberLerp(self, "ResFr", 0, 0.7, 2, 4)
	end

	local w, h = 676, 105

	surface.SetDrawColor(20, 20, 20, (180 + a * 20) * aMult)
	surface.DrawRect(0, 0, w, h)

	local rfrCur = self:GetResearchFrac()
	an:MemberLerp(self, "ProgFr", rfrCur or 0, 0.2, 0, 0.3)

	local x, y = 16, 12
	surface.SetDrawColor(0, 0, 0, (120 + a * 30 - o * 50) * aMult)
	surface.DrawRect(x, y, w - x * 2, h - (y * 2))

	tcol.a = (200 + a * 25 - o * 120) * aMult

	surface.SetDrawColor(tcol:Unpack())
	surface.DrawRect(x, y, (w - x * 2) * (self.ProgFr or 0), h - (y * 2))
end

function ENT:RequestResearch(lv)
	local pr = net.StartPromise("ResearchComputer")
		net.WriteUInt(0, 4)
		net.WriteEntity(self)
		net.WriteString(lv:GetPerk():GetID())
		net.WriteUInt(lv:GetLevel(), 16)
	net.SendToServer()

	pr:Then(function() print("reply good") end, function() print("reply bad") end)

	return pr
end

function ENT:OpenStatusMenu()
	local ent = self

	local f = vgui.Create("FFrame")
	f:SetSize(600, 300)
	f:Center()
	f:MakePopup()
	f:PopIn()

	local canv = vgui.Create("InvisPanel", f)
	canv:Dock(FILL)

	local perk = Research.GetPerk(self:GetRSPerk())
	local lv = perk:GetLevel(self:GetRSLevel())
	local name = lv:GetName()

	local tw, th = surface.GetTextSizeQuick(name, "EXSB32")
	local yOff = 8

	function canv:PostPaint(w, h)
		draw.SimpleText2("Researching: ", "EX32", w / 2, yOff, color_white,
			1, nil, tw)

		surface.SetFont("EXSB32")
		surface.SetTextColor(lv:GetColor() or perk:GetColor() or color_white)
		surface.DrawText(name)
	end

	canv:DockPadding(0, th + yOff, 0, 0)

	local mup = vgui.Create("MarkupText", canv)
	mup:Dock(TOP)

	f:InvalidateLayout(true)

	lv:FillMarkup(mup)

	local timePnl = vgui.Create("InvisPanel", canv)
	timePnl:Dock(TOP)
	timePnl:SetTall(32)
	timePnl:DockMargin(0, 24, 0, 0)

	local ic = Icons.Clock:Copy()
		:SetAlignment(5)

	local tfmt = ("%02i:%02i:%02i.%03d")
	local mx = tfmt:format(99, 99, 99, 999)
	local twMx = surface.GetTextSizeQuick(mx, "EX24")

	local col = Color(150, 150, 150)
	ic:SetColor(col)

	function timePnl:PostPaint(w, h)
		local fr = ent:GetResearchFrac()
		local time = fr and lv:GetResearchTime() * (1 - fr) or 0
		local hrs, m, s, ms = string.TimeToH(time)

		local xOff = 4

		local tw, th = draw.SimpleText2(tfmt:format(hrs, m, s, ms * 1000), "EX24",
			w / 2 - twMx / 2, h / 2, col, 0, 1, 28 + xOff * 2, -1)

		ic:Paint(w / 2 - twMx / 2 - xOff, h / 2, 28, 28)
	end

	local finish = vgui.Create("FButton", f)
	finish:Dock(BOTTOM)
	finish:SetTall(48)
	finish:DockMargin(f:GetWide() * 0.2, 0, f:GetWide() * 0.2, 12)

	finish.Label = "Complete research"
	finish:SetColor(Colors.Sky)

	finish:SetEnabled(ent:GetResearchFrac() >= 1)

	function finish:Think()
		local fr = ent:GetResearchFrac()
		self:SetEnabled(fr and fr >= 1)
	end

	function finish:DoClick()
		local pr = net.StartPromise("ResearchComputer")
			net.WriteUInt(1, 4)
			net.WriteEntity(ent)
		net.SendToServer()

		pr:Then(function()
			f:PopOut()
			f:SetInput(false)
		end, function()

		end)
	end
end

function ENT:OpenMenu()
	if self:GetRSPerk() ~= "" then
		self:OpenStatusMenu()
		return
	end

	local trees = Research.GetTrees()

	local f = vgui.Create("NavFrame")
	f:SetSize(
		math.min(1200, ScrW() * 0.7),
		math.min(800, ScrH() * 0.8)
	)
	f:Center()

	f:MakePopup()
	f:PopIn()
	f.Navbar:Expand()

	local side = vgui.Create("ResearchSidebar", f)
	local pos, sz = f:GetPositioned(side)

	side:SetSize(f:GetWide() * 0.35, sz[2])
	side:SetPos(f:GetWide() - side:GetWide(), pos[2])
	side:SetComputer(self)

	local canv = vgui.Create("ResearchMap", f)
	canv:SetComputer(self)
	f:PositionPanel(canv)
	canv:SetWide(sz[1] - side:GetSize())

	f.Navbar.ShowHolder:SetTall(f.ExpandHeight + 4)
	canv.SearchPanel:SetTall(f.ExpandHeight - 4)

	canv:Populate()

	local initial = true

	for k,v in pairs(trees) do
		local tab = f:AddTab(v:GetName(), function(...)
			canv:SetTree(v)
			if initial then
				initial = false
				f.Navbar:Retract()
			end
		end)

		tab:SetDescription(v:GetDescription())
	end

	side:On("ResearchStarted", "Disappear", function(_, lv)
		f:PopOut()
	end)

	canv:On("SelectedPerk", "Sidebar", function(_, btn, perk)
		side:SetPerk(perk)
	end)

	canv:On("DeselectedPerk", "Sidebar", function(_, btn, perk, another)
		if side:GetPerk() == perk then
			side:SetPerk(nil, another)
		end
	end)
end

-- forward/backward, right/left, up/down
local off = Vector(16.1, 4.55, 63.52)
local farX, closeX = 16.4, 16.05

local barOff = Vector(14.6, 6.1, 55.35)

function ENT:GetResearchFrac()
	local perkId, levelId = self:GetRSPerk(), self:GetRSLevel()

	local perk = Research.GetPerk(perkId)
	if not perk then return false end

	local lv = perk:GetLevel(levelId)
	if not lv then return false end -- shouldnt happen?

	local start, tend

	if self:GetRSHalted() then
		return self:GetRSProgress()
	else
		start = self:GetRSTime()
		tend = start + lv:GetResearchTime() * (1 - self:GetRSProgress())
	end

	local passedFr = math.TimeFraction(start, tend, CurTime())

	return Lerp(passedFr, self:GetRSProgress(), 1)
end


function ENT:Draw()
	self:DrawModel()

	local dist = EyePos():Distance(self:GetPos())
	if dist > 512 then return end

	local a = math.min(math.Remap(dist, 512, 384, 0, 1), 1)

	dist = dist - 256 -- I LOVE THE DEPTH BUFFER I LOVE THE DEPTH BUFFER
	off[1] = Lerp(dist / 384, closeX, farX)

	

	local pos = self:LocalToWorld(off)
	local ang = self:GetAngles()

	ang:RotateAroundAxis(ang:Up(), 90)
	ang:RotateAroundAxis(ang:Forward(), 90)

	cam.Start3D2D(pos, ang, 0.05)
		xpcall(self.DrawDisplay, GenerateErrorer("ResearchStationRender"), self, a)
	cam.End3D2D()

	pos = self:LocalToWorld(barOff)

	cam.Start3D2D(pos, ang, 0.05)
		xpcall(self.DrawBar, GenerateErrorer("ResearchStationRender"), self, a)
	cam.End3D2D()
end

net.Receive("ResearchComputer", function()
	local is_rep = net.ReadBool()
	if is_rep then
		net.ReadPromise()
		return
	end

	local comp = net.ReadEntity()
	if not IsValid(comp) or not comp.ResearchComputer then return end
	comp:OpenMenu()
end)