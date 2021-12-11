include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

util.AddNetworkString("mdigitizer")

function ENT:Init(me)

end

function ENT:Think()
	self:NextThink(CurTime() + 1)
	return true
end

function ENT:Use(ply)
	net.Start("mdigitizer")
		net.WriteEntity(self)
	net.Send(ply)
end
