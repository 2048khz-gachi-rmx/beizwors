local btyp = Inventory.BaseItemObjects.Typed
local bleaf = btyp:ExtendItemClass("CocaLeaf", "CocaLeaf")

bleaf:Register()
bleaf.BaseTransferCost = 150000

Agriculture.BaseLeaf = bleaf

local gen = Inventory.GetClass("item_meta", "typed")
local ileaf = Inventory.ItemObjects.CocaLeaf or gen:Extend("CocaLeaf")
ileaf.IsLeaf = true

ileaf:Register()

Agriculture.MetaLeaf = ileaf


local bseed = Agriculture.BaseSeed

bleaf.Types = Agriculture.CocaineTypes
bseed.Types = bleaf.Types

function Agriculture.AssignType(itm)
	itm:SetTypeID(math.random(#itm:GetTypes()))
end

local leaf = Agriculture.BaseLeaf("coca")
	:SetName("Coca Leaves")
	:SetModel("models/craphead_scripts/the_cocaine_factory/utility/leaves.mdl")
	:SetColor(Color(125, 170, 90))

	:SetCamPos( Vector(-55.1, 43.1, 58) )
	:SetLookAng( Angle(38.0, -38, 0.0) )
	:SetFOV( 26 )

	:SetCountable(true)
	:SetMaxStack(25)
	:SetShouldSpin(false)

	:SetRarity("common")
	:SetAmountFormat(function(base, n)
		return ("%dg"):format(n * 10)
	end)


