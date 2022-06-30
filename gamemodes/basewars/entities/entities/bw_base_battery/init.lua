include("shared.lua")

util.AddNetworkString("ConnectGenerator")

function ENT:SHInit()
	self:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
end


function ENT:ForceUpdate()
	self.TransmitTime = CurTime()
end

function ENT:UpdateTransmitState()
	if not self.TransmitTime or CurTime() - self.TransmitTime < 0.5 then
		self.TransmitTime = self.TransmitTime or CurTime()
		return TRANSMIT_ALWAYS
	end
	return TRANSMIT_PVS
end

function ENT:Think()
	if not self.TransmitTime or CurTime() - self.TransmitTime < 0.5 then
		self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
	else
		self:RemoveEFlags( EFL_FORCE_CHECK_TRANSMIT )
	end

	self:Emit("Think")
end