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

function ENT:DerivedGenDataTables()

end

function ENT:DerivedDataTables()
	--self:NetworkVar("Int", 3, "GridID")
	self:NetworkVar("Entity", 1, "Line")

	if CLIENT then

		self:NetworkVarNotify("GridID", function(self, name, old, new)
			self:OnChangeGridID(new)
		end)

	end


	self:DerivedGenDataTables()
end

if not LibItUp then
	hook.Add("LibbedItUp", "PowerGrid", function()
		include("power_grid.lua")
	end)
else
	include("power_grid.lua")
end