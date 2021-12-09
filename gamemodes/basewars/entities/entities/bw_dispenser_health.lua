
AddCSLuaFile()

ENT.Base = "bw_base_dispenser"
ENT.Type = "anim"

ENT.PrintName = "Health Dispenser"
ENT.Author = "grmx"

ENT.Model = "models/props_combine/health_charger001.mdl"

ENT.Sound = Sound("HL1/fvox/blip.wav")
ENT.EmitUnusableBeeps = false

ENT.StimRegenTime = math.huge
ENT.MaxStims = 5

ENT.IsHealthDispenser = true
ENT.MaxLevel = 4

ENT.StimDrains = 75

ENT.Levels = {
	[1] = {
		Cost = 0,
		HealRate = 5,
		ChargeRate = 1,
		MaxCharge = 65, -- not enough to create a stim
	},

	[2] = {
		Cost = 125000,
		HealRate = 10,
		ChargeRate = 1.5,
		MaxCharge = 100,
	},

	[3] = {
		Cost = 750000,
		HealRate = 15,
		ChargeRate = 2,
		MaxCharge = 150,
	},

	[4] = {
		Cost = 5e6,
		HealRate = 15,
		ChargeRate = 3,
		MaxCharge = 300,
	},
}

local RMB = Material("gui/rmb.png")
local RMBSz = 24

function ENT:GetStims()
	return math.floor(self:GetCharge() / self.StimDrains)
end

local blk = Color(0, 0, 0, 0)

function ENT:QMOnBeginClose(qm, self, pnl)
	pnl:MemberLerp(blk, "a", 0, 0.3, 0, 0.3)
	pnl:To("MouseFrac", 0, 0.3, 0, 0.3)

	local midX, midY = pnl:GetWide() / 2, pnl:GetTall() / 2

	local canv = qm:GetCanvas()
	local stimBtn = canv.GiveStimBtn
	if not stimBtn then return end

	local x = midX + pnl.MaxCircleSize + 24
	local y = midY - stimBtn:GetTall() / 2

	stimBtn:CircleMoveTo(x, y, 0.3, 0.4, true)
	local anim = stimBtn:PopOutHide(0.2)
end

local blur = Material( "pp/blurscreen" )
blur:SetFloat("$blur", 2)
blur:Recompute()

function ENT:QMOnReopen(qm, self, pnl)
	local canv = qm:GetCanvas()
	local minput = not not canv.ShouldMouse
	pnl:SetMouseInputEnabled(minput)

	pnl:MemberLerp(blk, "a", minput and 160 or 90, 0.3, 0, 0.3)
	pnl:To("MouseFrac", minput and 1 or 0, 0.3, 0, 0.3)
	canv.MaxInnerAlpha = minput and 255 or 40

	--[[local healBtn = pnl.HealBtn
	healBtn:CircleMoveTo(healBtn.ToX, healBtn.ToY, 0.3, 0.4)
	healBtn:PopIn(0.2)]]

	
	local stimBtn = canv.GiveStimBtn
	if not stimBtn then return end

	stimBtn:Stop()
	stimBtn:CircleMoveTo(stimBtn.ToX, stimBtn.ToY, 0.3, 0.4)
	stimBtn:AlphaTo(canv.StimAlpha, 0.3, 0, 0.3)
	stimBtn:Show()

end

function ENT:OpenShit(qm, self, pnl)

	local ent = self

	--pnl:SetSize(850, 600)	--cant fit
	--pnl:CenterHorizontal()
	local give_stim

	local canv = qm:GetCanvas()

	canv.MouseFrac = 0
	canv.PowerFrac = 0
	canv:SetMouseInputEnabled(true)

	function canv:PrePaint(w, h)

		if qm:GetProgress() == 1 then
			pnl:SetMouseInputEnabled(self.ShouldMouse)
		end

		local x, y = self:LocalToScreen(0, 0)

		DisableClipping(true)
			surface.SetDrawColor(blk:Unpack())
			surface.DrawRect(-ScrW(), -ScrH(), ScrW() * 2, ScrH() * 2)

			if pnl:IsMouseInputEnabled() then
				-- only blur if the user wants to interact with the dispenser
				render.UpdateScreenEffectTexture()
				surface.SetMaterial(blur)
				for i = -1, 1 do
					surface.DrawTexturedRect(-x + i, -y + i, ScrW(), ScrH())
				end
			end

		DisableClipping(false)

		if input.IsMouseDown(MOUSE_RIGHT) and not pnl:IsMouseInputEnabled() then
			pnl:SetMouseInputEnabled(true)
			self.ShouldMouse = true
			canv:MemberLerp(blk, "a", 160, 0.3, 0, 0.3)
			canv:To("MouseFrac", 1, 0.3, 0, 0.3)
			canv.MaxInnerAlpha = 255

			if canv.GiveStimBtn and canv.GiveStimBtn:IsValid() then
				local b = canv.GiveStimBtn
				b:PopIn(nil, nil, nil, true)
				b:MemberLerp(b.Shadow, "Intensity", 4, 0.2, 0, 0.3)
				b:MemberLerp(b.Shadow, "MinSpread", 1.2, 0.2, 0, 0.3)

				canv.StimAlpha = 255
			end
		end

		if self.ShouldMouse then
			DisableClipping(true)
				local ch = ent:GetCharge()
				local stims = ent:GetStims()
				local chargeStr = stims .. " stim" .. (stims > 1 and "s" or "")
				local col = lazy.Get("StimCntCol") or lazy.Set("StimCntCol", color_white:Copy())
				col.a = math.min(canv.MouseFrac, canv.PowerFrac + 0.05 + math.random() * 0.02) * 255

				local _, cntH = draw.SimpleText(Language("ChargesCounter", stims),
					"BSSB36", give_stim.X + give_stim:GetWide() / 2,
					give_stim.Y - 4, col, 1, 4)

				col = lazy.Get("NextStimCntCol") or lazy.Set("NextStimCntCol", color_white:Copy())
				col.a = math.min(canv.MouseFrac, canv.PowerFrac) * 65

				local _, cntH2 = draw.SimpleText(Language("StimCostTip", ent.StimDrains),
					"BS20", give_stim.X + give_stim:GetWide() / 2,
					give_stim.Y - 4 - cntH, col, 1, 4)

				if ent:GetLevelData().MaxCharge < ent.StimDrains then
					draw.SimpleText(Language("StimsLevel"), "BS24", give_stim.X + give_stim:GetWide() / 2,
						give_stim.Y - 4 - cntH - cntH2, col, 1, 4)
				end

			DisableClipping(false)
		end

		surface.SetMaterial(RMB)
		surface.SetDrawColor(255, 255, 255, 255 - (self.MouseFrac or 0) * 255)
		surface.DrawTexturedRect(w / 2 - RMBSz / 2, h / 2 - RMBSz / 2, RMBSz, RMBSz)
	end

	canv:MemberLerp(blk, "a", 90, 0.3, 0, 0.3)

	give_stim = vgui.Create("FButton", canv)
		give_stim:SetSize(200, 60)
		give_stim:Center()
		give_stim:SetDoubleClickingEnabled(false)

		give_stim.AlwaysDrawShadow = true
		give_stim.Shadow.Intensity = 1
		give_stim.Shadow.MaxSpread = 2
		give_stim.Shadow.MinSpread = 0.6
		give_stim.Shadow.Blur = 1

		give_stim.Label = "give me a stim,\nbartender"
		give_stim.Font = "OS22"
		give_stim.TextY = give_stim:GetTall() / 2 - 1
		give_stim.TextHeight = 18

		local toX = give_stim.X
		local toY = give_stim.Y - pnl.MaxCircleSize - give_stim:GetTall() / 2 - 22

		give_stim.Y = give_stim.Y - give_stim:GetTall() / 2 - pnl.MaxCircleSize / 2
		give_stim.X = give_stim.X - give_stim:GetWide() / 2 - pnl.MaxCircleSize / 2

		give_stim.FromX, give_stim.FromY = give_stim:GetPos()
		give_stim.ToX, give_stim.ToY = toX, toY

		give_stim:SetIcon("https://i.imgur.com/0SwgoHs.png", "adrenaline_shot.png", 32, 32)
		give_stim:CircleMoveTo(toX, toY, 0.3, 0.4)

		give_stim:SetAlpha(0)
		give_stim:AlphaTo(120, 0.1, 0)

		canv.GiveStimBtn = give_stim
		canv.StimAlpha = 120

		canv.MaxInnerAlpha = 40

		local canUse = ent:IsPowered() and ent:GetStims() >= 1

		if not canUse then
			give_stim:SetColor(Colors.Button, true)
		else
			give_stim:SetColor(Colors.Sky, true)
		end

		function give_stim:Think()
			if not ent:IsValid() then return end --thonk
			
			local pw = ent:IsPowered()
			canUse = pw and ent:GetStims() >= 1

			canv:To("PowerFrac", pw and 1 or 0, 0.3, 0, 0.3)

			if not canUse then
				self:SetColor(Colors.Button)
			else
				self:SetColor(Colors.Sky:Copy():ModHSV(0, -0.1, -0.2))
			end
		end

		function give_stim:OnHover()
			if not canUse then
				local why = (not ent:IsPowered() and Language.NoPower) or Language.NoCharges
				local cl, new = self:AddCloud("err", why)
				if new then
					cl:SetFont("OS24")
					cl:SetText(why)
					cl:SetTextColor(Colors.DarkerRed)
					cl:SetRelPos(self:GetWide() / 2, 0)
					cl.ToY = -8
				end
			end
		end

		function give_stim:OnUnhover()
			self:RemoveCloud("err")
		end

		function give_stim:DoClick()
			if not ent:IsPowered() or ent:GetStims() < 1 then return end

			net.Start("HealthDispenser")
				net.WriteEntity(ent)
			net.SendToServer()
		end

end

function ENT:CLInit()

	local qm = self:SetQuickInteractable()

	qm:SetTime(0.35)
	qm.OnOpen = function(...) self:OpenShit(...) end
	--qm.Think = function(...) self:QMThink(...) end
	qm.OnClose = function(...) self:QMOnBeginClose(...) end
	--qm.OnFullClose = function(...) self:QMOnClose(...) end
	qm.OnReopen = function(...) self:QMOnReopen(...) end

	qm.NoMouseInput = true
end

function ENT:CheckUsable()

	if self.Time and self.Time + 0.5 > CurTime() then return false end

end

function ENT:PaintStructureInfo(w, y)
	local add = self.BaseClass.PaintStructureInfo(self, w, y)
	y = y + add

	local tw, th = draw.SimpleText(self:GetStims() .. " stims", "BSB20",
		w / 2, y, color_white, 1, 5)
	return add + th
end

if SERVER then

	--[[function ENT:Think()
		local t = self:GetTable()

		if not self:IsPowered() then
			self:Halt()
			return
		elseif self:GetStims() < t.MaxStims then
			if t.Halted then
				self:SetNextStim(CurTime() + t.StimRegenTime)
			end
			self:Halt(false)
		end

		if not self.Halted then
			local ct = CurTime()

			if ct > t.NextStim then
				if self:GetStims() < t.MaxStims then
					self:SetNextStim(t.NextStim + t.StimRegenTime)
					self:SetStims(self:GetStims() + 1)
				else
					self:Halt()
				end
			end
		end
	end]]

	function ENT:Dispense(ply, dat)
		local hp = ply:Health()
		local max = ply:GetMaxHealth()
		if hp >= max then return true end
		if self:GetCharge() <= 5 then return false end

		local toHeal = math.min(self:GetCharge(), dat.HealRate, max - hp)
		self:TakeCharge(toHeal)

		ply:SetHealth(hp + toHeal)
	end

	function ENT:Halt(b)
		self.Halted = (b == nil and true) or b
		self:SetHalted(self.Halted)
	end

	--[[function ENT:SetNextStim(when)
		when = when or CurTime() + self.StimRegenTime
		self.NextStim = when
		self:SetNWNextStim(when)
	end]]

	function ENT:TakeStim(ply)
		local ok = ply:AddStims()
		if ok == false then return end

		--[[if self.Halted and self:GetStims() >= self.MaxStims then
			--self:SetNextStim()
			self:Halt(false)
		end]]
	end

	util.AddNetworkString("HealthDispenser")

	net.Receive("HealthDispenser", function(len, ply)
		local ent = net.ReadEntity()

		if not IsValid(ent) or not ent.IsHealthDispenser then return end
		if ply:GetPos():Distance(ent:GetPos()) > 256 then return end

		if ply:GetStims() >= ply:GetMaxStims() then return end
		if not ent:IsPowered() then return end
		if not ent:TakeCharge(ent.StimDrains) then return end

		ent:TakeStim(ply)
	end)
end