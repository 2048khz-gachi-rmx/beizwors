AddCSLuaFile()

ENT.Base = "bw_base"
ENT.Type = "anim"
ENT.PrintName = "Template Entity"

ENT.Model = "models/lt_c/holo_keypad_large.mdl"
ENT.Skin = 0

ENT.CanTakeDamage = false
ENT.NoHUD = true
ENT.IsAIBaseSignal = true
ENT.IsAIKeyReader = true

function ENT:DerivedDataTables()
	self:NetworkVar("Int", 1, "LevelRequired")
	self:NetworkVar("Float", 1, "InsertTime")
	self:NetworkVar("Bool", 1, "Opened")

	self:SetOpened(false)
	self:SetLevelRequired(1)
end

function ENT:SetTier(t)
	self:SetLevelRequired(t)
end

function ENT:CanUseCard(itm)
	local base = itm and itm:GetBase()
	if not base then return false end

	if not base.IsKeyCard then return false end

	return true
end

function ENT:CardValid(itm)
	local base = itm and itm:GetBase()
	if base.AccessLevel < self:GetLevelRequired() then return false end

	return true
end


ENT.SwipePosLocal = Vector(0.2, 13.528625488281, -1.5764809846878)

function ENT:GetSwipePos()
	return self:LocalToWorld(self.SwipePosLocal)
end