local base = Inventory.BaseItemObjects.Unique
local bcock = base:ExtendItemClass("Cocaine", "Cocaine")

bcock:Register()
bcock.BaseTransferCost = 150000

Agriculture.BaseCocaine = bcock

local gen = Inventory.GetClass("item_meta", "unique_item")
local cock = Inventory.ItemObjects.Cocaine or gen:Extend("Cocaine")
cock.IsCocaine = true

cock:Register()

Agriculture.MetaCocaine = cock

local cocainer = Inventory.BaseItemObjects.Generic("raw_cocaine")
	:SetName("Base Cocaine -- not supposed to see this")
	:SetModel("models/craphead_scripts/the_cocaine_factory/utility/bucket.mdl")
	:SetColor(Color(255, 250, 175))

	:SetCamPos( Vector(37.9, 48.7, 60.5) )
	:SetLookAng( Angle(41.7, -127.8, 0.0) )
	:SetFOV( 15.9 )

	:SetCountable(true)
	:SetMaxStack(25)
	:SetShouldSpin(true)

	:SetRarity("uncommon")

	:On("UpdateModel", "ResourceSkin", function(base, item, ent)
		local amt = item:GetAmount()

		local fr = math.RemapClamp(amt, 0, base:GetMaxStack(), 0, 100)

		ent:SetPoseParameter("cocaine", fr)
		ent:SetBodygroup(1, 1)
    end)

    :OverrideItemClass()

Agriculture.Cocaine = cocainer