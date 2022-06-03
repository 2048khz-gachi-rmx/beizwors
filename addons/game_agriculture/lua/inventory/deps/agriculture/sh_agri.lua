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