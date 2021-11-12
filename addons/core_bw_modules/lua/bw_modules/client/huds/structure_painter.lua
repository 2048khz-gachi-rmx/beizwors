local hud = BaseWars.HUD

hud.StructureInfo = hud.StructureInfo or {}
local sin = hud.StructureInfo

sin.Painter = sin.Painter or BaseWars.HUD.Painter:extend()
local ptr = sin.Painter
sin.PaintOps = sin.PaintOps or {}
sin.Anims = sin.Anims or Animatable("structureinfo")


sin.EntToPtr = sin.EntToPtr or {}		-- [ent] = painter
sin.ActivePainters = sin.ActivePainters or {}

sin.MaxY = sin.MaxY or 0


ChainAccessor(ptr, "_Entity", "Entity")

function ptr:Initialize(ent)
	assert(IsEntity(ent))

	self:SetEntity(ent)
	sin.EntToPtr[ent] = self

	table.insert(sin.ActivePainters, self)

	self.AppearTime = 0.3
	self.AppearDelay = 0.05
end

function ptr:_GenMatrix(mx)
	local infr, outfr = self.AppearFrac, self.DisappearFrac

	local fr = infr - outfr

	local ang = -22 + fr * 22

	local xOff = ScrW() - self:GetWide()
	local yAnimOff = 8

	local y = -yAnimOff + fr * yAnimOff --+ BaseWars.Bases.HUD.MaxY
		+ self.AppearToY
	y = math.floor(y)

	mx:TranslateNumber(math.floor(xOff - self.AppearToX * (infr + outfr)), y)

	mx:RotateNumber(0, ang)
	--self.TranslateY = cy
end

function sin.CreatePainter(ent)
	local p = ptr:new(ent)
	p:FillPainters(sin.PaintOps)
	return
end

function sin.AddPaintOp(prio, name, tbl)
	if (not tbl or not tbl[name]) and not ptr[name] then
		errorf("ptr:AddPaint() : tbl.%s and ptr.%s didn't exist.", name, name)
		return
	end

	for k,v in pairs(sin.EntToPtr) do
		v:AddPaint(prio, name, tbl)
	end

	sin.PaintOps[name] = {tbl, prio}
end

function ptr:Delete()
	table.RemoveByValue(sin.ActivePainters, self)
	local ent = self:GetEntity()

	if sin.EntToPtr[ent] == self then
		sin.EntToPtr[ent] = nil
	end
end


function sin.GetPainter(ent)
	if not sin.EntToPtr[ent] then
		sin.CreatePainter(ent)
	end

	return sin.EntToPtr[ent]
end

function sin.DoPainters(ent)
	local ptr = ent and sin.GetPainter(ent)

	if ptr then
		--if #sin.ActivePainters > 1 then
			ptr.AppearDelay = 0.1
		--end

		ptr:Appear()

		--[[if #sin.ActivePainters > 1 then
			ptr.AppearDelay = 0
		end]]
	end

	sin.MaxY = 0

	local pre = surface.GetAlphaMultiplier()

	local active


	-- both filters required for smooth rotation, idk whats up
	draw.EnableFilters(true, true)

	for i=#sin.ActivePainters, 1, -1 do
		local ptr = sin.ActivePainters[i]

		if ptr:GetEntity() ~= ent then
			if not ent then
				ptr.DisappearDelay = 0.2
			else
				ptr.DisappearDelay = 0
			end

			ptr:Disappear()
		else
			active = ptr -- active gets drawn on top of everyone
			continue
		end

		surface.SetAlphaMultiplier(ptr:GetFrac())
		xpcall(ptr.Paint, GenerateErrorer("StructurePainter"), ptr,
			BaseWars.Tutorial.MaxY)
	end

	if active then
		surface.SetAlphaMultiplier(ptr:GetFrac())
		xpcall(active.Paint, GenerateErrorer("StructurePainter"),
			active, BaseWars.Tutorial.MaxY)
	end

	draw.DisableFilters(true, true)
	surface.SetAlphaMultiplier(pre)
end

hook.Add("HUDPaint", "PaintBWStructure", function()
	local trace = LocalPlayer():GetEyeTrace()

	-- distance & validity check
	local ent = trace.Fraction * 32768 < 192 and
		trace.Entity:IsValid() and trace.Entity

	-- custom checks
	ent = ent and ent.IsBaseWars and
		not ent.NoHUD and ent

	sin.DoPainters(ent)
end)

FInc.FromHere("structureinfo/*.lua", _CL)

function hud.RestartPainters()
	table.Empty(sin.ActivePainters)
	table.Empty(sin.EntToPtr)
end

hud.RestartPainters()