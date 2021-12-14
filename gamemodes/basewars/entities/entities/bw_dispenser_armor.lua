AddCSLuaFile()

ENT.Base = "bw_base_dispenser"
ENT.Type = "anim"

ENT.PrintName = "Armor Dispenser"

ENT.Model = "models/props_combine/suit_charger001.mdl"
ENT.PowerRequired = 75

ENT.Levels = {
	{
		Cost = 0,
		ChargeRate = 0.5,
		MaxCharge = 75,

		DispenseAmt = 5,
		MaxArmor = 50,
	}, {
		Cost = 500e3,
		ChargeRate = 1,
		MaxCharge = 100,

		DispenseAmt = 10,
		MaxArmor = 75,
		PowerMult = 2,
	}, {
		Cost = 10e6,
		ChargeRate = 1.5,
		MaxCharge = 150,

		DispenseAmt = 15,
		MaxArmor = 100,
		PowerMult = 4,
	}, {
		Cost = 150e6,
		ChargeRate = 2,
		MaxCharge = 250,

		DispenseAmt = 20,
		MaxArmor = 150,
		PowerMult = 8,
	},
}


function ENT:Dispense(ply, dat)
	if not IsPlayer(ply) then return false end

	local ar = ply:Armor()
	if ar >= dat.MaxArmor then return true end

	if self:GetCharge() <= 5 then return false end

	local give = math.min(dat.DispenseAmt, dat.MaxArmor - ar, self:GetCharge())
	self:TakeCharge(give)
	ply:SetArmor(ar + give)
end
