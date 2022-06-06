Agriculture = Agriculture or {}

local leaves = Inventory.BaseItemObjects.Generic("coca")
	:SetName("Coca Leaves")
	:SetModel("models/craphead_scripts/the_cocaine_factory/utility/leaves.mdl")
	:SetColor(Color(125, 170, 90))

	:SetCamPos( Vector(-55.1, 43.1, 58) )
	:SetLookAng( Angle(38.0, -38, 0.0) )
	:SetFOV( 26 )

	:SetCountable(true)
	:SetMaxStack(25)
	:SetShouldSpin(false)

	:SetRarity("uncommon")
	:SetAmountFormat(function(base, n)
		return ("%dg"):format(n * 10)
	end)

local cocainer = Inventory.BaseItemObjects.Generic("raw_cocaine")
	:SetName("Unprocessed Cocaine")
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