AddCSLuaFile()
ENT.Base = "bw_base"
ENT.Type = "anim"
ENT.PrintName = "Base Generator"

ENT.Model = "models/props_wasteland/laundry_washer003.mdl"
ENT.Skin = 0

ENT.IsGenerator = true
ENT.PowerType = "Generator"

ENT.PowerGenerated = 15
ENT.PowerCapacity = 1000
ENT.TransmitRadius = 600
ENT.TransmitRate = 20
ENT.ConnectDistance = 600

ENT.Cableable = true


Generators = Generators or {}
ENT._UsesNetDTNotify = true

function ENT:DerivedGenDataTables()

end

function ENT:DerivedDataTables()
	self:DerivedGenDataTables()
end