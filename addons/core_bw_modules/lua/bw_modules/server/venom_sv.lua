local PLAYER = FindMetaTable("Player")

Venom = Venom or {}
Venom.Tracker = Venom.Tracker or {}

function PLAYER:AddVenom(add, atk, infl)
	if not atk or not infl then
		print("pls add atk/infl to AddVenom")
	end

	local dv = self:GetDeathVar("Venom", 0)
	self:SetDeathVar("Venom", dv + add)
	self:SetNWInt("Venom", dv + add)

	if dv + add > 0 then
		Venom.Tracker[self] = {atk or self, infl}
	end
end

function PLAYER:GetVenom()
	return self:GetDeathVar("Venom", 0)
end

function PLAYER:TakeVenom(amt)
	local cur = self:GetVenom()
	local take = math.min(cur, amt)

	self:SetDeathVar("Venom", cur - take)
	self:SetNWInt("Venom", cur - take)

	if self:GetVenom() == 0 then
		Venom.Tracker[self] = nil
	end

	return take
end

function PLAYER:ClearVenom()
	self:SetDeathVar("Venom", 0)
	self:SetNWInt("Venom", 0)

	Venom.Tracker[self] = nil
end

local venomFreq = 0.2
local venomDPS = 5
local lastDealt = CurTime()

timer.Create("VenomThink", venomFreq, 0, function()
	if table.IsEmpty(Venom.Tracker) then lastDealt = CurTime() return end

	Venom.Active = true

	local cur = CurTime()
	local passed = cur - lastDealt
	local fullDeal = passed * venomDPS
	local deal, carry = math.modf(fullDeal)

	lastDealt = cur - carry / venomDPS

	for ply, atkDat in pairs(Venom.Tracker) do
		if not ply:IsValid() or not ply:Alive() then continue end

		local took = ply:TakeVenom(deal)
		if took == 0 then continue end

		local din = DamageInfo()
		din:SetDamageType(DMG_RADIATION)
		din:SetDamage(took)
		din:SetInflictor(atkDat[2] or atkDat[1])
		din:SetAttacker(atkDat[1])

		ply:TakeDamageInfo(din)
	end

	Venom.Active = false
end)

hook.Add("PlayerStimInjected", "DeVenom", function(ply, dat)
	ply:ClearVenom()
end)

hook.Add("DeathVarsErase", "VenomNW", function(ply, vars)
	ply:ClearVenom() -- reset NW
end)

hook.Add("CanForceStimpak", "VenomStim", function(ply)
	-- can use a stimpak to clear venom, regardless of hp
	if ply:GetVenom() > 0 then return true end
end)