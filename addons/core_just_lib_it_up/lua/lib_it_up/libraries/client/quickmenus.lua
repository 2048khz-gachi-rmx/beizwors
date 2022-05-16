--ent quickmenus

QuickMenus = QuickMenus or {}
QuickMenus.Registered = QuickMenus.Registered or {} --table that holds ents that registered for quickmenus for fast lookups
QuickMenus.IRegistered = QuickMenus.IRegistered or {} --table that holds same shit but sequential for fast ipairs, yes its microoptimization stfu

local qmregistered = QuickMenus.Registered

local iqmr = QuickMenus.IRegistered

openedQM = openedQM or nil --panel

local ENTITY = FindMetaTable("Entity")

QuickMenus.QuickMenu = QuickMenus.QuickMenu or Animatable:callable()
local qobj = QuickMenus.QuickMenu

function qobj:__tostring()
	return ("[QuickInteractable: [%s][%s]]"):format(self.ent:EntIndex(), self.ent:GetClass())
end

AccessorFunc(qobj, "progress", "Progress")
AccessorFunc(qobj, "dist", "UseDistance")
AccessorFunc(qobj, "time", "Time")
AccessorFunc(qobj, "KeepAlive", "KeepAlive")
AccessorFunc(qobj, "ent", "Entity")

local CreateQuickMenu

--[[
	Functions for override
]]

function qobj:OnOpen(ent, pnl)
end
function qobj:OnHold(ent, pnl)
end
function qobj:OnClose(ent, pnl)		--this is called when the qm progress was 1 but became less than 1
end
function qobj:OnFullClose(ent, pnl)	--this is called when the qm progress reaches 0
end
function qobj:OnUnhold(ent, pnl)
end
function qobj:OnReopen(ent, pnl)
end
function qobj:OnRehold(ent, pnl)
end
function qobj:Think(ent, pnl)
end
function qobj:Paint(ent, pnl)
end

function qobj:Destroy()
	table.RemoveByValue(iqmr, self)
	qmregistered[self.ent] = nil
end

function qobj:StartClose()
	if self.Closing or self.progress == 0 then
		self.Closing = true
		self.Opening = false
		return
	end

	local anim, new = self:To("progress", 0, self.progress * self.time, 0, 1)

	self.Closing = true
	self.Opening = false

	if anim then
		self._progressAnim = anim
		anim:RemoveListeners("End", 1)
	end

	if self.wasopened then
		if new then
			anim:On("End", 1, function() self:__OnFullClose() end)
		end

		if self.progress == 1 then
			self:Emit("Close")
			self:__OnClose()
		end
	end

end

function qobj:StartOpen()
	if self.Opening then return end

	local anim, new = self:To("progress", 1, (1 - self.progress) * self.time, 0, 1)

	self.Opening = true
	self.Closing = false

	if anim then
		self._progressAnim = anim
	end
								-- panel Think runs b4 GM think,	(i think)
								-- so the panel can get removed before
								-- the QM starts reopening, thus causing a
								-- reopen on a fresh panel which is bad

								-- to proc that bug you need to open on exactly the same frame as the progress reaches 0
								-- sounds hard but i managed to proc it so let's put safeguards
	if self.progress > 0 and self.wasopened and IsValid(openedQM) then
		if anim then
			anim:On("End", 1, function()
				if not IsValid(openedQM) then return end
				self:Emit("Reopen")
				self:__OnReopen()
			end)
		end

		self:Emit("BeginReopen")
		return
	end

	if new then
		anim:On("End", 1, function()
			if not IsValid(openedQM) then return end -- yes, this can happen
			self:__OnOpen()
		end)

		self:Emit("BeginOpen")
	end
end

function qobj:StopProgress()
	if self._progressAnim then self._progressAnim:Stop() end
end

function qobj:Close()
	self.Opening = false
	self.Closing = true
	self:StartClose()

	if openedQM and openedQM:IsValid() then
		openedQM:Remove()
	end

	openedQM = CreateQuickMenu()
end

function qobj:RequestClose(t)
	self.activeCD = CurTime() + self:GetTime() + (t or 0.2)
	self:StartClose()
end

function qobj:Initialize(ent)
	qmregistered[ent] = self

	iqmr[#iqmr + 1] = self


	self.progress = 0
	self.active = false
	self.wasopened = false
	self.ent = ent
	self.PopIns = {}
end


--[[
	Internal functions
]]

function qobj:__HidePopins()
	for k,v in pairs(self.PopIns) do
		if not IsValid(v.Panel) then self.PopIns[k] = nil continue end

		local btn = v.Panel

		local oX, oY = v.OffX, v.OffY

		if v.PopInAnim then

			oX = v.X - btn.X + oX
			oY = v.Y - btn.Y + oY

			v.PopInAnim:Stop()
			v.PopInAnim = nil
		end
		if v.MoveInAnim then v.MoveInAnim:Stop() v.MoveInAnim = nil end

		v.PopOutAnim = btn:PopOutHide()
		v.MoveOutAnim = btn:MoveBy(oX, oY, self:GetTime(), 0, 0.2)
	end
end



function qobj:__ShowPopins()
	for k,v in pairs(self.PopIns) do

		if not IsValid(v.Panel) then self.PopIns[k] = nil continue end

		local btn = v.Panel

		if v.PopOutAnim then v.PopOutAnim:Stop() v.PopOutAnim = nil end
		if v.MoveOutAnim then v.MoveOutAnim:Stop() v.MoveOutAnim = nil end

		if not v.NoPopin then v.PopInAnim = btn:PopInShow() end
		if not v.NoMove then v.MoveInAnim = btn:MoveTo(v.X, v.Y, self:GetTime(), 0, 0.2) end
	end
end

function qobj:__OnFullClose()
	if not self.wasopened then return end

	self.opened = false
	self.wasopened = false
	self:__HidePopins()
	self.Closing = false
	self.Opening = false
	self.progress = 0

	if self.__Canvas then
		self.__Canvas:Remove()
		self.__Canvas = nil
	end

	self:Emit("FullClose")
	self:OnFullClose(self.ent, openedQM)
end

-- begin closing after qm reached 1
function qobj:__OnClose()
	if not self.wasopened then return end

	self:__HidePopins()

	self.opened = false
	self.Open = false
	self.Closing = true

	if self.__Canvas then
		self.__Canvas:PopOutHide()
	end

	self:OnClose(self.ent, openedQM)
end

-- opened again after it has been opened once
function qobj:__OnReopen()

	self:__ShowPopins()

	self.opened = true
	self.wasopened = true

	self.Open = true

	if self.__Canvas then
		self.__Canvas:PopInShow()
	end

	self:OnReopen(self.ent, openedQM)
end

-- full open for the first time
function qobj:__OnOpen()
	self.opened = true
	self.wasopened = true

	self:__ShowPopins()

	self.Open = true
	self.Closing = false

	self:OnOpen(self.ent, openedQM)
end

--quick function for making fancy button pop-in & out animations without much hassle

function qobj:AddPopIn(pnl, x, y, offx, offy, nopop, nomove)
	local pop = {}

	self.PopIns[#self.PopIns + 1] = pop

	pop.Panel = pnl
	pop.X = x
	pop.Y = y

	pop.OffX = offx or 0
	pop.OffY = offy or 0

	pnl:SetPos(x + offx, y + offy)

	pnl:SetAlpha(0)

	if not nopop then pop.PopInAnim = pnl:PopIn() end
	if not nomove then pop.MoveInAnim = pnl:MoveTo(x, y, self:GetTime(), 0, 0.2) end

	pop.NoPopin = nopop
	pop.NoMove = nomove

	return pop
end

-- adding a canvas will fade it when the qm starts closing, re-fade it back if it gets reopened and removes when the qm gets closed entirely
-- handy!

-- add a canvas manually
function qobj:AddCanvas(pnl)
	self.__Canvas = pnl
end

-- autocreate a canvas and grab it (cached panel)
function qobj:GetCanvas(nocreate)
	if not openedQM then
		error("Can't get QM canvas without the main QM panel existing!")
		return
	end
	local ret = IsValid(self.__Canvas) and self.__Canvas
	local new = false

	if not ret and not nocreate then
		ret = vgui.Create("InvisPanel", openedQM)
		ret:SetSize(openedQM:GetSize())
		ret:SetMouseInputEnabled(true)
		new = true
	end

	self.__Canvas = ret

	return ret, new
end

function ENTITY:SetQuickInteractable(b)

	if b == false then
		table.RemoveByValue(iqmr, qmregistered[self])
		qmregistered[self] = nil
	end

	local qm = qobj:new(self)
		qm.dist = 192
		qm.time = 0.3
		qm.ease = 2

	local id = ("QuickMenus:%p"):format(self)

	self.QM = qm

	hook.OnceRet("EntityActuallyRemoved", id, function(ent)
		if ent ~= self then return false end
		if qm.progress > 0 then
			qm:Close()
			qm:Destroy()
		end
	end)

	return qm
end

function ENTITY:SetQuickMenuDist(num)
	qmregistered[self].dist = num
end

function ENTITY:SetQuickMenuTime(num)
	qmregistered[self].time = num
end

function ENTITY:SetQuickMenuEase(num)
	qmregistered[self].ease = num
end

local function DoTimer(qm)

	if not qm then
		for k,v in ipairs(iqmr) do
			DoTimer(v)
		end
		return
	end

	if qm.active then
		qm:StartOpen()
	else
		qm:StartClose()
	end

	if qm.progress > 0 then
		qm:Think()
	end

end

local function mostActiveQM()
	local mx, qm = 0, nil

	for i=1, #iqmr do
		local v = iqmr[i]
		local pr = v.progress
		if pr > mx then
			qm = v
			mx = pr
		end
	end

	return qm, mx
end

local opened

function CreateQuickMenu()
	if IsValid(openedQM) then error("creating a panel on top of an existing panel -- this is really bad") end

	local p = vgui.Create("DPanel", nil, "QuickInteractable Canvas")
	p:SetSize(ScrW(), ScrH())
	--p:Center()

	p.CurrentCircleSize = 64

	local circleOuterCol = Color(10, 10, 10)
	p.CircleOuterColor = circleOuterCol

	p.CircleInnerColor = Colors.Sky:Copy():MulHSV(1, 0.3, 1.4)
	p._CircleAlpha = 255
	p.MaxCircleSize = 64
	p.MinCircleSize = 32

	local maxperc = 0

	local qm	--the quick menu with maximum progress
	local lastEase = 1

	local pad = 6

	local shrinking = false

	function p:Think()

		maxperc = 0

		-- iterate all QM's, find the 'most active'

		qm, maxperc = mostActiveQM()

		-- check if we should even keep the panel open and
		-- whether we should shrink the circle now

		if qm then
			lastEase = qm.ease
		end

		if not qm or maxperc == 0 then
			self:Remove()
			openedQM = nil
			return
		end

		if maxperc == 1 and not shrinking then
			shrinking = true

			self:To("CurrentCircleSize", p.MinCircleSize, 0.1, 0, 0.4)
			self:To("OpenedFrac", 1, 0.1, 0, 0.4)

			self:MakePopup()

			if not qm.NoMouseInput then
				self:SetMouseInputEnabled(true)
			end

			self:SetKeyBoardInputEnabled(false)

		elseif shrinking and maxperc < 1 then
			shrinking = false
			self:To("CurrentCircleSize", self.MaxCircleSize, 0.1, 0, 0.4)
			self:To("OpenedFrac", 0, 0.1, 0, 0.4)

			self:SetMouseInputEnabled(false)
		end

		--DoTimer()

		self.CurrentQM = qm.progress == 1 and qm
	end

	function p:Paint(w, h)
		self.Fraction = frac

		self:Emit("PrePaint", w, h)
		local midX, midY = self.CircleX, self.CircleY

		if not midX or not midY then

			local x, y = w/2, h/2
			midX, midY = midX or x, midY or y

			self.CircleX = midX
			self.CircleY = midY

		end

		local perc = (maxperc ^ lastEase)
		local size = self.CurrentCircleSize

		self.Alpha = perc * 100
		self.QMFrac = perc

		self.CircleOuterColor.a = perc * 160
		self.CircleInnerColor.a = perc * self._CircleAlpha

		local canv = qm:GetCanvas(true)

		if canv and canv.MaxInnerAlpha then
			self:To("_CircleAlpha", canv.MaxInnerAlpha, qm:GetTime(), 0, 0.3)
		else
			self:To("_CircleAlpha", 255, qm:GetTime(), 0, 0.3)
		end

		surface.SetDrawColor(self.CircleOuterColor:Unpack())
		draw.MaterialCircle(midX, midY, size * Lerp(perc, 4, 2))

		draw.BeginMask()
			draw.Circle(midX, midY, size + 6, 32, perc * 100)
		draw.DeMask()
			draw.Circle(midX, midY, size - pad - Lerp(self.OpenedFrac or 0, 16, 4), 32)
		draw.DrawOp()
			surface.SetDrawColor(self.CircleInnerColor:Unpack())
			draw.MaterialCircle(midX, midY, (size-pad)*2 )
		draw.FinishMask()

		self.CircleSize = size

		self:Emit("PostPaint", w, h)

		if qm then qm:Paint(qm.ent, self) end
	end


	return p
end

hook.Add("Think", "QuickMenus", function()

	for k,v in ipairs(iqmr) do
		if not IsValid(v.ent) then
			table.remove(iqmr, k)
			qmregistered[v.ent] = nil
		end
	end

	local haveKeepAlive = false

	for k,v in ipairs(iqmr) do
		if not v.KeepAlive then
			v.active = false
		else
			haveKeepAlive = true
		end
	end

	-- if we have a keepalive QM then we don't even do the logic for the rest,
	-- since we don't want two QM's active
	if haveKeepAlive then DoTimer() return end

	local lp = LocalPlayer()

	local using = lp:KeyDown(IN_USE)
	local physgunning = lp:GetPhysgunningEntity()

	local tr = lp:GetEyeTrace()

	if not using or (not IsValid(tr.Entity) or physgunning) then DoTimer() return end

	local ent = tr.Entity
	local qm = qmregistered[ent]

	if not qm then DoTimer() return end --??

	if tr.Fraction*32768 > qm.dist then DoTimer(qm) return end

	--if:
	-- 	1. player held use
	-- 	2. player looks at a valid ent
	-- 	3. distance is ok

	--then quickmenu counts up

	qm.active = not qm.activeCD or CurTime() > qm.activeCD

	DoTimer()

	if not IsValid(openedQM) then
		openedQM = CreateQuickMenu()
	end

	qm:OnHold(qm.ent, openedQM)
end)