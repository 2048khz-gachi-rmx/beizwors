ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
include("shared.lua")
AddCSLuaFile("shared.lua")


local an
local noise = CreateMaterial("aib_noise6", "UnlitGeneric", {
	["$basetexture"] = "engine/noise-blur-256x256.vtf",
	["$alpha"] = 0.1
})

local scan = CreateMaterial("aib_scanline3", "UnlitGeneric", {
	["$basetexture"] = "dev/dev_scanline",
	["$alpha"] = 0.06
})

noise:SetInt("$flags", bit.bor(noise:GetInt("$flags"), 128))
scan:SetInt("$flags", bit.bor(scan:GetInt("$flags"), 128))

function ENT:Acq()
	an = an or Animatable("aibkey")
end

function ENT:QMOnOpen(qm, pnl)
	local ent = self
	local canv = qm:GetCanvas()
	local hld = vgui.Create("FFrame", canv)

	hld:SetCloseable(false, true)
	hld.HeaderSize = 28

	canv.Holder = hld
	hld.Color = Color(40, 40, 40, 250)

	hld:SetWide(canv:GetWide() * 0.24)
	hld:SetTall(canv:GetTall() * 0.18)

	hld:CenterHorizontal()

	hld.WantY = canv:GetTall() * 0.55
	hld.GoneY = canv:GetTall() * 0.58
	hld.Y = hld.GoneY

	hld:PopIn()
	hld:MoveTo(hld.X, hld.WantY, 0.3, 0, 0.3)

	hld:CacheShadow(4, {4, 8}, 4)

	function hld:PostPaint(w, h)
		draw.SimpleText("Your access cards", "EXSB24", w / 2, self.HeaderSize / 2, color_white, 1, 1)
	end

	-- generate card slots
	local scr = vgui.Create("FScrollPanel", hld)
	scr:Dock(FILL)

	local lay = vgui.Create("FIconLayout", scr)
	lay:Dock(FILL)
	lay.NoDrawBG = true

	lay.AutoMargin = 2
	lay:SetSpaceX(16)

	hld:InvalidateLayout(true)

	local invs = Inventory.Util.GetUsableInventories(CachedLocalPlayer())
	local cards = {}

	for k, inv in pairs(invs) do
		local its = inv:GetItems()
		for k,v in pairs(its) do
			local zased = v:GetBase()
			if zased.IsKeyCard then cards[#cards + 1] = v end
		end
	end

	table.sort(cards, function(a, b) return a:GetSlot() < b:GetSlot() end)

	for i=1, math.max(#cards, 8) do
		local slot = lay:Add("ItemFrame")
		local sz = 72
		slot:SetSize(sz, sz)
		slot:On("CanDrag", function() return false end)

		if cards[i] then
			slot:SetItem(cards[i])
			if not self:CanUseCard(cards[i]) then
				slot:Dehighlight()
				slot:SetMouseInputEnabled(false)
			end
		end

		function slot:DoClick()
			ent:UseCard(self:GetItem())
			qm:RequestClose(0.5)
		end
	end
end

function ENT:QMOnBeginClose(qm, pnl)
	local canv = qm:GetCanvas()
	local hld = canv.Holder

	hld:MoveTo(hld.X, hld.GoneY, qm:GetTime(), 0, 0.3)
end

function ENT:QMOnReopen(qm, pnl)
	local canv = qm:GetCanvas()
	local hld = canv.Holder

	hld:MoveTo(hld.X, hld.WantY, qm:GetTime(), 0, 0.3)
end

function ENT:UseCard(itm)
	LocalPlayer():EmitSound("weapons/arccw_fml/universal/uni-draw.wav", 70)

	net.Start("aib_keyreader")
		net.WriteUInt(itm:GetUID(), 32)
		net.WriteEntity(self)
	net.SendToServer()
end

function ENT:Initialize()
	self:SetBodygroup(1, 1)

	local qm = self:SetQuickInteractable()

	qm:SetTime(0.2)
	qm.OnOpen = function(qm, _, pnl) self:QMOnOpen(qm, pnl) end
	qm.OnClose = function(qm, _, pnl) self:QMOnBeginClose(qm, pnl) end
	qm.OnReopen = function(qm, _, pnl) self:QMOnReopen(qm, pnl) end
end

local bgCol = Color(220, 200, 100, 110)
local bgOpenCol = Color(130, 255, 130, 110)

local curBg = Color(0, 0, 0)

local acGiven = Color(150, 255, 150)

function ENT:RenderScreen()
	local ep = EyePos()
	local dist = ep:Distance(self:GetPos())
	local ac = true
	local t = self:GetTable()
	local dfr = t.Dfr or 0

	if dist < 256 then
		an:MemberLerp(t, "Dfr", 0, 1.2, 0, 0.2)
	else
		an:MemberLerp(t, "Dfr", 1, 0.4, 0, 2.2)
		ac = false
	end

	t.Dfr = t.Dfr or 0

	local a = Ease(1 - t.Dfr, 0.3)

	an:MemberLerp(t, "Ofr", self:GetOpened() and 1 or 0, 0.5, 0, 0.2)
	local ofr = t.Ofr or 0
	local cfr = 1 - ofr

	curBg:Lerp(ofr, bgCol, bgOpenCol)
	curBg.a = curBg.a * a

	local w, h = 598, 280
	local x, y = 0, 0

	local nh = h * (1 - math.ease.InBack(t.Dfr or 0)) * (1 - ofr * 0.5)

	if ac then
		-- appear
		y = h - nh
		h = nh
	else
		y = h - nh
		h = nh
	end

	y = math.ceil(y)

	surface.SetDrawColor(curBg)
	surface.DrawRect(x, y, w, h)

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(noise)

	noise:SetFloat("$alpha", math.RemapClamp(dist, 128, 384, 0.02, 0.05))

	local ru = math.random()
	local rv = math.random()
	local noiseRes = dist * 2

	surface.DrawTexturedRectUV(x, y, w, h, ru, rv, w / noiseRes + ru, h / noiseRes + rv)

	surface.SetMaterial(scan)
	surface.SetDrawColor(0, 0, 0, 255)
	local tv = (t.tvt or 0) / -6
	t.tvt = (t.tvt or 0) + FrameTime() * (2.2 + 0.8 * math.random())

	surface.DrawTexturedRectUV(x, y, w, h, 0, tv, 1, h / 768 + tv)

	local bSz = 8
	surface.SetDrawColor(0, 0, 0, 215 * a)
	surface.DrawRect(x + bSz, y + bSz, w - bSz * 2, h - bSz)

	t.ic = t.ic or Icons.Arrow:Copy()
	local aW, aH = 28, 48
	local offsetToCardReader = 54

	for i=0, 2 do
		local aFr = ((CurTime() * 1 + i / 3) % 1.33) ^ 0.3 * 1
		local pa = (1 - aFr) * 255
		local aH = math.ceil(aH + (aH * (1 - aFr) * 0.5)) * cfr
		local naW = math.ceil(aW * (0.8 + (1 - aFr) * 0.2)) * cfr
		t.ic:GetColor().a = pa * a
		t.ic:Paint(x + w - offsetToCardReader,
			y + h - aW / 2 - i * aW * 0.66,
			naW, aH,
			-90)
	end

	local avW = w - bSz - offsetToCardReader - aH + 2
	local tx, ty = bSz, y + h - aW / 2

	if cfr > 0 then
		local ty = ty

		local _, th = draw.SimpleText("Access Level: " .. self:GetLevelRequired(), "EX40", tx + avW, ty, color_white:IAlpha(a * 255 * cfr), 2, 4)
		ty = ty - th

		local _, hh = draw.SimpleText("Insert Keycard", "EXB64", tx + avW, ty + draw.GetFontHeight("EXB64") * 0.125,
			color_white:IAlpha(a * 255 * cfr), 2, 4)
	end

	if ofr > 0 then
		acGiven.a = 255 * ofr
		draw.SimpleText("Access Granted", "EXB64", w / 2, y + nh / 2, acGiven, 1, 1)
	end
end

local animTime = 3
local outOff = Vector(5.1733378171921, 13.528625488281, -1.5764809846878)
local appOff = Vector(5, 13.528625488281, -4.5764809846878)

function ENT:DrawCard()
	local t = self:GetInsertTime()
	local ct = CurTime()
	local passed = ct - t
	local ce = self.CLCard

	if passed > animTime then
		self:RemoveCard()
		return
	end

	if not IsValid(ce) then
		local base = Inventory.Util.GetBase("card" .. self:GetLevelRequired())
		if not base then
			errorNHf("no base found for card %s; using default", "card" .. self:GetLevelRequired())
			base = Inventory.Util.GetBase("card1")
		end

		local mdl = base:GetModel()
		self.CLCard = ClientsideModel(mdl, RENDERGROUP_TRANSLUCENT)
		ce = self.CLCard
		ce:Spawn()
		ce:SetRenderMode(RENDERMODE_TRANSCOLOR)

		self:Timer("Fuckyou", 5, 1, function() self:RemoveCard() end)
	end

	local outPos = self:LocalToWorld(outOff)
	local inPos = self:GetSwipePos()
	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Up(), 90)

	local fr = 1

	local inOutAnim = animTime - 0.3

	local apFr = inOutAnim * 0.15
	local inFr = inOutAnim * 0.4
	local outFr = inOutAnim

	-- yandev
	if passed < apFr then
		inPos = outPos
		outPos = self:LocalToWorld(appOff)

		fr = math.ease.OutCirc(math.Remap(passed, 0, apFr, 0, 1))
		ang = LerpAngle(fr, ang + Angle(45, 45, 90), ang)
	elseif passed < inFr then
		local f2 = math.RemapClamp(passed, animTime * 0.2, inFr, 0, 1)
		local speedup = 0.5

		if f2 < speedup then
			local f3 = math.Remap(f2, 0, speedup, 0, 1)
			fr = Ease(f3, 0.7) * speedup
		else
			local f3 = math.Remap(f2, speedup, speedup + 0.1, 0, 1)
			fr = speedup + Ease(f3, 2.2) * (1 - speedup)
		end
	elseif passed < outFr then
		fr = math.ease.InElastic(math.RemapClamp(passed, inOutAnim * 0.8, inOutAnim, 1, 0))
	else
		fr = Ease(math.Remap(passed, inOutAnim, animTime, 0, 1), 3.3)

		inPos = self:LocalToWorld(appOff)
		outPos = outPos
		ang = LerpAngle(1 - fr, ang + Angle(-45, 45, 0), ang)
		ce:SetColor(Color(255, 255, 255, (1 - fr) * 255))
	end

	local pos = LerpVector(fr, outPos, inPos)
	ce:SetPos(pos)
	ce:SetAngles(ang)
end

function ENT:RemoveCard()
	if IsValid(self.CLCard) then
		self.CLCard:Remove()
		self.CLCard = nil
	end
end

function ENT:OnRemove()
	self:RemoveCard()
end

local off = Vector (0.28, -13.411619186401, 20 * 280 / 380)
local ang = Angle(0, 90, 90)

function ENT:Draw()
	self:Acq()
	self:SetBodygroup(1, 1) -- i hate this engine

	self:DrawModel()

	cam.Start3D2D(self:LocalToWorld(off), self:LocalToWorldAngles(ang), 0.05)
		xpcall(self.RenderScreen, GenerateErrorer("AIBKeyReader"), self)
	cam.End3D2D()

	self:DrawCard()
end