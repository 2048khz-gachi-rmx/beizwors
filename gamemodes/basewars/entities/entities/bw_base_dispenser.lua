AddCSLuaFile()

local base = "bw_base_upgradable"
ENT.Base = base
ENT.Type = "anim"
ENT.PrintName = "Base Dispenser"

ENT.Sound = Sound("HL1/fvox/blip.wav")
ENT.Sound = Sound("HL1/fvox/blip.wav")

ENT.Model = "models/props_c17/FurnitureToilet001a.mdl"
ENT.MaxHealth = 250
ENT.IdlePowerMult = 0.1

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
	scripted_ents.GetStored(base).t.SetupDataTables(self)
	self:NetworkVar("Float", 2, "DispenserCharge")
	self:SetDispenserCharge(0)
end

function ENT:Initialize()
	-- scripted_ents.GetStored(base).t.Initialize(self)
	self:BaseRecurseCall("Initialize")

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

		local ow = self:BW_GetOwner()
		if ow then
			local perk = ow:GetPerkLevel("dispcharge")
			if perk then
				rate = rate * perk.TotalRate
			end
		end

		if self:GetDispenserCharge() == max then
			self:SetConsumptionMult_Mult("DispenserIdle", self.IdlePowerMult)
		else
			self:SetConsumptionMult_Mult("DispenserIdle", 1)
		end

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

function ENT:DoDispense(ply, ...)
	return self:Dispense(ply, self:GetLevelData(), ...)
end

function ENT:UseFunc(ply)
	if not IsPlayer(ply) then return end

	self.Time = CurTime()
	local emit = self:DoDispense(ply)

	if emit == nil then
		self:EmitSound(self.Sound, 100, 60)
	elseif emit == false then
		self:EmitSound("buttons/button10.wav")
		self.Time = self.Time + 0.5
	end
end

function ENT:GetChargeText()
	local ch, max = self:GetCharge(), self:GetLevelData().MaxCharge or "?"
	local txt = ("%d/%s"):format(ch, max)

	return txt, ch, max
end

function ENT:DrawStructureCharge(font, tx, y, w)
	local txt, ch, max = self:GetChargeText()
	local tw, th = surface.GetTextSizeQuick(txt, font)

	local totalH = 0

	local ic = Icons.Electricity
	local icSz = math.floor(th * .875)

	if self.UseFractionCharge and (not isnumber(ch) or ch ~= max) then
		local txt2 = (" (%d%%)"):format( (ch % 1) * 100 )
		local font2, sz2 = Fonts.PickFont("EXM", txt2, (w or 64 / 0.7) * 0.7,
			DarkHUD.Scale * 26, nil, 16)

		tx = math.ceil(tx - surface.GetTextSizeQuick(txt2, font2) / 2 - icSz / 2 - 4)

		ic:Paint(tx, y, icSz, icSz)
		tx = tx + icSz + 2

		local tw, th = draw.SimpleText(txt, font, tx, y - th * 0.125, color_white, 0, 5)
		tx = tx + tw

		local _, th2 = draw.SimpleText(txt2, font2, tx, y + th * 0.75 - sz2,
			Colors.LighterGray, 0, 5)
		totalH = totalH + th
	else
		tx = math.ceil(tx - icSz / 2 - 4)
		ic:Paint(tx, y, icSz, icSz)
		tx = tx + icSz + 2

		local tw, th = draw.SimpleText(txt, font, tx, y - th * 0.125, color_white, 0, 5)
		totalH = totalH + th
	end

	return totalH
end

function ENT:PaintStructureInfo(w, y)
	local txt = self:GetChargeText()
	local font, th1, tw = Fonts.PickFont("EXSB", txt, w * 0.8,
		DarkHUD.Scale * 36, nil, 16)

	local tx = w / 2 - tw / 2

	local totalH = self:DrawStructureCharge(font, tx, y, w)
	return totalH
end