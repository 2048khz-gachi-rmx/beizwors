local bgen = Inventory.BaseItemObjects.Generic
local bseed = bgen:ExtendItemClass("Seed", "Seed")

bseed:Register()
bseed.BaseTransferCost = 150000

Agriculture.BaseSeed = bseed

local gen = Inventory.GetClass("item_meta", "generic_item")
local seed = Inventory.ItemObjects.Seed or gen:Extend("Seed")

seed.IsSeed = true

DataAccessor(seed, "Result", "Result")
DataAccessor(seed, "Health", "Health")
DataAccessor(seed, "Stats", "Stats")

function seed:Initialize(uid, iid)

end

function seed:InitializeNew()

	self:SetStats({})

	if not self:GetResult() then
		self:SetResult("coal")
	end

	if not self:GetHealth() then
		self:SetHealth(100)
	end
end

function seed:GetResultName()
	local b = self:GetResultBase()
	return b and b:GetName() or ("[No-Base: %d]"):format(self:GetResult())
end

function seed:GetResultBase()
	return Inventory.Util.GetBase(self:GetResult())
end

function seed:GetName()
	local base = Inventory.Util.GetBase(self:GetResult())
	if not base then return ("[No-Base: %d]"):format(self:GetResult()) end

	return ("%s Seed"):format(base:GetName())
end

function seed:GetGrowTime()
	return 5
end

function seed:GetRarityText()
	return self:GetRarity():GetName() .. " Seed"
end

function seed:GetTransferCost()
	return 10e12--self:GetBaseTransferCost() * (2 ^ (self:GetTier() - 1))
end

seed:Register()


function seed:GetWeaponType()
	return Inventory.Blueprints.WeaponPoolReverse[self:GetResult()]
end

Agriculture.MetaSeed = seed

local sneed = Inventory.BaseItemObjects.Seed("seed")
	:SetName("Base seed -- youre not supposed to see this")
	:SetModel("models/props_junk/garbage_takeoutcarton001a.mdl")
	:SetModelColor(Color(125, 170, 90))
	:SetColor(Color(125, 170, 90))

	:SetCamPos( Vector(-24.1, 74.8, 36.6) )
	:SetLookAng( Angle(25.0, -72.1, 0.0) )
	:SetFOV( 11 )

	:SetCountable(false)
	:SetShouldSpin(false)

	:SetRarity("uncommon")

Agriculture.Seed = sneed

include(Rlm(true) .. "_seed_ext.lua")