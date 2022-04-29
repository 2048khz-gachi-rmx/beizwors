include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

function ENT:Init(me)
	self:PhysicsInit(SOLID_VPHYSICS)

	self.ClaimedBy = nil
	self.BWBase = nil
	self.ClaimedPlayer = {}
	self:GetPhysicsObject():EnableMotion(false)
end

function ENT:SetBase(base)
	self.BWBase = base
	self:SetBaseID(base:GetID())

	if base:GetClaimed() then
		self:Claim(base:GetOwnerFaction() or base:GetOwnerPlayer(), true)
	end
end

function ENT:Think()
	self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
	self:NextThink(CurTime() + 3)
	return true
end

function ENT:UpdateTransmitState()
	if not self:GetClaimed() then
		return TRANSMIT_ALWAYS -- unclaimed bases are always transmitted
	end

	return TRANSMIT_PVS
end

function ENT:RequestClaim(ply)
	-- see: bw_modules/bases/actions
	if self:GetClaimed() then
		printf("Core %s is already claimed; %s can't claim.", self, ply)
		return
	end

	self:Claim(ply)
end

function ENT:RequestUnclaim(ply)
	if not self:GetClaimed() then
		printf("Core %s is already unclaimed; %s can't unclaim.", self, ply)
		return
	end

	self:Unclaim()
end

function ENT:Claim(by, restore)
	assert(IsFaction(by) or CanGetPInfo(by))

	local pin = not IsFaction(by) and GetPlayerInfoGuarantee(by)
	local ply = pin and pin:GetPlayer()

	local fac = IsFaction(by) and by or ply:GetFaction()
	local base = self:GetBase()
	if not base then error("BaseCore without base, wtf?") return end

	assert(ply or fac)

	local ok

	if restore then
		ok = true
	else
		ok = base:AttemptClaim(fac or ply, ply)
	end

	if ok then

		if fac then
			self:SetClaimedID(fac:GetID())
			self:SetClaimedByFaction(true)
			self.ClaimedFaction = fac
			self.ClaimedPlayer = nil
		else
			self:SetClaimedID(pin:SteamID64())
			self:SetClaimedByFaction(false)
			self.ClaimedPlayer = ply:GetPInfo()
			self.ClaimedFaction = nil
		end

		self:GetBase():Once("Unclaim", self, function()
			self:_UnclaimEnt()
		end)
	else
		printf("%s didn't allow claiming; %s can't claim.", base, ply)
	end

end

function ENT:_UnclaimEnt()
	self.ClaimedPlayer = nil
	self.ClaimedFaction = nil

	self:SetClaimedID("")
	self:SetClaimedByFaction(false)
end

function ENT:Unclaim()
	self:GetBase():AttemptUnclaim()
end

function ENT:Use(ply)

end
