include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

function ENT:Init(me)

end

function ENT:Think()
	self:NextThink(CurTime() + (self:CompletionThink() or 0))
	return true
end

function ENT:OnCompleted()
	self:UpdateTime(true)
end

function ENT:ResetCompletion()
	self._completed = nil
end

function ENT:CompletionThink()
	local st, et = self:GetTime()
	if st == 0 or et == 0 then
		return 2
	end

	local nt = math.Clamp(et - CurTime(), 0, 2)

	if et < CurTime() then
		if not self._completed then
			nt = self:OnCompleted() or nt
			self._completed = nt
			self:StateChanged()
		end
	else
		self:ResetCompletion()
	end

	return nt
end

function ENT:Use(ply)

end


function ENT:GetWorkTime() return 15 end

function ENT:UpdateTime(restart, ...)
	self:NextThink(CurTime())

	local halt = self:ShouldHalt(...)

	local isIdle = self:GetTime(...) == 0 and self:GetProgHalt(...) == 0

	local exTime = self:GetWorkTime(...)

	if isIdle or restart then
		-- idling or requested explicit restart; time anew
		self:SetProgHalt(0, ...)
		if halt then
			self:SetTime(0, 0, ...)
			return
		end

		self:ResetCompletion()
		self:SetTime(CurTime(), CurTime() + exTime, ...)
		return
	end

	if not halt then
		-- just unhalted... restore progress from fixed to time-remapping scheme
		local prog = self:GetProgHalt(...)
		self:SetProgHalt(0, ...)

		self:SetTime(
			Lerp(prog, CurTime(), CurTime() - exTime),
			Lerp(1 - prog, CurTime(), CurTime() + exTime),
			...
		)
	elseif self:GetProgHalt() == 0 then
		local sT, eT = self:GetTime(...)
		self:SetProgHalt(math.RemapClamp(CurTime(), sT, eT, 0, 1), ...)
		self:SetTime(0, 0, ...)
	else
		-- neither of the settime's hit; we have to update state manually
		self:StateChanged()
	end
end

function ENT:OnPower()
	self:UpdateTime(false)
end

function ENT:OnUnpower()
	self:UpdateTime(false)
end