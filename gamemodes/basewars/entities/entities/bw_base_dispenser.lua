AddCSLuaFile()

local base = "bw_base_upgradable"
ENT.Base = base
ENT.Type = "anim"
ENT.PrintName = "Base Dispenser"

ENT.Sound = Sound("HL1/fvox/blip.wav")
ENT.Sound = Sound("HL1/fvox/blip.wav")

ENT.Model = "models/props_c17/FurnitureToilet001a.mdl"

ENT.Levels = {
	{
		Cost = 0,
		DispenseMult = 1,
		ChargeRate = 1,
		MaxCharge = 100
	}, {
		Cost = 0,
		DispenseMult = 1.5,
		ChargeRate = 2,
		MaxCharge = 200
	}, {
		Cost = 0,
		DispenseMult = 2,
		ChargeRate = 3,
		MaxCharge = 300
	}
}

function ENT:SetupDataTables()
	baseclass.Get(base).SetupDataTables(self)
	self:NetworkVar("Float", 2, "DispenserCharge")
	self:SetDispenserCharge(0)
end

function ENT:Initialize()
	baseclass.Get(base).Initialize(self)
	if SERVER then
		self:SetUseType(CONTINUOUS_USE)
	end
end

function ENT:GetCharge()
	return self:GetDispenserCharge()
end
ENT.GetCharges = ENT.GetCharge

function ENT:SetCharge(amt)
	self:SetDispenserCharge(amt)
end
ENT.SetCharges = ENT.SetCharge

function ENT:TakeCharge(amt)
	amt = amt or 1
	local have = self:GetCharge() >= amt

	if have then
		self:SetCharge( math.max(self:GetCharge() - amt, 0) )
		return true
	else
		return false
	end
end
ENT.TakeCharges = ENT.TakeCharge

function ENT:HaveCharge(amt)
	return self:GetCharge() >= (amt or 1)
end

if SERVER then
	function ENT:Think()
		if not self:IsPowered() then
			self:NextThink(CurTime() + 0.5)
			return true
		end

		local dat = self:GetLevelData()
		local rate = dat.ChargeRate or 1
		local max = dat.MaxCharge or 100

		self:SetDispenserCharge(math.min(self:GetDispenserCharge() + rate, max))
		self:NextThink(CurTime() + 0.5)
		return true
	end
end

function ENT:Dispense()
	-- for override
end

function ENT:CheckUsable()
	if self.Time and self.Time + 0.5 > CurTime() then
		return false
	end
end

function ENT:UseFunc(ply)
	if not IsPlayer(ply) then return end

	self.Time = CurTime()
	local emit = self:Dispense(ply, self:GetLevelData())

	if emit == nil then
		self:EmitSound(self.Sound, 100, 60)
	elseif emit == false then
		self:EmitSound("buttons/button10.wav")
		self.Time = self.Time + 0.5
	end
end

function ENT:PaintStructureInfo(w, y)
	local ch, max = self:GetCharge(), self:GetLevelData().MaxCharge or "?"
	local txt = ("Charge: %d/%s"):format(ch, max)
	local font = Fonts.PickFont("BSB", txt, w * 0.8,
		DarkHUD.Scale * 32, nil, 16)

	local totalH = 0
	local tw = surface.GetTextSizeQuick(txt, font)

	local tx = w / 2 - tw / 2

	if self.UseFractionCharge and (not isnumber(ch) or ch ~= max) then
		local txt2 = ("  (%d%%)"):format( (ch % 1) * 100 )
		local font2, sz2 = Fonts.PickFont("BS", txt2, w * 0.7,
			DarkHUD.Scale * 26, nil, 16)

		tx = tx - surface.GetTextSizeQuick(txt2, font2) / 2
		local tw, th = draw.SimpleText(txt, font, tx, y, color_white, 0, 5)
		tx = tx + tw

		local _, th2 = draw.SimpleText(txt2, font2, tx, y + th / 2 - sz2 / 2,
			Colors.LighterGray, 0, 5)
		totalH = totalH + th
	else
		local tw, th = draw.SimpleText(txt, font, tx, y, color_white, 0, 5)
		totalH = totalH + th
	end

	return totalH
end