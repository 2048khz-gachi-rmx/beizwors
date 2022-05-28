AddCSLuaFile()
ENT.Base = "bw_base_electronics"

ENT.Model = "models/grp/rack/rack.mdl"
ENT.Skin = 0

ENT.Capacity 		= 10000
ENT.MaxLevel 		= 25
ENT.PowerCapacity = 50000

ENT.PrintName 		= "Printer Rack"

ENT.IsValidRaidable = false
ENT.Powerless = true

function ENT:GSAT(slot, name,  min, max)
	self:NetworkVar("Float", slot, name)
end

function ENT:DerivedDataTables()
	self:GSAT(2, "Capacity")
	self:GSAT(3, "Money", 0, "GetCapacity")
	self:NetworkVar("String", 1, "Printers")
end


ENT.UsesModules = true
ENT.CompatibleModules = {
	overclocker = true,
}

function ENT:Mod_Compatible(ply, itm)
	if self.CompatibleModules[itm:GetItemName()] then
		return true
	end

	return false
end

function ENT:OnInstalledModule(slot, itm)
	print("Rack: installed", itm)
end

function ENT:OnUninstalledModule(slot, itm)
	print("Rack: uninstalled", itm)
end
