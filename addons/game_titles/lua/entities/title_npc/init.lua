
AddCSLuaFile( "cl_init.lua" ) 
AddCSLuaFile( "shared.lua" )  
 
include('shared.lua')
 
function ENT:Initialize()
 
	self:SetModel( "models/player/monk.mdl" )
	self:PhysicsInit(SOLID_BBOX)
	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_NONE)          
 	self:SetUseType(3)

end

util.AddNetworkString("OpenTitleMenu")

function ENT:Use( activator, caller )
    net.Start("OpenTitleMenu")
    net.Send(activator)
end
 
function ENT:Think()
    self:SetSequence("idle_magic")

	local Time = CurTime() + self:SequenceDuration("idle_magic")
	self:NextThink(Time)

	return true

end

util.AddNetworkString("GiveMeMyTitle")

net.Receive("GiveMeMyTitle", function(len, ply)
	if not ply:GetTitleAccess() then return end
	local tit = net.ReadString()
	if #tit > 128 then return end

	ply:SetTitle(tit, true)
end)
