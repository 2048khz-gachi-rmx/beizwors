--easylua.StartEntity("bw_printer_manual")

AddCSLuaFile()
ENT.Base = "bw_base_moneyprinter"

ENT.Skin = 0

ENT.Capacity        = 0
ENT.PrintName = "Manual Printer"

ENT.FontColor = Color(200, 117, 51)
ENT.BackColor = color_black
ENT.IsValidRaidable = false
ENT.Model = "models/grp/printers/printer.mdl"

ENT.PrintAmount = 0
ENT.PrintAmount2 = 5
ENT.MaxLevel = 5
ENT.BypassMaster = true
ENT.RebootTime = 0

ENT.PowerRequired = 0
ENT.IsManualPrinter = true

function ENT:UseFunc(act, call)
	if self:BW_GetOwner() ~= act:GetPInfo() then return end

	local pg = self:GetPowerGrid()
	if not pg or not pg:TakePower(5) then return end

	if self:BW_GetOwner():GetMoney() > 25000 then
		self.BreakingDown = self.BreakingDown + 1
		self:EmitSound("buttons/combine_button7.wav")

		if self.BreakingDown >= 5 then
			local efd = EffectData()
			efd:SetOrigin(self:GetPos())
			util.Effect("Explosion", efd, nil, true)

			local ply = self:BW_GetOwner():GetPlayer()
			if IsPlayer(ply) then
				ply:TakeDamage(
					math.max(0, 100 - ply:GetPos():Distance(self:GetPos()) / 2), self, self)
			end

			self:Remove()
			return
		end
	end

	local printed = self.PrintAmount2 * self:GetLevel()

	act:GiveMoney(printed)
	hook.Run("BaseWars_PlayerEmptyPrinter", call, self, printed)
end

local misc = {}
local anim = Animatable()
anim.a = 0
local a = 0

local white = Color(255, 255, 255)
local blk = Color(0, 0, 0)

local wrappedtx
local wrappedsrc
local lines

local curTipY = 0

function ENT:Init()
	self:SetBoughtPrice(100)
	self.BreakingDown = 0
end

function ENT:PaintStructureInfo(w, y) return 0 end

function ENT:DrawTipDisplay(w, h, a)
	local tipW, tipH = w * 0.5, 72
	local tipX, tipY = w/2 - tipW/2, h * 0.05

	--surface.SetDrawColor(0, 0, 0, a * 220)
	--surface.DrawRect(tipX, tipY, tipW, tipH)

	blk.a = a * 220
	white.a = a * 255

	draw.RoundedBoxEx(32, tipX, tipY, tipW, tipH, blk, true, true, false, false)
	draw.SimpleText(Language.Tip, "OSB64", tipX + tipW / 2, tipY + tipH / 2, white, 1, 1)

	local contW, contH = w * 0.8, 0

		-- wrap text
		local contFont, exists = Language("PrinterUpgradeTipFont")
		if not exists then
			contFont = "OS28"
		end
		local hgt = contFont:match("%d+$")
		if not wrappedtx or wrappedsrc ~= Language.PrinterUpgradeTip then
			wrappedsrc = Language.PrinterUpgradeTip
			wrappedtx = string.WordWrap2(wrappedsrc, contW - 16, contFont)

			local _, lns = wrappedtx:gsub("[\r\n]", "")
			lines = lns + 1
			--lines = select("#", )
		end

		contH = lines * hgt + 16

	local contX, contY = w/2 - contW/2, tipY + tipH

	draw.RoundedBox(16, contX, contY, contW, contH, blk, false, false, true, true)
	draw.DrawText(wrappedtx, contFont, contX + 8, contY + 8, white)


	curTipY = contY + contH
end

function ENT:Draw()
	self:DrawModel()
	self:GetCachedPos(nil, misc, nil)

	local pos, ang, scale, w, h = misc[1], misc[2], misc[3], misc[4], misc[5]

	local nameW, nameH = w * 0.75, h * 0.2
    local nameX, nameY = (w - nameW) / 2, h * 0.075
    local lp = LocalPlayer()

    if self:ShouldDrawDisplay() and not BaseWars.EverUpgraded() and
    	lp:GetMoney() > self:GetUpgradeCost() and
    	self:BW_GetOwner() == lp:GetPInfo() then

    	anim:To("a", 1, 0.3, 0, 0.2)
    else
    	anim:To("a", 0, 0.3, 0, 0.2)
    end

    local a = anim.a

    
	draw.EnableFilters()
	cam.Start3D2D(pos, ang, scale)
		if a > 0 then
			local ok, err = pcall(self.DrawTipDisplay, self, w, h, a)

			if not ok then
				print("err", err)
			end
		end

		local y =  a * curTipY + 16
		local ok, err = pcall(self.DrawUpgradeCost, self, y, w, h, a)

		if not ok then
			print("err", err)
		end
	cam.End3D2D()
	draw.DisableFilters()



end

function ENT:ThinkFunc()
end

function ENT:UseBypass()
end

--easylua.EndEntity("bw_printer_manual")