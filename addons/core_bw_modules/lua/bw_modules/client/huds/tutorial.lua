setfenv(1, _G)

Basewars.Tutorial = Basewars.Tutorial or {}
local tut = Basewars.Tutorial

tut.Painter = tut.Painter or BaseWars.HUD.Painter:extend()
local ptr = tut.Painter

tut.ActivePainters = tut.ActivePainters or {}
tut.StepPainters = tut.StepPainters or {}
tut.CurrentStep = "Notify"
tut.Steps = tut.Steps or {}

if cookie.GetNumber("BW_TutorialComplete", 0) == 1 then
	tut.CurrentStep = "Complete"
end

--[[
if GetConVar("developer"):GetInt() > 0 then
	cookie.Set("BW_TutorialComplete", "0")
end
]]

ChainAccessor(ptr, "Step", "Step")
ChainAccessor(ptr, "Completed", "Completed")

for k,v in pairs(tut.StepPainters) do
	v:Disappear()

	for k,_ in pairs(v:GetPoints()) do
		v:CompletePoint(k, false)
	end
end

function tut.AddStep(stepNum, step)
	assert(isstring(step))
	assert(isnumber(stepNum))

	tut.Steps[stepNum] = step
	return ptr:new(step)
end
ptr.Anims = Animatable("Tutorial")

function ptr:Initialize(step)
	assert(isstring(step))

	self.Points = TwoWayTable()
	self.PointData = {}
	self.CompletedPoints = {}

	tut.StepPainters[step] = self -- register the painter:step
	self:SetStep(step)
	self:SetCompleted(false)

	self.AppearTime = 0.3
	self.AppearDelay = 0.1
	self:SetWide(math.max(250, ScrW() * 0.15))
end

function ptr:GetPoints()
	return self.Points:GetKeys()
end

function ptr:_PointPair(what)
	if isnumber(what) then
		return what, self.Points:Get(what)
	else
		return self.Points:GetByValue(what), what
	end
end

function ptr:AddPoint(num, name)
	assert(isnumber(num))
	self.Points:Set(num, name)
end

function ptr:CompletePoint(id, b)
	if not isnumber(id) then id = self.Points:GetByValue(id) end
	if not id then errorNHf("no such point: %s", id) return end
	if self:GetCompleted() then return end

	b = (b == nil) or b

	-- if b and self.CompletedPoints[id] then return end
	if not b and not self.CompletedPoints[id] then return end

	self.CompletedPoints[id] = b
	if tut.CurrentStep ~= self:GetStep() then return end

	local allDone = true

	for k,v in pairs(self.Points:GetKeys()) do
		if not self:IsCompleted(v) then
			allDone = false
			break
		end
	end

	if allDone then
		self:SetCompleted(true)
		self:Emit("Completed")
		for k,v in pairs(tut.Steps) do
			if v == tut.CurrentStep then
				tut.CurrentStep = tut.Steps[k + 1]
				break
			end
		end

		if not tut.CurrentStep then
			-- finished
			cookie.Set("BW_TutorialComplete", "1")
			tut.CurrentStep = "Complete"
		end
	end
end

function ptr:IsCompleted(id)
	if isnumber(id) then
		return self.CompletedPoints[id]
	else
		return self.CompletedPoints[self.Points:GetByValue(id)]
	end
end

local cache = string.WrapCache()
local col = color_white:Copy()

local uncompCol = Color(125, 125, 125)
local compColor = Colors.Sky:Copy()

function ptr:GetPointDT(name)
	local pd = self.PointData[name] or {}
	self.PointData[name] = pd

	if pd.DT then return pd.DT end

	pd.DT = DeltaText()
		:SetFont("OS20")

	local dt = pd.DT

	local piece = dt:AddText("")
	piece:AddFragment("", 1)

	dt._piece = piece
	dt:CycleNext()

	return pd.DT
end

function ptr:GetPointDescription(name)
	local id, name = self:_PointPair(name)
	local pd = self.PointData[name] or {}
	self.PointData[name] = pd

	return pd.Description
end

function ptr:AddPointDescription(name, desc)
	local id, name = self:_PointPair(name)
	local pd = self.PointData[name] or {}
	self.PointData[name] = pd

	pd.Description = desc
end


function ptr:PaintPoint(name, y)
	local id, name = self:_PointPair(name)

	local font = "OSB20"
	local comp = self:IsCompleted(id)

	local curDesc = not comp
	if curDesc then
		for i=1, id - 1 do
			if not self:IsCompleted(i) then
				curDesc = false
				break
			end
		end
	end

	local dt = self:GetPointDT(name)
	local pd = self.PointData[name]

	local status = comp and "✓" or "✕"

	local pc = dt._piece

	if comp then
		pc:SetLiftStrength(12)
		pc:SetDropStrength(-12)
	else
		pc:SetLiftStrength(-12)
		pc:SetDropStrength(12)
	end

	pc:ReplaceText(1, status)

	local offset = 8 + math.floor(4 * DarkHUD.Scale)

	draw.LerpColor(pd.CompFrac or 0, col, compColor, uncompCol)
	self.Anims:MemberLerp(pd, "CompFrac", comp and 1 or 0, 0.3, 0, 0.3)
	self.Anims:MemberLerp(pd, "DescFrac", curDesc and 1 or 0, 0.3, 0, 0.3)

	pc:SetColor(col)

	local tickWide = pc:GetWide()
	local tx = cache:Wrap(name, self:GetWide() - offset * 2 - tickWide, font)
	local lines = amtNewlines(tx) + 1
	local th = draw.GetFontHeight(font)

	local preY = y

	pc:Paint(offset, y)
	draw.DrawText(tx, font, offset + tickWide + 4, y, col)
	y = y + lines * th

	local dfr = pd.DescFrac or 0

	if self:GetPointDescription(name) and dfr > 0 then
		local ty = y - 8 + 8 * dfr
		local offset = offset + 4
		local font = "BS16"
		local desc = self:GetPointDescription(name)
		local tx = offset + tickWide + 4
		local dtx = cache:Wrap(desc, self:GetWide() - tx - offset, font)
		local dlines = amtNewlines(dtx) + 1
		local th = draw.GetFontHeight(font)

		local preA = col.a
		col.a = col.a * dfr
		draw.DrawText(dtx, font, tx, ty, col)
		col.a = preA

		y = y + dlines * th
	end

	print(y - preY + 4)
	return y - preY + 4
end


function ptr:PaintPoints(y)
	y = y or 0
	local oy = y

	for k,v in ipairs(self:GetPoints()) do
		y = y + self:PaintPoint(v, y)
	end

	return y - oy
end

local col = Color(210, 225, 240)

function ptr:PaintName(y)

	local _, th = draw.SimpleText(self:GetStep(), "BSSB24",
		6 * DarkHUD.Scale, y, col)

	return th
end

function ptr:_GenMatrix(mx)
	local infr, outfr = self.AppearFrac, self.DisappearFrac

	local fr = infr - outfr

	local xOff = ScrW() - self:GetWide() * (1 - outfr) * (0.75 + infr * 0.25)
	local yAnimOff = 8

	local y = -yAnimOff + fr * yAnimOff --+ BaseWars.Bases.HUD.MaxY
		+ self.AppearToY
	y = math.floor(y)

	mx:TranslateNumber(math.floor(xOff - self.AppearToX * (infr + outfr)), y)
end

function ptr:Delete()
	table.RemoveByValue(tut.ActivePainters, self) -- remove from active but not registered
	self.Active = false
end

function ptr:Activate()
	table.insert(tut.ActivePainters, self)
	self.Active = true
	self:SetCompleted(false) -- !?
end

function tut.GetCurrentPainter()
	return tut.StepPainters[tut.CurrentStep]
end

function tut.DoPainters()
	local acPtr = tut.GetCurrentPainter()

	if acPtr then
		if #tut.ActivePainters > 0 then
			acPtr.AppearDelay = 1.2
		end

		if not acPtr.Active then
			acPtr:Activate()
		end

		acPtr:Appear()
	end

	tut.MaxY = 0

	local pre = surface.GetAlphaMultiplier()
	local active

	for i=#tut.ActivePainters, 1, -1 do
		local ptr = tut.ActivePainters[i]
		if ptr:GetFrac() == 0 then continue end

		if acPtr ~= ptr then
			ptr.DisappearDelay = 0.7
			ptr:Disappear()
		else
			active = ptr -- active gets drawn on top of everyone
			continue
		end

		surface.SetAlphaMultiplier(ptr:GetFrac())
		local ok, y = xpcall(ptr.Paint, GenerateErrorer("TutorialPainter"), ptr)
		if ok then
			tut.MaxY = math.max(tut.MaxY, y)
		end
	end

	if active then
		surface.SetAlphaMultiplier(active:GetFrac())
		local ok, y = xpcall(active.Paint, GenerateErrorer("TutorialPainter"), active)
		if ok then
			tut.MaxY = math.max(tut.MaxY, y)
		end
	end

	tut.MaxY = math.ceil(tut.MaxY)

	surface.SetAlphaMultiplier(pre)
end

hook.Add("HUDPaint", "TutorialPaint", function()
	tut.DoPainters()
end)



LibItUp.OnLoaded("bases.lua", function()
	LibItUp.OnInitEntity(function()
		FInc.FromHere("tutorials/*.lua", FInc.CLIENT)
	end)
end)

include("tutorial_tab_ext.lua")