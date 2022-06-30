local base = Inventory.BaseItemObjects.Generic
local bcock = base:ExtendItemClass("Cocaine", "Cocaine")

bcock:Register()
bcock.BaseTransferCost = 150000


bcock:NetworkVar("NetStack", function(it, write)
	if write then
		local ns = netstack:new()
		ns:WriteBool(not not it:GetProcessed())

		local fx = it:GetEffects() or {}
		local amt = table.Count(fx)
		ns:WriteUInt(amt, 4)
		for k,v in pairs(fx) do
			ns:WriteUInt(k, 4)
			ns:WriteFloat(v)
		end

		return ns
	else
		it:SetProcessed(net.ReadBool())

		local efs = {}
		for i=1, net.ReadUInt(4) do
			local k = net.ReadUInt(4)
			local v = net.ReadFloat()
			efs[k] = v
		end

		it:SetEffects(efs)
	end
end, "Cocaine")

Agriculture.BaseCocaine = bcock

local gen = Inventory.GetClass("item_meta", "generic_item")
local cock = Inventory.ItemObjects.Cocaine or gen:Extend("Cocaine")
cock.IsCocaine = true

cock:Register()

DataAccessor(cock, "Effects", "Effects")
DataAccessor(cock, "Processed", "Processed")

Agriculture.MetaCocaine = cock


function cock:GetName()
	local efs = self:GetEffects()
	if not efs or table.IsEmpty(efs) then return "Dull Cocaine" end

	local proc = self:GetProcessed() and "" or "Unprocessed "
	local multiple = next(efs, next(efs))

	if not multiple then
		return ("%s %s%s"):format(Agriculture.CocaineTypes[next(efs)].Result, proc, "Cocaine")
	else
		return ("%s %s%s"):format("Mixed", proc, "Cocaine")
	end
end


local cocainer = Inventory.BaseItemObjects.Cocaine("cocaine")
	:SetName("Base Cocaine -- not supposed to see this")
	:SetModel("models/craphead_scripts/the_cocaine_factory/utility/bucket.mdl")
	:SetColor(Color(255, 250, 175))

	:SetCamPos( Vector(37.9, 48.7, 60.5) )
	:SetLookAng( Angle(41.7, -127.8, 0.0) )
	:SetFOV( 15.9 )

	:SetCountable(true)
	:SetMaxStack(10)
	:SetShouldSpin(true)

	:SetRarity("uncommon")

	:On("UpdateModel", "ResourceSkin", function(base, item, ent)
		local amt = item:GetAmount()

		local fr = math.RemapClamp(amt, 0, base:GetMaxStack(), 0, 100)

		ent:SetPoseParameter("cocaine", fr)
		ent:SetBodygroup(1, 1)
    end)


Agriculture.Cocaine = cocainer

IncludeCS("sh_cocaine_fx_ext.lua")